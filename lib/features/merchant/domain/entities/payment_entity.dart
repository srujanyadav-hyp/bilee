/// Payment Method Types
enum PaymentMethodType {
  cash,
  card,
  upi,
  netbanking,
  wallet,
  credit, // For partial payments
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.card:
        return 'Card';
      case PaymentMethodType.upi:
        return 'UPI';
      case PaymentMethodType.netbanking:
        return 'Net Banking';
      case PaymentMethodType.wallet:
        return 'Wallet';
      case PaymentMethodType.credit:
        return 'Credit/Pending';
    }
  }

  String get iconName {
    switch (this) {
      case PaymentMethodType.cash:
        return 'payments';
      case PaymentMethodType.card:
        return 'credit_card';
      case PaymentMethodType.upi:
        return 'qr_code_2';
      case PaymentMethodType.netbanking:
        return 'account_balance';
      case PaymentMethodType.wallet:
        return 'account_balance_wallet';
      case PaymentMethodType.credit:
        return 'schedule';
    }
  }
}

/// Payment Status
enum PaymentStatus { pending, partial, paid, failed, refunded }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Single Payment Entry (for split payments)
class PaymentEntry {
  final String id;
  final PaymentMethodType method;
  final double amount;
  final String? transactionId;
  final String? reference;
  final DateTime timestamp;
  final bool verified;
  final String? verificationNote;

  const PaymentEntry({
    required this.id,
    required this.method,
    required this.amount,
    this.transactionId,
    this.reference,
    required this.timestamp,
    this.verified = false,
    this.verificationNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method.name,
    'amount': amount,
    'transactionId': transactionId,
    'reference': reference,
    'timestamp': timestamp.toIso8601String(),
    'verified': verified,
    'verificationNote': verificationNote,
  };

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
    id: json['id'] as String,
    method: PaymentMethodType.values.firstWhere(
      (e) => e.name == json['method'],
    ),
    amount: (json['amount'] as num).toDouble(),
    transactionId: json['transactionId'] as String?,
    reference: json['reference'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    verified: json['verified'] as bool? ?? false,
    verificationNote: json['verificationNote'] as String?,
  );
}

/// Discount Type
enum DiscountType { percentage, fixed }

/// Discount Entry
class DiscountEntry {
  final String id;
  final DiscountType type;
  final double value;
  final String name;
  final String? reason;
  final DateTime appliedAt;

  const DiscountEntry({
    required this.id,
    required this.type,
    required this.value,
    required this.name,
    this.reason,
    required this.appliedAt,
  });

  double calculateDiscount(double amount) {
    if (type == DiscountType.percentage) {
      return amount * (value / 100);
    }
    return value;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'value': value,
    'name': name,
    'reason': reason,
    'appliedAt': appliedAt.toIso8601String(),
  };

  factory DiscountEntry.fromJson(Map<String, dynamic> json) => DiscountEntry(
    id: json['id'] as String,
    type: DiscountType.values.firstWhere((e) => e.name == json['type']),
    value: (json['value'] as num).toDouble(),
    name: json['name'] as String,
    reason: json['reason'] as String?,
    appliedAt: DateTime.parse(json['appliedAt'] as String),
  );
}

/// Discount Preset
class DiscountPreset {
  final String id;
  final String name;
  final DiscountType type;
  final double value;
  final String? description;
  final bool isActive;

  const DiscountPreset({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.description,
    this.isActive = true,
  });

  DiscountEntry toEntry() {
    return DiscountEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      value: value,
      name: name,
      appliedAt: DateTime.now(),
    );
  }

  static List<DiscountPreset> get defaultPresets => [
    const DiscountPreset(
      id: 'preset_5_percent',
      name: '5% Off',
      type: DiscountType.percentage,
      value: 5,
      description: 'Small discount',
    ),
    const DiscountPreset(
      id: 'preset_10_percent',
      name: '10% Off',
      type: DiscountType.percentage,
      value: 10,
      description: 'Regular customer',
    ),
    const DiscountPreset(
      id: 'preset_15_percent',
      name: '15% Off',
      type: DiscountType.percentage,
      value: 15,
      description: 'Bulk purchase',
    ),
    const DiscountPreset(
      id: 'preset_20_percent',
      name: '20% Off',
      type: DiscountType.percentage,
      value: 20,
      description: 'Special offer',
    ),
    const DiscountPreset(
      id: 'preset_50_fixed',
      name: '₹50 Off',
      type: DiscountType.fixed,
      value: 50,
      description: 'Flat discount',
    ),
    const DiscountPreset(
      id: 'preset_100_fixed',
      name: '₹100 Off',
      type: DiscountType.fixed,
      value: 100,
      description: 'Festival offer',
    ),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'value': value,
    'description': description,
    'isActive': isActive,
  };

  factory DiscountPreset.fromJson(Map<String, dynamic> json) => DiscountPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    type: DiscountType.values.firstWhere((e) => e.name == json['type']),
    value: (json['value'] as num).toDouble(),
    description: json['description'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}

/// Enhanced Payment Details (supports split & partial payments)
class PaymentDetails {
  final String sessionId;
  final double billTotal;
  final double discountAmount;
  final double finalAmount;
  final List<PaymentEntry> payments;
  final PaymentStatus status;
  final double? pendingAmount;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> notes;

  const PaymentDetails({
    required this.sessionId,
    required this.billTotal,
    this.discountAmount = 0,
    required this.finalAmount,
    required this.payments,
    required this.status,
    this.pendingAmount,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.notes = const [],
  });

  double get paidAmount => payments.fold(0.0, (sum, p) => sum + p.amount);
  double get remainingAmount => finalAmount - paidAmount;
  bool get isFullyPaid => remainingAmount <= 0.01;
  bool get isSplitPayment => payments.length > 1;
  bool get hasCredit => remainingAmount > 0.01;

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'billTotal': billTotal,
    'discountAmount': discountAmount,
    'finalAmount': finalAmount,
    'payments': payments.map((p) => p.toJson()).toList(),
    'status': status.name,
    'pendingAmount': pendingAmount,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'dueDate': dueDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'notes': notes,
  };

  factory PaymentDetails.fromJson(Map<String, dynamic> json) => PaymentDetails(
    sessionId: json['sessionId'] as String,
    billTotal: (json['billTotal'] as num).toDouble(),
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
    finalAmount: (json['finalAmount'] as num).toDouble(),
    payments: (json['payments'] as List)
        .map((p) => PaymentEntry.fromJson(p as Map<String, dynamic>))
        .toList(),
    status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
    pendingAmount: (json['pendingAmount'] as num?)?.toDouble(),
    customerId: json['customerId'] as String?,
    customerName: json['customerName'] as String?,
    customerPhone: json['customerPhone'] as String?,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
    notes: (json['notes'] as List?)?.cast<String>() ?? [],
  );
}
