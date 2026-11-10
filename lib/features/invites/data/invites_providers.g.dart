// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invites_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(invitesRepository)
final invitesRepositoryProvider = InvitesRepositoryProvider._();

final class InvitesRepositoryProvider
    extends
        $FunctionalProvider<
          InvitesRepository,
          InvitesRepository,
          InvitesRepository
        >
    with $Provider<InvitesRepository> {
  InvitesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitesRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvitesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvitesRepository create(Ref ref) {
    return invitesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvitesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvitesRepository>(value),
    );
  }
}

String _$invitesRepositoryHash() => r'4875d50a9e87bf01e7b2e3119dbda742cc87c3fe';

/// Every invite of a kameti (owner only), newest first.

@ProviderFor(kametiInvites)
final kametiInvitesProvider = KametiInvitesFamily._();

/// Every invite of a kameti (owner only), newest first.

final class KametiInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Invite>>,
          List<Invite>,
          FutureOr<List<Invite>>
        >
    with $FutureModifier<List<Invite>>, $FutureProvider<List<Invite>> {
  /// Every invite of a kameti (owner only), newest first.
  KametiInvitesProvider._({
    required KametiInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'kametiInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$kametiInvitesHash();

  @override
  String toString() {
    return r'kametiInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Invite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Invite>> create(Ref ref) {
    final argument = this.argument as String;
    return kametiInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is KametiInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$kametiInvitesHash() => r'9d122dd1ff0f9e6b9292cc6bb3ed74c2f3e2031f';

/// Every invite of a kameti (owner only), newest first.

final class KametiInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Invite>>, String> {
  KametiInvitesFamily._()
    : super(
        retry: null,
        name: r'kametiInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every invite of a kameti (owner only), newest first.

  KametiInvitesProvider call(String kametiId) =>
      KametiInvitesProvider._(argument: kametiId, from: this);

  @override
  String toString() => r'kametiInvitesProvider';
}

/// Live invitations addressed to the signed-in account.

@ProviderFor(myInvitations)
final myInvitationsProvider = MyInvitationsProvider._();

/// Live invitations addressed to the signed-in account.

final class MyInvitationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MyInvitation>>,
          List<MyInvitation>,
          FutureOr<List<MyInvitation>>
        >
    with
        $FutureModifier<List<MyInvitation>>,
        $FutureProvider<List<MyInvitation>> {
  /// Live invitations addressed to the signed-in account.
  MyInvitationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myInvitationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myInvitationsHash();

  @$internal
  @override
  $FutureProviderElement<List<MyInvitation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MyInvitation>> create(Ref ref) {
    return myInvitations(ref);
  }
}

String _$myInvitationsHash() => r'3c7687c614f16f839935acc26e2f7d4d18302e63';

/// What an invite link or code is for, before accepting it. [token] may
/// be the 6-character code.

@ProviderFor(invitePreview)
final invitePreviewProvider = InvitePreviewFamily._();

/// What an invite link or code is for, before accepting it. [token] may
/// be the 6-character code.

final class InvitePreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<InvitePreview>,
          InvitePreview,
          FutureOr<InvitePreview>
        >
    with $FutureModifier<InvitePreview>, $FutureProvider<InvitePreview> {
  /// What an invite link or code is for, before accepting it. [token] may
  /// be the 6-character code.
  InvitePreviewProvider._({
    required InvitePreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invitePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invitePreviewHash();

  @override
  String toString() {
    return r'invitePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InvitePreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InvitePreview> create(Ref ref) {
    final argument = this.argument as String;
    return invitePreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invitePreviewHash() => r'9fd7c9d3362daeeee578d144eb61c5b7ef729e39';

/// What an invite link or code is for, before accepting it. [token] may
/// be the 6-character code.

final class InvitePreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InvitePreview>, String> {
  InvitePreviewFamily._()
    : super(
        retry: null,
        name: r'invitePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What an invite link or code is for, before accepting it. [token] may
  /// be the 6-character code.

  InvitePreviewProvider call(String token) =>
      InvitePreviewProvider._(argument: token, from: this);

  @override
  String toString() => r'invitePreviewProvider';
}
