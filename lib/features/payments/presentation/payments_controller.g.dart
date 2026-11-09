// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The clock the payment screens read "today" from (Pakistan time).
/// Tests override it to freeze time.
// TODO(payments): move to core/time once another feature needs it.

@ProviderFor(kametiClock)
final kametiClockProvider = KametiClockProvider._();

/// The clock the payment screens read "today" from (Pakistan time).
/// Tests override it to freeze time.
// TODO(payments): move to core/time once another feature needs it.

final class KametiClockProvider
    extends $FunctionalProvider<KametiClock, KametiClock, KametiClock>
    with $Provider<KametiClock> {
  /// The clock the payment screens read "today" from (Pakistan time).
  /// Tests override it to freeze time.
  // TODO(payments): move to core/time once another feature needs it.
  KametiClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kametiClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kametiClockHash();

  @$internal
  @override
  $ProviderElement<KametiClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KametiClock create(Ref ref) {
    return kametiClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KametiClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KametiClock>(value),
    );
  }
}

String _$kametiClockHash() => r'939c34edf02c141760311468c4fe2c356de439f0';

/// Writes for the payment screens. Each successful write refreshes the
/// ledger, payments and payouts of the kameti so every screen updates.

@ProviderFor(PaymentsActions)
final paymentsActionsProvider = PaymentsActionsProvider._();

/// Writes for the payment screens. Each successful write refreshes the
/// ledger, payments and payouts of the kameti so every screen updates.
final class PaymentsActionsProvider
    extends $NotifierProvider<PaymentsActions, void> {
  /// Writes for the payment screens. Each successful write refreshes the
  /// ledger, payments and payouts of the kameti so every screen updates.
  PaymentsActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentsActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentsActionsHash();

  @$internal
  @override
  PaymentsActions create() => PaymentsActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$paymentsActionsHash() => r'a645ee17dc0b0bb240050bb7da12ce920172ba48';

/// Writes for the payment screens. Each successful write refreshes the
/// ledger, payments and payouts of the kameti so every screen updates.

abstract class _$PaymentsActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
