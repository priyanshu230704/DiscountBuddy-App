import 'package:get/get.dart';
import 'package:discount_buddy/features/auth/data/auth_provider.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthProvider>(AuthProvider(), permanent: true);
  }
}
