import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/role_storage_service.dart';
import '../../../core/models/auth_models.dart';

/// Registration Screen with Email/Phone tabs
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _roleStorage = RoleStorageService();

  // Tab controller
  late TabController _tabController;

  // Form keys
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  // Controllers - Email
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _categoryController = TextEditingController();

  // Controllers - Phone
  final _phoneController = TextEditingController();
  final _phoneDisplayNameController = TextEditingController();
  final _phoneCategoryController = TextEditingController();

  // State
  String? _userRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _countryCode = '+91';
  String? _selectedCategory;

  final List<String> _merchantCategories = [
    'Restaurant',
    'Retail',
    'Grocery',
    'Pharmacy',
    'Electronics',
    'Clothing',
    'Services',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _roleStorage.getRole();
    setState(() {
      _userRole = role;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _phoneDisplayNameController.dispose();
    _phoneCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.lightTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppDimensions.spacingLG),
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logos/logo_symbol_glow-removebg-preview.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingLG),
              // Title
              Text(
                'Create Account',
                style: AppTypography.h1.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingSM),
              // Role Badge
              if (_userRole != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _userRole == 'merchant'
                              ? Icons.store
                              : Icons.shopping_bag_outlined,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _userRole == 'merchant' ? 'Merchant' : 'Customer',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: AppDimensions.spacingXL),
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.lightTextSecondary,
                  labelStyle: AppTypography.button,
                  tabs: const [
                    Tab(icon: Icon(Icons.email_outlined), text: 'Email'),
                    Tab(icon: Icon(Icons.phone_outlined), text: 'Phone'),
                  ],
                ),
              ),
              SizedBox(height: AppDimensions.spacingLG),
              // Tab Views
              SizedBox(
                height: _userRole == 'merchant' ? 550 : 450,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildEmailForm(), _buildPhoneForm()],
                ),
              ),
              SizedBox(height: AppDimensions.spacingMD),
              // Sign In Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Already have an account? Sign in',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Display Name / Business Name
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: _userRole == 'merchant'
                    ? 'Business Name'
                    : 'Username',
                hintText: _userRole == 'merchant'
                    ? 'Enter business name'
                    : 'Choose a username',
                prefixIcon: Icon(
                  _userRole == 'merchant' ? Icons.business : Icons.person,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ${_userRole == 'merchant' ? 'business name' : 'username'}';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.spacingMD),
            // Category (Merchant only)
            if (_userRole == 'merchant')
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Business Category',
                  hintText: 'Select category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                items: _merchantCategories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (_userRole == 'merchant' &&
                      (value == null || value.isEmpty)) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            if (_userRole == 'merchant')
              SizedBox(height: AppDimensions.spacingMD),
            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.spacingMD),
            // Password
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                if (value.length < 8) {
                  return 'Password must be 8+ characters';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.spacingMD),
            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.spacingXL),
            // Create Account Button
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Account',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Display Name / Business Name
            TextFormField(
              controller: _phoneDisplayNameController,
              decoration: InputDecoration(
                labelText: _userRole == 'merchant'
                    ? 'Business Name'
                    : 'Username',
                hintText: _userRole == 'merchant'
                    ? 'Enter business name'
                    : 'Choose a username',
                prefixIcon: Icon(
                  _userRole == 'merchant' ? Icons.business : Icons.person,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ${_userRole == 'merchant' ? 'business name' : 'username'}';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.spacingMD),
            // Category (Merchant only)
            if (_userRole == 'merchant')
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Business Category',
                  hintText: 'Select category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                items: _merchantCategories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (_userRole == 'merchant' &&
                      (value == null || value.isEmpty)) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            if (_userRole == 'merchant')
              SizedBox(height: AppDimensions.spacingMD),
            // Phone Field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Code
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<String>(
                    value: _countryCode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: '+91', child: Text('+91')),
                      DropdownMenuItem(value: '+1', child: Text('+1')),
                      DropdownMenuItem(value: '+44', child: Text('+44')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _countryCode = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: AppDimensions.spacingMD),
                // Phone Number
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter phone number';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Enter valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.spacingXL),
            // Send OTP Button
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerWithPhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Send OTP',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final registrationData = RegistrationData(
      role: _userRole!,
      method: AuthMethod.email,
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
      category: _selectedCategory,
    );

    final result = await _authService.registerWithEmail(registrationData);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result.success) {
      final userData = await _authService.getUserData(result.uid!);
      if (userData != null) {
        final route = userData.isMerchant
            ? '/merchant/dashboard'
            : '/customer/dashboard';
        Navigator.of(context).pushReplacementNamed(route);
      }
    } else {
      _showError(result.errorMessage!);
    }
  }

  Future<void> _registerWithPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final registrationData = RegistrationData(
      role: _userRole!,
      method: AuthMethod.phone,
      phone: _phoneController.text,
      countryCode: _countryCode,
      displayName: _phoneDisplayNameController.text,
      category: _selectedCategory,
    );

    await _authService.sendOTP(
      phoneNumber: _phoneController.text,
      countryCode: _countryCode,
      onCodeSent: (verificationId) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushNamed(
          '/auth/otp',
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': '$_countryCode${_phoneController.text}',
            'isRegistration': true,
            'registrationData': registrationData,
          },
        );
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        _showError(error);
      },
      onAutoVerify: () async {
        setState(() {
          _isLoading = false;
        });
        // Auto-verified, navigate to home
        final user = _authService.currentUser;
        if (user != null) {
          final userData = await _authService.getUserData(user.uid);
          if (userData != null) {
            final route = userData.isMerchant
                ? '/merchant/dashboard'
                : '/customer/dashboard';
            Navigator.of(context).pushReplacementNamed(route);
          }
        }
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
