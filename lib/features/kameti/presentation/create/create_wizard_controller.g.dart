// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_wizard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Now" for the wizard's default first month. Tests override it.

@ProviderFor(createWizardClock)
final createWizardClockProvider = CreateWizardClockProvider._();

/// "Now" for the wizard's default first month. Tests override it.

final class CreateWizardClockProvider
    extends $FunctionalProvider<KametiClock, KametiClock, KametiClock>
    with $Provider<KametiClock> {
  /// "Now" for the wizard's default first month. Tests override it.
  CreateWizardClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createWizardClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createWizardClockHash();

  @$internal
  @override
  $ProviderElement<KametiClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KametiClock create(Ref ref) {
    return createWizardClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KametiClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KametiClock>(value),
    );
  }
}

String _$createWizardClockHash() => r'b209f5a15c731d7e665515f637445c23e5905c0f';

/// Drives the create-kameti wizard (board AC-1…AC-6, FR-10–FR-12).
///
/// Step 1 creates the draft on the server (`createKameti`); later saves
/// update it (`updateKametiDraft`) and use the real kameti id. Every write
/// returns the [Failure] to show, or null on success, and invalidates the
/// kameti providers it touched.

@ProviderFor(CreateWizard)
final createWizardProvider = CreateWizardProvider._();

/// Drives the create-kameti wizard (board AC-1…AC-6, FR-10–FR-12).
///
/// Step 1 creates the draft on the server (`createKameti`); later saves
/// update it (`updateKametiDraft`) and use the real kameti id. Every write
/// returns the [Failure] to show, or null on success, and invalidates the
/// kameti providers it touched.
final class CreateWizardProvider
    extends $NotifierProvider<CreateWizard, CreateWizardState> {
  /// Drives the create-kameti wizard (board AC-1…AC-6, FR-10–FR-12).
  ///
  /// Step 1 creates the draft on the server (`createKameti`); later saves
  /// update it (`updateKametiDraft`) and use the real kameti id. Every write
  /// returns the [Failure] to show, or null on success, and invalidates the
  /// kameti providers it touched.
  CreateWizardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createWizardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createWizardHash();

  @$internal
  @override
  CreateWizard create() => CreateWizard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateWizardState>(value),
    );
  }
}

String _$createWizardHash() => r'e7375d4828ddda4c81d4561376af73e0f07663d3';

/// Drives the create-kameti wizard (board AC-1…AC-6, FR-10–FR-12).
///
/// Step 1 creates the draft on the server (`createKameti`); later saves
/// update it (`updateKametiDraft`) and use the real kameti id. Every write
/// returns the [Failure] to show, or null on success, and invalidates the
/// kameti providers it touched.

abstract class _$CreateWizard extends $Notifier<CreateWizardState> {
  CreateWizardState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CreateWizardState, CreateWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateWizardState, CreateWizardState>,
              CreateWizardState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
