import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/daily_aggregate_entity.dart';
import '../../domain/entities/merchant_entity.dart';
import '../../domain/repositories/i_merchant_repository.dart';
import '../datasources/merchant_firestore_datasource.dart';
import '../mappers/entity_model_mapper.dart';
import '../models/item_model.dart';
import '../models/session_model.dart';
import '../models/daily_aggregate_model.dart';
import '../../../../core/utils/firebase_error_handler.dart';

/// Repository Implementation - Implements domain interface using data sources
class MerchantRepositoryImpl implements IMerchantRepository {
  final MerchantFirestoreDataSource _dataSource;

  MerchantRepositoryImpl(this._dataSource);

  // ==================== MERCHANT PROFILE OPERATIONS ====================

  @override
  Future<MerchantEntity?> getMerchantProfile(String merchantId) async {
    try {
      return await _dataSource.getMerchantProfile(merchantId);
    } catch (e) {
      FirebaseErrorHandler.logError('getMerchantProfile', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  @override
  Future<void> saveMerchantProfile(MerchantEntity merchant) async {
    try {
      await _dataSource.saveMerchantProfile(merchant);
    } catch (e) {
      FirebaseErrorHandler.logError('saveMerchantProfile', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  // ==================== ITEM OPERATIONS ====================

  @override
  Stream<List<ItemEntity>> getItemsStream(String merchantId) {
    try {
      return _dataSource.firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          // Removed orderBy to avoid composite index requirement
          // Client-side sorting is applied in the provider
          .snapshots()
          .map((snapshot) {
            final items = snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc).toEntity())
                .toList();
            // Sort by name on client side
            items.sort((a, b) => a.name.compareTo(b.name));
            return items;
          });
    } catch (e) {
      FirebaseErrorHandler.logError('getItemsStream', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  @override
  Future<ItemEntity?> searchItemByBarcode(
    String merchantId,
    String barcode,
  ) async {
    try {
      final querySnapshot = await _dataSource.firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ItemModel.fromFirestore(querySnapshot.docs.first).toEntity();
    } catch (e) {
      FirebaseErrorHandler.logError('searchItemByBarcode', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  @override
  Future<ItemEntity?> searchItemByCode(String merchantId, String code) async {
    try {
      final querySnapshot = await _dataSource.firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          .where('itemCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ItemModel.fromFirestore(querySnapshot.docs.first).toEntity();
    } catch (e) {
      FirebaseErrorHandler.logError('searchItemByCode', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
        barcode: item.barcode,
        itemCode: item.itemCode,
        taxRate: item.taxRate,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        // ✅ ADD UNIT INFORMATION FROM ENTITY
        unit: item.unit,
        isWeightBased: item.isWeightBased,
        pricePerUnit: item.pricePerUnit,
        defaultQuantity: item.defaultQuantity,
      );

      await _dataSource.createItem(model);
    } catch (e) {
      FirebaseErrorHandler.logError('createItem', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
        barcode: item.barcode,
        itemCode: item.itemCode,
        taxRate: item.taxRate,
        createdAt: Timestamp.fromDate(item.createdAt),
        updatedAt: Timestamp.now(),
        // ✅ ADD UNIT INFORMATION FROM ENTITY
        unit: item.unit,
        isWeightBased: item.isWeightBased,
        pricePerUnit: item.pricePerUnit,
        defaultQuantity: item.defaultQuantity,
      );

      await _dataSource.updateItem(model);
    } catch (e) {
      FirebaseErrorHandler.logError('updateItem', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  @override
  Future<void> deleteItem(String merchantId, String itemId) async {
    try {
      await _dataSource.deleteItem(itemId);
    } catch (e) {
      FirebaseErrorHandler.logError('deleteItem', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
      FirebaseErrorHandler.logError('getSessionStream', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  @override
  Future<String> createSession(SessionEntity session) async {
    try {
      print('🟡 [REPOSITORY] Creating session model...');
      final model = SessionModel(
        sessionId: '', // Firestore will generate ID
        merchantId: session.merchantId,
        items: session.items.map((item) => item.toModel()).toList(),
        subtotal: session.subtotal,
        tax: session.tax,
        total: session.total,
        status: session.status,
        paymentStatus: session.paymentStatus,
        paymentConfirmed: session
            .paymentConfirmed, // ← CRITICAL: Include for Cloud Function trigger
        paymentMethod: session.paymentMethod,
        txnId: session.paymentTxnId,
        connectedCustomers: session.connectedCustomers,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(session.expiresAt),
        completedAt: session.completedAt != null
            ? Timestamp.fromDate(session.completedAt!)
            : null,
        // ✅ RESTAURANT ORDER FIELDS (kitchen tracking)
        kitchenStatus: session.kitchenStatus,
        orderType: session.orderType,
        customerName: session.customerName,
        tableNumber: session.tableNumber,
        phoneNumber: session.phoneNumber,
        cookingStartedAt: session.cookingStartedAt != null
            ? Timestamp.fromDate(session.cookingStartedAt!)
            : null,
        readyAt: session.readyAt != null
            ? Timestamp.fromDate(session.readyAt!)
            : null,
      );

      print('🟡 [REPOSITORY] Model created, calling datasource...');
      print('🟡 [REPOSITORY] Items count: ${model.items.length}');
      print('🟡 [REPOSITORY] Total: ${model.total}');

      final createdModel = await _dataSource.createBillingSession(model);
      print(
        '🟡 [REPOSITORY] Session created with ID: ${createdModel.sessionId}',
      );
      return createdModel.sessionId;
    } catch (e) {
      print('🔴 [REPOSITORY ERROR] Failed to create session: $e');
      FirebaseErrorHandler.logError('createSession', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
      FirebaseErrorHandler.logError('markSessionPaid', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
      FirebaseErrorHandler.logError('finalizeSession', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
      FirebaseErrorHandler.logError('getDailyAggregateStream', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
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
      FirebaseErrorHandler.logError('updateDailyAggregate', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }

  // ==================== CLOUD FUNCTION OPERATIONS ====================

  @override
  Future<String> callFinalizeSession(String sessionId) async {
    try {
      await finalizeSession(sessionId);
      return 'Session finalized successfully';
    } catch (e) {
      FirebaseErrorHandler.logError('callFinalizeSession', e);
      throw Exception(FirebaseErrorHandler.handleError(e));
    }
  }
}
