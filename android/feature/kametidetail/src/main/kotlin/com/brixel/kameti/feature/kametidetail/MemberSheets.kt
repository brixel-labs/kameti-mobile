package com.brixel.kameti.feature.kametidetail

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.InviteLink
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.feature.invites.ApproveJoinSheet
import com.brixel.kameti.feature.invites.InviteLogic
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KPill
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val small = KTextStyle(size = 13f, weight = FontWeight.SemiBold)

/** Closes a confirm sheet on success; shows what went wrong in it otherwise. */
internal fun confirmOutcome(failure: Failure?, title: String, context: Context): KConfirmOutcome =
    if (failure == null) {
        KConfirmOutcome.Dismiss
    } else {
        KConfirmOutcome.Result(KSheetMessage(title, failure.userMessage(context), KSheetMessage.Tone.Error))
    }

/**
 * Edit member (board AM-1b): name, email and phone, their app access, a
 * reminder when they owe, transferring a share, and removing the member when
 * nothing ties them to the ledger; otherwise the reason is shown.
 */
@Composable
internal fun EditMemberSheet(data: KametiDetailData, model: KametiDetailViewModel, member: Member, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val contact = MemberLogic.contact(member, data)
    var name by remember { mutableStateOf(member.name) }
    var email by remember { mutableStateOf(contact?.email.orEmpty()) }
    var phone by remember { mutableStateOf(contact?.phone.orEmpty()) }
    var submitted by remember { mutableStateOf(false) }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var confirmingRemove by remember { mutableStateOf(false) }
    var transferring by remember { mutableStateOf(false) }
    var reminding by remember { mutableStateOf(false) }

    // The member as loaded now, so invite changes show while the sheet is open.
    val currentMember = data.members.firstOrNull { it.id == member.id } ?: member
    val changes = MemberLogic.changes(name, email, phone, member, contact)
    val block = MemberLogic.removalBlock(member, data)
    val first = firstName(member.name)
    // What this member owes now, if anything (running kameti only).
    val owes = data.balances.firstOrNull { it.memberId == member.id }?.owes
        ?.takeIf { data.kameti.status == KametiStatus.Active && it.isPositive }

    KBottomSheet(stringResource(R.string.detail_edit_member), onDismiss, expanded = true, dismissDisabled = isBusy) { close ->
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).kDismissesKeyboard()
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            Identity(member, data)
            if (owes != null) {
                Row(
                    Modifier.fillMaxWidth().background(KColors.warningSubtle, RoundedCornerShape(12.dp)).padding(KSpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
                ) {
                    KIcon(KIcons.clock, tint = KColors.warning, size = 18.dp)
                    KText(
                        stringResource(R.string.detail_owes_s, owes.format()), KTextToken.bodyStrong,
                        modifier = Modifier.weight(1f), color = KColors.warning,
                    )
                    SmallButton(stringResource(R.string.detail_remind), KIcons.bell, KColors.textOnBrand, KColors.warning, CircleShape) {
                        reminding = true
                    }
                }
            }
            AppAccessCard(data, model, currentMember)
            KTextField(
                name, { name = it }, title = stringResource(R.string.detail_name),
                error = if (submitted && !MemberLogic.isValidName(name)) stringResource(R.string.detail_enter_a_name) else null,
                capitalization = KeyboardCapitalization.Words,
            )
            KTextField(
                email, { email = it }, title = stringResource(R.string.detail_email), placeholder = "name@example.com",
                error = if (submitted && !MemberLogic.isValidEmail(email)) {
                    stringResource(R.string.detail_enter_a_valid_email_or_leave_it_empty)
                } else {
                    null
                },
                keyboardType = KeyboardType.Email, capitalization = KeyboardCapitalization.None,
            )
            KTextField(
                phone, { phone = it }, title = stringResource(R.string.detail_phone), placeholder = "0300 1234567",
                error = if (submitted && !MemberLogic.isValidPhone(phone)) {
                    stringResource(R.string.detail_enter_a_valid_phone_number_or_leave_it)
                } else {
                    null
                },
                keyboardType = KeyboardType.Phone, capitalization = KeyboardCapitalization.None,
            )
            FailureLine(failure)
            KButton(
                stringResource(R.string.detail_save_changes),
                onClick = {
                    submitted = true
                    val valid = MemberLogic.isValidName(name) && MemberLogic.isValidEmail(email) && MemberLogic.isValidPhone(phone)
                    if (valid && changes != null) {
                        isBusy = true
                        failure = null
                        scope.launch {
                            val result = model.updateMember(member.id, changes)
                            isBusy = false
                            if (result != null) failure = result else close()
                        }
                    }
                },
                enabled = changes != null, isLoading = isBusy,
            )
            if (TransferLogic.movableShares(currentMember, data).isNotEmpty()) {
                // FR-33: hand a share to someone else from a month onward.
                Row(
                    Modifier.fillMaxWidth().heightIn(min = 48.dp).clip(CircleShape).border(1.5.dp, KColors.brand, CircleShape)
                        .clickable(enabled = !isBusy, role = Role.Button) { transferring = true },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(KSpace.sm, Alignment.CenterHorizontally),
                ) {
                    KIcon(KIcons.swap, tint = KColors.brand, size = 18.dp)
                    KText(stringResource(R.string.detail_transfer_share), KTextToken.bodyStrong, color = KColors.brand)
                }
            }
            KDivider()
            Row(
                Modifier.fillMaxWidth().heightIn(min = 44.dp).clip(RoundedCornerShape(12.dp))
                    .clickable(enabled = block == null && !isBusy, role = Role.Button) { confirmingRemove = true },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(KSpace.sm, Alignment.CenterHorizontally),
            ) {
                val color = if (block == null) KColors.negative else KColors.textTertiary
                KIcon(KIcons.trash, tint = color, size = 18.dp)
                KText(stringResource(R.string.detail_remove_from_kameti), KTextToken.bodyStrong, color = color)
            }
            if (block != null) {
                NoteBanner(blockMessage(block, first), KIcons.warning, KColors.warning, KColors.warningSubtle)
            }
        }

        if (confirmingRemove) {
            val couldnt = stringResource(R.string.detail_couldnt_remove_s, member.name)
            KConfirmSheet(
                title = stringResource(R.string.detail_remove_s, member.name),
                confirmTitle = stringResource(R.string.detail_remove),
                onDismiss = { confirmingRemove = false },
                onConfirm = {
                    val result = model.removeMember(member.id)
                    if (result == null) {
                        // Let the confirm sheet close before this one follows.
                        scope.launch {
                            delay(350)
                            close()
                        }
                    }
                    confirmOutcome(result, couldnt, context)
                },
                message = stringResource(R.string.detail_they_have_no_shares_or_payments_so_nothing),
                isDestructive = true,
            )
        }
    }
    if (reminding) RemindSheet(data.kameti, model.dependencies, onDismiss = { reminding = false }, onlyMemberId = member.id)
    if (transferring) TransferShareSheet(data, model, currentMember) { transferring = false }
}

@Composable
private fun Identity(member: Member, data: KametiDetailData) {
    val slots = DetailLogic.slotCount(member, data.shares)
    val due = data.balances.firstOrNull { it.memberId == member.id }?.monthlyDue
    val slotText = when (slots) {
        0 -> stringResource(R.string.detail_no_slot_yet)
        1 -> stringResource(R.string.detail_1_slot)
        else -> stringResource(R.string.detail_n_slots, slots)
    }
    val status = stringResource(
        when (member.joinStatus) {
            JoinStatus.Joined -> R.string.detail_joined
            JoinStatus.Invited -> R.string.detail_invited
            JoinStatus.PendingApproval -> R.string.detail_needs_approval
            JoinStatus.NotInvited -> R.string.detail_not_invited
            JoinStatus.Declined -> R.string.detail_declined
        },
    )
    val summary = if (due != null && due.isPositive) {
        "$slotText · ${stringResource(R.string.detail_s_mo, due.format())} · $status"
    } else {
        "$slotText · $status"
    }
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically) {
        KAvatar(member.name, DetailLogic.colorIndex(member, data.members))
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(member.name, KTextToken.title)
            KText(summary, KTextToken.subtitleSmall, color = KColors.textSubtitle)
        }
    }
}

@Composable
private fun blockMessage(block: MemberLogic.RemovalBlock, first: String): String {
    val slots = if (block.slots == 1) {
        stringResource(R.string.detail_1_slot_share)
    } else {
        stringResource(R.string.detail_n_slot_shares, block.slots)
    }
    val payments = if (block.payments == 1) {
        stringResource(R.string.detail_1_payment)
    } else {
        stringResource(R.string.detail_n_payments, block.payments)
    }
    return when {
        block.payments == 0 -> stringResource(R.string.detail_s_cant_be_removed_while_holding_s_transfer, first, slots)
        block.slots == 0 -> stringResource(R.string.detail_s_cant_be_removed_s_on_the_ledger, first, payments)
        else -> stringResource(R.string.detail_s_cant_be_removed_they_hold_s_and, first, slots, payments)
    }
}

/** A plain brand-coloured text button under a card's content. */
@Composable
private fun TextAction(title: String, enabled: Boolean = true, onClick: () -> Unit) {
    KText(
        title, KTextToken.bodyStrong,
        modifier = Modifier.fillMaxWidth().heightIn(min = 36.dp).alpha(if (enabled) 1f else 0.5f)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick).padding(vertical = KSpace.sm),
        color = KColors.brand, textAlign = androidx.compose.ui.text.style.TextAlign.Center,
    )
}

/** A compact button inside a card: an optional icon and a short label. */
@Composable
private fun SmallButton(
    title: String,
    icon: ImageVector?,
    foreground: Color,
    background: Color,
    shape: androidx.compose.ui.graphics.Shape = RoundedCornerShape(10.dp),
    modifier: Modifier = Modifier,
    border: Color? = null,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Row(
        modifier.heightIn(min = 36.dp).alpha(if (enabled) 1f else 0.5f).clip(shape).background(background)
            .then(if (border != null) Modifier.border(1.dp, border, shape) else Modifier)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(horizontal = KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
    ) {
        if (icon != null) KIcon(icon, tint = foreground, size = 16.dp)
        KText(title, small, color = foreground, maxLines = 1)
    }
}

/**
 * App access (board AI-1a): invite status, the code and link to share, and
 * Send / Resend / Revoke; Review join when someone is waiting for approval;
 * Remove access once they've joined.
 */
@Composable
private fun AppAccessCard(data: KametiDetailData, model: KametiDetailViewModel, member: Member) {
    val state = AccessState.of(member, data)
    if (state == AccessState.Owner) return
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val sentInvites by model.sentInvites.collectAsStateWithLifecycle()
    val sent = sentInvites[member.id]
    val first = firstName(member.name)
    val strings = rememberStrings()
    val wentWrong = stringResource(R.string.detail_something_went_wrong)
    var busy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var confirmingRevoke by remember { mutableStateOf(false) }
    var confirmingUnlink by remember { mutableStateOf(false) }
    var reviewing by remember { mutableStateOf(false) }
    var copied by remember { mutableStateOf(false) }

    fun run(work: suspend () -> Failure?) {
        busy = true
        failure = null
        scope.launch {
            failure = work()
            busy = false
        }
    }

    @Composable
    fun note(text: String, modifier: Modifier = Modifier) {
        KText(text, KTextToken.bodySm, modifier = modifier, color = KColors.textSecondary)
    }

    @Composable
    fun resend() = SmallButton(
        stringResource(R.string.detail_resend), KIcons.refresh, KColors.textPrimary, KColors.surface,
        border = KColors.border, enabled = !busy,
    ) { run { model.invite(member.id, resend = true) } }

    @Composable
    fun danger(title: String, onClick: () -> Unit) = SmallButton(
        title, null, KColors.negative, Color.Transparent, border = KColors.negative.copy(alpha = 0.35f),
        enabled = !busy, onClick = onClick,
    )

    @Composable
    fun wide(title: String, icon: ImageVector, onClick: () -> Unit) {
        Box(
            Modifier.fillMaxWidth().heightIn(min = 44.dp).clip(RoundedCornerShape(12.dp)).background(KColors.brand)
                .clickable(enabled = !busy, role = Role.Button, onClick = onClick),
            contentAlignment = Alignment.Center,
        ) {
            if (busy) {
                KSpinner(size = 18.dp, color = KColors.textOnBrand)
            } else {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    KIcon(icon, tint = KColors.textOnBrand, size = 18.dp)
                    KText(title, KTextToken.bodyStrong, color = KColors.textOnBrand)
                }
            }
        }
    }

    Column(
        Modifier.fillMaxWidth().border(1.dp, KColors.border, RoundedCornerShape(14.dp)).padding(KSpace.lg),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            KText(stringResource(R.string.detail_app_access), KTextToken.bodyStrong, modifier = Modifier.weight(1f), color = KColors.textSecondary)
            when (state) {
                AccessState.Owner -> Unit
                AccessState.Joined -> KPill(stringResource(R.string.detail_joined), KColors.positive, KColors.positiveSubtle)
                is AccessState.NeedsApproval -> KPill(stringResource(R.string.detail_needs_approval), KColors.info, KColors.infoSubtle)
                is AccessState.Invited ->
                    if (state.invite.deliveryStatus?.didNotArrive == true && sent == null) {
                        KPill(stringResource(R.string.detail_email_bounced), KColors.negative, KColors.negativeSubtle, icon = KIcons.warningFilled)
                    } else {
                        KPill(
                            stringResource(R.string.detail_invited_s, InviteLogic.expiryText(state.invite.expiresAt, model.now)),
                            KColors.warning, KColors.warningSubtle,
                        )
                    }
                is AccessState.NotInvited ->
                    if (state.declined) {
                        KPill(stringResource(R.string.detail_declined), KColors.negative, KColors.negativeSubtle)
                    } else {
                        KPill(stringResource(R.string.detail_not_invited), KColors.textSecondary, KColors.surfaceSunken)
                    }
                is AccessState.Guest ->
                    KPill(stringResource(R.string.detail_without_the_app), KColors.info, KColors.infoSubtle, icon = KIcons.message)
            }
        }
        when (state) {
            AccessState.Owner -> Unit
            AccessState.Joined -> Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                note(stringResource(R.string.detail_s_can_see_this_kameti_in_the_app, first), Modifier.weight(1f))
                if (data.kameti.status != KametiStatus.Archived) {
                    danger(stringResource(R.string.detail_remove_access)) { confirmingUnlink = true }
                }
            }
            is AccessState.NeedsApproval -> {
                note(stringResource(R.string.detail_s_accepted_with_a_different_email_check_its, first))
                wide(stringResource(R.string.detail_review_join), KIcons.personWaiting) { reviewing = true }
            }
            is AccessState.Invited -> {
                val invite = state.invite
                val address = invite.email.orEmpty()
                when {
                    sent != null -> {
                        note(
                            if (sent.emailed) {
                                stringResource(R.string.detail_emailed_to_s_they_can_also_join_with, sent.link.email ?: address)
                            } else {
                                stringResource(R.string.detail_email_isnt_set_up_yet_so_share_the, first)
                            },
                        )
                        Row(
                            Modifier.fillMaxWidth().background(KColors.surfaceSunken, RoundedCornerShape(10.dp))
                                .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            SelectionContainer(Modifier.weight(1f)) {
                                KText(sent.link.code, KTextStyle(size = 22f, weight = FontWeight.Bold, tracking = 4f))
                            }
                            SmallButton(
                                stringResource(if (copied) R.string.detail_copied else R.string.detail_copy_14bc),
                                if (copied) KIcons.check else KIcons.duplicate, KColors.textPrimary, KColors.surface,
                                border = KColors.border,
                            ) {
                                copy(context, sent.link.code)
                                copied = true
                                scope.launch {
                                    delay(1500)
                                    copied = false
                                }
                            }
                        }
                        val text = shareText(data, sent.link)
                        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                            SmallButton(
                                stringResource(R.string.detail_share_link), KIcons.share, KColors.textOnBrand, KColors.brand,
                                modifier = Modifier.weight(1f),
                            ) { share(context, text) }
                            resend()
                            danger(stringResource(R.string.detail_revoke)) { confirmingRevoke = true }
                        }
                    }
                    else -> {
                        // E39b: when the email didn't arrive, a resend gives a new code and link to share by hand.
                        note(
                            stringResource(
                                when {
                                    invite.deliveryStatus?.didNotArrive == true -> R.string.detail_the_invite_email_to_s_didnt_arrive_check
                                    invite.deliveryStatus == com.brixel.kameti.domain.EmailDelivery.Delivered ->
                                        R.string.detail_delivered_to_s_the_code_is_only_shown
                                    else -> R.string.detail_sent_to_s_the_code_is_only_shown
                                },
                                address,
                            ),
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                            resend()
                            danger(stringResource(R.string.detail_revoke)) { confirmingRevoke = true }
                        }
                    }
                }
            }
            is AccessState.NotInvited ->
                if (state.email != null) {
                    note(stringResource(R.string.detail_send_s_an_invite_to_see_this_kameti, first, state.email))
                    wide(stringResource(R.string.detail_send_invite), KIcons.send) { run { model.invite(member.id) } }
                } else {
                    note(stringResource(R.string.detail_add_an_email_above_and_save_then_you, first))
                }
            is AccessState.Guest -> {
                note(
                    stringResource(
                        if (state.phone == null) R.string.detail_s_gets_updates_by_whatsapp_add_a_phone else R.string.detail_s_gets_updates_by_whatsapp,
                        first,
                    ),
                )
                GuestMessageButton(
                    stringResource(R.string.detail_send_update), GuestUpdate.text(strings, member, data), state.phone, prominent = true,
                )
                if (data.kameti.status != KametiStatus.Archived) {
                    TextAction(stringResource(R.string.detail_invite_to_the_app_instead), enabled = !busy) {
                        run { model.setNoApp(member.id, false) }
                    }
                }
            }
        }
        // Someone who won't use the app: stop waiting for them and send updates by WhatsApp instead.
        if (state is AccessState.NotInvited && data.kameti.status != KametiStatus.Archived) {
            TextAction(stringResource(R.string.detail_doesnt_use_the_app), enabled = !busy) { run { model.setNoApp(member.id, true) } }
        }
        FailureLine(failure)
    }

    if (confirmingRevoke) {
        KConfirmSheet(
            title = stringResource(R.string.detail_revoke_s_s_invite, first),
            confirmTitle = stringResource(R.string.detail_revoke),
            onDismiss = { confirmingRevoke = false },
            onConfirm = { confirmOutcome(model.revokeInvite(member.id), wentWrong, context) },
            message = stringResource(R.string.detail_the_link_and_code_stop_working_you_can),
            isDestructive = true,
        )
    }
    if (confirmingUnlink) {
        KConfirmSheet(
            title = stringResource(R.string.detail_remove_s_s_app_access, first),
            confirmTitle = stringResource(R.string.detail_remove_access),
            onDismiss = { confirmingUnlink = false },
            onConfirm = { confirmOutcome(model.unlinkMember(member.id), wentWrong, context) },
            message = stringResource(R.string.detail_s_stops_seeing_this_kameti_in_the_app, first),
            isDestructive = true,
        )
    }
    if (reviewing && state is AccessState.NeedsApproval) {
        ApproveJoinSheet(
            memberName = member.name, invitedEmail = state.invitedEmail, acceptedEmail = state.acceptedEmail,
            approve = { model.approveJoin(member.id) }, reject = { model.declineJoin(member.id) },
            onDismiss = { reviewing = false },
        )
    }
}

@Composable
private fun shareText(data: KametiDetailData, link: InviteLink): String =
    stringResource(R.string.detail_join_s_on_kameti_s_or_open_the, data.kameti.name, link.link, link.code)

private fun copy(context: Context, text: String) {
    context.getSystemService(ClipboardManager::class.java)?.setPrimaryClip(ClipData.newPlainText("Kameti", text))
}

private fun share(context: Context, text: String) {
    val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
    runCatching { context.startActivity(Intent.createChooser(send, null)) }
}
