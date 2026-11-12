// Generated once from the Flutter app's app_en.arb so the wording stays identical.
import Foundation
import KametiCore

extension Failure {
    /// A message a person can act on, localized. Raw backend text is never shown.
    public var userMessage: String {
        switch self {
        case .network:
            String(localized: "You're offline. Connect and try again.", bundle: .module)
        case .auth:
            String(localized: "Your session has ended. Please sign in again.", bundle: .module)
        case .unknown:
            String(localized: "Something went wrong. Please try again.", bundle: .module)
        case .server(let code, _):
            Self.serverMessage(code)
        case .signIn(let problem, _):
            switch problem {
            case .notConfigured:
                String(localized: "This build isn't connected to the Kameti service.", bundle: .module)
            case .misconfigured:
                String(localized: "Sign-in isn't set up correctly for this build.", bundle: .module)
            case .interrupted:
                String(localized: "Sign-in was interrupted. Please try again.", bundle: .module)
            case .unavailable:
                String(localized: "Sign-in isn't available on this device right now.", bundle: .module)
            case .rejected:
                String(localized: "We couldn't sign you in. Please try again.", bundle: .module)
            }
        }
    }

    static func serverMessage(_ code: String) -> String {
        switch code {
        case "not_authenticated":
            String(localized: "Your session has ended. Please sign in again.", bundle: .module)
        case "not_kameti_owner":
            String(localized: "Only the person running this kameti can do that.", bundle: .module)
        case "kameti_not_draft":
            String(localized: "This can only be changed before the kameti starts.", bundle: .module)
        case "kameti_not_active":
            String(localized: "This kameti hasn't started yet.", bundle: .module)
        case "kameti_not_ready":
            String(localized: "Fill every slot and payout month before starting.", bundle: .module)
        case "kameti_not_editable":
            String(localized: "This kameti has ended, so it can't be changed.", bundle: .module)
        case "kameti_already_running":
            String(localized: "Its first month has started, so the setup can't change any more.", bundle: .module)
        case "kameti_has_records":
            String(localized: "Payments or changes are already recorded, so the setup can't change any more.", bundle: .module)
        case "kameti_name_taken":
            String(localized: "You already have a kameti with this name.", bundle: .module)
        case "invalid_name":
            String(localized: "Name must be 3 to 40 characters.", bundle: .module)
        case "invalid_amount":
            String(localized: "Enter an amount above zero.", bundle: .module)
        case "invalid_share_amount":
            String(localized: "Shares must be whole Rs 1,000 steps.", bundle: .module)
        case "invalid_slot_amount":
            String(localized: "Shares must be whole Rs 1,000 steps.", bundle: .module)
        case "shares_must_sum_to_slot_amount":
            String(localized: "The shares must add up exactly to the slot amount.", bundle: .module)
        case "too_many_sharers":
            String(localized: "A slot can be shared by at most 4 people.", bundle: .module)
        case "member_slot_limit_exceeded":
            String(localized: "This person has reached the slot limit for this kameti.", bundle: .module)
        case "future_date":
            String(localized: "The date can't be in the future.", bundle: .module)
        case "month_locked":
            String(localized: "Months that have been paid out can't be moved.", bundle: .module)
        case "member_has_history":
            String(localized: "This person holds a slot share or has payments, so they can’t be removed.", bundle: .module)
        case "already_member":
            String(localized: "You're already a member of this kameti.", bundle: .module)
        case "contact_already_member":
            String(localized: "This person is already in the kameti.", bundle: .module)
        case "already_voided":
            String(localized: "This entry was already voided.", bundle: .module)
        case "void_reason_required":
            String(localized: "Add a reason for voiding.", bundle: .module)
        case "empty_batch":
            String(localized: "Mark at least one payment.", bundle: .module)
        case "payout_note_required":
            String(localized: "Add a note: the payout differs from the expected amount.", bundle: .module)
        case "member_has_no_email":
            String(localized: "Add an email address for this person first.", bundle: .module)
        case "invite_already_pending":
            String(localized: "They already have an open invite.", bundle: .module)
        case "member_already_joined":
            String(localized: "This person has already joined.", bundle: .module)
        case "approval_pending":
            String(localized: "This person is waiting for your approval.", bundle: .module)
        case "invite_rate_limited":
            String(localized: "Too many invites sent. Try again in an hour.", bundle: .module)
        case "no_invite":
            String(localized: "There's no invite to resend yet.", bundle: .module)
        case "resend_too_soon":
            String(localized: "You just sent one. Wait about 10 minutes before resending.", bundle: .module)
        case "no_pending_invite":
            String(localized: "There's no open invite to revoke.", bundle: .module)
        case "not_pending_approval":
            String(localized: "This request was already handled.", bundle: .module)
        case "share_not_active":
            String(localized: "This share has already been transferred.", bundle: .module)
        case "same_member":
            String(localized: "Pick someone other than the current holder.", bundle: .module)
        case "already_reminded_today":
            String(localized: "Everyone you picked already had a reminder from you today. Try again tomorrow.", bundle: .module)
        case "nobody_to_remind":
            String(localized: "Nobody with the app owes anything right now.", bundle: .module)
        case "invalid_transfer_month":
            String(localized: "Pick this month or a later one.", bundle: .module)
        case "already_in_slot":
            String(localized: "This person already has a share in this slot.", bundle: .module)
        case "member_not_in_kameti":
            String(localized: "This person isn't a member of this kameti.", bundle: .module)
        case "member_not_linked":
            String(localized: "This person isn't linked to an account.", bundle: .module)
        case "cannot_unlink_owner":
            String(localized: "You can't unlink the person running the kameti.", bundle: .module)
        case "invite_not_found":
            String(localized: "We couldn't find that invite. Check the link or code.", bundle: .module)
        case "invalid_invite":
            String(localized: "We couldn't find that invite. Check the link or code.", bundle: .module)
        case "invite_not_active":
            String(localized: "This invite is no longer active.", bundle: .module)
        case "invite_expired":
            String(localized: "This invite has expired.", bundle: .module)
        case "kameti_not_joinable":
            String(localized: "This kameti isn't open for joining.", bundle: .module)
        case "owner_cannot_join":
            String(localized: "You run this kameti, so you can't join it as a member.", bundle: .module)
        case "member_already_linked":
            String(localized: "Your account is already linked to this kameti.", bundle: .module)
        case "owner_has_active_kametis":
            String(localized: "You still run a kameti. Archive it or hand it over before deleting your account.", bundle: .module)
        case "confirmation_required":
            String(localized: "Confirm that you want to delete your account.", bundle: .module)
        case "delete_failed", "auth_delete_failed", "check_failed":
            String(localized: "Your account couldn't be deleted. Please try again.", bundle: .module)
        case "invalid_note_body":
            String(localized: "A note must be 1 to 2,000 characters.", bundle: .module)
        case "invalid_visibility":
            String(localized: "Choose private or shared.", bundle: .module)
        case "invalid_target":
            String(localized: "Choose what the note is about.", bundle: .module)
        case "target_not_found":
            String(localized: "That item isn't in this kameti any more.", bundle: .module)
        case "nothing_to_change":
            String(localized: "Change the text or who can see it.", bundle: .module)
        case "not_kameti_member":
            String(localized: "You're not in this kameti.", bundle: .module)
        default:
            String(localized: "Something went wrong. Please try again.", bundle: .module)
        }
    }
}
