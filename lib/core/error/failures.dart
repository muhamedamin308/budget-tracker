sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class PersistenceFailure extends Failure {
  const PersistenceFailure(super.message);
}
