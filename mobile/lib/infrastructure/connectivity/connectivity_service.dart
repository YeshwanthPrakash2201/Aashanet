import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the AASHANet backend can be reached.
///
/// "Online" here means the server answered, not merely that Wi-Fi or
/// mobile data is switched on: a phone can be connected to a network
/// with no internet, or the server can be down.
///
/// Network change events (from connectivity_plus) trigger an immediate
/// check; while a network is present the server is also re-checked
/// periodically, so recovery is noticed even without a network event.
class ConnectivityService {
  ConnectivityService({
    required this.probe,
    Stream<List<ConnectivityResult>>? networkChanges,
    Future<List<ConnectivityResult>> Function()? currentNetwork,
    this.recheckInterval = const Duration(seconds: 30),
  })  : _networkChanges =
            networkChanges ?? Connectivity().onConnectivityChanged,
        _currentNetwork =
            currentNetwork ?? Connectivity().checkConnectivity;

  /// Returns true when the backend answers.
  final Future<bool> Function() probe;
  final Stream<List<ConnectivityResult>> _networkChanges;
  final Future<List<ConnectivityResult>> Function() _currentNetwork;
  final Duration recheckInterval;

  /// Current state for the UI. Starts offline until the first check.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _hasNetwork = false;
  bool _checking = false;

  Future<void> start() async {
    _subscription ??= _networkChanges.listen(_onNetworkChanged);
    _timer ??= Timer.periodic(recheckInterval, (_) {
      if (_hasNetwork) {
        checkNow();
      }
    });

    try {
      _onNetworkChanged(await _currentNetwork());
    } catch (_) {
      // Some platforms cannot report the network type; just probe.
      _hasNetwork = true;
      await checkNow();
    }
  }

  void _onNetworkChanged(List<ConnectivityResult> results) {
    _hasNetwork =
        results.any((result) => result != ConnectivityResult.none);

    if (_hasNetwork) {
      checkNow();
    } else {
      isOnline.value = false;
    }
  }

  /// Probes the server now and updates [isOnline].
  Future<bool> checkNow() async {
    if (_checking) {
      return isOnline.value;
    }

    _checking = true;

    try {
      final reachable = await probe();
      isOnline.value = reachable;
      return reachable;
    } finally {
      _checking = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    _subscription = null;
    _timer = null;
  }
}
