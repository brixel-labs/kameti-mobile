import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/invites/domain/invite_models.dart';
import 'package:kameti/features/invites/domain/invites_repository.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInvitesRepository implements InvitesRepository {
  const new(this._db);

  final SupabaseClient _db;

  static Map<String, dynamic> _map(Object? r) =>
      Map<String, dynamic>.from(r! as Map);

  Future<Member> _member(String fn, Map<String, dynamic> params) async =>
      Member.fromJson(_map(await _db.rpc<Object?>(fn, params: params)));

  Future<InviteLink> _link(String fn, String memberId) async =>
      InviteLink.fromJson(
        _map(await _db.rpc<Object?>(fn, params: {'p_member_id': memberId})),
      );

  Map<String, dynamic> _lookup(String? token, String? inviteId) => {
    'p_token': token,
    'p_invite_id': inviteId,
  };

  @override
  Future<Result<InviteLink>> createInvite(String memberId) =>
      Result.guard(() => _link('create_invite', memberId));

  @override
  Future<Result<InviteLink>> resendInvite(String memberId) =>
      Result.guard(() => _link('resend_invite', memberId));

  @override
  Future<Result<Member>> revokeInvite(String memberId) =>
      Result.guard(() => _member('revoke_invite', {'p_member_id': memberId}));

  @override
  Future<Result<Member>> approveJoin(String memberId) =>
      Result.guard(() => _member('approve_join', {'p_member_id': memberId}));

  @override
  Future<Result<Member>> declineJoin(String memberId) =>
      Result.guard(() => _member('decline_join', {'p_member_id': memberId}));

  @override
  Future<Result<Member>> unlinkMember(String memberId) =>
      Result.guard(() => _member('unlink_member', {'p_member_id': memberId}));

  @override
  Future<Result<bool>> sendInviteEmail(InviteLink link) =>
      Result.guard(() async {
        try {
          await _db.functions.invoke(
            'send-invites',
            body: {
              'invite_id': link.inviteId,
              'token': link.token,
              'code': link.code,
            },
          );
          return true;
        } on FunctionException catch (e) {
          // 503 email_not_configured: the link still works by hand.
          if (e.status == 503) return false;
          rethrow;
        }
      });

  @override
  Future<Result<List<Invite>>> listInvites(String kametiId) =>
      Result.guard(() async {
        final rows = await _db
            .from('invites')
            .select()
            .eq('kameti_id', kametiId)
            .order('created_at', ascending: false);
        return [for (final r in rows) Invite.fromJson(_map(r))];
      });

  @override
  Future<Result<InvitePreview>> previewInvite({
    String? token,
    String? inviteId,
  }) => Result.guard(
    () async => InvitePreview.fromJson(
      _map(
        await _db.rpc<Object?>(
          'preview_invite',
          params: _lookup(token, inviteId),
        ),
      ),
    ),
  );

  @override
  Future<Result<Member>> acceptInvite({String? token, String? inviteId}) =>
      Result.guard(() => _member('accept_invite', _lookup(token, inviteId)));

  @override
  Future<Result<Member>> declineInvite({String? token, String? inviteId}) =>
      Result.guard(() => _member('decline_invite', _lookup(token, inviteId)));

  @override
  Future<Result<List<MyInvitation>>> listMyInvitations() =>
      Result.guard(() async {
        final rows = await _db.rpc<List<dynamic>>('list_my_invitations');
        return [for (final r in rows) MyInvitation.fromJson(_map(r))];
      });
}
