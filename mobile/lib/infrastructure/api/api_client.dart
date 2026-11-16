import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ============================================================
// ERRORS
// ============================================================

/// The server could not be reached (no internet, server down, timeout).
/// Nothing is wrong with the record; try again later.
class NetworkException implements Exception {
  const NetworkException(this.cause);
  final Object cause;

  @override
  String toString() => 'NetworkException';
}

/// The saved login is missing or expired. The worker must log in again.
class LoginRequiredException implements Exception {
  const LoginRequiredException();
}

/// The server answered with an error status.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.detail);

  final int statusCode;

  /// Parsed `detail` from the FastAPI error body (string or map).
  final Object? detail;

  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'ApiException($statusCode)';
}

// ============================================================
// CLIENT
// ============================================================

/// All calls from the app to the FastAPI backend.
///
/// Logs only the endpoint and status code - never request or response
/// bodies, which contain patient information.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _http;

  static const _shortTimeout = Duration(seconds: 20);

  // Gemini can take up to ~60 s per model (with one fallback model),
  // plus the upload.
  static const _audioTimeout = Duration(seconds: 150);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await tokenProvider();

    if (token == null) {
      throw const LoginRequiredException();
    }

    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  /// Sends a request and maps every failure to one of three exceptions.
  /// [loginRequiredOn401] is false only for the login call itself, where
  /// 401 means "wrong credentials" and the server's message must be kept.
  Future<Map<String, dynamic>> _send(
    String label,
    Future<http.Response> Function() request, {
    bool loginRequiredOn401 = true,
  }) async {
    final http.Response response;

    try {
      response = await request();
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on SocketException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    } on HandshakeException catch (e) {
      throw NetworkException(e);
    }

    debugPrint('API $label -> ${response.statusCode}');

    if (response.statusCode == 401 && loginRequiredOn401) {
      throw const LoginRequiredException();
    }

    Object? body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      body = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map<String, dynamic> ? body['detail'] : null;
      throw ApiException(response.statusCode, detail);
    }

    if (body is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'Unexpected response');
    }

    return body;
  }

  // ----------------------------------------------------------
  // CONNECTIVITY PROBE
  // ----------------------------------------------------------

  /// True when the backend answers. Used to show Online/Offline: a phone
  /// can be on Wi-Fi and still not reach the server.
  Future<bool> ping() async {
    try {
      final response = await _http
          .get(_uri('/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // AUTHENTICATION
  // ----------------------------------------------------------

  /// Logs in (no token needed). Returns the server's login response with
  /// access_token, username, role and full_name. Wrong credentials or a
  /// disabled account give ApiException(401/403) whose detail is the
  /// server's message; an unreachable server gives NetworkException.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _send(
      'login',
      () => _http
          .post(
            _uri('/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_shortTimeout),
      loginRequiredOn401: false,
    );
  }

  /// Checks a saved session at start-up. Returns true if the server accepts
  /// the token and false if it rejects it (expired or invalid). Throws
  /// NetworkException when the server cannot be reached, and ApiException
  /// for any other server error, so the caller can keep working offline.
  Future<bool> isSessionValid() async {
    final headers = await _headers(json: false);

    try {
      await _send(
        'session check',
        () => _http
            .get(_uri('/auth/me'), headers: headers)
            .timeout(const Duration(seconds: 5)),
      );
      return true;
    } on LoginRequiredException {
      return false;
    }
  }

  // ----------------------------------------------------------
  // HEALTH RECORDS
  // ----------------------------------------------------------

  /// Safe to repeat: the same [clientRecordId] always maps to the same
  /// server record.
  Future<Map<String, dynamic>> createRecord({
    required String clientRecordId,
    required String rawInput,
    String? inputLanguage,
  }) async {
    final headers = await _headers();

    return _send(
      'create record',
      () => _http
          .post(
            _uri('/health-records'),
            headers: headers,
            body: jsonEncode({
              'client_record_id': clientRecordId,
              'raw_input': rawInput,
              'input_language': inputLanguage,
            }),
          )
          .timeout(_shortTimeout),
    );
  }

  Future<Map<String, dynamic>> getRecord(String serverRecordId) async {
    final headers = await _headers(json: false);

    return _send(
      'get record',
      () => _http
          .get(_uri('/health-records/$serverRecordId'), headers: headers)
          .timeout(_shortTimeout),
    );
  }

  /// Analyse a typed record on the server.
  Future<Map<String, dynamic>> processText(String serverRecordId) async {
    final headers = await _headers();

    return _send(
      'process text',
      () => _http
          .post(
            _uri('/health-records/$serverRecordId/process'),
            headers: headers,
          )
          .timeout(_shortTimeout),
    );
  }

  /// Send the recording to the server for Gemini transcription,
  /// translation and extraction.
  Future<Map<String, dynamic>> processAudio({
    required String serverRecordId,
    required File audioFile,
    required String language,
  }) async {
    final headers = await _headers(json: false);

    return _send('process audio', () async {
      final request = http.MultipartRequest(
        'POST',
        _uri('/health-records/$serverRecordId/process-audio'),
      )
        ..headers.addAll(headers)
        ..fields['language'] = language
        ..files.add(
          await http.MultipartFile.fromPath('audio', audioFile.path),
        );

      final streamed = await _http.send(request).timeout(_audioTimeout);
      return http.Response.fromStream(streamed).timeout(_audioTimeout);
    });
  }

  /// Safe to repeat with the same data. Different data on an already
  /// confirmed record gives ApiException(409) with the server copy in
  /// `detail['server_record']`.
  Future<Map<String, dynamic>> confirm({
    required String serverRecordId,
    required Map<String, dynamic> confirmedData,
  }) async {
    final headers = await _headers();

    return _send(
      'confirm record',
      () => _http
          .post(
            _uri('/health-records/$serverRecordId/confirm'),
            headers: headers,
            body: jsonEncode(confirmedData),
          )
          .timeout(_shortTimeout),
    );
  }
}
