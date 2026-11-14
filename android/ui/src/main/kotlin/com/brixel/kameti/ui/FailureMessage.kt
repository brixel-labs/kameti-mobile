package com.brixel.kameti.ui

import android.content.Context
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.SignInProblem

// The same wording as the iOS app's FailureMessage.swift.

/** A message a person can act on. Raw backend text is never shown. */
@get:StringRes
val Failure.messageRes: Int
    get() = when (this) {
        Failure.Network -> R.string.ui_youre_offline_connect_and_try_again
        is Failure.Auth -> R.string.ui_your_session_has_ended_please_sign_in_again
        is Failure.Unknown -> R.string.ui_something_went_wrong_please_try_again
        is Failure.Server -> serverMessageRes(code)
        is Failure.SignIn -> when (problem) {
            SignInProblem.NotConfigured -> R.string.ui_this_build_isnt_connected_to_the_kameti_service
            SignInProblem.Misconfigured -> R.string.ui_sign_in_isnt_set_up_correctly_for_this
            SignInProblem.Interrupted -> R.string.ui_sign_in_was_interrupted_please_try_again
            SignInProblem.Unavailable -> R.string.ui_sign_in_isnt_available_on_this_device_right
            SignInProblem.Rejected -> R.string.ui_we_couldnt_sign_you_in_please_try_again
        }
    }

/**
 * The help line under an error title: connection advice when offline,
 * otherwise the failure's own message.
 */
@get:StringRes
val Failure.helpMessageRes: Int
    get() = if (this == Failure.Network) R.string.ui_check_your_connection_and_try_again else messageRes

@Composable
fun Failure.userMessage(): String = stringResource(messageRes)

@Composable
fun Failure.helpMessage(): String = stringResource(helpMessageRes)

fun Failure.userMessage(context: Context): String = context.getString(messageRes)

fun Failure.helpMessage(context: Context): String = context.getString(helpMessageRes)

@StringRes
internal fun serverMessageRes(code: String): Int = when (code) {
    "not_authenticated" -> R.string.ui_your_session_has_ended_please_sign_in_again
    "not_kameti_owner" -> R.string.ui_only_the_person_running_this_kameti_can_do
    "kameti_not_draft" -> R.string.ui_this_can_only_be_changed_before_the_kameti
    "kameti_not_active" -> R.string.ui_this_kameti_hasnt_started_yet
    "kameti_not_ready" -> R.string.ui_fill_every_slot_and_payout_month_before_starting
    "kameti_not_editable" -> R.string.ui_this_kameti_has_ended_so_it_cant_be
    "kameti_already_running" -> R.string.ui_its_first_month_has_started_so_the_setup
    "kameti_has_records" -> R.string.ui_payments_or_changes_are_already_recorded_so_the
    "kameti_name_taken" -> R.string.ui_you_already_have_a_kameti_with_this_name
    "invalid_name" -> R.string.ui_name_must_be_3_to_40_characters
    "invalid_amount" -> R.string.ui_enter_an_amount_above_zero
    "invalid_share_amount", "invalid_slot_amount" -> R.string.ui_shares_must_be_whole_rs_1_000_steps
    "shares_must_sum_to_slot_amount" -> R.string.ui_the_shares_must_add_up_exactly_to_the
    "too_many_sharers" -> R.string.ui_a_slot_can_be_shared_by_at_most
    "member_slot_limit_exceeded" -> R.string.ui_this_person_has_reached_the_slot_limit_for
    "future_date" -> R.string.ui_the_date_cant_be_in_the_future
    "month_locked" -> R.string.ui_months_that_have_been_paid_out_cant_be
    "member_has_history" -> R.string.ui_this_person_holds_a_slot_share_or_has
    "already_member" -> R.string.ui_youre_already_a_member_of_this_kameti
    "contact_already_member" -> R.string.ui_this_person_is_already_in_the_kameti
    "already_voided" -> R.string.ui_this_entry_was_already_voided
    "void_reason_required" -> R.string.ui_add_a_reason_for_voiding
    "empty_batch" -> R.string.ui_mark_at_least_one_payment
    "payout_note_required" -> R.string.ui_add_a_note_the_payout_differs_from_the
    "member_has_no_email" -> R.string.ui_add_an_email_address_for_this_person_first
    "invite_already_pending" -> R.string.ui_they_already_have_an_open_invite
    "member_already_joined" -> R.string.ui_this_person_has_already_joined
    "approval_pending" -> R.string.ui_this_person_is_waiting_for_your_approval
    "invite_rate_limited" -> R.string.ui_too_many_invites_sent_try_again_in_an
    "no_invite" -> R.string.ui_theres_no_invite_to_resend_yet
    "resend_too_soon" -> R.string.ui_you_just_sent_one_wait_about_10_minutes
    "no_pending_invite" -> R.string.ui_theres_no_open_invite_to_revoke
    "not_pending_approval" -> R.string.ui_this_request_was_already_handled
    "share_not_active" -> R.string.ui_this_share_has_already_been_transferred
    "same_member" -> R.string.ui_pick_someone_other_than_the_current_holder
    "already_reminded_today" -> R.string.ui_everyone_you_picked_already_had_a_reminder_from
    "nobody_to_remind" -> R.string.ui_nobody_with_the_app_owes_anything_right_now
    "invalid_transfer_month" -> R.string.ui_pick_this_month_or_a_later_one
    "already_in_slot" -> R.string.ui_this_person_already_has_a_share_in_this
    "member_not_in_kameti" -> R.string.ui_this_person_isnt_a_member_of_this_kameti
    "member_not_linked" -> R.string.ui_this_person_isnt_linked_to_an_account
    "cannot_unlink_owner" -> R.string.ui_you_cant_unlink_the_person_running_the_kameti
    "invite_not_found", "invalid_invite" -> R.string.ui_we_couldnt_find_that_invite_check_the_link
    "invite_not_active" -> R.string.ui_this_invite_is_no_longer_active
    "invite_expired" -> R.string.ui_this_invite_has_expired
    "kameti_not_joinable" -> R.string.ui_this_kameti_isnt_open_for_joining
    "owner_cannot_join" -> R.string.ui_you_run_this_kameti_so_you_cant_join
    "member_already_linked" -> R.string.ui_your_account_is_already_linked_to_this_kameti
    "owner_has_active_kametis" -> R.string.ui_you_still_run_a_kameti_archive_it_or
    "confirmation_required" -> R.string.ui_confirm_that_you_want_to_delete_your_account
    "delete_failed", "auth_delete_failed", "check_failed" -> R.string.ui_your_account_couldnt_be_deleted_please_try_again
    "invalid_note_body" -> R.string.ui_a_note_must_be_1_to_2_000
    "invalid_visibility" -> R.string.ui_choose_private_or_shared
    "invalid_target" -> R.string.ui_choose_what_the_note_is_about
    "target_not_found" -> R.string.ui_that_item_isnt_in_this_kameti_any_more
    "nothing_to_change" -> R.string.ui_change_the_text_or_who_can_see_it
    "not_kameti_member" -> R.string.ui_youre_not_in_this_kameti
    else -> R.string.ui_something_went_wrong_please_try_again
}
