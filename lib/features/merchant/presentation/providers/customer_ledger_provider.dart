import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_ledger_entity.dart';
import '../../domain/entities/payment_entity.dart';

/// Customer Ledger Provider - Manages credit tracking and partial payments
class CustomerLedgerProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CustomerLedgerEntry> _entries = [];
  Map<String, CustomerLedgerSummary> _summaries = {};
  bool _isLoading = false;
  String? _error;

  List<CustomerLedgerEntry> get entries => _entries;
  Map<String, CustomerLedgerSummary> get summaries => _summaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all ledger entries for a merchant
  Future<void> loadLedger(String merchantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('customerLedger')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('billDate', descending: true)
          .get();

      _entries = snapshot.docs
          .map(
            (doc) =>
                CustomerLedgerEntry.fromJson({'id': doc.id, ...doc.data()}),
          )
          .toList();

      _buildSummaries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new ledger entry for partial payment
  Future<String?> createEntry(PaymentDetails paymentDetails) async {
    if (!paymentDetails.hasCredit) {
      _error = 'No pending amount to track';
      notifyListeners();
      return null;
    }

    if (paymentDetails.customerName == null ||
        paymentDetails.customerName!.isEmpty) {
      _error = 'Customer name is required for credit tracking';
      notifyListeners();
      return null;
    }

    _error = null;

    try {
      final entry = CustomerLedgerEntry(
        id: '', // Will be generated
        merchantId: '', // Will be set from session
        customerId: paymentDetails.customerId ?? '',
        customerName: paymentDetails.customerName!,
        customerPhone: paymentDetails.customerPhone,
        sessionId: paymentDetails.sessionId,
        billAmount: paymentDetails.billTotal,
        paidAmount: paymentDetails.paidAmount,
        pendingAmount: paymentDetails.pendingAmount ?? 0,
        billDate: DateTime.now(),
        dueDate: paymentDetails.dueDate,
        partialPayments: paymentDetails.payments,
        status: 'PENDING',
        notes: paymentDetails.notes.isNotEmpty
            ? paymentDetails.notes.first
            : null,
      );

      final docRef = await _firestore
          .collection('customerLedger')
          .add(entry.toJson());

      // Reload to update the list
      await loadLedger(entry.merchantId);

      return docRef.id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Add a payment to an existing ledger entry
  Future<bool> addPayment(String entryId, PaymentEntry payment) async {
    _error = null;

    try {
      final docRef = _firestore.collection('customerLedger').doc(entryId);
      final doc = await docRef.get();

      if (!doc.exists) {
        _error = 'Ledger entry not found';
        notifyListeners();
        return false;
      }

      final entry = CustomerLedgerEntry.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });

      // Calculate new paid amount
      final newPaidAmount = entry.paidAmount + payment.amount;
      final newPendingAmount = entry.billAmount - newPaidAmount;

      // Update partial payments list
      final updatedPayments = [...entry.partialPayments, payment];

      // Determine new status
      String status = entry.status;
      DateTime? settledAt;

      if (newPendingAmount <= 0.01) {
        status = 'SETTLED';
        settledAt = DateTime.now();
      }

      // Update Firestore
      await docRef.update({
        'paidAmount': newPaidAmount,
        'pendingAmount': newPendingAmount,
        'partialPayments': updatedPayments.map((p) => p.toJson()).toList(),
        'status': status,
        'settledAt': settledAt?.toIso8601String(),
      });

      // Reload to update the list
      await loadLedger(entry.merchantId);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Settle a ledger entry (mark as paid)
  Future<bool> settleEntry(String entryId, PaymentEntry finalPayment) async {
    return await addPayment(entryId, finalPayment);
  }

  /// Get ledger entries for a specific customer
  List<CustomerLedgerEntry> getEntriesForCustomer(String customerPhone) {
    return _entries
        .where((entry) => entry.customerPhone == customerPhone)
        .toList();
  }

  /// Get customer summary by phone
  CustomerLedgerSummary? getCustomerSummary(String customerPhone) {
    return _summaries[customerPhone];
  }

  /// Get all pending entries
  List<CustomerLedgerEntry> getPendingEntries() {
    return _entries.where((entry) => entry.status == 'PENDING').toList();
  }

  /// Get all overdue entries
  List<CustomerLedgerEntry> getOverdueEntries() {
    return _entries.where((entry) => entry.isOverdue).toList();
  }

  /// Build summaries grouped by customer
  void _buildSummaries() {
    final Map<String, List<CustomerLedgerEntry>> grouped = {};

    for (var entry in _entries) {
      final phone = entry.customerPhone ?? 'Unknown';
      if (!grouped.containsKey(phone)) {
        grouped[phone] = [];
      }
      grouped[phone]!.add(entry);
    }

    _summaries = grouped.map(
      (phone, entries) =>
          MapEntry(phone, CustomerLedgerSummary.fromEntries(entries)),
    );
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
