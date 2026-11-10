import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kameti/core/json/money_converter.dart';
import 'package:kameti/core/money/money.dart';

part 'invite_models.freezed.dart';
part 'invite_models.g.dart';

/// Matches `public.invite_status`.
@JsonEnum(fieldRename: FieldRename.snake)
enum InviteStatus { pending, accepted, declined, revoked, superseded }

/// Row of `public.invites`: owner-only. The token itself is never stored in
/// readable form, so "Copy link" later means resending (a new link).
@freezed
abstract class Invite with _$Invite {
  const factory({
    required String id,
    required String kametiId,
    required String memberId,
    required InviteStatus status,
    required DateTime expiresAt,
    required int sendCount,
    String? email,
    DateTime? sentAt,

    /// The email the invitee signed in with. Show it masked.
    String? acceptedEmail,
  }) = _Invite;

  factory fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

  const new _();

  /// Expired is derived: pending past its expiry (the member stays
  /// `invited` on the backend).
  bool isExpiredAt(DateTime now) =>
      status == InviteStatus.pending && expiresAt.isBefore(now);
}

/// Result of `create_invite` / `resend_invite`. [token] and [code] are
/// readable exactly once: hand them to the email function or the owner.
@freezed
abstract class InviteLink with _$InviteLink {
  const factory({
    required String inviteId,
    required String memberId,
    required String token,
    required String code,
    required String link,
    required DateTime expiresAt,
    String? email,
  }) = _InviteLink;

  factory fromJson(Map<String, dynamic> json) => _$InviteLinkFromJson(json);
}

/// One share of the invited member, shown before they accept.
@freezed
abstract class InviteShare with _$InviteShare {
  const factory({
    required int payoutMonthIndex,
    @MoneyConverter() required Money monthlyAmount,
  }) = _InviteShare;

  factory fromJson(Map<String, dynamic> json) => _$InviteShareFromJson(json);
}

/// Result of `preview_invite`: what the invitee sees on the accept screen.
@freezed
abstract class InvitePreview with _$InvitePreview {
  const factory({
    required String inviteId,
    required String status,
    required bool expired,
    required DateTime expiresAt,
    required bool emailMatches,
    required String kametiName,
    required String ownerName,
    required String memberName,
    @Default(<InviteShare>[]) List<InviteShare> shares,
  }) = _InvitePreview;

  factory fromJson(Map<String, dynamic> json) => _$InvitePreviewFromJson(json);

  const new _();

  /// Still open: pending and not past its expiry.
  bool get isOpen => status == 'pending' && !expired;
}

/// Row of `list_my_invitations()`: live invites addressed to the
/// signed-in account's email.
@freezed
abstract class MyInvitation with _$MyInvitation {
  const factory({
    required String inviteId,
    required String kametiName,
    required String ownerName,
    required String memberName,
    required DateTime expiresAt,
    required DateTime createdAt,
  }) = _MyInvitation;

  factory fromJson(Map<String, dynamic> json) => _$MyInvitationFromJson(json);
}
