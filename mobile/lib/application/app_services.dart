import 'package:flutter/foundation.dart';

import '../config.dart';
import '../domain/repositories/health_record_local_repository.dart';
import '../infrastructure/api/api_client.dart';
import '../infrastructure/auth/session_storage.dart';
import '../infrastructure/connectivity/connectivity_service.dart';
import '../infrastructure/database/app_database.dart';
import 'sync_service.dart';

/// The shared services for the logged-in ASHA worker: one database,
/// one API client, one connectivity monitor and one sync engine, used
/// by every screen.
class AppServices {
  AppServices._({
    required this.username,
    required this.records,
    required this.api,
    required this.connectivity,
    required this.sync,
  });

  /// For widget tests: services built from test doubles.
  @visibleForTesting
  AppServices.forTesting({
    required this.username,
    required this.records,
    required this.api,
    required this.connectivity,
    required this.sync,
  });

  final String username;
  final HealthRecordLocalRepository records;
  final ApiClient api;
  final ConnectivityService connectivity;
  final SyncService sync;

  static AppServices? _current;

  /// Services for the current user. Only valid after [startFor].
  static AppServices get current {
    final services = _current;

    if (services == null) {
      throw StateError('AppServices.startFor() has not been called');
    }

    return services;
  }

  /// Starts (or reuses) the services for [username]. Safe to call every
  /// time the home screen opens.
  static Future<AppServices> startFor(String username) async {
    final existing = _current;

    if (existing != null && existing.username == username) {
      return existing;
    }

    stop();

    final records = HealthRecordLocalRepository(AppDatabase.instance);
    final api = ApiClient(
      baseUrl: baseUrl,
      tokenProvider: SessionStorage.getAccessToken,
    );
    final connectivity = ConnectivityService(probe: api.ping);
    final sync = SyncService(
      username: username,
      repository: records,
      api: api,
      connectivity: connectivity,
    );

    final services = AppServices._(
      username: username,
      records: records,
      api: api,
      connectivity: connectivity,
      sync: sync,
    );

    _current = services;

    await sync.start();
    await connectivity.start();

    return services;
  }

  /// Stops syncing (e.g. on logout). Local records are not touched.
  static void stop() {
    _current?.sync.dispose();
    _current?.connectivity.dispose();
    _current = null;
  }
}
