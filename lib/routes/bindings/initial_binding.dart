import 'package:get/get.dart';
import '../../core/analytics/analytics_service.dart';
import '../../providers/auth_provider.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AnalyticsService>(AnalyticsService(), permanent: true);
    Get.put<AuthProvider>(AuthProvider(), permanent: true);
  }
}
