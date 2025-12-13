import 'package:flutter/foundation.dart';
import '../../domain/entities/staff_entity.dart';

/// Staff Provider - Manages staff state and operations
class StaffProvider extends ChangeNotifier {
  final List<StaffEntity> _staffList = [];
  StaffEntity? _currentStaff;
  bool _isLoading = false;
  String? _error;

  List<StaffEntity> get staffList => List.unmodifiable(_staffList);
  StaffEntity? get currentStaff => _currentStaff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all staff for merchant
  Future<void> loadStaff(String merchantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement Firestore fetch
      // For now, add mock data for demonstration
      _staffList.clear();
      _staffList.addAll(_getMockStaff(merchantId));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set current logged-in staff
  void setCurrentStaff(StaffEntity staff) {
    _currentStaff = staff;
    notifyListeners();
  }

  /// Check if current staff has permission
  bool hasPermission(StaffPermission permission) {
    if (_currentStaff == null) return false;
    return _currentStaff!.permissions.contains(permission);
  }

  /// Check if current staff has any of the permissions
  bool hasAnyPermission(List<StaffPermission> permissions) {
    if (_currentStaff == null) return false;
    return permissions.any((p) => _currentStaff!.permissions.contains(p));
  }

  /// Add new staff member
  Future<void> addStaff(StaffEntity staff) async {
    try {
      // TODO: Implement Firestore create
      _staffList.add(staff);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update staff member
  Future<void> updateStaff(StaffEntity staff) async {
    try {
      // TODO: Implement Firestore update
      final index = _staffList.indexWhere((s) => s.id == staff.id);
      if (index != -1) {
        _staffList[index] = staff;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Deactivate staff member
  Future<void> deactivateStaff(String staffId) async {
    try {
      final index = _staffList.indexWhere((s) => s.id == staffId);
      if (index != -1) {
        _staffList[index] = _staffList[index].copyWith(isActive: false);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Mock data for demonstration
  List<StaffEntity> _getMockStaff(String merchantId) {
    return [
      StaffEntity(
        id: 'staff_001',
        merchantId: merchantId,
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+91 98765 43210',
        role: StaffRole.owner,
        permissions: StaffRole.owner.defaultPermissions,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      StaffEntity(
        id: 'staff_002',
        merchantId: merchantId,
        name: 'Sarah Manager',
        email: 'sarah@example.com',
        phone: '+91 98765 43211',
        role: StaffRole.manager,
        permissions: StaffRole.manager.defaultPermissions,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      StaffEntity(
        id: 'staff_003',
        merchantId: merchantId,
        name: 'Mike Cashier',
        email: 'mike@example.com',
        phone: '+91 98765 43212',
        role: StaffRole.cashier,
        permissions: StaffRole.cashier.defaultPermissions,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      StaffEntity(
        id: 'staff_004',
        merchantId: merchantId,
        name: 'Emma Assistant',
        email: 'emma@example.com',
        role: StaffRole.assistant,
        permissions: StaffRole.assistant.defaultPermissions,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      StaffEntity(
        id: 'staff_005',
        merchantId: merchantId,
        name: 'Tom Former',
        email: 'tom@example.com',
        role: StaffRole.cashier,
        permissions: StaffRole.cashier.defaultPermissions,
        isActive: false,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
}
