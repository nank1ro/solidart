part of '../widgets/provider_scope.dart';

sealed class MaybeProvidedValue<T> {
  MaybeProvidedValue._();

  T unwrap() => switch (this) {
        ProvidedValue<T>(:final T value) => value,
        ProviderNotFound<T>() => throw ProviderError(),
      };
}

final class ProvidedValue<T> extends MaybeProvidedValue<T> {
  ProvidedValue._(this.value) : super._();

  final T value;
}

final class ProviderNotFound<T> extends MaybeProvidedValue<T> {
  ProviderNotFound._() : super._();
}
