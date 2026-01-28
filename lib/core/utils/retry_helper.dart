import 'dart:math';
import 'package:flutter/foundation.dart';

/// Retry Helper with Exponential Backoff
///
/// Provides retry logic for operations that may fail due to network issues
/// or temporary service unavailability.
///
/// Features:
/// - Exponential backoff (delays increase: 1s, 2s, 4s, 8s, etc.)
/// - Configurable max attempts
/// - Custom retry conditions
/// - Automatic error logging
class RetryHelper {
  /// Execute an operation with retry logic and exponential backoff
  ///
  /// [operation]: The async operation to retry
  /// [maxAttempts]: Maximum number of retry attempts (default: 3)
  /// [initialDelay]: Initial delay before first retry (default: 1 second)
  /// [maxDelay]: Maximum delay between retries (default: 30 seconds)
  /// [retryIf]: Optional condition to determine if retry should happen
  ///
  /// Example:
  /// ```dart
  /// final result = await RetryHelper.withRetry(
  ///   operation: () => _firestore.collection('items').get(),
  ///   maxAttempts: 3,
  ///   retryIf: (e) => e is FirebaseException && e.code == 'unavailable',
  /// );
  /// ```
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    bool Function(dynamic)? retryIf,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        // Check if we should retry
        final shouldRetry =
            attempts < maxAttempts && (retryIf == null || retryIf(e));

        if (!shouldRetry) {
          debugPrint('❌ Operation failed after $attempts attempts: $e');
          rethrow;
        }

        // Calculate exponential backoff delay
        final delay = _calculateDelay(
          attempts: attempts,
          initialDelay: initialDelay,
          maxDelay: maxDelay,
        );

        debugPrint(
          '⚠️ Attempt $attempts failed, retrying in ${delay.inSeconds}s: $e',
        );

        await Future.delayed(delay);
      }
    }
  }

  /// Calculate exponential backoff delay with jitter
  static Duration _calculateDelay({
    required int attempts,
    required Duration initialDelay,
    required Duration maxDelay,
  }) {
    // Exponential backoff: initialDelay * 2^(attempts-1)
    final exponentialDelay = initialDelay * pow(2, attempts - 1).toInt();

    // Cap at maxDelay
    final cappedDelay = exponentialDelay > maxDelay
        ? maxDelay
        : exponentialDelay;

    // Add jitter (random 0-20% variation) to prevent thundering herd
    final jitter = Random().nextDouble() * 0.2;
    final delayWithJitter = cappedDelay * (1 + jitter);

    return delayWithJitter;
  }

  /// Retry with custom backoff strategy
  ///
  /// Allows specifying exact delays for each retry attempt
  ///
  /// Example:
  /// ```dart
  /// await RetryHelper.withCustomBackoff(
  ///   operation: () => apiCall(),
  ///   delays: [
  ///     Duration(seconds: 1),
  ///     Duration(seconds: 5),
  ///     Duration(seconds: 10),
  ///   ],
  /// );
  /// ```
  static Future<T> withCustomBackoff<T>({
    required Future<T> Function() operation,
    required List<Duration> delays,
    bool Function(dynamic)? retryIf,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (attempts >= delays.length || (retryIf != null && !retryIf(e))) {
          rethrow;
        }

        final delay = delays[attempts];
        debugPrint(
          '⚠️ Attempt ${attempts + 1} failed, retrying in ${delay.inSeconds}s',
        );

        await Future.delayed(delay);
        attempts++;
      }
    }
  }
}
