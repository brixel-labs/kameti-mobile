// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(auditRepository)
final auditRepositoryProvider = AuditRepositoryProvider._();

final class AuditRepositoryProvider
    extends
        $FunctionalProvider<AuditRepository, AuditRepository, AuditRepository>
    with $Provider<AuditRepository> {
  AuditRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuditRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditRepository create(Ref ref) {
    return auditRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditRepository>(value),
    );
  }
}

String _$auditRepositoryHash() => r'0295f8271410d84a5621eda921901849dc206ff1';

/// The latest 100 audit entries of a kameti, newest first.

@ProviderFor(kametiAudit)
final kametiAuditProvider = KametiAuditFamily._();

/// The latest 100 audit entries of a kameti, newest first.

final class KametiAuditProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AuditEntry>>,
          List<AuditEntry>,
          FutureOr<List<AuditEntry>>
        >
    with $FutureModifier<List<AuditEntry>>, $FutureProvider<List<AuditEntry>> {
  /// The latest 100 audit entries of a kameti, newest first.
  KametiAuditProvider._({
    required KametiAuditFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiAuditProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiAuditHash();

  @override
  String toString() {
    return r'kametiAuditProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AuditEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AuditEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiAudit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiAuditProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiAuditHash() => r'af55adf180b35688ddcead79c61c44c3436a8e57';

/// The latest 100 audit entries of a kameti, newest first.

final class KametiAuditFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AuditEntry>>, String> {
  KametiAuditFamily._()
    : super(
        retry: null,
        name: r'kametiAuditProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The latest 100 audit entries of a kameti, newest first.

  KametiAuditProvider call(String kametiId) =>
      KametiAuditProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiAuditProvider';
}
