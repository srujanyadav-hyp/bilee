import 'package:flutter/foundation.dart';
import '../../domain/entities/merchant_entity.dart';
import '../../domain/usecases/merchant_usecases.dart';

/// Merchant Provider - State management for merchant profile
class MerchantProvider with ChangeNotifier {
  final GetMerchantProfile _getMerchantProfile;
  final SaveMerchantProfile _saveMerchantProfile;

  MerchantProvider({
    required GetMerchantProfile getMerchantProfile,
    required SaveMerchantProfile saveMerchantProfile,
  }) : _getMerchantProfile = getMerchantProfile,
       _saveMerchantProfile = saveMerchantProfile;

  MerchantEntity? _profile;
  bool _isLoading = false;
  String? _error;

  MerchantEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  /// Load merchant profile by ID
  Future<void> loadProfile(String merchantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _getMerchantProfile(merchantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update merchant profile
  Future<bool> updateProfile(MerchantEntity merchant) async {
    _error = null;
    notifyListeners();

    try {
      await _saveMerchantProfile(merchant);
      _profile = merchant;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Create a new merchant profile
  Future<bool> createProfile(MerchantEntity merchant) async {
    return await updateProfile(merchant);
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear profile data (on logout)
  void clearProfile() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _profile = null;
    super.dispose();
  }
}
