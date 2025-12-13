import '../entities/merchant_entity.dart';
import '../repositories/i_merchant_repository.dart';

/// Get Merchant Profile Use Case
class GetMerchantProfile {
  final IMerchantRepository _repository;

  GetMerchantProfile(this._repository);

  Future<MerchantEntity?> call(String merchantId) async {
    return await _repository.getMerchantProfile(merchantId);
  }
}

/// Save Merchant Profile Use Case
class SaveMerchantProfile {
  final IMerchantRepository _repository;

  SaveMerchantProfile(this._repository);

  Future<void> call(MerchantEntity merchant) async {
    return await _repository.saveMerchantProfile(merchant);
  }
}
