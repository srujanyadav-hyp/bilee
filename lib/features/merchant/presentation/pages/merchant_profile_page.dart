import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/account_deletion_service.dart';
import '../../domain/entities/merchant_entity.dart';
import '../providers/merchant_provider.dart';

/// Merchant Profile Page
/// Shows merchant information, settings, and account management
class MerchantProfilePage extends StatefulWidget {
  final String merchantId;

  const MerchantProfilePage({super.key, required this.merchantId});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _loadingUserData = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MerchantProvider>().loadProfile(widget.merchantId);
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.merchantId)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = UserModel.fromFirestore(doc.data()!);
          _loadingUserData = false;
        });

        // Create merchant profile if it doesn't exist
        final provider = context.read<MerchantProvider>();
        if (provider.profile == null && !provider.isLoading) {
          await _createDefaultProfile(_userData!);
        }
      } else {
        setState(() => _loadingUserData = false);
      }
    } catch (e) {
      setState(() => _loadingUserData = false);
    }
  }

  Future<void> _createDefaultProfile(UserModel userData) async {
    try {
      final defaultProfile = MerchantEntity(
        id: widget.merchantId,
        businessName: userData.displayName,
        businessEmail: userData.email,
        businessPhone: userData.phone,
        businessAddress: null,
        gstNumber: null,
        panNumber: null,
        upiId: null,
        logoUrl: null,
        businessType: userData.category ?? 'General',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context.read<MerchantProvider>().createProfile(defaultProfile);
    } catch (e) {
      debugPrint('Error creating default profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MerchantProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            title: const Text('Profile'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: provider.isLoading ? null : _editProfile,
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.error ?? 'Failed to load profile',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            provider.loadProfile(widget.merchantId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(provider.profile!),
        );
      },
    );
  }

  Widget _buildProfileContent(profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(profile),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildInfoSection(profile),
          const SizedBox(height: AppDimensions.spacingLG),
          if (!_loadingUserData) _buildKYCSection(profile),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildSettingsSection(),
          const SizedBox(height: AppDimensions.spacingLG),
          _buildAccountSection(),
          const SizedBox(height: AppDimensions.spacingXL),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(profile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacingLG),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: profile.logoUrl != null
                ? NetworkImage(profile.logoUrl!)
                : null,
            child: profile.logoUrl == null
                ? Text(
                    profile.businessName.isNotEmpty
                        ? profile.businessName[0].toUpperCase()
                        : 'M',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 40,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            profile.businessName,
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'MERCHANT',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLG),
        ],
      ),
    );
  }

  Widget _buildInfoSection(profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: AppDimensions.spacingLG),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.businessEmail ?? 'Not provided',
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile.businessPhone ?? 'Not provided',
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: profile.businessAddress ?? 'Not provided',
            ),
            if (profile.businessType.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingMD),
              _buildInfoRow(
                icon: Icons.category_outlined,
                label: 'Business Type',
                value: profile.businessType,
              ),
            ],
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Registered Since',
              value: _formatDate(profile.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: AppDimensions.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: AppTypography.body1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKYCSection(profile) {
    final isActive = profile.isActive;
    final kycStatus = _userData?.kycStatus ?? 'PENDING';
    final isVerified = kycStatus == 'VERIFIED';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Account & KYC Status',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: AppDimensions.spacingLG),
            // Account Status
            _buildInfoRow(
              icon: Icons.account_circle,
              label: 'Account Status',
              value: isActive ? 'Active' : 'Inactive',
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            // KYC Status
            Row(
              children: [
                Text(
                  'KYC Status',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.verified : Icons.pending,
                        size: 16,
                        color: isVerified
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kycStatus,
                        style: AppTypography.caption.copyWith(
                          color: isVerified
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingLG),
            const Divider(height: AppDimensions.spacingLG),
            Text(
              'Tax Information',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.receipt_long,
              label: 'GST Number',
              value: profile.gstNumber ?? 'Not provided',
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.credit_card,
              label: 'PAN Number',
              value: profile.panNumber ?? 'Not provided',
            ),
            const SizedBox(height: AppDimensions.spacingLG),
            if (!isVerified) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete your KYC verification to unlock all features and increase transaction limits.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startKYC,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Complete KYC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your KYC is verified. You have access to all features.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startKYC() {
    // TODO: Navigate to KYC verification flow
    _showComingSoon();
  }

  Widget _buildSettingsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // TODO: Navigate to notifications settings
              _showComingSoon();
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and security settings',
            onTap: () {
              // TODO: Navigate to security settings
              _showComingSoon();
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // TODO: Navigate to language settings
              _showComingSoon();
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact us',
            onTap: () {
              // TODO: Navigate to help & support
              _showComingSoon();
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () {
              // TODO: Navigate to privacy policy
              _showComingSoon();
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'View terms and conditions',
            onTap: () {
              // TODO: Navigate to terms & conditions
              _showComingSoon();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: AppTypography.body1),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildAccountSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      color: Colors.red.shade50,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Sign Out',
              style: AppTypography.body1.copyWith(color: Colors.red),
            ),
            onTap: _signOut,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Delete Account',
              style: AppTypography.body1.copyWith(color: Colors.red),
            ),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _editProfile() {
    final profile = context.read<MerchantProvider>().profile;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditProfileSheet(
        profile: profile,
        userData: _userData,
        onSave: _saveProfile,
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting account and cleaning up data...'),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Delete account using service
      final deletionService = AccountDeletionService();
      await deletionService.deleteMerchantAccount(user.uid);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Sign out (account is already deleted, but clean up local state)
      await _authService.signOut();

      // Navigate to login
      if (mounted) {
        context.go('/login');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Handle re-authentication requirement
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          await _showReauthDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auth error: ${e.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReauthDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authenticate Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'For security, please re-enter your password to delete your account.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deletionService = AccountDeletionService();
        await deletionService.reauthenticateWithCredential(
          emailController.text.trim(),
          passwordController.text,
        );

        // Now retry deletion
        await _deleteAccount();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Re-authentication failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _saveProfile(
    MerchantEntity updatedProfile,
    String? category,
  ) async {
    try {
      // Update merchant profile
      await context.read<MerchantProvider>().updateProfile(updatedProfile);

      // Update category in users collection if changed
      if (category != null && category != _userData?.category) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.merchantId)
            .update({'category': category});

        // Reload user data
        await _loadUserData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Edit Profile Bottom Sheet
class _EditProfileSheet extends StatefulWidget {
  final MerchantEntity profile;
  final UserModel? userData;
  final Future<void> Function(MerchantEntity, String?) onSave;

  const _EditProfileSheet({
    required this.profile,
    required this.userData,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _businessNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  late TextEditingController _panController;
  late TextEditingController _upiIdController;

  String? _selectedCategory;
  bool _isSaving = false;

  final List<String> _categories = [
    'Restaurant',
    'Retail',
    'Grocery',
    'Pharmacy',
    'Electronics',
    'Clothing',
    'Services',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.profile.businessName,
    );
    _emailController = TextEditingController(
      text: widget.profile.businessEmail ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile.businessPhone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profile.businessAddress ?? '',
    );
    _gstController = TextEditingController(
      text: widget.profile.gstNumber ?? '',
    );
    _panController = TextEditingController(
      text: widget.profile.panNumber ?? '',
    );
    _upiIdController = TextEditingController(text: widget.profile.upiId ?? '');
    _selectedCategory =
        widget.userData?.category ?? widget.profile.businessType;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLG),

              // Business Name
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // Business Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Business Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // Phone
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // Address
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // GST Number
              TextField(
                controller: _gstController,
                decoration: const InputDecoration(
                  labelText: 'GST Number (Optional)',
                  prefixIcon: Icon(Icons.receipt_long),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // PAN Number
              TextField(
                controller: _panController,
                decoration: const InputDecoration(
                  labelText: 'PAN Number (Optional)',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMD),

              // UPI ID
              TextField(
                controller: _upiIdController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (For receiving payments)',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                  hintText: 'yourname@upi',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppDimensions.spacingXL),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
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

  Future<void> _handleSave() async {
    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedProfile = MerchantEntity(
        id: widget.profile.id,
        businessName: _businessNameController.text.trim(),
        businessEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        businessPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        businessAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty
            ? null
            : _gstController.text.trim(),
        panNumber: _panController.text.trim().isEmpty
            ? null
            : _panController.text.trim(),
        upiId: _upiIdController.text.trim().isEmpty
            ? null
            : _upiIdController.text.trim(),
        logoUrl: widget.profile.logoUrl,
        businessType: _selectedCategory ?? 'Other',
        isActive: widget.profile.isActive,
        createdAt: widget.profile.createdAt,
        updatedAt: DateTime.now(),
      );

      await widget.onSave(updatedProfile, _selectedCategory);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
