import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/infrastructure/connectivity/connectivity_service.dart';

void main() {
  late StreamController<List<ConnectivityResult>> network;
  late bool serverUp;
  late ConnectivityService service;

  setUp(() {
    network = StreamController<List<ConnectivityResult>>.broadcast();
    serverUp = true;
    service = ConnectivityService(
      probe: () async => serverUp,
      networkChanges: network.stream,
      currentNetwork: () async => [ConnectivityResult.none],
      recheckInterval: const Duration(hours: 1),
    );
  });

  tearDown(() async {
    service.dispose();
    await network.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts offline when there is no network', () async {
    await service.start();
    expect(service.isOnline.value, isFalse);
  });

  test('goes online when Wi-Fi appears and the server answers', () async {
    await service.start();

    network.add([ConnectivityResult.wifi]);
    await settle();

    expect(service.isOnline.value, isTrue);
  });

  test('Wi-Fi without a reachable server still counts as offline', () async {
    serverUp = false;
    await service.start();

    network.add([ConnectivityResult.wifi]);
    await settle();

    expect(service.isOnline.value, isFalse);
  });

  test('goes offline immediately when the network disappears', () async {
    await service.start();
    network.add([ConnectivityResult.mobile]);
    await settle();
    expect(service.isOnline.value, isTrue);

    network.add([ConnectivityResult.none]);
    await settle();

    expect(service.isOnline.value, isFalse);
  });
}
