/// Domain Entity - Aggregated Item
class AggregatedItemEntity {
  final String name;
  final int quantity;
  final double revenue;

  const AggregatedItemEntity({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

/// Domain Entity - Daily Sales Aggregate
class DailyAggregateEntity {
  final String id;
  final String merchantId;
  final String date; // YYYY-MM-DD
  final double totalRevenue;
  final int totalOrders;
  final List<AggregatedItemEntity> items;
  final DateTime updatedAt;

  const DailyAggregateEntity({
    required this.id,
    required this.merchantId,
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.items,
    required this.updatedAt,
  });
}
