import 'package:firebase_analytics/firebase_analytics.dart';

/// Analytics service for tracking merchant events
class MerchantAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Merchant Home Events
  static Future<void> logMerchantHomeViewed(String merchantId) async {
    await _analytics.logEvent(
      name: 'merchant_home_viewed',
      parameters: {
        'merchant_id': merchantId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logStartBillingClicked(String merchantId) async {
    await _analytics.logEvent(
      name: 'merchant_start_billing_clicked',
      parameters: {
        'merchant_id': merchantId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Item Library Events
  static Future<void> logItemAdded({
    required String merchantId,
    required String itemName,
    required double price,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'merchant_item_added',
      parameters: {
        'merchant_id': merchantId,
        'item_name': itemName,
        'price': price,
        'category': category,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logItemEdited({
    required String merchantId,
    required String itemId,
    required String itemName,
  }) async {
    await _analytics.logEvent(
      name: 'merchant_item_edited',
      parameters: {
        'merchant_id': merchantId,
        'item_id': itemId,
        'item_name': itemName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logItemDeleted({
    required String merchantId,
    required String itemId,
    required String itemName,
  }) async {
    await _analytics.logEvent(
      name: 'merchant_item_deleted',
      parameters: {
        'merchant_id': merchantId,
        'item_id': itemId,
        'item_name': itemName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Billing Events
  static Future<void> logBillingStarted(String merchantId) async {
    await _analytics.logEvent(
      name: 'merchant_billing_started',
      parameters: {
        'merchant_id': merchantId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logBillingItemAdded({
    required String merchantId,
    required String itemName,
    required int quantity,
    required double price,
  }) async {
    await _analytics.logEvent(
      name: 'merchant_billing_item_added',
      parameters: {
        'merchant_id': merchantId,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Session Events
  static Future<void> logSessionCreated({
    required String merchantId,
    required String sessionId,
    required double total,
    required int itemCount,
  }) async {
    await _analytics.logEvent(
      name: 'session_created',
      parameters: {
        'merchant_id': merchantId,
        'session_id': sessionId,
        'total': total,
        'item_count': itemCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logSessionPaymentMarked({
    required String merchantId,
    required String sessionId,
    required String paymentMethod,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'session_payment_marked',
      parameters: {
        'merchant_id': merchantId,
        'session_id': sessionId,
        'payment_method': paymentMethod,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logSessionFinalized({
    required String merchantId,
    required String sessionId,
    required double total,
    required String paymentMethod,
  }) async {
    await _analytics.logEvent(
      name: 'session_finalized',
      parameters: {
        'merchant_id': merchantId,
        'session_id': sessionId,
        'total': total,
        'payment_method': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Daily Summary Events
  static Future<void> logDailySummaryViewed({
    required String merchantId,
    required String date,
  }) async {
    await _analytics.logEvent(
      name: 'daily_summary_viewed',
      parameters: {
        'merchant_id': merchantId,
        'date': date,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logDailySummaryExported({
    required String merchantId,
    required String date,
    required String format,
  }) async {
    await _analytics.logEvent(
      name: 'daily_summary_exported',
      parameters: {
        'merchant_id': merchantId,
        'date': date,
        'format': format,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Revenue Tracking
  static Future<void> logRevenue({
    required String merchantId,
    required double amount,
    required String currency,
  }) async {
    await _analytics.logEvent(
      name: 'revenue',
      parameters: {
        'merchant_id': merchantId,
        'value': amount,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Error Tracking
  static Future<void> logError({
    required String merchantId,
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await _analytics.logEvent(
      name: 'merchant_error',
      parameters: {
        'merchant_id': merchantId,
        'error_type': errorType,
        'error_message': errorMessage,
        if (screenName != null) 'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
