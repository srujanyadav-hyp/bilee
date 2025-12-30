import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../../../core/services/local_storage_service.dart';

/// Repository for managing budgets with local-first architecture
class BudgetRepository {
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorage;

  BudgetRepository({
    FirebaseFirestore? firestore,
    required LocalStorageService localStorage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _localStorage = localStorage;

  // ==================== CREATE ====================

  /// Create new budget
  Future<Budget> createBudget({
    required String userId,
    required String category,
    required double monthlyLimit,
  }) async {
    debugPrint('💰 Creating budget: $category = ₹$monthlyLimit');

    final id = _firestore.collection('budgets').doc().id;
    final now = DateTime.now();

    final budget = Budget(
      id: id,
      userId: userId,
      category: category,
      monthlyLimit: monthlyLimit,
      createdAt: now,
    );

    try {
      // Save locally first (instant!)
      await _localStorage.saveBudget(id, budget.toJson());
      debugPrint('✅ Budget saved locally');

      // Sync to Firestore in background
      await _firestore.collection('budgets').doc(id).set(budget.toJson());
      debugPrint('✅ Budget synced to Firestore');

      return budget;
    } catch (e) {
      debugPrint('❌ Error creating budget: $e');
      rethrow;
    }
  }

  // ==================== READ ====================

  /// Get all budgets for user from local storage (instant!)
  List<Budget> getUserBudgets(String userId) {
    try {
      final budgetsData = _localStorage.getUserBudgets(userId);
      return budgetsData.map((data) => Budget.fromJson(data)).toList();
    } catch (e) {
      debugPrint('❌ Error getting user budgets: $e');
      return [];
    }
  }

  /// Get budget for specific category
  Budget? getBudgetForCategory(String userId, String category) {
    try {
      final budgets = getUserBudgets(userId);
      return budgets.firstWhere(
        (b) => b.category == category,
        orElse: () => throw StateError('No budget found for $category'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Sync budgets from Firestore to local storage
  Future<void> syncBudgetsFromFirestore(String userId) async {
    debugPrint('🔄 Syncing budgets from Firestore...');

    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await _localStorage.saveBudget(doc.id, doc.data());
      }

      debugPrint('✅ Synced ${snapshot.docs.length} budgets');
    } catch (e) {
      debugPrint('❌ Error syncing budgets: $e');
    }
  }

  // ==================== UPDATE ====================

  /// Update budget
  Future<Budget> updateBudget(Budget budget) async {
    debugPrint('💰 Updating budget: ${budget.id}');

    final updatedBudget = budget.copyWith(updatedAt: DateTime.now());

    try {
      // Update locally first
      await _localStorage.saveBudget(budget.id, updatedBudget.toJson());

      // Sync to Firestore
      await _firestore
          .collection('budgets')
          .doc(budget.id)
          .update(updatedBudget.toJson());

      debugPrint('✅ Budget updated');
      return updatedBudget;
    } catch (e) {
      debugPrint('❌ Error updating budget: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// Delete budget
  Future<void> deleteBudget(String budgetId) async {
    debugPrint('🗑️ Deleting budget: $budgetId');

    try {
      // Delete locally first
      await _localStorage.deleteBudget(budgetId);

      // Delete from Firestore
      await _firestore.collection('budgets').doc(budgetId).delete();

      debugPrint('✅ Budget deleted');
    } catch (e) {
      debugPrint('❌ Error deleting budget: $e');
      rethrow;
    }
  }

  // ==================== BUDGET PROGRESS ====================

  /// Calculate budget progress for current month
  Future<BudgetProgress> getBudgetProgress({
    required Budget budget,
    required List<Map<String, dynamic>> receipts,
  }) async {
    debugPrint('📊 Calculating budget progress for ${budget.category}');

    try {
      // Get current month boundaries
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      // Filter receipts for current month and category
      final categoryReceipts = receipts.where((receipt) {
        // Check category
        if (receipt['category'] != budget.category) return false;

        // Check date is in current month
        final createdAt = _parseDateTime(receipt['createdAt']);
        return createdAt.isAfter(monthStart) && createdAt.isBefore(monthEnd);
      }).toList();

      // Calculate total spent
      final spent = categoryReceipts.fold<double>(
        0.0,
        (sum, receipt) => sum + (receipt['total'] as num).toDouble(),
      );

      final receiptIds = categoryReceipts
          .map((r) => r['id'] as String)
          .toList();

      debugPrint('   Spent: ₹$spent / ₹${budget.monthlyLimit}');

      return BudgetProgress(
        budget: budget,
        spent: spent,
        receiptIds: receiptIds,
      );
    } catch (e) {
      debugPrint('❌ Error calculating budget progress: $e');
      rethrow;
    }
  }

  /// Get all budget progress for user
  Future<List<BudgetProgress>> getAllBudgetProgress({
    required String userId,
    required List<Map<String, dynamic>> receipts,
  }) async {
    final budgets = getUserBudgets(userId);
    final progressList = <BudgetProgress>[];

    for (final budget in budgets) {
      final progress = await getBudgetProgress(
        budget: budget,
        receipts: receipts,
      );
      progressList.add(progress);
    }

    return progressList;
  }

  /// Check if any budgets need alerts (>=80%)
  Future<List<BudgetProgress>> getBudgetsNeedingAlert({
    required String userId,
    required List<Map<String, dynamic>> receipts,
  }) async {
    final allProgress = await getAllBudgetProgress(
      userId: userId,
      receipts: receipts,
    );

    return allProgress
        .where((progress) => progress.isApproachingLimit || progress.isExceeded)
        .toList();
  }

  // ==================== HELPERS ====================

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is Timestamp) return value.toDate();
    if (value is Map && value.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    throw ArgumentError('Invalid datetime format: $value');
  }
}
