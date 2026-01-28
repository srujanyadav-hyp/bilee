import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/session_usecases.dart';
import '../../domain/usecases/receipt_usecases.dart';
import '../../domain/usecases/merchant_usecases.dart';
import '../../../../core/services/receipt_generator_service.dart';
import '../../../../core/services/performance_service.dart';
import '../widgets/order_info_dialog.dart';
import 'inventory_provider.dart';
import '../../../../core/services/enhanced_upi_payment_service.dart';
import '../../domain/entities/merchant_entity.dart';

/// Session Provider - State management for billing sessions
class SessionProvider with ChangeNotifier {
  final CreateBillingSession _createBillingSession;
  final GetLiveSession _getLiveSession;
  final MarkSessionPaid _markSessionPaid;
  final FinalizeSession _finalizeSession;
  // ignore: unused_field
  final LogReceiptAccess _logReceiptAccess;
  final GetMerchantProfile _getMerchantProfile;
  final ReceiptGeneratorService _receiptGenerator;
  final InventoryProvider? _inventoryProvider;

  SessionProvider({
    required CreateBillingSession createBillingSession,
    required GetLiveSession getLiveSession,
    required MarkSessionPaid markSessionPaid,
    required FinalizeSession finalizeSession,
    required LogReceiptAccess logReceiptAccess,
    required GetMerchantProfile getMerchantProfile,
    ReceiptGeneratorService? receiptGenerator,
    InventoryProvider? inventoryProvider,
  }) : _createBillingSession = createBillingSession,
       _getLiveSession = getLiveSession,
       _markSessionPaid = markSessionPaid,
       _finalizeSession = finalizeSession,
       _logReceiptAccess = logReceiptAccess,
       _getMerchantProfile = getMerchantProfile,
       _receiptGenerator = receiptGenerator ?? ReceiptGeneratorService(),
       _inventoryProvider = inventoryProvider;

  SessionEntity? _currentSession;
  bool _isLoading = false;
  String? _error;

  // Cart items for building a session
  final Map<String, SessionItemEntity> _cartItems = {};

  // Tax calculation flag
  bool _isTaxEnabled = false;

  // Bill parking - Multiple parked carts
  final Map<String, Map<String, SessionItemEntity>> _parkedCarts = {};
  String? _activeCartId;

  // Stream subscription for proper disposal
  StreamSubscription<SessionEntity?>? _sessionSubscription;

  SessionEntity? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession =>
      _currentSession != null && _currentSession!.isActive;
  List<SessionItemEntity> get cartItems => _cartItems.values.toList();
  int get cartItemCount =>
      _cartItems.values.fold(0, (sum, item) => sum + item.qty.toInt());
  double get cartSubtotal => _cartItems.values.fold(
    0.0,
    (sum, item) => sum + item.subtotalAfterDiscount,
  );
  double get cartTax => _isTaxEnabled
      ? _cartItems.values.fold(0.0, (sum, item) => sum + item.tax)
      : 0.0;
  double get cartTotal => cartSubtotal + cartTax;
  double get cartTotalDiscount =>
      _cartItems.values.fold(0.0, (sum, item) => sum + item.discount);
  bool get isTaxEnabled => _isTaxEnabled;

  // Bill parking getters
  Map<String, Map<String, SessionItemEntity>> get parkedCarts => _parkedCarts;
  int get parkedCartsCount => _parkedCarts.length;
  String? get activeCartId => _activeCartId;

  /// Watch live session updates
  void watchSession(String sessionId) {
    // Cancel any existing subscription
    _sessionSubscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    _sessionSubscription = _getLiveSession(sessionId).listen(
      (session) {
        // Validate session exists and is not expired
        if (session == null) {
          _error = 'Session not found';
          _currentSession = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        if (session.isExpired) {
          _error = 'Session has expired';
          _currentSession = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

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

  /// Stop watching session
  void stopWatchingSession() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
  }

  /// Add item to cart
  void addToCart(ItemEntity item, {double quantity = 1}) {
    final key = item.id;

    if (_cartItems.containsKey(key)) {
      // Update quantity
      final existing = _cartItems[key]!;
      final newQty = existing.qty + quantity;

      // Calculate price: use pricePerUnit for weight-based items, regular price for piece-based
      final effectivePrice = item.isWeightBased && item.pricePerUnit != null
          ? item.pricePerUnit!
          : item.price;
      final itemTotal = effectivePrice * newQty;
      final itemTax = _isTaxEnabled ? (itemTotal * (item.taxRate / 100)) : 0.0;

      _cartItems[key] = SessionItemEntity(
        itemId: item.id, // For inventory tracking
        name: item.name,
        hsnCode: item.hsnCode,
        price: effectivePrice,
        qty: newQty,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
        unit: item.unit,
        pricePerUnit: item.isWeightBased ? item.pricePerUnit : null,
      );
    } else {
      // Add new item
      final effectivePrice = item.isWeightBased && item.pricePerUnit != null
          ? item.pricePerUnit!
          : item.price;
      final itemTotal = effectivePrice * quantity;
      final itemTax = _isTaxEnabled ? (itemTotal * (item.taxRate / 100)) : 0.0;

      _cartItems[key] = SessionItemEntity(
        itemId: item.id, // For inventory tracking
        name: item.name,
        hsnCode: item.hsnCode,
        price: effectivePrice,
        qty: quantity,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
        unit: item.unit,
        pricePerUnit: item.isWeightBased ? item.pricePerUnit : null,
      );
    }

    notifyListeners();
  }

  /// Update item quantity in cart
  void updateCartItemQuantity(String itemName, double quantity) {
    final entry = _cartItems.entries.firstWhere(
      (e) => e.value.name == itemName,
      orElse: () => throw Exception('Item not found in cart'),
    );

    if (quantity <= 0) {
      _cartItems.remove(entry.key);
    } else {
      final item = entry.value;
      final itemTotal = item.price * quantity;
      final itemTax = _isTaxEnabled ? (itemTotal * (item.taxRate / 100)) : 0.0;

      _cartItems[entry.key] = SessionItemEntity(
        itemId: item.itemId, // Preserve itemId for inventory tracking
        name: item.name,
        hsnCode: item.hsnCode,
        price: item.price,
        qty: quantity,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
        unit: item.unit,
        pricePerUnit: item.pricePerUnit,
      );
    }

    notifyListeners();
  }

  /// Set tax enabled/disabled and recalculate all cart items
  void setTaxEnabled(bool enabled) {
    _isTaxEnabled = enabled;

    // Recalculate tax for all items in cart
    final itemsList = _cartItems.entries.toList();
    for (final entry in itemsList) {
      final item = entry.value;
      final itemTotal = item.price * item.qty;
      final itemTax = _isTaxEnabled ? (itemTotal * (item.taxRate / 100)) : 0.0;

      _cartItems[entry.key] = SessionItemEntity(
        itemId: item.itemId, // Preserve itemId for inventory tracking
        name: item.name,
        hsnCode: item.hsnCode,
        price: item.price,
        qty: item.qty,
        taxRate: item.taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
        discount: item.discount,
      );
    }

    notifyListeners();
  }

  /// Remove item from cart
  void removeFromCart(String itemName) {
    _cartItems.removeWhere((key, item) => item.name == itemName);
    notifyListeners();
  }

  /// Add temporary item to cart (for barcode-scanned items not yet in library)
  /// This creates a session item directly without an ItemEntity
  void addTemporaryItemToCart({
    required String name,
    required double price,
    String? barcode,
    double quantity = 1,
    double taxRate = 0,
    String? unit,
  }) {
    // Use name as key for temporary items
    final key = name.toLowerCase().replaceAll(' ', '_');

    if (_cartItems.containsKey(key)) {
      // Update quantity if item already exists
      final existing = _cartItems[key]!;
      final newQty = existing.qty + quantity;
      final itemTotal = price * newQty;
      final itemTax = _isTaxEnabled ? (itemTotal * (taxRate / 100)) : 0.0;

      _cartItems[key] = SessionItemEntity(
        name: name,
        hsnCode: barcode, // Store barcode in hsnCode field temporarily
        price: price,
        qty: newQty,
        taxRate: taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
        unit: unit ?? existing.unit ?? 'piece',
      );
    } else {
      // Add new temporary item
      final itemTotal = price * quantity;
      final itemTax = _isTaxEnabled ? (itemTotal * (taxRate / 100)) : 0.0;

      _cartItems[key] = SessionItemEntity(
        name: name,
        hsnCode: barcode, // Store barcode in hsnCode field temporarily
        price: price,
        qty: quantity,
        taxRate: taxRate,
        tax: itemTax,
        total: itemTotal + itemTax,
        unit: unit ?? 'piece',
      );
    }

    notifyListeners();
  }

  /// Clear cart
  void clearCart() {
    _cartItems.clear();
    _activeCartId = null;
    notifyListeners();
  }

  // ==================== BILL PARKING OPERATIONS ====================

  /// Park current cart and start a new one
  String parkCurrentCart({String? cartName}) {
    if (_cartItems.isEmpty) return '';

    final cartId = 'cart_${DateTime.now().millisecondsSinceEpoch}';
    _parkedCarts[cartId] = Map.from(_cartItems);
    _cartItems.clear();
    _activeCartId = null;
    notifyListeners();
    return cartId;
  }

  /// Switch to a parked cart
  void switchToParkedCart(String cartId) {
    if (!_parkedCarts.containsKey(cartId)) return;

    // Save current cart if not empty
    if (_cartItems.isNotEmpty && _activeCartId != null) {
      _parkedCarts[_activeCartId!] = Map.from(_cartItems);
    }

    // Load parked cart
    _cartItems.clear();
    _cartItems.addAll(_parkedCarts[cartId]!);
    _activeCartId = cartId;
    notifyListeners();
  }

  /// Delete a parked cart
  void deleteParkedCart(String cartId) {
    _parkedCarts.remove(cartId);
    if (_activeCartId == cartId) {
      _activeCartId = null;
    }
    notifyListeners();
  }

  /// Get parked cart summary
  Map<String, dynamic> getParkedCartSummary(String cartId) {
    if (!_parkedCarts.containsKey(cartId)) {
      return {'items': 0, 'total': 0.0};
    }

    final cart = _parkedCarts[cartId]!;
    final itemCount = cart.values.fold<int>(
      0,
      (sum, item) =>
          sum + item.qty.round(), // Fixed: use round() to convert double to int
    );
    final total = cart.values.fold(0.0, (sum, item) => sum + item.total);

    return {'items': itemCount, 'total': total};
  }

  /// Create a billing session from cart with payment details
  /// For restaurant merchants, pass OrderInfo to enable kitchen tracking
  Future<String?> createSessionWithPayment(
    String merchantId,
    PaymentDetails paymentDetails, {
    OrderInfo? orderInfo, // Restaurant order information
  }) async {
    if (_cartItems.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    print('🟢 [PROVIDER] Starting createSessionWithPayment');
    print('🟢 [PROVIDER] Merchant ID: $merchantId');
    print(
      '🟢 [PROVIDER] Payment details: ${paymentDetails.payments.length} payment(s)',
    );
    print('🟢 [PROVIDER] Total amount: ${paymentDetails.billTotal}');

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Track billing session performance
    final sessionStartTime = DateTime.now();

    try {
      // Determine payment method and status for session
      String? paymentMethod;
      String? paymentStatus;
      String? txnId;

      if (paymentDetails.payments.length == 1) {
        // Single payment
        paymentMethod = paymentDetails.payments.first.method.displayName;
        txnId = paymentDetails.payments.first.transactionId;
        print('🟢 [PROVIDER] Single payment: $paymentMethod');
      } else if (paymentDetails.payments.length > 1) {
        // Split payment - use "Split Payment" as method
        paymentMethod = 'Split Payment';
        print(
          '🟢 [PROVIDER] Split payment with ${paymentDetails.payments.length} methods',
        );
      }

      if (paymentDetails.isFullyPaid) {
        paymentStatus = 'PAID';
        print('🟢 [PROVIDER] Payment status: PAID (fully paid)');
      } else if (paymentDetails.hasCredit) {
        paymentStatus = 'PARTIAL';
        print('🟢 [PROVIDER] Payment status: PARTIAL (has credit)');
      }

      // Critical: Set paymentConfirmed flag to trigger Cloud Function for receipt generation
      bool? paymentConfirmed;
      if (paymentDetails.isFullyPaid) {
        paymentConfirmed = true;
        print(
          '✅ [PROVIDER] paymentConfirmed: true (triggers receipt generation)',
        );
      } else {
        paymentConfirmed = false;
      }

      final session = SessionEntity(
        id: '', // Will be generated
        merchantId: merchantId,
        items: _cartItems.values.toList(),
        subtotal: cartSubtotal,
        tax: cartTax,
        total: cartTotal,
        status: 'ACTIVE',
        paymentStatus: paymentStatus,
        paymentConfirmed:
            paymentConfirmed, // ✅ Added field - triggers Cloud Function
        paymentMethod: paymentMethod,
        paymentTxnId: txnId,
        connectedCustomers: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        // Complete session immediately if fully paid (for proper revenue tracking)
        completedAt: paymentDetails.isFullyPaid ? DateTime.now() : null,
        // Restaurant order fields (only set if orderInfo is provided)
        kitchenStatus: orderInfo != null ? 'NEW' : null,
        orderType: orderInfo?.orderType,
        customerName: orderInfo?.customerName,
        tableNumber: orderInfo?.tableNumber,
        phoneNumber: orderInfo?.phoneNumber,
      );

      print(
        '🟢 [PROVIDER] Session entity created, calling _createBillingSession...',
      );
      final sessionId = await _createBillingSession(session);
      print('🟢 [PROVIDER] Session created successfully with ID: $sessionId');

      _currentSession = session.copyWith(id: sessionId);

      // ✅ FIX: Remove parked cart if current cart was loaded from a parked cart
      if (_activeCartId != null) {
        debugPrint(
          '🗑️ [PROVIDER] Removing parked cart $_activeCartId after checkout',
        );
        _parkedCarts.remove(_activeCartId);
        _activeCartId = null;
      }

      _cartItems.clear();
      _isLoading = false;
      notifyListeners();

      // ⭐ GENERATE RECEIPT FOR PAID SESSIONS (Replaces Cloud Function)
      // This was previously handled by a Cloud Function watching paymentConfirmed flag
      // Now we generate receipts client-side immediately after session creation
      if (paymentDetails.isFullyPaid && _currentSession != null) {
        debugPrint('========================================');
        debugPrint('📝 [PROVIDER] Session fully paid, generating receipt...');
        debugPrint('   Session ID: $sessionId');
        debugPrint('   Merchant ID: $merchantId');
        debugPrint('========================================');

        try {
          // Get merchant profile for business details
          final merchantProfile = await _getMerchantProfile(merchantId);
          debugPrint(
            '👤 [PROVIDER] Merchant profile loaded: ${merchantProfile?.businessName}',
          );

          // Generate receipt using ReceiptGeneratorService
          final receiptId = await _receiptGenerator.generateReceiptForSession(
            session: _currentSession!,
            merchantName: merchantProfile?.businessName ?? 'MY BUSINESS',
            merchantLogo: merchantProfile?.logoUrl,
            merchantAddress: merchantProfile?.businessAddress,
            merchantPhone: merchantProfile?.businessPhone,
            merchantGst: merchantProfile?.gstNumber,
            businessCategory: merchantProfile?.businessType,
          );

          if (receiptId != null) {
            debugPrint('========================================');
            debugPrint('✅ [PROVIDER] RECEIPT GENERATED SUCCESSFULLY');
            debugPrint('   Receipt ID: $receiptId');
            debugPrint('   Session ID: $sessionId');
            debugPrint('========================================');
          } else {
            debugPrint('========================================');
            debugPrint('⚠️ [PROVIDER] Receipt generation returned null');
            debugPrint('   Session ID: $sessionId');
            debugPrint('========================================');
          }
        } catch (receiptError) {
          debugPrint('========================================');
          debugPrint('❌ [PROVIDER] ERROR generating receipt');
          debugPrint('   Error: $receiptError');
          debugPrint('   Session ID: $sessionId');
          debugPrint('========================================');
          // Don't fail the entire checkout if receipt generation fails
          // The session was still created successfully
        }
      } else if (!paymentDetails.isFullyPaid) {
        debugPrint(
          'ℹ️ [PROVIDER] Partial payment - receipt will be generated when fully paid',
        );
      }

      // Clear cart after successful session creation
      clearCart();

      print('✅ [PROVIDER] Session created successfully: $sessionId');

      // Track billing session performance
      final sessionDuration = DateTime.now().difference(sessionStartTime);
      await PerformanceService.trackBillingSession(
        sessionId: sessionId,
        itemCount: _cartItems.length,
        duration: sessionDuration,
      );

      return sessionId;
    } catch (e, stackTrace) {
      print('❌ [PROVIDER] Error creating session: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create a billing session from cart (legacy method for backward compatibility)
  Future<String?> createSession(String merchantId) async {
    // Create default payment details with full cash payment
    final paymentDetails = PaymentDetails(
      sessionId: '',
      billTotal: cartTotal,
      discountAmount: 0,
      finalAmount: cartTotal,
      payments: [
        PaymentEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          method: PaymentMethodType.cash,
          amount: cartTotal,
          timestamp: DateTime.now(),
        ),
      ],
      status: PaymentStatus.paid,
      pendingAmount: 0,
      createdAt: DateTime.now(),
    );

    return createSessionWithPayment(merchantId, paymentDetails);
  }

  /// Handle automated UPI payment flow
  /// Returns UpiPaymentResult with payment status
  Future<UpiPaymentResult> handleUpiPayment({
    required MerchantEntity merchant,
    required String sessionId,
    required double amount,
  }) async {
    try {
      debugPrint('💳 [SessionProvider] Starting UPI payment flow');
      debugPrint('   Merchant: ${merchant.businessName}');
      debugPrint('   Session: $sessionId');
      debugPrint('   Amount: ₹$amount');

      // Check if merchant has UPI enabled
      if (!merchant.isUpiEnabled || merchant.upiId == null) {
        debugPrint('❌ [SessionProvider] Merchant UPI not configured');
        return UpiPaymentResult.error(
          message: 'UPI payment not configured for this merchant',
        );
      }

      // Initialize UPI service
      final upiService = UpiPaymentService();

      // Check if UPI apps are available
      final hasUpiApps = await upiService.hasUpiApps();
      if (!hasUpiApps) {
        debugPrint('❌ [SessionProvider] No UPI apps found');
        return UpiPaymentResult.error(
          message: 'No UPI apps installed on device',
        );
      }

      // Generate transaction ID
      final txnId = 'BL${DateTime.now().millisecondsSinceEpoch}';
      final transactionNote = 'Bill Payment - ${merchant.businessName}';

      debugPrint('🚀 [SessionProvider] Initiating UPI payment');
      debugPrint('   Transaction ID: $txnId');

      // Initiate UPI payment
      final response = await upiService.initiatePayment(
        encryptedMerchantUpiId: merchant.upiId!,
        merchantName: merchant.businessName,
        transactionId: txnId,
        transactionNote: transactionNote,
        amount: amount,
      );

      debugPrint('📱 [SessionProvider] UPI payment response received');
      debugPrint('   Status: ${response.status}');
      debugPrint('   Error: ${response.error}');

      // Handle payment response
      if (response.isSuccess) {
        debugPrint('✅ [SessionProvider] Payment successful!');
        debugPrint('   Transaction ID: ${response.transactionId}');

        // Mark session as paid
        final marked = await markAsPaid(
          sessionId,
          'upi',
          response.transactionId ?? txnId,
        );

        if (marked) {
          debugPrint('✅ [SessionProvider] Session marked as paid');

          // Auto-complete session
          final completed = await completeSession(sessionId);

          if (completed) {
            debugPrint('🎉 [SessionProvider] Session auto-closed successfully');
            return UpiPaymentResult.success(
              message: 'Payment successful! Session closed.',
              txnId: response.transactionId,
            );
          } else {
            debugPrint('⚠️ [SessionProvider] Session completion failed');
            return UpiPaymentResult.success(
              message: 'Payment successful but session close failed',
              txnId: response.transactionId,
            );
          }
        } else {
          debugPrint('⚠️ [SessionProvider] Failed to mark session as paid');
          return UpiPaymentResult.error(
            message: 'Payment successful but session update failed',
          );
        }
      } else if (response.status == UpiPaymentStatus.submitted) {
        debugPrint('⏳ [SessionProvider] Payment pending');
        return UpiPaymentResult.pending(
          message: 'Payment submitted. Awaiting confirmation.',
        );
      } else {
        debugPrint('❌ [SessionProvider] Payment failed');
        return UpiPaymentResult.failed(
          message: response.error ?? 'Payment failed',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SessionProvider] UPI payment error: $e');
      debugPrint('   Stack trace: $stackTrace');
      return UpiPaymentResult.error(message: 'Payment error: ${e.toString()}');
    }
  }

  /// Mark session as paid and create permanent receipt
  /// Uses client-side receipt generation (Phase 3 optimization)
  Future<bool> markAsPaid(
    String sessionId,
    String paymentMethod,
    String txnId,
  ) async {
    _error = null;
    notifyListeners();

    try {
      debugPrint('========================================');
      debugPrint('💰 [SessionProvider] MARK AS PAID CALLED');
      debugPrint('   Session ID: $sessionId');
      debugPrint('   Payment Method: $paymentMethod');
      debugPrint('   Transaction ID: $txnId');
      debugPrint('   Current Session: ${_currentSession?.id}');
      debugPrint('========================================');

      // Mark session as paid in Firestore
      debugPrint('💳 [SessionProvider] Calling _markSessionPaid use case...');
      await _markSessionPaid(sessionId, paymentMethod, txnId);
      debugPrint('✅ [SessionProvider] Session marked as paid in Firestore');

      // ⭐ CRITICAL FIX: Reload session from Firestore to sync local state
      // This ensures _currentSession.isPaid reflects the updated Firestore value
      // BEFORE we try to generate the receipt
      debugPrint(
        '🔄 [SessionProvider] Reloading session from Firestore to sync local state...',
      );
      try {
        final sessionStream = _getLiveSession(sessionId);
        _currentSession = await sessionStream.first;
        notifyListeners();
        debugPrint('✅ [SessionProvider] Session reloaded successfully');
        debugPrint('   isPaid: ${_currentSession?.isPaid}');
        debugPrint(
          '   Connected Customers: ${_currentSession?.connectedCustomers}',
        );
      } catch (reloadError) {
        debugPrint(
          '⚠️ [SessionProvider] Failed to reload session: $reloadError',
        );
        debugPrint(
          '   Will attempt receipt generation anyway with current session state',
        );
        // Continue with receipt generation even if reload fails
      }

      // Generate receipt client-side (replaces Cloud Function)
      if (_currentSession != null) {
        debugPrint(
          '📝 [SessionProvider] _currentSession is NOT null, proceeding with receipt generation',
        );
        debugPrint('   Session isPaid: ${_currentSession!.isPaid}');
        debugPrint('   Merchant ID: ${_currentSession!.merchantId}');

        // Get merchant profile for business details
        debugPrint('👤 [SessionProvider] Fetching merchant profile...');
        final merchantProfile = await _getMerchantProfile(
          _currentSession!.merchantId,
        );
        debugPrint(
          '   Merchant: ${merchantProfile?.businessName ?? "Unknown"}',
        );

        // Generate receipt using ReceiptGeneratorService
        debugPrint('🎯 [SessionProvider] Calling ReceiptGeneratorService...');
        final receiptId = await _receiptGenerator.generateReceiptForSession(
          session: _currentSession!,
          merchantName: merchantProfile?.businessName ?? 'MY BUSINESS',
          merchantLogo: merchantProfile?.logoUrl,
          merchantAddress: merchantProfile?.businessAddress,
          merchantPhone: merchantProfile?.businessPhone,
          merchantGst: merchantProfile?.gstNumber,
          businessCategory: merchantProfile?.businessType,
        );

        if (receiptId != null) {
          debugPrint('========================================');
          debugPrint('✅ [SessionProvider] RECEIPT GENERATED SUCCESSFULLY');
          debugPrint('   Receipt ID: $receiptId');
          debugPrint('========================================');
        } else {
          debugPrint('========================================');
          debugPrint('⚠️ [SessionProvider] RECEIPT GENERATION RETURNED NULL');
          debugPrint('   This means generation was skipped or failed');
          debugPrint('========================================');
        }
      } else {
        debugPrint('========================================');
        debugPrint('❌ [SessionProvider] _currentSession is NULL!');
        debugPrint('   Cannot generate receipt without session object');
        debugPrint('========================================');
      }

      debugPrint('✅ [SessionProvider] Session marked as paid successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ [SessionProvider] ERROR IN MARK AS PAID');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('========================================');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Finalize (complete) session
  /// Now includes receipt generation for Phase 3
  Future<bool> completeSession(String sessionId) async {
    _error = null;
    notifyListeners();

    // Track session completion performance
    return await PerformanceService.trace('complete_session', () async {
      try {
        debugPrint('🏁 [SessionProvider] Completing session: $sessionId');

        // STEP 1: Ensure session is marked as PAID and generate receipt
        if (_currentSession != null && !_currentSession!.isPaid) {
          debugPrint(
            '💰 [SessionProvider] Session not paid yet, marking as PAID...',
          );

          // Mark as paid with default payment method
          final paymentMethod = _currentSession!.paymentMethod ?? 'cash';
          final txnId =
              _currentSession!.paymentTxnId ??
              'TXN${DateTime.now().millisecondsSinceEpoch}';

          final paid = await markAsPaid(sessionId, paymentMethod, txnId);

          if (!paid) {
            debugPrint('❌ [SessionProvider] Failed to mark session as paid');
            throw Exception('Failed to mark session as paid');
          }
        } else if (_currentSession != null && _currentSession!.isPaid) {
          debugPrint(
            '✅ [SessionProvider] Session already paid, ensuring receipt exists...',
          );

          // Session is paid, but check if receipt was generated
          final receiptExists = await _receiptGenerator.receiptExistsForSession(
            sessionId,
          );

          if (!receiptExists) {
            debugPrint(
              '📝 [SessionProvider] Receipt missing, generating now...',
            );

            final merchantProfile = await _getMerchantProfile(
              _currentSession!.merchantId,
            );

            await _receiptGenerator.generateReceiptForSession(
              session: _currentSession!,
              merchantName: merchantProfile?.businessName ?? 'MY BUSINESS',
              merchantLogo: merchantProfile?.logoUrl,
              merchantAddress: merchantProfile?.businessAddress,
              merchantPhone: merchantProfile?.businessPhone,
              merchantGst: merchantProfile?.gstNumber,
              businessCategory: merchantProfile?.businessType,
            );
          } else {
            debugPrint(
              '✅ [SessionProvider] Receipt already exists for session',
            );
          }
        }

        // STEP 2: Finalize the session
        debugPrint('🏁 [SessionProvider] Finalizing session...');
        await _finalizeSession(sessionId);

        // STEP 3: Deduct inventory stock for items with inventory tracking enabled
        if (_inventoryProvider != null && _currentSession != null) {
          debugPrint('📦 [SessionProvider] Deducting inventory stock...');
          try {
            // Build item quantities map from session items using itemId
            final itemQuantities = <String, double>{};
            for (final item in _currentSession!.items) {
              // Only deduct stock for items with itemId (skip manually added items)
              if (item.itemId != null) {
                itemQuantities[item.itemId!] = item.qty;
              }
            }

            if (itemQuantities.isNotEmpty) {
              await _inventoryProvider.deductStockForSession(
                sessionId: sessionId,
                merchantId: _currentSession!.merchantId,
                itemQuantities: itemQuantities,
              );
              debugPrint('✅ [SessionProvider] Inventory deducted successfully');
            } else {
              debugPrint(
                'ℹ️ [SessionProvider] No items with inventory tracking',
              );
            }
          } catch (e) {
            // Don't fail session completion if inventory deduction fails
            debugPrint('⚠️ [SessionProvider] Inventory deduction failed: $e');
          }
        }

        _currentSession = null;

        debugPrint('✅ [SessionProvider] Session completed successfully');
        return true;
      } catch (e) {
        debugPrint('❌ [SessionProvider] Error completing session: $e');
        _error = e.toString();
        notifyListeners();
        return false;
      }
    }, attributes: {'session_id': sessionId});
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
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
