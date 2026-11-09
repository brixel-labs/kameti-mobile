// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentsRepository)
final paymentsRepositoryProvider = PaymentsRepositoryProvider._();

final class PaymentsRepositoryProvider
    extends
        $FunctionalProvider<
          PaymentsRepository,
          PaymentsRepository,
          PaymentsRepository
        >
    with $Provider<PaymentsRepository> {
  PaymentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentsRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentsRepository create(Ref ref) {
    return paymentsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentsRepository>(value),
    );
  }
}

String _$paymentsRepositoryHash() =>
    r'c507700839b2643473d870df299945dcc446dd70';

@ProviderFor(kametiPayments)
final kametiPaymentsProvider = KametiPaymentsFamily._();

final class KametiPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Payment>>,
          List<Payment>,
          FutureOr<List<Payment>>
        >
    with $FutureModifier<List<Payment>>, $FutureProvider<List<Payment>> {
  KametiPaymentsProvider._({
    required KametiPaymentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiPaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiPaymentsHash();

  @override
  String toString() {
    return r'kametiPaymentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Payment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Payment>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiPayments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiPaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiPaymentsHash() => r'af74a17d1d00b853410e55452cff3e7f74be9e8c';

final class KametiPaymentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Payment>>, String> {
  KametiPaymentsFamily._()
    : super(
        retry: null,
        name: r'kametiPaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KametiPaymentsProvider call(String kametiId) =>
      KametiPaymentsProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiPaymentsProvider';
}

@ProviderFor(kametiPayouts)
final kametiPayoutsProvider = KametiPayoutsFamily._();

final class KametiPayoutsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Payout>>,
          List<Payout>,
          FutureOr<List<Payout>>
        >
    with $FutureModifier<List<Payout>>, $FutureProvider<List<Payout>> {
  KametiPayoutsProvider._({
    required KametiPayoutsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiPayoutsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiPayoutsHash();

  @override
  String toString() {
    return r'kametiPayoutsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Payout>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Payout>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiPayouts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiPayoutsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiPayoutsHash() => r'b8b2c05f5891367e4327cdcabe08b6bf9c0b6d69';

final class KametiPayoutsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Payout>>, String> {
  KametiPayoutsFamily._()
    : super(
        retry: null,
        name: r'kametiPayoutsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KametiPayoutsProvider call(String kametiId) =>
      KametiPayoutsProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiPayoutsProvider';
}
