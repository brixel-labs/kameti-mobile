import 'package:kameti/core/supabase/supabase_client_provider.dart';
import 'package:kameti/features/invites/data/supabase_invites_repository.dart';
import 'package:kameti/features/invites/domain/invite_models.dart';
import 'package:kameti/features/invites/domain/invites_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invites_providers.g.dart';

@Riverpod(keepAlive: true)
InvitesRepository invitesRepository(Ref ref) =>
    SupabaseInvitesRepository(ref.watch(supabaseClientProvider));

/// Every invite of a kameti (owner only), newest first.
@riverpod
Future<List<Invite>> kametiInvites(Ref ref, String kametiId) async =>
    (await ref.watch(invitesRepositoryProvider).listInvites(kametiId))
        .getOrThrow();

/// Live invitations addressed to the signed-in account.
@riverpod
Future<List<MyInvitation>> myInvitations(Ref ref) async =>
    (await ref.watch(invitesRepositoryProvider).listMyInvitations())
        .getOrThrow();

/// What an invite link or code is for, before accepting it. [token] may
/// be the 6-character code.
@riverpod
Future<InvitePreview> invitePreview(Ref ref, String token) async =>
    (await ref.watch(invitesRepositoryProvider).previewInvite(token: token))
        .getOrThrow();
