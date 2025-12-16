import '../repositories/live_bill_repository.dart';

/// Use case: Initiate UPI payment
class InitiatePaymentUseCase {
  final LiveBillRepository repository;

  InitiatePaymentUseCase(this.repository);

  Future<bool> call({
    required String sessionId,
    required String upiString,
    required double amount,
  }) async {
    try {
      return await repository.initiateUpiPayment(
        sessionId: sessionId,
        upiString: upiString,
        amount: amount,
      );
    } catch (e) {
      throw Exception('Payment initiation failed: $e');
    }
  }
}
