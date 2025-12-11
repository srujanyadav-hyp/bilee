import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/daily_aggregate_entity.dart';
import '../../domain/repositories/i_merchant_repository.dart';
import '../datasources/merchant_firestore_datasource.dart';
import '../mappers/entity_model_mapper.dart';
import '../models/item_model.dart';
import '../models/session_model.dart';
import '../models/daily_aggregate_model.dart';

/// Repository Implementation - Implements domain interface using data sources
class MerchantRepositoryImpl implements IMerchantRepository {
  final MerchantFirestoreDataSource _dataSource;

  MerchantRepositoryImpl(this._dataSource);

  // ==================== ITEM OPERATIONS ====================

  @override
  Stream<List<ItemEntity>> getItemsStream(String merchantId) {
    try {
      return _dataSource.firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc).toEntity())
                .toList(),
          );
    } catch (e) {
      throw Exception('Repository: Failed to get items stream - $e');
    }
  }

  @override
  Future<void> createItem(ItemEntity item) async {
    try {
      final model = ItemModel(
        id: '', // Firestore will generate ID
        merchantId: item.merchantId,
        name: item.name,
        price: item.price,
        hsn: item.hsnCode,
        category: null,
        taxRate: item.taxRate,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await _dataSource.createItem(model);
    } catch (e) {
      throw Exception('Repository: Failed to create item - $e');
    }
  }

  @override
  Future<void> updateItem(ItemEntity item) async {
    try {
      final model = ItemModel(
        id: item.id,
        merchantId: item.merchantId,
        name: item.name,
        price: item.price,
        hsn: item.hsnCode,
        category: null,
        taxRate: item.taxRate,
        createdAt: Timestamp.fromDate(item.createdAt),
        updatedAt: Timestamp.now(),
      );

      await _dataSource.updateItem(model);
    } catch (e) {
      throw Exception('Repository: Failed to update item - $e');
    }
  }

  @override
  Future<void> deleteItem(String merchantId, String itemId) async {
    try {
      await _dataSource.deleteItem(itemId);
    } catch (e) {
      throw Exception('Repository: Failed to delete item - $e');
    }
  }

  // ==================== SESSION OPERATIONS ====================

  @override
  Stream<SessionEntity?> getSessionStream(String sessionId) {
    try {
      return _dataSource.firestore
          .collection('billingSessions')
          .doc(sessionId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return SessionModel.fromFirestore(doc).toEntity();
          });
    } catch (e) {
      throw Exception('Repository: Failed to get session stream - $e');
    }
  }

  @override
  Future<String> createSession(SessionEntity session) async {
    try {
      final model = SessionModel(
        sessionId: '', // Firestore will generate ID
        merchantId: session.merchantId,
        items: session.items.map((item) => item.toModel()).toList(),
        subtotal: session.subtotal,
        tax: session.tax,
        total: session.total,
        status: session.status,
        paymentStatus: session.paymentStatus,
        paymentMethod: session.paymentMethod,
        txnId: session.paymentTxnId,
        connectedCustomers: session.connectedCustomers,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(session.expiresAt),
        completedAt: null,
      );

      final createdModel = await _dataSource.createBillingSession(model);
      return createdModel.sessionId;
    } catch (e) {
      throw Exception('Repository: Failed to create session - $e');
    }
  }

  @override
  Future<void> markSessionPaid(
    String sessionId,
    String paymentMethod,
    String txnId,
  ) async {
    try {
      await _dataSource.markSessionPaid(sessionId, paymentMethod, txnId);
    } catch (e) {
      throw Exception('Repository: Failed to mark session as paid - $e');
    }
  }

  @override
  Future<void> finalizeSession(String sessionId) async {
    try {
      // Get session details before finalizing
      final sessionDoc = await _dataSource.firestore
          .collection('billingSessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      final session = SessionModel.fromFirestore(sessionDoc).toEntity();

      // Finalize the session
      await _dataSource.finalizeSession(sessionId);

      // Update daily aggregate after session is finalized
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await updateDailyAggregate(
        session.merchantId,
        dateStr,
        session.total,
        session.items,
      );
    } catch (e) {
      throw Exception('Repository: Failed to finalize session - $e');
    }
  }

  // ==================== DAILY AGGREGATE OPERATIONS ====================

  @override
  Stream<DailyAggregateEntity?> getDailyAggregateStream(
    String merchantId,
    String date,
  ) {
    try {
      return _dataSource.firestore
          .collection('dailyAggregates')
          .where('merchantId', isEqualTo: merchantId)
          .where('date', isEqualTo: date)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) return null;
            return DailyAggregateModel.fromFirestore(
              snapshot.docs.first,
            ).toEntity();
          });
    } catch (e) {
      throw Exception('Repository: Failed to get daily aggregate stream - $e');
    }
  }

  @override
  Future<void> updateDailyAggregate(
    String merchantId,
    String date,
    double revenue,
    List<SessionItemEntity> items,
  ) async {
    try {
      // Get existing aggregate to merge with
      final existingSnapshot = await _dataSource.firestore
          .collection('dailyAggregates')
          .where('merchantId', isEqualTo: merchantId)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      DailyAggregateEntity aggregate;

      if (existingSnapshot.docs.isEmpty) {
        // Create new aggregate
        final Map<String, AggregatedItemEntity> aggregatedMap = {};
        for (final item in items) {
          if (aggregatedMap.containsKey(item.name)) {
            final existing = aggregatedMap[item.name]!;
            aggregatedMap[item.name] = AggregatedItemEntity(
              name: item.name,
              quantity: existing.quantity + item.qty,
              revenue: existing.revenue + item.total,
            );
          } else {
            aggregatedMap[item.name] = AggregatedItemEntity(
              name: item.name,
              quantity: item.qty,
              revenue: item.total,
            );
          }
        }

        aggregate = DailyAggregateEntity(
          id: '',
          merchantId: merchantId,
          date: date,
          totalRevenue: revenue,
          totalOrders: 1,
          items: aggregatedMap.values.toList(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Merge with existing aggregate
        final existing = DailyAggregateModel.fromFirestore(
          existingSnapshot.docs.first,
        ).toEntity();

        // Merge items
        final Map<String, AggregatedItemEntity> aggregatedMap = {};

        // Add existing items
        for (final item in existing.items) {
          aggregatedMap[item.name] = item;
        }

        // Add/merge new items from session
        for (final item in items) {
          if (aggregatedMap.containsKey(item.name)) {
            final existingItem = aggregatedMap[item.name]!;
            aggregatedMap[item.name] = AggregatedItemEntity(
              name: item.name,
              quantity: existingItem.quantity + item.qty,
              revenue: existingItem.revenue + item.total,
            );
          } else {
            aggregatedMap[item.name] = AggregatedItemEntity(
              name: item.name,
              quantity: item.qty,
              revenue: item.total,
            );
          }
        }

        aggregate = DailyAggregateEntity(
          id: existing.id,
          merchantId: merchantId,
          date: date,
          totalRevenue: existing.totalRevenue + revenue,
          totalOrders: existing.totalOrders + 1,
          items: aggregatedMap.values.toList(),
          updatedAt: DateTime.now(),
        );
      }

      await _dataSource.updateDailyAggregate(aggregate.toModel());
    } catch (e) {
      throw Exception('Repository: Failed to update daily aggregate - $e');
    }
  }

  // ==================== CLOUD FUNCTION OPERATIONS ====================

  @override
  Future<String> callFinalizeSession(String sessionId) async {
    try {
      await finalizeSession(sessionId);
      return 'Session finalized successfully';
    } catch (e) {
      throw Exception('Repository: Failed to call finalize session - $e');
    }
  }

  @override
  Future<String> callGenerateDailyReport(
    String merchantId,
    String date,
    String format,
  ) async {
    try {
      return await _dataSource.generateDailyReport(merchantId, date, format);
    } catch (e) {
      throw Exception('Repository: Failed to generate daily report - $e');
    }
  }
}
