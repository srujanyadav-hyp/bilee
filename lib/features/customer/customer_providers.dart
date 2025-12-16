import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Domain
import 'domain/usecases/connect_to_session.dart';
import 'domain/usecases/watch_live_bill.dart';
import 'domain/usecases/initiate_payment.dart';
import 'domain/usecases/get_all_receipts.dart';
import 'domain/usecases/get_recent_receipts.dart';
import 'domain/usecases/search_receipts.dart';

// Data
import 'data/repositories/live_bill_repository_impl.dart';
import 'data/repositories/receipt_repository_impl.dart';

// Presentation
import 'presentation/providers/live_bill_provider.dart';
import 'presentation/providers/receipt_provider.dart';

/// Customer Providers Setup
class CustomerProviders {
  /// Setup all customer providers
  static List<SingleChildWidget> getProviders() {
    // Initialize repositories
    final liveBillRepository = LiveBillRepositoryImpl();
    final receiptRepository = ReceiptRepositoryImpl();

    // Initialize use cases
    final connectToSessionUseCase = ConnectToSessionUseCase(liveBillRepository);
    final watchLiveBillUseCase = WatchLiveBillUseCase(liveBillRepository);
    final initiatePaymentUseCase = InitiatePaymentUseCase(liveBillRepository);

    final getAllReceiptsUseCase = GetAllReceiptsUseCase(receiptRepository);
    final getRecentReceiptsUseCase = GetRecentReceiptsUseCase(
      receiptRepository,
    );
    final searchReceiptsUseCase = SearchReceiptsUseCase(receiptRepository);

    return [
      // Live Bill Provider
      ChangeNotifierProvider<LiveBillProvider>(
        create: (_) => LiveBillProvider(
          connectToSessionUseCase: connectToSessionUseCase,
          watchLiveBillUseCase: watchLiveBillUseCase,
          initiatePaymentUseCase: initiatePaymentUseCase,
        ),
      ),

      // Receipt Provider
      ChangeNotifierProvider<ReceiptProvider>(
        create: (_) => ReceiptProvider(
          getAllReceiptsUseCase: getAllReceiptsUseCase,
          getRecentReceiptsUseCase: getRecentReceiptsUseCase,
          searchReceiptsUseCase: searchReceiptsUseCase,
          repository: receiptRepository,
        ),
      ),
    ];
  }
}
