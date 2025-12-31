import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/budget_provider.dart';

/// Budget Settings Screen - Set and manage category budgets
class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Common expense categories for Indian users
  final List<String> _categories = [
    'Grocery',
    'Food',
    'Transport',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  // Category icons
  static const Map<String, IconData> _categoryIcons = {
    'Grocery': Icons.shopping_cart,
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills & Utilities': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Health': Icons.local_hospital,
    'Education': Icons.school,
    'Other': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Defer loading until after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
    });
  }

  void _initializeControllers() {
    for (final category in _categories) {
      _controllers[category] = TextEditingController();
      _focusNodes[category] = FocusNode();
    }
  }

  Future<void> _loadBudgets() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await context.read<BudgetProvider>().loadBudgets(userId);
      _populateExistingBudgets();
    }
  }

  void _populateExistingBudgets() {
    final budgets = context.read<BudgetProvider>().budgets;
    for (final budget in budgets) {
      if (_controllers.containsKey(budget.category)) {
        _controllers[budget.category]!.text = budget.monthlyLimit
            .toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Budget Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 24),

                // Budget Categories
                ...List.generate(
                  _categories.length,
                  (index) => _buildCategoryCard(_categories[index]),
                ),

                const SizedBox(height: 24),

                // Save Button
                _buildSaveButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.primaryBlueLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Monthly Budgets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get alerts when you reach 80%',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    final icon = _categoryIcons[category] ?? Icons.category;
    final budgetProvider = context.read<BudgetProvider>();
    final progress = budgetProvider.getProgressForCategory(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: progress != null && progress.isApproachingLimit
              ? Colors.orange.shade300
              : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '₹${progress.spent.toStringAsFixed(0)} / ₹${progress.budget.monthlyLimit.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: progress.isExceeded
                                ? Colors.red
                                : progress.isApproachingLimit
                                ? Colors.orange
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controllers[category],
              focusNode: _focusNodes[category],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Monthly Limit',
                prefixText: '₹ ',
                hintText: '0',
                filled: true,
                fillColor: AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.percentage.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress.isExceeded
                        ? Colors.red
                        : progress.isApproachingLimit
                        ? Colors.orange
                        : AppColors.primaryBlue,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.percentageDisplay.toStringAsFixed(0)}% used',
                    style: TextStyle(
                      fontSize: 12,
                      color: progress.isExceeded
                          ? Colors.red
                          : progress.isApproachingLimit
                          ? Colors.orange
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${progress.remaining.toStringAsFixed(0)} left',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        return ElevatedButton(
          onPressed: budgetProvider.isLoading ? null : _saveBudgets,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            elevation: 2,
          ),
          child: budgetProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save Budgets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  Future<void> _saveBudgets() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showError('Please sign in to save budgets');
      return;
    }

    final budgetProvider = context.read<BudgetProvider>();
    int savedCount = 0;

    for (final category in _categories) {
      final text = _controllers[category]!.text;
      if (text.isNotEmpty) {
        final limit = double.tryParse(text);
        if (limit != null && limit > 0) {
          await budgetProvider.setBudget(
            userId: userId,
            category: category,
            monthlyLimit: limit,
          );
          savedCount++;
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Saved $savedCount budget(s) successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Budget Settings'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💰 Set monthly spending limits for each category'),
            SizedBox(height: 8),
            Text('⚠️ Get alerts when you reach 80%threshold'),
            SizedBox(height: 8),
            Text('📊 Track your progress in real-time'),
            SizedBox(height: 8),
            Text('🎯 Save money by staying within limits'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
