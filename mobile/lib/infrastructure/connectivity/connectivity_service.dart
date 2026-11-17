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
/// check, and the server is also re-checked periodically, so recovery is
/// noticed even without a network event.
///
/// The network type Android reports is only a hint, never the answer: a
/// phone sharing its own hotspot with the PC that runs the backend can
/// report "no network" while the server is perfectly reachable through
/// the hotspot. So the server is always probed, whatever is reported.
class ConnectivityService {
  ConnectivityService({
    required this.probe,
    Stream<List<ConnectivityResult>>? networkChanges,
    Future<List<ConnectivityResult>> Function()? currentNetwork,
    this.recheckInterval = const Duration(seconds: 30),
  }) : _networkChanges = networkChanges ?? Connectivity().onConnectivityChanged,
       _currentNetwork = currentNetwork ?? Connectivity().checkConnectivity;

  /// Returns true when the backend answers.
  final Future<bool> Function() probe;
  final Stream<List<ConnectivityResult>> _networkChanges;
  final Future<List<ConnectivityResult>> Function() _currentNetwork;
  final Duration recheckInterval;

  /// Current state for the UI. Starts offline until the first check.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;
  bool _checking = false;

  Future<void> start() async {
    _subscription ??= _networkChanges.listen(_onNetworkChanged);
    _timer ??= Timer.periodic(recheckInterval, (_) => checkNow());

    try {
      if (_reportsNoNetwork(await _currentNetwork())) {
        isOnline.value = false;
      }
    } catch (_) {
      // Some platforms cannot report the network type; just probe.
    }

    await checkNow();
  }

  static bool _reportsNoNetwork(List<ConnectivityResult> results) =>
      results.every((result) => result == ConnectivityResult.none);

  void _onNetworkChanged(List<ConnectivityResult> results) {
    // Show "Offline" straight away when the network seems to be gone,
    // then let the server itself confirm (see the class comment).
    if (_reportsNoNetwork(results)) {
      isOnline.value = false;
    }

    checkNow();
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
