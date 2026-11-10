// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Join requests waiting on kametis the signed-in user runs.

@ProviderFor(pendingApprovals)
final pendingApprovalsProvider = PendingApprovalsProvider._();

/// Join requests waiting on kametis the signed-in user runs.

final class PendingApprovalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PendingApproval>>,
          List<PendingApproval>,
          FutureOr<List<PendingApproval>>
        >
    with
        $FutureModifier<List<PendingApproval>>,
        $FutureProvider<List<PendingApproval>> {
  /// Join requests waiting on kametis the signed-in user runs.
  PendingApprovalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingApprovalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingApprovalsHash();

  @$internal
  @override
  $FutureProviderElement<List<PendingApproval>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PendingApproval>> create(Ref ref) {
    return pendingApprovals(ref);
  }
}

String _$pendingApprovalsHash() => r'95871c8df19a711e5aba9f46d08f28fc81b37dbf';

/// How many things need the user's attention (open invitations plus join
/// requests). Drives the dot on the Inbox tab.

@ProviderFor(inboxCount)
final inboxCountProvider = InboxCountProvider._();

/// How many things need the user's attention (open invitations plus join
/// requests). Drives the dot on the Inbox tab.

final class InboxCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many things need the user's attention (open invitations plus join
  /// requests). Drives the dot on the Inbox tab.
  InboxCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return inboxCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$inboxCountHash() => r'444e91c10a807c4fc511d311332610238d793502';
