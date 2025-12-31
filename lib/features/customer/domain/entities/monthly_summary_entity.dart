import 'package:equatable/equatable.dart';

/// Category summary for monthly archives
class CategorySummary extends Equatable {
  final String name;
  final String icon;
  final double total;
  final int count;
  final double percentage;

  const CategorySummary({
    required this.name,
    required this.icon,
    required this.total,
    required this.count,
    required this.percentage,
  });

  @override
  List<Object?> get props => [name, icon, total, count, percentage];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'total': total,
      'count': count,
      'percentage': percentage,
    };
  }

  factory CategorySummary.fromMap(Map<String, dynamic> map) {
    return CategorySummary(
      name: map['name'] as String,
      icon: map['icon'] as String,
      total: (map['total'] as num).toDouble(),
      count: map['count'] as int,
      percentage: (map['percentage'] as num).toDouble(),
    );
  }

  CategorySummary copyWith({
    String? name,
    String? icon,
    double? total,
    int? count,
    double? percentage,
  }) {
    return CategorySummary(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      total: total ?? this.total,
      count: count ?? this.count,
      percentage: percentage ?? this.percentage,
    );
  }
}

/// Monthly summary entity - aggregates a month's receipts
class MonthlySummaryEntity extends Equatable {
  final String id;
  final String userId;
  final String month; // '2024-12'
  final int year;
  final int monthNumber;
  final List<CategorySummary> categories;
  final double grandTotal;
  final int totalReceipts;
  final int archivedCount;
  final int keptCount;
  final double? budgetLimit;
  final double? budgetDifference;
  final DateTime createdAt;

  const MonthlySummaryEntity({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    required this.monthNumber,
    required this.categories,
    required this.grandTotal,
    required this.totalReceipts,
    required this.archivedCount,
    required this.keptCount,
    this.budgetLimit,
    this.budgetDifference,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    month,
    year,
    monthNumber,
    categories,
    grandTotal,
    totalReceipts,
    archivedCount,
    keptCount,
    budgetLimit,
    budgetDifference,
    createdAt,
  ];

  MonthlySummaryEntity copyWith({
    String? id,
    String? userId,
    String? month,
    int? year,
    int? monthNumber,
    List<CategorySummary>? categories,
    double? grandTotal,
    int? totalReceipts,
    int? archivedCount,
    int? keptCount,
    double? budgetLimit,
    double? budgetDifference,
    DateTime? createdAt,
  }) {
    return MonthlySummaryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      monthNumber: monthNumber ?? this.monthNumber,
      categories: categories ?? this.categories,
      grandTotal: grandTotal ?? this.grandTotal,
      totalReceipts: totalReceipts ?? this.totalReceipts,
      archivedCount: archivedCount ?? this.archivedCount,
      keptCount: keptCount ?? this.keptCount,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      budgetDifference: budgetDifference ?? this.budgetDifference,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if under budget
  bool get isUnderBudget => budgetDifference != null && budgetDifference! <= 0;

  /// Check if over budget
  bool get isOverBudget => budgetDifference != null && budgetDifference! > 0;

  /// Get status text
  String get budgetStatus {
    if (budgetDifference == null || budgetLimit == null) return '';
    if (isUnderBudget) {
      return 'Under budget by ₹${budgetDifference!.abs().toStringAsFixed(0)}';
    } else {
      return 'Over budget by ₹${budgetDifference!.toStringAsFixed(0)}';
    }
  }
}
