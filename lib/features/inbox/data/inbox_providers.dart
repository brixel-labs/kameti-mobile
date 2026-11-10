import 'package:kameti/features/auth/data/auth_repository.dart';
import 'package:kameti/features/invites/data/invites_providers.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inbox_providers.g.dart';

/// Someone who accepted an invite with a different email and waits for the
/// owner's approval (`pending_approval`).
class PendingApproval {
  const new({required this.kameti, required this.member});

  final Kameti kameti;
  final Member member;
}

/// Join requests waiting on kametis the signed-in user runs.
@riverpod
Future<List<PendingApproval>> pendingApprovals(Ref ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  final kametis = await ref.watch(myKametisProvider.future);
  final owned = [
    for (final k in kametis)
      if (k.isOwnedBy(userId) &&
          (k.status == KametiStatus.active || k.status == KametiStatus.draft))
        k,
  ];
  final members = await Future.wait([
    for (final k in owned) ref.watch(kametiMembersProvider(k.id).future),
  ]);
  return [
    for (var i = 0; i < owned.length; i++)
      for (final m in members[i])
        if (m.joinStatus == JoinStatus.pendingApproval)
          PendingApproval(kameti: owned[i], member: m),
  ];
}

/// How many things need the user's attention (open invitations plus join
/// requests). Drives the dot on the Inbox tab.
@riverpod
int inboxCount(Ref ref) =>
    (ref.watch(pendingApprovalsProvider).value?.length ?? 0) +
    (ref.watch(myInvitationsProvider).value?.length ?? 0);
