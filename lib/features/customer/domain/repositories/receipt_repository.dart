import '../entities/receipt_entity.dart';

/// Repository interface for Receipt operations
abstract class ReceiptRepository {
  /// Get all receipts for current customer
  Future<List<ReceiptEntity>> getAllReceipts();

  /// Get recent receipts (last 3-5)
  Future<List<ReceiptEntity>> getRecentReceipts({int limit = 3});

  /// Get receipt by ID
  Future<ReceiptEntity?> getReceiptById(String receiptId);

  /// Get receipt by session ID
  Future<ReceiptEntity?> getReceiptBySessionId(String sessionId);

  /// Search receipts by merchant name, date, or amount
  Future<List<ReceiptEntity>> searchReceipts(String query);

  /// Filter receipts by date range
  Future<List<ReceiptEntity>> getReceiptsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Filter receipts by merchant
  Future<List<ReceiptEntity>> getReceiptsByMerchant(String merchantId);

  /// Save receipt after payment
  Future<void> saveReceipt(ReceiptEntity receipt);

  /// Create manual receipt (customer-entered expense)
  Future<void> createManualReceipt({
    required String category,
    required double amount,
    required PaymentMethod paymentMethod,
    String? merchantName,
    String? merchantUpiId,
    String? transactionId,
    bool verified = false,
  });

  /// Update receipt notes
  Future<void> updateReceiptNotes({
    required String receiptId,
    required String notes,
  });

  /// Delete receipt (local only)
  Future<void> deleteReceipt(String receiptId);

  /// Download receipt as PDF
  Future<String?> downloadReceiptPdf(String receiptId);

  /// Share receipt
  Future<bool> shareReceipt(String receiptId);

  /// Stream for real-time receipt updates
  Stream<List<ReceiptEntity>> watchReceipts();
}
