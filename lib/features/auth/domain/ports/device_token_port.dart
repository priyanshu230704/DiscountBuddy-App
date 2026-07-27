/// Narrow port for push-token side effects after login / on logout.
abstract class DeviceTokenPort {
  Future<void> registerAfterLogin();
  Future<void> deactivateCurrentDevice();
}
