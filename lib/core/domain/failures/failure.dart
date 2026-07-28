/// Base domain failure — never parse Exception strings in UI.
abstract class Failure {
  final String message;
  const Failure(this.message);
}
