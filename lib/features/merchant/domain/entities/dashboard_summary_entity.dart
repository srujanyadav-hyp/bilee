/// Dashboard Summary Entity
class DashboardSummaryEntity {
  // Today's stats
  final double todayRevenue;
  final int todayOrders;
  final int todayPending;

  // Yesterday's stats
  final double yesterdayRevenue;
  final int yesterdayOrders;

  // Week stats
  final double weekRevenue;
  final int weekOrders;

  // Month stats
  final double monthRevenue;
  final int monthOrders;

  // Active sessions
  final int activeSessions;
  final int pendingPayments;

  // Top selling items today
  final List<TopSellingItem> topItems;

  // Payment breakdown
  final Map<String, double> paymentMethodBreakdown;

  const DashboardSummaryEntity({
    required this.todayRevenue,
    required this.todayOrders,
    required this.todayPending,
    required this.yesterdayRevenue,
    required this.yesterdayOrders,
    required this.weekRevenue,
    required this.weekOrders,
    required this.monthRevenue,
    required this.monthOrders,
    required this.activeSessions,
    required this.pendingPayments,
    required this.topItems,
    required this.paymentMethodBreakdown,
  });
}

/// Top Selling Item
class TopSellingItem {
  final String name;
  final int quantity;
  final double revenue;

  const TopSellingItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}
