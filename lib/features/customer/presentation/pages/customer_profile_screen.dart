import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/account_deletion_service.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/customer_bottom_nav.dart';

/// Customer Profile Screen - Settings and preferences
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String? _displayName;
  String? _phoneNumber;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _displayName = doc.data()?['display_name'] as String?;
            _phoneNumber = doc.data()?['phoneNumber'] as String?;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editProfile(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 60 + MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: AppDimensions.spacingLG),
                  _buildInfoSection(context, user),
                  const SizedBox(height: AppDimensions.spacingLG),
                  _buildSettingsSection(context),
                  const SizedBox(height: AppDimensions.spacingLG),
                  _buildAccountSection(context),
                ],
              ),
            ),
      floatingActionButton: CustomerFloatingScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomerBottomNav(currentRoute: '/customer/profile'),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacingLG),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Text(
                    (_displayName?.isNotEmpty == true
                        ? _displayName![0].toUpperCase()
                        : (user?.email?.isNotEmpty == true
                              ? user!.email![0].toUpperCase()
                              : 'C')),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 40,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            _displayName ?? user?.email?.split('@')[0] ?? 'Customer',
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.email!,
              style: AppTypography.body2.copyWith(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingSM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'CUSTOMER',
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

  Widget _buildInfoSection(BuildContext context, User? user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Divider(height: AppDimensions.spacingLG),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? 'Not provided',
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _phoneNumber ?? 'Not provided',
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: user?.metadata.creationTime != null
                  ? _formatDate(user!.metadata.creationTime!)
                  : 'Not available',
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
              Text(
                value,
                style: AppTypography.body1.copyWith(color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      color: Colors.white,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Password and security settings',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help or contact us',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            onTap: () => _showComingSoon(context),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'View terms and conditions',
            onTap: () => _showComingSoon(context),
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
      title: Text(
        title,
        style: AppTypography.body1.copyWith(color: Colors.black),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildAccountSection(BuildContext context) {
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
            onTap: () => _signOut(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Delete Account',
              style: AppTypography.body1.copyWith(color: Colors.red),
            ),
            onTap: () => _deleteAccount(context),
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

  void _editProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditProfileDialog(
        initialName: _displayName ?? '',
        initialPhone: _phoneNumber ?? '',
      ),
    );

    if (result != null && mounted) {
      final newName = result['name']!;
      final newPhone = result['phone']!;

      // Check if anything changed
      final nameChanged = newName != _displayName;
      final phoneChanged = newPhone != (_phoneNumber ?? '');

      if (!nameChanged && !phoneChanged) return;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Update Firestore
        final updates = <String, dynamic>{
          'updated_at': FieldValue.serverTimestamp(),
        };

        if (nameChanged) {
          updates['display_name'] = newName;
        }

        if (phoneChanged) {
          updates['phoneNumber'] = newPhone.isNotEmpty ? newPhone : null;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updates);

        if (!mounted) return;

        // Update local state
        setState(() {
          if (nameChanged) _displayName = newName;
          if (phoneChanged) {
            _phoneNumber = newPhone.isNotEmpty ? newPhone : null;
          }
        });

        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
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

    if (confirm == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
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
    if (!context.mounted) return;
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
      await deletionService.deleteCustomerAccount(user.uid);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Sign out (account is already deleted, but clean up local state)
      final authService = AuthService();
      await authService.signOut();

      // Navigate to login
      if (context.mounted) {
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
      if (context.mounted) Navigator.pop(context);

      // Handle re-authentication requirement
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          await _showReauthDialog(context);
        }
      } else {
        if (context.mounted) {
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
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReauthDialog(BuildContext context) async {
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
        if (context.mounted) {
          await _deleteAccount(context);
        }
      } catch (e) {
        if (context.mounted) {
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
}

/// Separate dialog widget to properly manage TextEditingController lifecycle
class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialPhone;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialPhone,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  // Basic phone validation (10 digits)
                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();
              Navigator.pop(context, {'name': name, 'phone': phone});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
