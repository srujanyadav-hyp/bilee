import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/live_bill_entity.dart';
import '../../domain/usecases/connect_to_session.dart';
import '../../domain/usecases/watch_live_bill.dart';
import '../../domain/usecases/initiate_payment.dart';

/// Provider for Live Bill functionality
class LiveBillProvider with ChangeNotifier {
  final ConnectToSessionUseCase connectToSessionUseCase;
  final WatchLiveBillUseCase watchLiveBillUseCase;
  final InitiatePaymentUseCase initiatePaymentUseCase;

  LiveBillProvider({
    required this.connectToSessionUseCase,
    required this.watchLiveBillUseCase,
    required this.initiatePaymentUseCase,
  });

  LiveBillEntity? _currentBill;
  bool _isLoading = false;
  bool _isConnected = false;
  String? _error;
  StreamSubscription<LiveBillEntity>? _billSubscription;

  // Getters
  LiveBillEntity? get currentBill => _currentBill;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Connect to a session by scanning QR
  Future<void> connectToSession(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First connect
      final bill = await connectToSessionUseCase.call(sessionId);
      _currentBill = bill;
      _isConnected = true;

      // Then watch for updates
      _watchBillUpdates(sessionId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Watch bill updates in real-time
  void _watchBillUpdates(String sessionId) {
    _billSubscription?.cancel();
    _billSubscription = watchLiveBillUseCase
        .call(sessionId)
        .listen(
          (bill) {
            _currentBill = bill;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  /// Initiate UPI payment
  Future<bool> initiatePayment({
    required String sessionId,
    required String upiString,
    required double amount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await initiatePaymentUseCase.call(
        sessionId: sessionId,
        upiString: upiString,
        amount: amount,
      );

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current session
  void disconnect() {
    _billSubscription?.cancel();
    _billSubscription = null;
    _currentBill = null;
    _isConnected = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _billSubscription?.cancel();
    super.dispose();
  }
}
