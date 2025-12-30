import 'package:flutter/material.dart';

/// Badge widget to show merchant status (e.g., "Closed" for deleted merchants)
class MerchantStatusBadge extends StatelessWidget {
  final String? status;
  final bool isCompact;

  const MerchantStatusBadge({super.key, this.status, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    // Don't show badge if no status or status is active
    if (status == null || status == 'active') {
      return const SizedBox.shrink();
    }

    // Get badge properties based on status
    final badgeData = _getBadgeData(status!);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: badgeData.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeData.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeData.icon,
            size: isCompact ? 12 : 14,
            color: badgeData.textColor,
          ),
          SizedBox(width: isCompact ? 3 : 4),
          Text(
            badgeData.label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: badgeData.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeData _getBadgeData(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return _BadgeData(
          label: 'Closed',
          icon: Icons.store_mall_directory_outlined,
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          textColor: Colors.orange.shade800,
        );
      case 'suspended':
        return _BadgeData(
          label: 'Suspended',
          icon: Icons.warning_outlined,
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          textColor: Colors.red.shade800,
        );
      case 'inactive':
        return _BadgeData(
          label: 'Inactive',
          icon: Icons.pause_circle_outline,
          backgroundColor: Colors.grey.shade200,
          borderColor: Colors.grey.shade400,
          textColor: Colors.grey.shade700,
        );
      default:
        return _BadgeData(
          label: status,
          icon: Icons.info_outline,
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          textColor: Colors.blue.shade800,
        );
    }
  }
}

class _BadgeData {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _BadgeData({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
