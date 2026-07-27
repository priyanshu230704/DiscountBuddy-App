import 'dart:io';

import 'package:discount_buddy/features/auth/domain/entities/user_entity.dart';
import 'package:discount_buddy/features/auth/domain/repositories/auth_repository.dart';
import 'package:discount_buddy/features/auth/domain/result.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    File? imageFile,
    String? avatarUrl,
  }) {
    return _repository.updateProfile(
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      imageFile: imageFile,
      avatarUrl: avatarUrl,
    );
  }
}
