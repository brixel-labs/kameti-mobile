package com.brixel.kameti.feature.kametidetail

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.ReminderResult
import com.brixel.kameti.domain.ReminderTargets
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.kDismissesKeyboard
import kotlinx.coroutines.launch

/**
 * Owner's "Remind members who owe" (FR-82): a push to everyone with the app,
 * once a day, with an optional message; WhatsApp for the rest (FR-84).
 */
@Composable
internal fun RemindSheet(
    kameti: Kameti,
    dependencies: KametiDependencies,
    onDismiss: () -> Unit,
    /** From a member's sheet: just that person. */
    onlyMemberId: String? = null,
) {
    var targets by remember { mutableStateOf<ReminderTargets?>(null) }
    var selected by remember { mutableStateOf(emptySet<String>()) }
    var message by remember { mutableStateOf("") }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var sent by remember { mutableStateOf<ReminderResult?>(null) }
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current

    suspend fun load() {
        failure = null
        try {
            var loaded = dependencies.notifications.reminderTargets(kameti.id)
            if (onlyMemberId != null) loaded = loaded.copy(members = loaded.members.filter { it.memberId == onlyMemberId })
            targets = loaded
            selected = loaded.members.filter { it.hasApp && !it.remindedToday }.map { it.id }.toSet()
        } catch (caught: Failure) {
            failure = caught
        }
    }
    LaunchedEffect(Unit) { load() }

    val withApp = targets?.members?.filter { it.hasApp }.orEmpty()
    val withoutApp = targets?.members?.filter { !it.hasApp }.orEmpty()

    KBottomSheet(
        title = stringResource(R.string.detail_remind_members), onDismiss = onDismiss, expanded = true, dismissDisabled = isBusy,
    ) {
        Column(
            Modifier
                .weight(1f, fill = false)
                .verticalScroll(rememberScrollState())
                .kDismissesKeyboard()
                .padding(horizontal = KSpace.xl)
                .padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            val loaded = targets
            when {
                loaded != null -> {
                    val result = sent
                    if (result != null) {
                        Column(verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                                KIcon(KIcons.checkCircleFilled, tint = KColors.positive)
                                KText(
                                    if (result.sent == 1) {
                                        stringResource(R.string.detail_reminder_sent_to_1_member)
                                    } else {
                                        stringResource(R.string.detail_reminder_sent_to_n_members, result.sent)
                                    },
                                    KTextToken.bodyStrong,
                                    color = KColors.positive,
                                )
                            }
                            if (result.skipped.isNotEmpty()) {
                                KText(
                                    stringResource(R.string.detail_s_already_had_a_reminder_today, result.skipped.joinToString(", ")),
                                    KTextToken.bodySm,
                                    color = KColors.textSecondary,
                                )
                            }
                        }
                    } else if (withApp.isNotEmpty() && withApp.all { it.remindedToday }) {
                        NoteBanner(
                            stringResource(R.string.detail_youve_already_reminded_everyone_here_today_you_can),
                            KIcons.info, KColors.info, KColors.infoSubtle,
                        )
                    }

                    if (withApp.isNotEmpty()) {
                        val canSend = sent == null && withApp.any { !it.remindedToday }
                        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                            FieldLabel(stringResource(R.string.detail_in_the_app_they_get_a_notification))
                            Group {
                                withApp.forEachIndexed { index, member ->
                                    val enabled = canSend && !member.remindedToday
                                    TargetRow(
                                        member, last = index == withApp.size - 1,
                                        onClick = if (enabled) {
                                            { selected = if (member.id in selected) selected - member.id else selected + member.id }
                                        } else {
                                            null
                                        },
                                    ) {
                                        if (member.remindedToday) {
                                            KText(
                                                stringResource(R.string.detail_reminded_today), KTextToken.caption,
                                                color = KColors.textSecondary,
                                            )
                                        } else {
                                            val isOn = member.id in selected
                                            KIcon(
                                                if (isOn) KIcons.checkCircleFilled else KIcons.circle,
                                                tint = if (isOn) KColors.brand else KColors.borderStrong,
                                                size = 24.dp,
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        if (canSend) {
                            KTextField(
                                message, { message = it },
                                title = stringResource(R.string.detail_message_optional),
                                placeholder = stringResource(
                                    R.string.detail_rs_is_due_by_the_s_s, ReminderLogic.ordinal(loaded.dueDay), kameti.name,
                                ),
                                helper = stringResource(R.string.detail_each_person_sees_what_they_owe_unless_you),
                                lines = 2,
                            )
                            KButton(
                                if (selected.size == 1) {
                                    stringResource(R.string.detail_send_reminder_to_1)
                                } else {
                                    stringResource(R.string.detail_send_reminder_to_n, selected.size)
                                },
                                onClick = {
                                    focus.clearFocus()
                                    isBusy = true
                                    failure = null
                                    val trimmed = message.trim()
                                    val all = withApp.filter { !it.remindedToday }.map { it.id }.toSet()
                                    scope.launch {
                                        try {
                                            sent = dependencies.notifications.sendReminder(
                                                kameti.id, trimmed.ifEmpty { null }, if (selected == all) null else selected.toList(),
                                            )
                                        } catch (caught: Failure) {
                                            failure = caught
                                        }
                                        isBusy = false
                                    }
                                },
                                enabled = selected.isNotEmpty(),
                                isLoading = isBusy,
                            )
                        }
                    }

                    if (withoutApp.isNotEmpty()) {
                        val template = stringResource(R.string.detail_hi_s_a_reminder_that_s_for_s)
                        val context = LocalContext.current
                        val uris = LocalUriHandler.current
                        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                            FieldLabel(stringResource(R.string.detail_without_the_app_remind_on_whatsapp))
                            Group {
                                withoutApp.forEachIndexed { index, member ->
                                    val text = ReminderLogic.text(template, member.name, member.owed, kameti.name, loaded.dueDay)
                                    TargetRow(member, last = index == withoutApp.size - 1, onClick = null) {
                                        WhatsAppButton {
                                            val url = ReminderLogic.whatsAppUrl(member.phone, text)
                                            // No WhatsApp (or no phone number): any app that can send text.
                                            if (url == null || runCatching { uris.openUri(url) }.isFailure) share(context, text)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (loaded.members.isEmpty()) {
                        KMessageCard(
                            title = stringResource(
                                if (onlyMemberId == null) R.string.detail_nobody_owes_right_now else R.string.detail_nothing_owed_right_now,
                            ),
                            icon = KIcons.verified,
                        )
                    }
                    FailureLine(failure)
                }
                failure != null -> KMessageCard(
                    title = stringResource(R.string.detail_couldnt_load_who_owes),
                    message = failure?.helpMessage(),
                    actionTitle = stringResource(R.string.detail_try_again),
                    action = { scope.launch { load() } },
                )
                else -> KSkeletonRows(rows = 3)
            }
        }
    }
}

private fun share(context: Context, text: String) {
    val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
    runCatching { context.startActivity(Intent.createChooser(send, null)) }
}

/** The white rounded box around a list of people. */
@Composable
private fun Group(content: @Composable () -> Unit) {
    Column(Modifier.fillMaxWidth().background(KColors.surface, RoundedCornerShape(16.dp)).padding(horizontal = KSpace.lg)) {
        content()
    }
}

@Composable
private fun TargetRow(member: ReminderTargets.Member, last: Boolean, onClick: (() -> Unit)?, trailing: @Composable () -> Unit) {
    Column(if (onClick != null) Modifier.clickable(role = Role.Checkbox, onClick = onClick) else Modifier) {
        Row(
            Modifier.padding(vertical = KSpace.md),
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(member.name, KTextToken.bodyStrong)
                KText(stringResource(R.string.detail_owes_s, member.owed.format()), KTextToken.bodySm, color = KColors.warning)
            }
            trailing()
        }
        if (!last) KDivider()
    }
}

@Composable
private fun WhatsAppButton(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .heightIn(min = 36.dp)
            .clip(CircleShape)
            .border(1.dp, KColors.positive.copy(alpha = 0.4f), CircleShape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(KIcons.message, tint = KColors.positive, size = 16.dp)
        KText(stringResource(R.string.detail_whatsapp), KTextStyle(size = 13f, weight = FontWeight.SemiBold), color = KColors.positive)
    }
}
