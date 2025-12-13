import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/receipt_entity.dart';

/// Receipt Data Source - Firestore operations for receipts
class ReceiptRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReceiptRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save receipt to Firestore
  Future<String> saveReceipt(ReceiptEntity receipt) async {
    try {
      final docRef = _firestore.collection('receipts').doc();

      await docRef.set({
        'sessionId': receipt.sessionId,
        'merchantId': receipt.merchantId,
        'customerId': receipt.customerId,
        'businessName': receipt.businessName,
        'businessPhone': receipt.businessPhone,
        'businessAddress': receipt.businessAddress,
        'items': receipt.items
            .map(
              (item) => {
                'name': item.name,
                'hsnCode': item.hsnCode,
                'price': item.price,
                'qty': item.qty,
                'taxRate': item.taxRate,
                'tax': item.tax,
                'total': item.total,
              },
            )
            .toList(),
        'subtotal': receipt.subtotal,
        'tax': receipt.tax,
        'total': receipt.total,
        'paymentMethod': receipt.paymentMethod,
        'paymentTxnId': receipt.paymentTxnId,
        'paidAt': Timestamp.fromDate(receipt.paidAt),
        'createdAt': Timestamp.fromDate(receipt.createdAt),
        'accessLogs': receipt.accessLogs
            .map(
              (log) => {
                'userId': log.userId,
                'accessType': log.accessType,
                'accessedAt': Timestamp.fromDate(log.accessedAt),
                'ipAddress': log.ipAddress,
              },
            )
            .toList(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }

  /// Get receipt by ID
  Future<ReceiptEntity?> getReceipt(String receiptId) async {
    try {
      final doc = await _firestore.collection('receipts').doc(receiptId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return _mapToEntity(doc.id, data);
    } catch (e) {
      throw Exception('Failed to get receipt: $e');
    }
  }

  /// Get receipt by session ID
  Future<ReceiptEntity?> getReceiptBySessionId(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('receipts')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return _mapToEntity(doc.id, doc.data());
    } catch (e) {
      throw Exception('Failed to get receipt: $e');
    }
  }

  /// Get all receipts for a merchant
  Future<List<ReceiptEntity>> getMerchantReceipts(
    String merchantId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('receipts')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => _mapToEntity(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get merchant receipts: $e');
    }
  }

  /// Log receipt access
  Future<void> logAccess(String receiptId, ReceiptAccessLog accessLog) async {
    try {
      await _firestore.collection('receipts').doc(receiptId).update({
        'accessLogs': FieldValue.arrayUnion([
          {
            'userId': accessLog.userId,
            'accessType': accessLog.accessType,
            'accessedAt': Timestamp.fromDate(accessLog.accessedAt),
            'ipAddress': accessLog.ipAddress,
          },
        ]),
      });
    } catch (e) {
      throw Exception('Failed to log access: $e');
    }
  }

  /// Map Firestore data to ReceiptEntity
  ReceiptEntity _mapToEntity(String id, Map<String, dynamic> data) {
    return ReceiptEntity(
      id: id,
      sessionId: data['sessionId'] ?? '',
      merchantId: data['merchantId'] ?? '',
      customerId: data['customerId'],
      businessName: data['businessName'] ?? '',
      businessPhone: data['businessPhone'],
      businessAddress: data['businessAddress'],
      items:
          (data['items'] as List<dynamic>?)
              ?.map(
                (item) => ReceiptItemEntity(
                  name: item['name'] ?? '',
                  hsnCode: item['hsnCode'],
                  price: (item['price'] ?? 0).toDouble(),
                  qty: item['qty'] ?? 0,
                  taxRate: (item['taxRate'] ?? 0).toDouble(),
                  tax: (item['tax'] ?? 0).toDouble(),
                  total: (item['total'] ?? 0).toDouble(),
                ),
              )
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      paymentTxnId: data['paymentTxnId'],
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      accessLogs:
          (data['accessLogs'] as List<dynamic>?)
              ?.map(
                (log) => ReceiptAccessLog(
                  userId: log['userId'],
                  accessType: log['accessType'] ?? '',
                  accessedAt: (log['accessedAt'] as Timestamp).toDate(),
                  ipAddress: log['ipAddress'],
                ),
              )
              .toList() ??
          [],
    );
  }
}
