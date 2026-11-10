import 'package:kameti/core/result/result.dart';
import 'package:kameti/features/invites/domain/invite_models.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';

/// Invites and joining (REQUIREMENTS §5.4, §5.5). Writes go through RPCs
/// only; the invite email is sent by the `send-invites` Edge Function.
abstract interface class InvitesRepository {
  // ---- Owner ----

  /// First invite for a member. Errors: `member_has_no_email`,
  /// `invite_already_pending`, `member_already_joined`, `approval_pending`.
  Future<Result<InviteLink>> createInvite(String memberId);

  /// New link, old one superseded. Errors include `resend_too_soon`.
  Future<Result<InviteLink>> resendInvite(String memberId);

  Future<Result<Member>> revokeInvite(String memberId);
  Future<Result<Member>> approveJoin(String memberId);
  Future<Result<Member>> declineJoin(String memberId);

  /// Removes the link between a member and their account; history stays.
  Future<Result<Member>> unlinkMember(String memberId);

  /// Emails [link]. Ok(false) means email isn't configured on the server
  /// (the link is still valid: share it by hand).
  Future<Result<bool>> sendInviteEmail(InviteLink link);

  /// Every invite of the kameti (owner only).
  Future<Result<List<Invite>>> listInvites(String kametiId);

  // ---- Invitee (any signed-in user) ----
  // Exactly one of [token] (or the 6-character code) and [inviteId].

  Future<Result<InvitePreview>> previewInvite({
    String? token,
    String? inviteId,
  });

  /// The member row; `joinStatus` is `joined` or `pendingApproval`.
  Future<Result<Member>> acceptInvite({String? token, String? inviteId});
  Future<Result<Member>> declineInvite({String? token, String? inviteId});

  Future<Result<List<MyInvitation>>> listMyInvitations();
}
