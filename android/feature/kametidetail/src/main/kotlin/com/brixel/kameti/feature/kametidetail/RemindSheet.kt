package com.brixel.kameti.feature.kametidetail

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.ReminderTargets
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.helpMessage
import com.brixel.kameti.ui.kDismissesKeyboard
import kotlinx.coroutines.launch

/**
 * Owner's "Remind members who owe" (FR-82, FR-84): everyone who owes in one
 * list, each with the one action that suits them: a notification for people
 * with the app (once a day each, with an optional message), WhatsApp for the rest.
 */
@Composable
internal fun RemindSheet(
    kameti: Kameti,
    /** The kameti's people, slots and dues, for each person's row. */
    data: KametiDetailData,
    dependencies: KametiDependencies,
    onDismiss: () -> Unit,
    /** From a member's sheet: just that person. */
    onlyMemberId: String? = null,
) {
    var targets by remember { mutableStateOf<ReminderTargets?>(null) }
    var message by remember { mutableStateOf("") }
    var notifyingId by remember { mutableStateOf<String?>(null) }
    var sentIds by remember { mutableStateOf(emptySet<String>()) }
    var alreadyIds by remember { mutableStateOf(emptySet<String>()) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current

    suspend fun load() {
        failure = null
        try {
            var loaded = dependencies.notifications.reminderTargets(kameti.id)
            if (onlyMemberId != null) loaded = loaded.copy(members = loaded.members.filter { it.memberId == onlyMemberId })
            targets = loaded
        } catch (caught: Failure) {
            failure = caught
        }
    }
    LaunchedEffect(Unit) { load() }

    val members = targets?.members.orEmpty()
    fun isReminded(member: ReminderTargets.Member) = member.remindedToday || member.id in alreadyIds
    val canNotifyAny = members.any { it.hasApp && !isReminded(it) }

    KBottomSheet(
        title = stringResource(R.string.detail_remind_members), onDismiss = onDismiss, expanded = true, dismissDisabled = notifyingId != null,
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
                    if (members.isNotEmpty()) {
                        val template = stringResource(R.string.detail_assalam_o_alaikum_s_a_reminder_that_s)
                        val context = LocalContext.current
                        val uris = LocalUriHandler.current
                        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                            if (onlyMemberId == null) {
                                val total = members.fold(Money.ZERO) { sum, member -> sum + member.owed }
                                KText(
                                    stringResource(R.string.detail_n_owe_s, members.size, total.format()),
                                    KTextToken.body, color = KColors.textSecondary,
                                )
                            }
                            Column {
                                members.forEachIndexed { index, member ->
                                    TargetRow(data, member, last = index == members.size - 1) {
                                        if (member.hasApp) {
                                            when {
                                                member.id in sentIds -> Row(
                                                    horizontalArrangement = Arrangement.spacedBy(KSpace.xs),
                                                    verticalAlignment = Alignment.CenterVertically,
                                                ) {
                                                    KIcon(KIcons.checkCircleFilled, tint = KColors.positive, size = 16.dp)
                                                    KText(stringResource(R.string.detail_sent), KTextToken.caption, color = KColors.positive)
                                                }
                                                isReminded(member) -> KText(
                                                    stringResource(R.string.detail_reminded_today), KTextToken.caption,
                                                    color = KColors.textSecondary,
                                                )
                                                else -> ActionButton(
                                                    icon = KIcons.bell, label = stringResource(R.string.detail_notify),
                                                    color = KColors.brand, isBusy = notifyingId == member.id,
                                                    enabled = notifyingId == null,
                                                ) {
                                                    focus.clearFocus()
                                                    notifyingId = member.id
                                                    failure = null
                                                    val trimmed = message.trim()
                                                    scope.launch {
                                                        try {
                                                            val result = dependencies.notifications.sendReminder(
                                                                kameti.id, trimmed.ifEmpty { null }, listOf(member.id),
                                                            )
                                                            if (result.sent > 0) sentIds = sentIds + member.id else alreadyIds = alreadyIds + member.id
                                                        } catch (caught: Failure) {
                                                            failure = caught
                                                        }
                                                        notifyingId = null
                                                    }
                                                }
                                            }
                                        } else {
                                            val text = ReminderLogic.text(template, member.name, member.owed, kameti.name, loaded.dueDay)
                                            ActionButton(
                                                icon = KIcons.whatsApp, label = stringResource(R.string.detail_whatsapp),
                                                color = KColors.positive,
                                            ) {
                                                val url = ReminderLogic.whatsAppUrl(member.phone, text)
                                                // No WhatsApp (or no phone number): any app that can send text.
                                                if (url == null || runCatching { uris.openUri(url) }.isFailure) share(context, text)
                                            }
                                        }
                                    }
                                }
                            }
                            KText(
                                stringResource(R.string.detail_members_with_the_app_get_a_notification_instead),
                                KTextToken.caption, color = KColors.textSecondary,
                            )
                        }
                    }
                    if (canNotifyAny) {
                        KTextField(
                            message, { message = it },
                            title = stringResource(R.string.detail_notification_message_optional),
                            placeholder = stringResource(
                                R.string.detail_rs_is_due_by_the_s_s, ReminderLogic.ordinal(loaded.dueDay), kameti.name,
                            ),
                            lines = 2,
                        )
                    }
                    if (members.isEmpty()) {
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

/**
 * A list row like the Members tab's (avatar, name, a line under it, a divider),
 * with what they owe under the name and the action on the right.
 */
@Composable
private fun TargetRow(data: KametiDetailData, member: ReminderTargets.Member, last: Boolean, action: @Composable () -> Unit) {
    val person = data.members.firstOrNull { it.id == member.memberId }
    Column {
        Row(
            Modifier.padding(vertical = KSpace.md),
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KAvatar(member.name, person?.let { DetailLogic.colorIndex(it, data.members) } ?: 0, size = KAvatarSize.Medium)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(member.name, KTextToken.bodyStrong)
                KText(stringResource(R.string.detail_owes_s, member.owed.format()), KTextToken.bodySm, color = KColors.warning)
            }
            action()
        }
        if (!last) KDivider()
    }
}

/** A small outlined pill button: Notify (in the app) or WhatsApp. */
@Composable
private fun ActionButton(
    icon: ImageVector,
    label: String,
    color: Color,
    isBusy: Boolean = false,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Box(contentAlignment = Alignment.Center) {
        Row(
            modifier = Modifier
                .heightIn(min = 30.dp)
                .clip(CircleShape)
                .border(1.dp, color.copy(alpha = 0.4f), CircleShape)
                .clickable(enabled = enabled && !isBusy, role = Role.Button, onClick = onClick)
                .padding(horizontal = KSpace.md),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            KIcon(icon, tint = if (isBusy) color.copy(alpha = 0f) else color, size = 15.dp)
            KText(label, KTextStyle(size = 12f, weight = FontWeight.SemiBold), color = if (isBusy) color.copy(alpha = 0f) else color)
        }
        if (isBusy) KSpinner(size = 16.dp, color = color)
    }
}
