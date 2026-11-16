import 'dart:math';

final Random _secureRandom = Random.secure();

/// Random (version 4) UUID, e.g. "3f2b8c1e-9d4a-4f6b-8e2a-1c5d7b9e0a34".
///
/// Generated on the phone so a record has a stable ID before the server
/// has ever seen it. Uses a cryptographically secure random source.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

bool isUuid(String value) => _uuidPattern.hasMatch(value);
