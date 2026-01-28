import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/daily_aggregate_entity.dart';
import '../models/item_model.dart';
import '../models/session_model.dart';
import '../models/daily_aggregate_model.dart';

/// Extension to convert ItemModel to ItemEntity
extension ItemModelToEntity on ItemModel {
  ItemEntity toEntity() {
    return ItemEntity(
      id: id,
      merchantId: merchantId,
      name: name,
      hsnCode: hsn, // Firestore: hsn → Entity: hsnCode
      barcode: barcode,
      itemCode: itemCode,
      price: price,
      taxRate: taxRate,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
      unit: unit,
      isWeightBased: isWeightBased,
      pricePerUnit: pricePerUnit,
      defaultQuantity: defaultQuantity,
      inventoryEnabled: inventoryEnabled,
      currentStock: currentStock,
      lowStockThreshold: lowStockThreshold,
      stockUnit: stockUnit,
      lastStockUpdate: lastStockUpdate?.toDate(),
    );
  }
}

/// Extension to convert ItemEntity to ItemModel
extension ItemEntityToModel on ItemEntity {
  ItemModel toModel() {
    return ItemModel(
      id: id,
      merchantId: merchantId,
      name: name,
      price: price,
      hsn: hsnCode, // Entity: hsnCode → Firestore: hsn
      category: null, // Category not in entity, set to null
      barcode: barcode,
      itemCode: itemCode,
      taxRate: taxRate,
      createdAt: Timestamp.fromDate(createdAt),
      updatedAt: Timestamp.fromDate(updatedAt),
      unit: unit,
      isWeightBased: isWeightBased,
      pricePerUnit: pricePerUnit,
      defaultQuantity: defaultQuantity,
      inventoryEnabled: inventoryEnabled,
      currentStock: currentStock,
      lowStockThreshold: lowStockThreshold,
      stockUnit: stockUnit,
      lastStockUpdate: lastStockUpdate != null
          ? Timestamp.fromDate(lastStockUpdate!)
          : null,
    );
  }
}

/// Extension to convert SessionItemLine to SessionItemEntity
extension SessionItemLineToEntity on SessionItemLine {
  SessionItemEntity toEntity() {
    return SessionItemEntity(
      itemId: itemId, // Preserve itemId for inventory tracking
      name: name,
      hsnCode: hsn, // Firestore: hsn → Entity: hsnCode
      price: price,
      qty: qty,
      taxRate: taxRate,
      tax: tax,
      total: total,
      unit: unit ?? 'piece',
      pricePerUnit: pricePerUnit,
    );
  }
}

/// Extension to convert SessionItemEntity to SessionItemLine
extension SessionItemEntityToModel on SessionItemEntity {
  SessionItemLine toModel() {
    return SessionItemLine(
      itemId: itemId, // Preserve itemId for inventory tracking
      name: name,
      hsn: hsnCode, // Entity: hsnCode → Firestore: hsn
      price: price,
      qty: qty,
      taxRate: taxRate,
      tax: tax,
      total: total,
      unit: unit,
      pricePerUnit: pricePerUnit,
    );
  }
}

/// Extension to convert SessionModel to SessionEntity
extension SessionModelToEntity on SessionModel {
  SessionEntity toEntity() {
    return SessionEntity(
      id: sessionId, // Firestore: sessionId → Entity: id
      merchantId: merchantId,
      items: items.map((item) => item.toEntity()).toList(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      status: status,
      paymentStatus: paymentStatus,
      paymentConfirmed: paymentConfirmed, // ✅ Added field
      paymentMethod: paymentMethod,
      paymentTxnId: txnId, // Firestore: txnId → Entity: paymentTxnId
      connectedCustomers: connectedCustomers,
      createdAt: createdAt.toDate(),
      expiresAt: expiresAt.toDate(),
      completedAt: completedAt?.toDate(),
      // 🍽️ RESTAURANT ORDER FIELDS (kitchen tracking)
      kitchenStatus: kitchenStatus,
      orderType: orderType,
      customerName: customerName,
      tableNumber: tableNumber,
      phoneNumber: phoneNumber,
      cookingStartedAt: cookingStartedAt?.toDate(),
      readyAt: readyAt?.toDate(),
    );
  }
}

/// Extension to convert SessionEntity to SessionModel
extension SessionEntityToModel on SessionEntity {
  SessionModel toModel() {
    return SessionModel(
      sessionId: id, // Entity: id → Firestore: sessionId
      merchantId: merchantId,
      items: items.map((item) => item.toModel()).toList(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      status: status,
      paymentStatus: paymentStatus,
      paymentConfirmed: paymentConfirmed, // ✅ Added field
      paymentMethod: paymentMethod,
      txnId: paymentTxnId, // Entity: paymentTxnId → Firestore: txnId
      connectedCustomers: connectedCustomers,
      createdAt: Timestamp.fromDate(createdAt),
      expiresAt: Timestamp.fromDate(expiresAt),
      completedAt: completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      // 🍽️ RESTAURANT ORDER FIELDS (kitchen tracking)
      kitchenStatus: kitchenStatus,
      orderType: orderType,
      customerName: customerName,
      tableNumber: tableNumber,
      phoneNumber: phoneNumber,
      cookingStartedAt: cookingStartedAt != null
          ? Timestamp.fromDate(cookingStartedAt!)
          : null,
      readyAt: readyAt != null ? Timestamp.fromDate(readyAt!) : null,
    );
  }
}

/// Extension to convert AggregatedItem to AggregatedItemEntity
extension AggregatedItemToEntity on AggregatedItem {
  AggregatedItemEntity toEntity() {
    return AggregatedItemEntity(
      name: name,
      quantity: qty, // Firestore: qty → Entity: quantity
      revenue: revenue,
    );
  }
}

/// Extension to convert AggregatedItemEntity to AggregatedItem
extension AggregatedItemEntityToModel on AggregatedItemEntity {
  AggregatedItem toModel() {
    return AggregatedItem(
      name: name,
      qty: quantity, // Entity: quantity → Firestore: qty
      revenue: revenue,
    );
  }
}

/// Extension to convert DailyAggregateModel to DailyAggregateEntity
extension DailyAggregateModelToEntity on DailyAggregateModel {
  DailyAggregateEntity toEntity() {
    return DailyAggregateEntity(
      id: id,
      merchantId: merchantId,
      date: date,
      totalRevenue: total, // Firestore: total → Entity: totalRevenue
      totalOrders: ordersCount, // Firestore: ordersCount → Entity: totalOrders
      items: itemsSold
          .map((item) => item.toEntity())
          .toList(), // Firestore: itemsSold → Entity: items
      updatedAt: updatedAt.toDate(),
    );
  }
}

/// Extension to convert DailyAggregateEntity to DailyAggregateModel
extension DailyAggregateEntityToModel on DailyAggregateEntity {
  DailyAggregateModel toModel() {
    return DailyAggregateModel(
      id: id,
      merchantId: merchantId,
      date: date,
      total: totalRevenue, // Entity: totalRevenue → Firestore: total
      ordersCount: totalOrders, // Entity: totalOrders → Firestore: ordersCount
      itemsSold: items
          .map((item) => item.toModel())
          .toList(), // Entity: items → Firestore: itemsSold
      updatedAt: Timestamp.fromDate(updatedAt),
    );
  }
}
