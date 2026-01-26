import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Performance Monitoring Service
///
/// Tracks app performance metrics and sends them to Firebase Performance Monitoring.
///
/// Features:
/// - Automatic screen rendering tracking
/// - Custom trace monitoring
/// - Network request monitoring
/// - Custom metrics
class PerformanceService {
  static final FirebasePerformance _performance = FirebasePerformance.instance;

  /// Initialize Performance Monitoring
  static Future<void> initialize() async {
    // Enable performance monitoring in release mode
    if (kReleaseMode) {
      await _performance.setPerformanceCollectionEnabled(true);
    }

    debugPrint('✅ Performance Monitoring initialized');
  }

  /// Trace an operation and measure its performance
  ///
  /// Automatically starts and stops a trace, measuring execution time
  ///
  /// Example:
  /// ```dart
  /// final receipt = await PerformanceService.trace(
  ///   'generate_receipt',
  ///   () => generateReceipt(session),
  /// );
  /// ```
  static Future<T> trace<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, int>? metrics,
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(traceName);

    // Add custom attributes
    if (attributes != null) {
      for (final entry in attributes.entries) {
        trace.putAttribute(entry.key, entry.value);
      }
    }

    await trace.start();
    debugPrint('⏱️ Performance trace started: $traceName');

    try {
      final result = await operation();

      // Add success metric
      trace.setMetric('success', 1);

      // Add custom metrics
      if (metrics != null) {
        for (final entry in metrics.entries) {
          trace.setMetric(entry.key, entry.value);
        }
      }

      return result;
    } catch (e) {
      // Add error metric
      trace.setMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
      debugPrint('✅ Performance trace stopped: $traceName');
    }
  }

  /// Create a custom trace for manual control
  ///
  /// Use this when you need fine-grained control over trace lifecycle
  ///
  /// Example:
  /// ```dart
  /// final trace = PerformanceService.createTrace('billing_session');
  /// await trace.start();
  /// // ... do work
  /// trace.setMetric('items_count', itemCount);
  /// await trace.stop();
  /// ```
  static Trace createTrace(String traceName) {
    return _performance.newTrace(traceName);
  }

  /// Track screen rendering performance
  ///
  /// Measures how long it takes to render a screen
  ///
  /// Example:
  /// ```dart
  /// await PerformanceService.trackScreenLoad(
  ///   'merchant_home',
  ///   () => Navigator.push(...),
  /// );
  /// ```
  static Future<T> trackScreenLoad<T>(
    String screenName,
    Future<T> Function() loadOperation,
  ) async {
    return trace(
      'screen_$screenName',
      loadOperation,
      attributes: {'screen_name': screenName},
    );
  }

  /// Track billing session performance
  ///
  /// Specialized trace for billing sessions
  static Future<void> trackBillingSession({
    required String sessionId,
    required int itemCount,
    required Duration duration,
  }) async {
    final trace = _performance.newTrace('billing_session');

    trace.putAttribute('session_id', sessionId);
    trace.setMetric('item_count', itemCount);
    trace.setMetric('duration_ms', duration.inMilliseconds);

    await trace.start();
    await trace.stop();

    debugPrint(
      '📊 Billing session tracked: $itemCount items in ${duration.inSeconds}s',
    );
  }

  /// Track receipt generation performance
  static Future<void> trackReceiptGeneration({
    required String receiptId,
    required int itemCount,
    required Duration duration,
  }) async {
    final trace = _performance.newTrace('receipt_generation');

    trace.putAttribute('receipt_id', receiptId);
    trace.setMetric('item_count', itemCount);
    trace.setMetric('duration_ms', duration.inMilliseconds);

    await trace.start();
    await trace.stop();

    debugPrint(
      '📊 Receipt generation tracked: $itemCount items in ${duration.inMilliseconds}ms',
    );
  }

  /// Track PDF generation performance
  static Future<void> trackPDFGeneration({
    required String reportType,
    required int pageCount,
    required Duration duration,
  }) async {
    final trace = _performance.newTrace('pdf_generation');

    trace.putAttribute('report_type', reportType);
    trace.setMetric('page_count', pageCount);
    trace.setMetric('duration_ms', duration.inMilliseconds);

    await trace.start();
    await trace.stop();

    debugPrint(
      '📊 PDF generation tracked: $pageCount pages in ${duration.inMilliseconds}ms',
    );
  }

  /// Track sync operation performance
  static Future<void> trackSyncOperation({
    required String syncType,
    required int recordCount,
    required Duration duration,
    required bool success,
  }) async {
    final trace = _performance.newTrace('sync_operation');

    trace.putAttribute('sync_type', syncType);
    trace.setMetric('record_count', recordCount);
    trace.setMetric('duration_ms', duration.inMilliseconds);
    trace.setMetric(success ? 'success' : 'error', 1);

    await trace.start();
    await trace.stop();

    debugPrint(
      '📊 Sync tracked: $syncType - $recordCount records in ${duration.inSeconds}s',
    );
  }

  /// Track database query performance
  static Future<T> trackDatabaseQuery<T>(
    String queryName,
    Future<T> Function() query,
  ) async {
    return trace(
      'db_query_$queryName',
      query,
      attributes: {'query_name': queryName},
    );
  }

  /// Enable/disable performance monitoring
  static Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    await _performance.setPerformanceCollectionEnabled(enabled);
    debugPrint('🔧 Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if performance monitoring is enabled
  static Future<bool> isPerformanceCollectionEnabled() async {
    return await _performance.isPerformanceCollectionEnabled();
  }
}
