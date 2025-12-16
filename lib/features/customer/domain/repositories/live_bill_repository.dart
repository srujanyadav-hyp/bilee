import '../entities/live_bill_entity.dart';

/// Repository interface for Live Bill operations
abstract class LiveBillRepository {
  /// Connect to a merchant's live session by scanning QR
  Future<LiveBillEntity> connectToSession(String sessionId);

  /// Stream live bill updates in real-time
  Stream<LiveBillEntity> watchLiveBill(String sessionId);

  /// Disconnect from current session
  Future<void> disconnectFromSession(String sessionId);

  /// Initiate UPI payment
  Future<bool> initiateUpiPayment({
    required String sessionId,
    required String upiString,
    required double amount,
  });

  /// Confirm cash payment (merchant confirms)
  Future<bool> confirmCashPayment({
    required String sessionId,
    required double amount,
  });

  /// Get current session status
  Future<BillStatus> getSessionStatus(String sessionId);
}
