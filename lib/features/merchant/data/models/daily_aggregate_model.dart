import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Model - Aggregated Item (Firestore Representation)
class AggregatedItem {
  final String name;
  final int qty;
  final double revenue;

  const AggregatedItem({
    required this.name,
    required this.qty,
    required this.revenue,
  });

  factory AggregatedItem.fromJson(Map<String, dynamic> json) {
    return AggregatedItem(
      name: json['name'] as String,
      qty: json['qty'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'qty': qty, 'revenue': revenue};
  }
}

/// Data Model - Daily Sales Aggregate (Firestore Representation)
/// Matches Firestore document structure exactly
class DailyAggregateModel {
  final String id;
  final String merchantId;
  final String date; // YYYY-MM-DD
  final double total;
  final int ordersCount;
  final List<AggregatedItem> itemsSold;
  final Timestamp updatedAt;

  const DailyAggregateModel({
    required this.id,
    required this.merchantId,
    required this.date,
    required this.total,
    required this.ordersCount,
    required this.itemsSold,
    required this.updatedAt,
  });

  /// Create DailyAggregateModel from Firestore document
  factory DailyAggregateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyAggregateModel(
      id: doc.id,
      merchantId: data['merchantId'] as String,
      date: data['date'] as String,
      total: (data['total'] as num).toDouble(),
      ordersCount: data['ordersCount'] as int,
      itemsSold: (data['itemsSold'] as List<dynamic>)
          .map((item) => AggregatedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      updatedAt: data['updatedAt'] as Timestamp,
    );
  }

  /// Create DailyAggregateModel from JSON map
  factory DailyAggregateModel.fromJson(Map<String, dynamic> json) {
    return DailyAggregateModel(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String,
      date: json['date'] as String,
      total: (json['total'] as num).toDouble(),
      ordersCount: json['ordersCount'] as int,
      itemsSold: (json['itemsSold'] as List<dynamic>)
          .map((item) => AggregatedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  /// Convert DailyAggregateModel to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'date': date,
      'total': total,
      'ordersCount': ordersCount,
      'itemsSold': itemsSold.map((item) => item.toJson()).toList(),
      'updatedAt': updatedAt,
    };
  }
}
