import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/auth_service.dart';

/// Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
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
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppDimensions.spacingXL),
        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_outlined,
              size: 40,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingXL),
        // Title
        Text(
          'Forgot Password?',
          style: AppTypography.h1.copyWith(color: AppColors.lightTextPrimary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacingMD),
        // Description
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: AppTypography.body1.copyWith(
            color: AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacingXL * 1.5),
        // Form
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: AppTypography.body1,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: AppTypography.body2.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppColors.lightTextSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide(color: AppColors.lightBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide(color: AppColors.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.lightSurface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppDimensions.spacingXL),
              // Send Reset Link Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
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
                          'Send Reset Link',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingLG),
              // Back to Login
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    context.go('/login');
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  label: Text(
                    'Back to Login',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppDimensions.spacingXL * 2),
        // Success Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 60,
              color: AppColors.success,
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spacingXL * 1.5),
        // Success Title
        Text(
          'Check Your Email',
          style: AppTypography.h1.copyWith(color: AppColors.lightTextPrimary),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacingMD),
        // Success Message
        Text(
          'We\'ve sent a password reset link to',
          style: AppTypography.body1.copyWith(
            color: AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacingSM),
        Text(
          _emailController.text,
          style: AppTypography.body1.copyWith(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppDimensions.spacingXL * 1.5),
        // Instructions
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMD),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: AppDimensions.spacingSM),
                  Text(
                    'What\'s next?',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.spacingSM),
              _buildInstructionItem('1. Check your inbox and spam/junk folder'),
              SizedBox(height: AppDimensions.spacingSM),
              _buildInstructionItem('2. Click the reset link'),
              SizedBox(height: AppDimensions.spacingSM),
              _buildInstructionItem('3. Create a new password'),
              SizedBox(height: AppDimensions.spacingSM),
              _buildInstructionItem('4. Sign in with your new password'),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.spacingXL),
        // Didn't receive email?
        Center(
          child: Column(
            children: [
              Text(
                'Didn\'t receive the email?',
                style: AppTypography.body2.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                  });
                },
                child: Text(
                  'Try again',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimensions.spacingLG),
        // Back to Login Button
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
            ),
            child: Text(
              'Back to Login',
              style: AppTypography.button.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      children: [
        SizedBox(width: AppDimensions.spacingMD),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: AppDimensions.spacingSM),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body2.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _emailSent = true;
      });
    } else {
      _showError(result.errorMessage!);
    }
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
