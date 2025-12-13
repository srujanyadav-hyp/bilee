import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity Service - Monitors network status and manages offline mode
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isOnline = true;
  bool _isInitialized = false;
  DateTime? _lastOnlineAt;
  Duration? _offlineDuration;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get isInitialized => _isInitialized;
  DateTime? get lastOnlineAt => _lastOnlineAt;
  Duration? get offlineDuration => _offlineDuration;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('Connectivity error: $error');
      },
    );

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;

    // Check if connection is available
    _isOnline = result != ConnectivityResult.none;

    // Track offline duration
    if (!_isOnline && wasOnline) {
      // Just went offline
      _lastOnlineAt = DateTime.now();
    } else if (_isOnline && !wasOnline) {
      // Just came back online
      if (_lastOnlineAt != null) {
        _offlineDuration = DateTime.now().difference(_lastOnlineAt!);
      }
    }

    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
      notifyListeners();
    }
  }

  String getConnectionType(ConnectivityResult result) {
    if (result == ConnectivityResult.wifi) {
      return 'WiFi';
    } else if (result == ConnectivityResult.mobile) {
      return 'Mobile Data';
    } else if (result == ConnectivityResult.ethernet) {
      return 'Ethernet';
    } else {
      return 'None';
    }
  }

  Future<bool> checkInternetAccess() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking internet access: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
