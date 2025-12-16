import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/customer_bottom_nav.dart';

/// Customer Profile Screen - Settings and preferences
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String? _displayName;
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
        title: Text(
          'Profile',
          style: AppTypography.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editProfile(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: AppDimensions.spacingLG),
                  _buildInfoSection(context, user),
                  const SizedBox(height: AppDimensions.spacingLG),
                  _buildSettingsSection(context),
                  const SizedBox(height: AppDimensions.spacingLG),
                  _buildAccountSection(context),
                  const SizedBox(height: 100), // Space for bottom navigation
                ],
              ),
            ),
      floatingActionButton: const CustomerFloatingScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomerBottomNav(
        currentRoute: '/customer/profile',
      ),
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
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingSM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
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
              value: user?.phoneNumber ?? 'Not provided',
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
              Text(value, style: AppTypography.body1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
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

  void _editProfile(BuildContext context) {
    _showComingSoon(context);
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

    if (confirm == true) {
      _showComingSoon(context);
    }
  }
}
