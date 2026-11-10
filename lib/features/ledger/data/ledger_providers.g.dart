// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ledgerRepository)
final ledgerRepositoryProvider = LedgerRepositoryProvider._();

final class LedgerRepositoryProvider
    extends
        $FunctionalProvider<
          LedgerRepository,
          LedgerRepository,
          LedgerRepository
        >
    with $Provider<LedgerRepository> {
  LedgerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerRepositoryHash();

  @$internal
  @override
  $ProviderElement<LedgerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LedgerRepository create(Ref ref) {
    return ledgerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerRepository>(value),
    );
  }
}

String _$ledgerRepositoryHash() => r'50eea66c71001fe072fab688b8afe8adda07a16e';

@ProviderFor(memberBalances)
final memberBalancesProvider = MemberBalancesFamily._();

final class MemberBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberBalanceRow>>,
          List<MemberBalanceRow>,
          FutureOr<List<MemberBalanceRow>>
        >
    with
        $FutureModifier<List<MemberBalanceRow>>,
        $FutureProvider<List<MemberBalanceRow>> {
  MemberBalancesProvider._({
    required MemberBalancesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'memberBalancesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberBalancesHash();

  @override
  String toString() {
    return r'memberBalancesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MemberBalanceRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MemberBalanceRow>> create(Ref ref) {
    final argument = this.argument as String;
    return memberBalances(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberBalancesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberBalancesHash() => r'cefa4f900b7b92f74dc42751de112426bfbd0de4';

final class MemberBalancesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MemberBalanceRow>>, String> {
  MemberBalancesFamily._()
    : super(
        retry: null,
        name: r'memberBalancesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberBalancesProvider call(String kametiId) =>
      MemberBalancesProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'memberBalancesProvider';
}

@ProviderFor(memberMonths)
final memberMonthsProvider = MemberMonthsFamily._();

final class MemberMonthsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberMonthRow>>,
          List<MemberMonthRow>,
          FutureOr<List<MemberMonthRow>>
        >
    with
        $FutureModifier<List<MemberMonthRow>>,
        $FutureProvider<List<MemberMonthRow>> {
  MemberMonthsProvider._({
    required MemberMonthsFamily super.from,
    required (String, {String? memberId}) super.argument,
  }) : super(
         retry: null,
         name: r'memberMonthsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$memberMonthsHash();

  @override
  String toString() {
    return r'memberMonthsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<MemberMonthRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MemberMonthRow>> create(Ref ref) {
    final argument = this.argument as (String, {String? memberId});
    return memberMonths(ref, argument.$1, memberId: argument.memberId);
  }

  @override
  bool operator ==(Object other) {
    return other is MemberMonthsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberMonthsHash() => r'ad9139f47880a2d8663904e93b047494cb69a00e';

final class MemberMonthsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MemberMonthRow>>,
          (String, {String? memberId})
        > {
  MemberMonthsFamily._()
    : super(
        retry: null,
        name: r'memberMonthsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MemberMonthsProvider call(String kametiId, {String? memberId}) =>
      MemberMonthsProvider._(
        argument: (kametiId, memberId: memberId),
        from: this,
      );

  @override
  String toString() => r'memberMonthsProvider';
}

@ProviderFor(monthCollections)
final monthCollectionsProvider = MonthCollectionsFamily._();

final class MonthCollectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MonthCollectionRow>>,
          List<MonthCollectionRow>,
          FutureOr<List<MonthCollectionRow>>
        >
    with
        $FutureModifier<List<MonthCollectionRow>>,
        $FutureProvider<List<MonthCollectionRow>> {
  MonthCollectionsProvider._({
    required MonthCollectionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'monthCollectionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthCollectionsHash();

  @override
  String toString() {
    return r'monthCollectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MonthCollectionRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MonthCollectionRow>> create(Ref ref) {
    final argument = this.argument as String;
    return monthCollections(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthCollectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthCollectionsHash() => r'fd5bed8785953efb5a4643efbc02ccf1dc48ae9f';

final class MonthCollectionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MonthCollectionRow>>, String> {
  MonthCollectionsFamily._()
    : super(
        retry: null,
        name: r'monthCollectionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MonthCollectionsProvider call(String kametiId) =>
      MonthCollectionsProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'monthCollectionsProvider';
}
