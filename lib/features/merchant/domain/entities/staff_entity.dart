/// Staff Entity - Represents a staff member with role and permissions
class StaffEntity {
  final String id;
  final String merchantId;
  final String name;
  final String email;
  final String? phone;
  final StaffRole role;
  final Set<StaffPermission> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const StaffEntity({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.permissions,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
    };
  }

  factory StaffEntity.fromMap(Map<String, dynamic> map) {
    return StaffEntity(
      id: map['id'] as String,
      merchantId: map['merchantId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: StaffRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => StaffRole.cashier,
      ),
      permissions:
          (map['permissions'] as List<dynamic>?)
              ?.map(
                (p) => StaffPermission.values.firstWhere(
                  (perm) => perm.name == p,
                  orElse: () => StaffPermission.viewDashboard,
                ),
              )
              .toSet() ??
          {},
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] as int)
          : null,
    );
  }

  StaffEntity copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    Set<StaffPermission>? permissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return StaffEntity(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Staff Role - Defines role hierarchy
enum StaffRole { owner, manager, cashier, assistant }

/// Staff Permission - Granular permission control
enum StaffPermission {
  // Dashboard & Reports
  viewDashboard,
  viewReports,
  exportReports,

  // Billing
  createBilling,
  editBilling,
  deleteBilling,
  viewAllBillings,

  // Items & Inventory
  viewItems,
  addItems,
  editItems,
  deleteItems,
  manageInventory,

  // Staff Management
  viewStaff,
  addStaff,
  editStaff,
  deleteStaff,
  managePermissions,

  // Settings
  viewSettings,
  editSettings,
  editMerchantProfile,

  // Financial
  viewRevenue,
  managePricing,
  viewCashFlow,
}

/// Default permissions for each role
extension StaffRolePermissions on StaffRole {
  Set<StaffPermission> get defaultPermissions {
    switch (this) {
      case StaffRole.owner:
        return StaffPermission.values.toSet();

      case StaffRole.manager:
        return {
          StaffPermission.viewDashboard,
          StaffPermission.viewReports,
          StaffPermission.exportReports,
          StaffPermission.createBilling,
          StaffPermission.editBilling,
          StaffPermission.viewAllBillings,
          StaffPermission.viewItems,
          StaffPermission.addItems,
          StaffPermission.editItems,
          StaffPermission.manageInventory,
          StaffPermission.viewStaff,
          StaffPermission.viewSettings,
          StaffPermission.viewRevenue,
          StaffPermission.managePricing,
        };

      case StaffRole.cashier:
        return {
          StaffPermission.viewDashboard,
          StaffPermission.createBilling,
          StaffPermission.viewItems,
          StaffPermission.viewRevenue,
        };

      case StaffRole.assistant:
        return {
          StaffPermission.viewDashboard,
          StaffPermission.createBilling,
          StaffPermission.viewItems,
        };
    }
  }
}
