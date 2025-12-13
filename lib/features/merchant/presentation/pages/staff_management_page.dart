import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/staff_entity.dart';
import '../providers/staff_provider.dart';

/// Staff Management Page - Manage team members and permissions
class StaffManagementPage extends StatefulWidget {
  final String merchantId;

  const StaffManagementPage({super.key, required this.merchantId});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff(widget.merchantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildStats()),
          _buildStaffList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewStaff,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: FlexibleSpaceBar(
          title: const Text(
            'Staff Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // TODO: Implement staff search
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: _showFilterOptions,
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Consumer<StaffProvider>(
      builder: (context, provider, _) {
        final totalStaff = provider.staffList.length;
        final activeStaff = provider.staffList.where((s) => s.isActive).length;
        final onlineStaff = provider.staffList
            .where(
              (s) =>
                  s.lastLoginAt != null &&
                  DateTime.now().difference(s.lastLoginAt!).inMinutes < 5,
            )
            .length;

        return Container(
          margin: const EdgeInsets.all(AppDimensions.paddingMD),
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Staff',
                '$totalStaff',
                Icons.people,
                Colors.blue,
              ),
              _buildStatItem(
                'Active',
                '$activeStaff',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Online Now',
                '$onlineStaff',
                Icons.circle,
                Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStaffList() {
    return Consumer<StaffProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.staffList.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No staff members yet',
                    style: AppTypography.h4.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first team member to get started',
                    style: AppTypography.body2.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final staff = provider.staffList[index];
              return _buildStaffCard(staff);
            }, childCount: provider.staffList.length),
          ),
        );
      },
    );
  }

  Widget _buildStaffCard(StaffEntity staff) {
    final roleColor = _getRoleColor(staff.role);
    final isOnline =
        staff.lastLoginAt != null &&
        DateTime.now().difference(staff.lastLoginAt!).inMinutes < 5;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: InkWell(
        onTap: () => _viewStaffDetails(staff),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: roleColor.withOpacity(0.2),
                        child: Text(
                          staff.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              staff.name,
                              style: AppTypography.h5.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!staff.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff.email,
                          style: AppTypography.body3.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getRoleLabel(staff.role),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              Row(
                children: [
                  Icon(Icons.security, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${staff.permissions.length} permissions',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  if (staff.lastLoginAt != null) ...[
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatLastLogin(staff.lastLoginAt!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(StaffRole role) {
    switch (role) {
      case StaffRole.owner:
        return Colors.purple;
      case StaffRole.manager:
        return Colors.blue;
      case StaffRole.cashier:
        return Colors.green;
      case StaffRole.assistant:
        return Colors.orange;
    }
  }

  String _getRoleLabel(StaffRole role) {
    return role.name[0].toUpperCase() + role.name.substring(1);
  }

  String _formatLastLogin(DateTime lastLogin) {
    final diff = DateTime.now().difference(lastLogin);

    if (diff.inMinutes < 5) return 'Online';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _addNewStaff() {
    // TODO: Show add staff dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Staff feature - Coming soon')),
    );
  }

  void _viewStaffDetails(StaffEntity staff) {
    // TODO: Show staff details and edit screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('View details for ${staff.name}')));
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Staff', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.spacingMD),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('All Staff'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Active Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.circle, color: Colors.orange),
              title: const Text('Online Now'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
