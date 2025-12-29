import '../entities/daily_aggregate_entity.dart';
import '../entities/session_entity.dart';
import '../repositories/i_merchant_repository.dart';

/// Use Case - Get daily aggregate
class GetDailyAggregate {
  final IMerchantRepository repository;

  GetDailyAggregate(this.repository);

  Stream<DailyAggregateEntity?> call(String merchantId, String date) {
    return repository.getDailyAggregateStream(merchantId, date);
  }
}

/// Use Case - Update daily aggregate
class UpdateDailyAggregate {
  final IMerchantRepository repository;

  UpdateDailyAggregate(this.repository);

  Future<void> call(
    String merchantId,
    String date,
    double revenue,
    List<SessionItemEntity> items,
  ) async {
    if (revenue < 0) {
      throw Exception('Revenue cannot be negative');
    }

    await repository.updateDailyAggregate(merchantId, date, revenue, items);
  }
}

/// Use Case - Generate daily report
class GenerateDailyReport {
  final IMerchantRepository repository;

  GenerateDailyReport(this.repository);

  Future<String> call(String merchantId, String date, String format) async {
    // Business validation - Only PDF is supported
    if (format.toUpperCase() != 'PDF') {
      throw Exception('Invalid export format. Only PDF is supported');
    }

    return await repository.callGenerateDailyReport(
      merchantId,
      date,
      'PDF', // Always use PDF
    );
  }
}
