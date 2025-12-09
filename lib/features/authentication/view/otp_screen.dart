import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/auth_models.dart';

/// OTP Verification Screen
class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _authService = AuthService();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  // Arguments
  String? _verificationId;
  String? _phoneNumber;
  bool? _isRegistration;
  RegistrationData? _registrationData;

  // State
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;
  Timer? _timer;
  int _resendAttempts = 0;
  final int _maxResendAttempts = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Add listeners to auto-focus next field
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < 5) {
          _otpFocusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _verificationId = args['verificationId'] as String?;
      _phoneNumber = args['phoneNumber'] as String?;
      _isRegistration = args['isRegistration'] as bool? ?? false;
      _registrationData = args['registrationData'] as RegistrationData?;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
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
                    Icons.sms_outlined,
                    size: 40,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingXL),
              // Title
              Text(
                'Verify Phone Number',
                style: AppTypography.h1.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingMD),
              // Description
              Text(
                'Enter the 6-digit code sent to',
                style: AppTypography.body1.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingSM),
              // Phone Number
              Text(
                _phoneNumber ?? '',
                style: AppTypography.body1.copyWith(
                  color: AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingXL),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOTPField(index)),
              ),
              SizedBox(height: AppDimensions.spacingMD),
              // Auto-retrieval message (Android)
              if (Theme.of(context).platform == TargetPlatform.android)
                Text(
                  'Code will be auto-detected',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: AppDimensions.spacingXL),
              // Verify Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
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
                          'Verify',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingLG),
              // Countdown / Resend
              Center(
                child: _countdown > 0
                    ? Text(
                        'Resend code in ${_countdown}s',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      )
                    : TextButton(
                        onPressed:
                            _isResending ||
                                _resendAttempts >= _maxResendAttempts
                            ? null
                            : _resendOTP,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _resendAttempts >= _maxResendAttempts
                                    ? 'Max resend attempts reached'
                                    : 'Resend Code',
                                style: AppTypography.body2.copyWith(
                                  color: _resendAttempts >= _maxResendAttempts
                                      ? AppColors.lightTextSecondary
                                      : AppColors.primaryBlue,
                                ),
                              ),
                      ),
              ),
              SizedBox(height: AppDimensions.spacingMD),
              // Change Number
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  label: Text(
                    'Change Number',
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

  Widget _buildOTPField(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTypography.h2,
        decoration: InputDecoration(
          counterText: '',
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
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: AppColors.lightSurface,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isEmpty && index > 0) {
            // Move back on delete
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  String _getOTPCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOTP() async {
    final code = _getOTPCode();

    if (code.length != 6) {
      _showError('Please enter complete 6-digit code');
      return;
    }

    if (_verificationId == null) {
      _showError('Verification ID missing. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.verifyOTP(
      verificationId: _verificationId!,
      smsCode: code,
      registrationData: _isRegistration == true ? _registrationData : null,
    );

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
      } else {
        // User exists but no Firestore document - need to set up profile
        _showError(
          'Account setup incomplete. Please contact support or try registering again.',
        );
        await _authService.signOut();
      }
    } else {
      _showError(result.errorMessage!);

      // Clear OTP fields on error
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOTP() async {
    if (_resendAttempts >= _maxResendAttempts) {
      _showError('Maximum resend attempts reached. Please try again later.');
      return;
    }

    setState(() {
      _isResending = true;
    });

    await _authService.sendOTP(
      phoneNumber: _phoneNumber!.replaceAll(RegExp(r'\D'), ''),
      countryCode: _phoneNumber!.substring(
        0,
        _phoneNumber!.indexOf(RegExp(r'\d')),
      ),
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _isResending = false;
          _resendAttempts++;
        });
        _startCountdown();
        _showSuccess('Code resent successfully');
      },
      onError: (error) {
        setState(() {
          _isResending = false;
        });
        _showError(error);
      },
      onAutoVerify: () {
        // Auto-verified
        setState(() {
          _isResending = false;
        });
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
