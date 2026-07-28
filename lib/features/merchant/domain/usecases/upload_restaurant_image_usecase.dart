import 'package:discount_buddy/core/domain/result.dart';
import 'package:discount_buddy/features/merchant/domain/repositories/merchant_repository.dart';

class UploadRestaurantImageUseCase {
  UploadRestaurantImageUseCase(this._repository);

  final MerchantRepository _repository;

  Future<Result<Map<String, dynamic>>> call({
    required int restaurantId,
    required String imagePath,
    required String imageType,
    String? altText,
    bool isPrimary = false,
  }) =>
      _repository.uploadRestaurantImage(
        restaurantId: restaurantId,
        imagePath: imagePath,
        imageType: imageType,
        altText: altText,
        isPrimary: isPrimary,
      );
}
