import 'package:flutter/foundation.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/session_usecases.dart';

/// Session Provider - State management for billing sessions
class SessionProvider with ChangeNotifier {
  final CreateBillingSession _createBillingSession;
  final GetLiveSession _getLiveSession;
  final MarkSessionPaid _markSessionPaid;
  final FinalizeSession _finalizeSession;

  SessionProvider({
    required CreateBillingSession createBillingSession,
    required GetLiveSession getLiveSession,
    required MarkSessionPaid markSessionPaid,
    required FinalizeSession finalizeSession,
  }) : _createBillingSession = createBillingSession,
       _getLiveSession = getLiveSession,
       _markSessionPaid = markSessionPaid,
       _finalizeSession = finalizeSession;

  SessionEntity? _currentSession;
  bool _isLoading = false;
  String? _error;

  // Cart items for building a session
  final Map<String, SessionItemEntity> _cartItems = {};

  SessionEntity? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession =>
      _currentSession != null && _currentSession!.isActive;
  List<SessionItemEntity> get cartItems => _cartItems.values.toList();
  int get cartItemCount =>
      _cartItems.values.fold(0, (sum, item) => sum + item.qty);
  double get cartSubtotal =>
      _cartItems.values.fold(0.0, (sum, item) => sum + (item.price * item.qty));
  double get cartTax =>
      _cartItems.values.fold(0.0, (sum, item) => sum + item.tax);
  double get cartTotal => cartSubtotal + cartTax;

  /// Watch live session updates
  void watchSession(String sessionId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _getLiveSession(sessionId).listen(
      (session) {
        _currentSession = session;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Add item to cart
  void addToCart(ItemEntity item, {int quantity = 1}) {
    final key = item.id;

    if (_cartItems.containsKey(key)) {
      // Update quantity
      final existing = _cartItems[key]!;
      final newQty = existing.qty + quantity;
      final itemTotal = item.price * newQty;
      final itemTax = itemTotal * (item.taxRate / 100);

      _cartItems[key] = SessionItemEntity(
        name: item.name,
        hsnCode: item.hsnCode,
        price: item.price,
        qty: newQty,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
      );
    } else {
      // Add new item
      final itemTotal = item.price * quantity;
      final itemTax = itemTotal * (item.taxRate / 100);

      _cartItems[key] = SessionItemEntity(
        name: item.name,
        hsnCode: item.hsnCode,
        price: item.price,
        qty: quantity,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
      );
    }

    notifyListeners();
  }

  /// Update item quantity in cart
  void updateCartItemQuantity(String itemName, int quantity) {
    final entry = _cartItems.entries.firstWhere(
      (e) => e.value.name == itemName,
      orElse: () => throw Exception('Item not found in cart'),
    );

    if (quantity <= 0) {
      _cartItems.remove(entry.key);
    } else {
      final item = entry.value;
      final itemTotal = item.price * quantity;
      final itemTax = itemTotal * (item.taxRate / 100);

      _cartItems[entry.key] = SessionItemEntity(
        name: item.name,
        hsnCode: item.hsnCode,
        price: item.price,
        qty: quantity,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
      );
    }

    notifyListeners();
  }

  /// Remove item from cart
  void removeFromCart(String itemName) {
    _cartItems.removeWhere((key, item) => item.name == itemName);
    notifyListeners();
  }

  /// Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Create a billing session from cart
  Future<String?> createSession(String merchantId) async {
    if (_cartItems.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = SessionEntity(
        id: '', // Will be generated
        merchantId: merchantId,
        items: _cartItems.values.toList(),
        subtotal: cartSubtotal,
        tax: cartTax,
        total: cartTotal,
        status: 'ACTIVE',
        paymentStatus: null,
        paymentMethod: null,
        paymentTxnId: null,
        connectedCustomers: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        completedAt: null,
      );

      final sessionId = await _createBillingSession(session);
      _currentSession = session.copyWith(id: sessionId);
      _cartItems.clear();
      _isLoading = false;
      notifyListeners();
      return sessionId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark session as paid
  Future<bool> markAsPaid(
    String sessionId,
    String paymentMethod,
    String txnId,
  ) async {
    _error = null;
    notifyListeners();

    try {
      await _markSessionPaid(sessionId, paymentMethod, txnId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Finalize (complete) session
  Future<bool> completeSession(String sessionId) async {
    _error = null;
    notifyListeners();

    try {
      await _finalizeSession(sessionId);
      _currentSession = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _currentSession = null;
    _cartItems.clear();
    super.dispose();
  }
}

/// Extension to add copyWith to SessionEntity
extension SessionEntityCopyWith on SessionEntity {
  SessionEntity copyWith({
    String? id,
    String? merchantId,
    List<SessionItemEntity>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentTxnId,
    List<String>? connectedCustomers,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTxnId: paymentTxnId ?? this.paymentTxnId,
      connectedCustomers: connectedCustomers ?? this.connectedCustomers,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
