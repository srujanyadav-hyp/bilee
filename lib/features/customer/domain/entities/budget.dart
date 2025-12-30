/// Budget entity representing a spending limit for a category
class Budget {
  final String id;
  final String userId;
  final String category;
  final double monthlyLimit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create budget from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'monthlyLimit': monthlyLimit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Helper to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is Map && value.containsKey('_seconds')) {
      // Firestore Timestamp
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    throw ArgumentError('Invalid datetime format: $value');
  }

  /// Create copy with updated fields
  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? monthlyLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          category == other.category &&
          monthlyLimit == other.monthlyLimit;

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ category.hashCode ^ monthlyLimit.hashCode;

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, limit: ₹$monthlyLimit)';
  }
}

/// Budget progress with spending information
class BudgetProgress {
  final Budget budget;
  final double spent;
  final List<String> receiptIds;

  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.receiptIds,
  });

  /// Amount remaining in budget
  double get remaining => budget.monthlyLimit - spent;

  /// Percentage of budget used (0.0 to 1.0+)
  double get percentage => spent / budget.monthlyLimit;

  /// Percentage for UI display (0-100)
  double get percentageDisplay => (percentage * 100).clamp(0, 100);

  /// Is budget exceeded?
  bool get isExceeded => spent > budget.monthlyLimit;

  /// Is budget approaching limit? (>=80%)
  bool get isApproachingLimit => percentage >= 0.8 && !isExceeded;

  /// Is budget healthy? (<80%)
  bool get isHealthy => percentage < 0.8;

  /// Get status color
  BudgetStatus get status {
    if (isExceeded) return BudgetStatus.exceeded;
    if (isApproachingLimit) return BudgetStatus.warning;
    return BudgetStatus.healthy;
  }

  @override
  String toString() {
    return 'BudgetProgress(category: ${budget.category}, spent: ₹$spent/${budget.monthlyLimit}, ${percentageDisplay.toStringAsFixed(1)}%)';
  }
}

/// Budget status enum
enum BudgetStatus {
  healthy, // < 80%
  warning, // 80-100%
  exceeded, // > 100%
}
