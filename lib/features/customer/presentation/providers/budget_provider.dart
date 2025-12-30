import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../data/repositories/budget_repository.dart';
import '../providers/receipt_provider.dart';

/// Provider for managing budget state and progress
class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository;
  final ReceiptProvider _receiptProvider;

  List<Budget> _budgets = [];
  List<BudgetProgress> _budgetProgress = [];
  bool _isLoading = false;
  String? _error;

  BudgetProvider({
    required BudgetRepository repository,
    required ReceiptProvider receiptProvider,
  }) : _repository = repository,
       _receiptProvider = receiptProvider {
    // Listen to receipt changes to update budget progress
    _receiptProvider.addListener(_onReceiptsChanged);
  }

  // ==================== GETTERS ====================

  List<Budget> get budgets => _budgets;
  List<BudgetProgress> get budgetProgress => _budgetProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get budgets that need alerts (>=80% or exceeded)
  List<BudgetProgress> get budgetsNeedingAlert {
    return _budgetProgress
        .where((p) => p.isApproachingLimit || p.isExceeded)
        .toList();
  }

  /// Check if there are any budget alerts
  bool get hasAlerts => budgetsNeedingAlert.isNotEmpty;

  // ==================== LOAD ====================

  /// Load budgets for user
  Future<void> loadBudgets(String userId) async {
    debugPrint('💰 Loading budgets for user: $userId');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load from local storage (instant!)
      _budgets = _repository.getUserBudgets(userId);

      // Calculate progress
      await _calculateProgress(userId);

      // Sync from Firestore in background
      _repository.syncBudgetsFromFirestore(userId).then((_) {
        // Reload after sync
        _budgets = _repository.getUserBudgets(userId);
        _calculateProgress(userId);
      });

      debugPrint('✅ Loaded ${_budgets.length} budgets');
    } catch (e) {
      debugPrint('❌ Error loading budgets: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate budget progress for all budgets
  Future<void> _calculateProgress(String userId) async {
    try {
      // Get all receipts from receipt provider
      final receipts = _receiptProvider.receipts
          .map(
            (r) => {
              'id': r.id,
              'category': r.businessCategory ?? 'Other',
              'total': r.total,
              'createdAt': r.createdAt,
            },
          )
          .toList();

      _budgetProgress = await _repository.getAllBudgetProgress(
        userId: userId,
        receipts: receipts,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error calculating progress: $e');
    }
  }

  /// Listener for receipt changes
  void _onReceiptsChanged() {
    // Recalculate progress when receipts change
    if (_budgets.isNotEmpty) {
      final userId = _budgets.first.userId;
      _calculateProgress(userId);
    }
  }

  // ==================== CREATE / UPDATE ====================

  /// Create or update budget for category
  Future<void> setBudget({
    required String userId,
    required String category,
    required double monthlyLimit,
  }) async {
    debugPrint('💰 Setting budget: $category = ₹$monthlyLimit');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Check if budget already exists for this category
      final existing = _budgets.firstWhere(
        (b) => b.category == category,
        orElse: () => Budget(
          id: '',
          userId: userId,
          category: category,
          monthlyLimit: 0,
          createdAt: DateTime.now(),
        ),
      );

      if (existing.id.isEmpty) {
        // Create new budget
        final budget = await _repository.createBudget(
          userId: userId,
          category: category,
          monthlyLimit: monthlyLimit,
        );
        _budgets.add(budget);
      } else {
        // Update existing budget
        final updated = existing.copyWith(monthlyLimit: monthlyLimit);
        await _repository.updateBudget(updated);

        final index = _budgets.indexWhere((b) => b.id == existing.id);
        if (index != -1) {
          _budgets[index] = updated;
        }
      }

      // Recalculate progress
      await _calculateProgress(userId);

      debugPrint('✅ Budget set successfully');
    } catch (e) {
      debugPrint('❌ Error setting budget: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete budget for category
  Future<void> deleteBudget(String budgetId) async {
    debugPrint('🗑️ Deleting budget: $budgetId');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.deleteBudget(budgetId);
      _budgets.removeWhere((b) => b.id == budgetId);
      _budgetProgress.removeWhere((p) => p.budget.id == budgetId);

      debugPrint('✅ Budget deleted');
    } catch (e) {
      debugPrint('❌ Error deleting budget: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UTILITY ====================

  /// Get progress for specific category
  BudgetProgress? getProgressForCategory(String category) {
    try {
      return _budgetProgress.firstWhere((p) => p.budget.category == category);
    } catch (e) {
      return null;
    }
  }

  /// Check if category has budget set
  bool hasBudgetForCategory(String category) {
    return _budgets.any((b) => b.category == category);
  }

  @override
  void dispose() {
    _receiptProvider.removeListener(_onReceiptsChanged);
    super.dispose();
  }
}
