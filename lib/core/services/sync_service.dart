import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';
import '../utils/retry_helper.dart';
import 'performance_service.dart';

/// Sync Service - Manages syncing local data to Firestore when online
class SyncService extends ChangeNotifier {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;
  int _pendingSyncCount = 0;
  DateTime? _lastSyncAt;
  String? _lastSyncError;
  Timer? _syncTimer;

  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSyncCount;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastSyncError => _lastSyncError;

  SyncService(this._connectivity) {
    _init();
  }

  void _init() {
    // Listen to connectivity changes
    _connectivity.addListener(_onConnectivityChanged);

    // Start periodic sync check (every 2 minutes)
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });

    // Check pending items on init
    _updatePendingCount();
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline && _pendingSyncCount > 0) {
      // Trigger sync when coming back online
      debugPrint('Back online, starting sync...');
      syncAll();
    }
  }

  Future<void> _updatePendingCount() async {
    try {
      final stats = await _localDb.getDatabaseStats();
      _pendingSyncCount = stats['syncQueue'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pending count: $e');
    }
  }

  /// Sync all pending operations to Firestore
  Future<void> syncAll() async {
    if (_isSyncing || _connectivity.isOffline) {
      return;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    // Track sync performance
    final syncStartTime = DateTime.now();
    int totalRecordsSynced = 0;
    bool syncSuccess = true;

    try {
      // 1. Sync pending sessions
      final sessionCount = await _syncSessions();
      totalRecordsSynced += sessionCount;

      // 2. Sync activity logs
      final logCount = await _syncActivityLogs();
      totalRecordsSynced += logCount;

      // 3. Process sync queue
      final queueCount = await _processSyncQueue();
      totalRecordsSynced += queueCount;

      _lastSyncAt = DateTime.now();
      debugPrint('✅ Sync completed successfully');
    } catch (e) {
      syncSuccess = false;
      _lastSyncError = e.toString();
      debugPrint('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
      await _updatePendingCount();

      // Track sync operation performance
      final syncDuration = DateTime.now().difference(syncStartTime);
      await PerformanceService.trackSyncOperation(
        syncType: 'full_sync',
        recordCount: totalRecordsSynced,
        duration: syncDuration,
        success: syncSuccess,
      );
    }
  }

  Future<int> _syncSessions() async {
    final sessions = await _localDb.getUnsyncedSessions();
    debugPrint('🔄 Syncing ${sessions.length} sessions...');

    int syncedCount = 0;

    for (final session in sessions) {
      try {
        // Parse items from JSON
        final items = jsonDecode(session['items'] as String) as List;

        // Create session in Firestore with retry logic
        await RetryHelper.withRetry(
          operation: () => _firestore
              .collection('sessions')
              .doc(session['id'] as String)
              .set({
                'merchantId': session['merchantId'],
                'staffId': session['staffId'],
                'items': items,
                'totalAmount': session['totalAmount'],
                'discount': session['discount'],
                'tax': session['tax'],
                'paymentMethod': session['paymentMethod'],
                'paymentStatus': session['paymentStatus'],
                'createdAt': Timestamp.fromMillisecondsSinceEpoch(
                  session['createdAt'] as int,
                ),
                'syncedFrom': 'offline',
              }),
          maxAttempts: 3,
          retryIf: (e) =>
              e is FirebaseException &&
              (e.code == 'unavailable' || e.code == 'deadline-exceeded'),
        );

        // Mark as synced in local DB
        await _localDb.markSessionAsSynced(session['id'] as String);
        debugPrint('✅ Synced session: ${session['id']}');
        syncedCount++;
      } catch (e) {
        debugPrint('❌ Error syncing session ${session['id']}: $e');
        // Continue with next session
      }
    }

    return syncedCount;
  }

  Future<int> _syncActivityLogs() async {
    final logs = await _localDb.getUnsyncedLogs();
    debugPrint('Syncing ${logs.length} activity logs...');

    final batch = _firestore.batch();
    final syncedIds = <int>[];

    for (final log in logs) {
      try {
        final docRef = _firestore.collection('staff_activity_logs').doc();

        batch.set(docRef, {
          'staffId': log['staffId'],
          'merchantId': log['merchantId'],
          'activityType': log['activityType'],
          'description': log['description'],
          'entityType': log['entityType'],
          'entityId': log['entityId'],
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(
            log['createdAt'] as int,
          ),
          'syncedFrom': 'offline',
        });

        syncedIds.add(log['id'] as int);
      } catch (e) {
        debugPrint('Error preparing log ${log['id']} for sync: $e');
      }
    }

    if (syncedIds.isNotEmpty) {
      await RetryHelper.withRetry(
        operation: () => batch.commit(),
        maxAttempts: 3,
        retryIf: (e) =>
            e is FirebaseException &&
            (e.code == 'unavailable' || e.code == 'deadline-exceeded'),
      );
      await _localDb.markLogsAsSynced(syncedIds);
      debugPrint('✅ Synced ${syncedIds.length} activity logs');
    }

    return syncedIds.length;
  }

  Future<int> _processSyncQueue() async {
    final queue = await _localDb.getSyncQueue();
    debugPrint('🔄 Processing ${queue.length} sync queue items...');

    int syncedCount = 0;

    for (final item in queue) {
      try {
        final operationType = item['operationType'] as String;
        final entityType = item['entityType'] as String;
        final entityId = item['entityId'] as String;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

        // Process based on operation type with retry logic
        await RetryHelper.withRetry(
          operation: () async {
            switch (operationType) {
              case 'CREATE':
                await _firestore.collection(entityType).doc(entityId).set(data);
                break;
              case 'UPDATE':
                await _firestore
                    .collection(entityType)
                    .doc(entityId)
                    .update(data);
                break;
              case 'DELETE':
                await _firestore.collection(entityType).doc(entityId).delete();
                break;
            }
          },
          maxAttempts: 3,
          retryIf: (e) =>
              e is FirebaseException &&
              (e.code == 'unavailable' || e.code == 'deadline-exceeded'),
        );

        // Remove from queue after successful sync
        await _localDb.removeSyncQueueItem(item['id'] as int);
        debugPrint('✅ Synced $operationType $entityType: $entityId');
        syncedCount++;
      } catch (e) {
        debugPrint('❌ Error syncing queue item ${item['id']}: $e');

        // Update retry count
        await _localDb.updateSyncQueueRetry(item['id'] as int, e.toString());

        // Remove if retry count exceeds threshold (increased to 10 with exponential backoff)
        if ((item['retryCount'] as int) >= 10) {
          await _localDb.removeSyncQueueItem(item['id'] as int);
          debugPrint('⚠️ Removed failed item after 10 retries');
        }
      }
    }

    return syncedCount;
  }

  /// Force sync now (called by user action)
  Future<void> forceSyncNow() async {
    if (_connectivity.isOffline) {
      throw Exception('Cannot sync while offline');
    }
    await syncAll();
  }

  /// Clear sync errors
  void clearErrors() {
    _lastSyncError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
