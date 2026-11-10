// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kameti_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kametiRepository)
final kametiRepositoryProvider = KametiRepositoryProvider._();

final class KametiRepositoryProvider
    extends
        $FunctionalProvider<
          KametiRepository,
          KametiRepository,
          KametiRepository
        >
    with $Provider<KametiRepository> {
  KametiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kametiRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kametiRepositoryHash();

  @$internal
  @override
  $ProviderElement<KametiRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KametiRepository create(Ref ref) {
    return kametiRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KametiRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KametiRepository>(value),
    );
  }
}

String _$kametiRepositoryHash() => r'da9fe55f9031030fbad7e444ec8df040f78d9e9f';

/// Every kameti the user runs or has joined. Invalidate after a write.

@ProviderFor(myKametis)
final myKametisProvider = MyKametisProvider._();

/// Every kameti the user runs or has joined. Invalidate after a write.

final class MyKametisProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Kameti>>,
          List<Kameti>,
          FutureOr<List<Kameti>>
        >
    with $FutureModifier<List<Kameti>>, $FutureProvider<List<Kameti>> {
  /// Every kameti the user runs or has joined. Invalidate after a write.
  MyKametisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myKametisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myKametisHash();

  @$internal
  @override
  $FutureProviderElement<List<Kameti>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Kameti>> create(Ref ref) {
    return myKametis(ref);
  }
}

String _$myKametisHash() => r'a126fd1425116bed4a40e82906ab90c07c94c881';

@ProviderFor(kameti)
final kametiProvider = KametiFamily._();

final class KametiProvider
    extends $FunctionalProvider<AsyncValue<Kameti>, Kameti, FutureOr<Kameti>>
    with $FutureModifier<Kameti>, $FutureProvider<Kameti> {
  KametiProvider._({
    required KametiFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiHash();

  @override
  String toString() {
    return r'kametiProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Kameti> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Kameti> create(Ref ref) {
    final argument = this.argument as String;
    return kameti(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiHash() => r'504c4e34f684fb5a93e97302318801651c23f92b';

final class KametiFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Kameti>, String> {
  KametiFamily._()
    : super(
        retry: null,
        name: r'kametiProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KametiProvider call(String kametiId) =>
      KametiProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiProvider';
}

@ProviderFor(kametiMembers)
final kametiMembersProvider = KametiMembersFamily._();

final class KametiMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Member>>,
          List<Member>,
          FutureOr<List<Member>>
        >
    with $FutureModifier<List<Member>>, $FutureProvider<List<Member>> {
  KametiMembersProvider._({
    required KametiMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiMembersHash();

  @override
  String toString() {
    return r'kametiMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Member>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Member>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiMembersHash() => r'85c51052d31ef080007a57bcbc21d71846423663';

final class KametiMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Member>>, String> {
  KametiMembersFamily._()
    : super(
        retry: null,
        name: r'kametiMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KametiMembersProvider call(String kametiId) =>
      KametiMembersProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiMembersProvider';
}

@ProviderFor(kametiSlots)
final kametiSlotsProvider = KametiSlotsFamily._();

final class KametiSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Slot>>,
          List<Slot>,
          FutureOr<List<Slot>>
        >
    with $FutureModifier<List<Slot>>, $FutureProvider<List<Slot>> {
  KametiSlotsProvider._({
    required KametiSlotsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiSlotsHash();

  @override
  String toString() {
    return r'kametiSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Slot>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Slot>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiSlots(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiSlotsHash() => r'2f775a89351ca690c083dfdef2ce9fee218c9509';

final class KametiSlotsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Slot>>, String> {
  KametiSlotsFamily._()
    : super(
        retry: null,
        name: r'kametiSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KametiSlotsProvider call(String kametiId) =>
      KametiSlotsProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiSlotsProvider';
}

@ProviderFor(kametiShares)
final kametiSharesProvider = KametiSharesFamily._();

final class KametiSharesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Share>>,
          List<Share>,
          FutureOr<List<Share>>
        >
    with $FutureModifier<List<Share>>, $FutureProvider<List<Share>> {
  KametiSharesProvider._({
    required KametiSharesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiSharesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiSharesHash();

  @override
  String toString() {
    return r'kametiSharesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Share>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Share>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiShares(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiSharesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiSharesHash() => r'd97729c979d514248987e74788d4d8d23dff93a4';

final class KametiSharesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Share>>, String> {
  KametiSharesFamily._()
    : super(
        retry: null,
        name: r'kametiSharesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  KametiSharesProvider call(String kametiId) =>
      KametiSharesProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiSharesProvider';
}

/// Whether the signed-in user owns this kameti. The single place the UI
/// decides owner vs member (flutter-architecture rule 7). The backend
/// enforces it again on every write.

@ProviderFor(isKametiOwner)
final isKametiOwnerProvider = IsKametiOwnerFamily._();

/// Whether the signed-in user owns this kameti. The single place the UI
/// decides owner vs member (flutter-architecture rule 7). The backend
/// enforces it again on every write.

final class IsKametiOwnerProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether the signed-in user owns this kameti. The single place the UI
  /// decides owner vs member (flutter-architecture rule 7). The backend
  /// enforces it again on every write.
  IsKametiOwnerProvider._({
    required IsKametiOwnerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isKametiOwnerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isKametiOwnerHash();

  @override
  String toString() {
    return r'isKametiOwnerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isKametiOwner(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsKametiOwnerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isKametiOwnerHash() => r'd9410892c6f1d1338598cb1468c960d13fcad993';

/// Whether the signed-in user owns this kameti. The single place the UI
/// decides owner vs member (flutter-architecture rule 7). The backend
/// enforces it again on every write.

final class IsKametiOwnerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsKametiOwnerFamily._()
    : super(
        retry: null,
        name: r'isKametiOwnerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether the signed-in user owns this kameti. The single place the UI
  /// decides owner vs member (flutter-architecture rule 7). The backend
  /// enforces it again on every write.

  IsKametiOwnerProvider call(String kametiId) =>
      IsKametiOwnerProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'isKametiOwnerProvider';
}
