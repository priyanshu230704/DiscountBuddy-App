import 'package:get/get.dart';

/// Route-level binding for the main shell (tabs / merchant dashboard).
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // AuthProvider is registered globally in [InitialBinding].
  }
}
