import 'payment_entity.dart';

/// Customer Ledger Entry (who owes what)
class CustomerLedgerEntry {
  final String id;
  final String merchantId;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String sessionId;
  final double billAmount;
  final double paidAmount;
  final double pendingAmount;
  final DateTime billDate;
  final DateTime? dueDate;
  final DateTime? settledAt;
  final List<PaymentEntry> partialPayments;
  final String status; // PENDING, OVERDUE, SETTLED
  final String? notes;

  const CustomerLedgerEntry({
    required this.id,
    required this.merchantId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.sessionId,
    required this.billAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.billDate,
    this.dueDate,
    this.settledAt,
    this.partialPayments = const [],
    required this.status,
    this.notes,
  });

  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isSettled;
  bool get isSettled => status == 'SETTLED';
  int get daysOverdue =>
      isOverdue ? DateTime.now().difference(dueDate!).inDays : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'merchantId': merchantId,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'sessionId': sessionId,
    'billAmount': billAmount,
    'paidAmount': paidAmount,
    'pendingAmount': pendingAmount,
    'billDate': billDate.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'settledAt': settledAt?.toIso8601String(),
    'partialPayments': partialPayments.map((p) => p.toJson()).toList(),
    'status': status,
    'notes': notes,
  };

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> json) =>
      CustomerLedgerEntry(
        id: json['id'] as String,
        merchantId: json['merchantId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String?,
        sessionId: json['sessionId'] as String,
        billAmount: (json['billAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        pendingAmount: (json['pendingAmount'] as num).toDouble(),
        billDate: DateTime.parse(json['billDate'] as String),
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        settledAt: json['settledAt'] != null
            ? DateTime.parse(json['settledAt'] as String)
            : null,
        partialPayments:
            (json['partialPayments'] as List?)
                ?.map((p) => PaymentEntry.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        status: json['status'] as String,
        notes: json['notes'] as String?,
      );
}

/// Customer Summary (aggregate view)
class CustomerLedgerSummary {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final double totalCredit;
  final int pendingBillsCount;
  final int overdueBillsCount;
  final DateTime? lastBillDate;
  final DateTime? lastPaymentDate;
  final List<CustomerLedgerEntry> entries;

  const CustomerLedgerSummary({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.totalCredit,
    required this.pendingBillsCount,
    required this.overdueBillsCount,
    this.lastBillDate,
    this.lastPaymentDate,
    this.entries = const [],
  });

  bool get hasOverdue => overdueBillsCount > 0;
  bool get hasPending => pendingBillsCount > 0;

  factory CustomerLedgerSummary.fromEntries(List<CustomerLedgerEntry> entries) {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot create summary from empty entries');
    }

    final first = entries.first;
    final totalCredit = entries
        .where((e) => !e.isSettled)
        .fold(0.0, (sum, e) => sum + e.pendingAmount);
    final pendingCount = entries.where((e) => !e.isSettled).length;
    final overdueCount = entries.where((e) => e.isOverdue).length;

    DateTime? lastBill;
    DateTime? lastPayment;
    for (final entry in entries) {
      if (lastBill == null || entry.billDate.isAfter(lastBill)) {
        lastBill = entry.billDate;
      }
      if (entry.partialPayments.isNotEmpty) {
        final latestPayment = entry.partialPayments.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
        );
        if (lastPayment == null ||
            latestPayment.timestamp.isAfter(lastPayment)) {
          lastPayment = latestPayment.timestamp;
        }
      }
    }

    return CustomerLedgerSummary(
      customerId: first.customerId,
      customerName: first.customerName,
      customerPhone: first.customerPhone,
      totalCredit: totalCredit,
      pendingBillsCount: pendingCount,
      overdueBillsCount: overdueCount,
      lastBillDate: lastBill,
      lastPaymentDate: lastPayment,
      entries: entries,
    );
  }

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'totalCredit': totalCredit,
    'pendingBillsCount': pendingBillsCount,
    'overdueBillsCount': overdueBillsCount,
    'lastBillDate': lastBillDate?.toIso8601String(),
    'lastPaymentDate': lastPaymentDate?.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory CustomerLedgerSummary.fromJson(Map<String, dynamic> json) =>
      CustomerLedgerSummary(
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String?,
        totalCredit: (json['totalCredit'] as num).toDouble(),
        pendingBillsCount: json['pendingBillsCount'] as int,
        overdueBillsCount: json['overdueBillsCount'] as int,
        lastBillDate: json['lastBillDate'] != null
            ? DateTime.parse(json['lastBillDate'] as String)
            : null,
        lastPaymentDate: json['lastPaymentDate'] != null
            ? DateTime.parse(json['lastPaymentDate'] as String)
            : null,
        entries: (json['entries'] as List)
            .map((e) => CustomerLedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
