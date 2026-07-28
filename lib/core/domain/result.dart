import 'package:discount_buddy/core/domain/failures/failure.dart';

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Err<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Err<T>(:final failure) => failure,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onError,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Err<T>(:final failure) => onError(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
