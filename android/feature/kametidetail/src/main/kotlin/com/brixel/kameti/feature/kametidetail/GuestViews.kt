package com.brixel.kameti.feature.kametidetail

import android.content.Intent
import androidx.compose.animation.animateContentSize
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.domain.Member
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import kotlinx.coroutines.launch

/**
 * "Waiting for Ali to join" / "3 of 9 haven't joined yet": the prominent card at the top of the
 * owner's Overview while anyone hasn't joined. The whole card opens the Members tab.
 */
@Composable
internal fun SetupCard(progress: SetupProgress, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val only = progress.waiting.singleOrNull()
    val title = if (only != null) {
        stringResource(R.string.detail_waiting_for_s_to_join, only.name)
    } else {
        stringResource(R.string.detail_n_of_n_havent_joined_yet, progress.waiting.size, progress.expected)
    }
    val subtitle = stringResource(
        if (progress.needsApproval) R.string.detail_someone_is_waiting_for_your_approval else R.string.detail_invite_them_to_see_their_payments,
    )
    val shape = RoundedCornerShape(KRadius.card)
    Row(
        modifier
            .fillMaxWidth()
            .clip(shape)
            .background(KColors.warningSubtle)
            .clickable(role = Role.Button, onClick = onClick)
            .semantics(mergeDescendants = true) {}
            .padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(KIcons.personWaiting, tint = KColors.warning, size = 22.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(title, KTextToken.bodyStrong, color = KColors.warning)
            KText(subtitle, KTextToken.bodySm, color = KColors.warning)
        }
        KIcon(KIcons.chevronRight, tint = KColors.warning, size = 18.dp)
    }
}

/**
 * Opens WhatsApp with the message for a member who isn't on the app, or the share sheet when they
 * have no usable phone number (or WhatsApp isn't there).
 */
@Composable
internal fun GuestMessageButton(title: String, text: String, phone: String?, modifier: Modifier = Modifier, prominent: Boolean = false) {
    val context = LocalContext.current
    val uris = LocalUriHandler.current
    val shape = RoundedCornerShape(KRadius.pill)
    val foreground = if (prominent) KColors.textOnBrand else KColors.positive
    Row(
        modifier
            .then(if (prominent) Modifier.fillMaxWidth() else Modifier)
            .heightIn(min = if (prominent) 44.dp else 36.dp)
            .clip(shape)
            .background(if (prominent) KColors.brand else KColors.surface)
            .border(1.dp, if (prominent) KColors.brand else KColors.positive.copy(alpha = 0.4f), shape)
            .clickable(role = Role.Button) {
                val url = ReminderLogic.whatsAppUrl(phone, text)
                // No WhatsApp (or no phone number): any app that can send text.
                if (url == null || runCatching { uris.openUri(url) }.isFailure) {
                    val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
                    runCatching { context.startActivity(Intent.createChooser(send, null)) }
                }
            }
            .padding(horizontal = KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(if (prominent) KIcons.shareArrow else KIcons.message, tint = foreground, size = 16.dp)
        KText(title, KTextStyle(size = if (prominent) 15f else 13f, weight = FontWeight.SemiBold), color = foreground, maxLines = 1)
    }
}

/**
 * Right after a payment for someone who isn't on the app: a receipt ready to send on WhatsApp.
 * One row per person (tap-to-settle can record several), and an easy way out.
 */
@Composable
internal fun ReceiptSheet(data: KametiDetailData, receipts: List<PendingReceipt>, onDismiss: () -> Unit) {
    val strings = rememberStrings()
    val title = stringResource(if (receipts.size == 1) R.string.detail_send_a_receipt else R.string.detail_send_receipts)
    KBottomSheet(title = title, onDismiss = onDismiss) { close ->
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            KText(stringResource(R.string.detail_they_dont_use_the_app_so_send_them), KTextToken.body, color = KColors.textSecondary)
            Column(Modifier.fillMaxWidth().background(KColors.surface, RoundedCornerShape(KRadius.card)).padding(horizontal = KSpace.lg)) {
                receipts.forEachIndexed { index, receipt ->
                    val member = data.members.firstOrNull { it.id == receipt.memberId } ?: return@forEachIndexed
                    Row(
                        Modifier.padding(vertical = KSpace.md),
                        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KAvatar(member.name, DetailLogic.colorIndex(member, data.members))
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            KText(member.name, KTextToken.bodyStrong)
                            KText(receipt.amount.format(), KTextToken.subtitleSmall, color = KColors.textSubtitle)
                        }
                        GuestMessageButton(
                            stringResource(R.string.detail_whatsapp),
                            GuestUpdate.text(strings, member, data, receipt),
                            MemberLogic.contact(member, data)?.phone,
                        )
                    }
                    if (index < receipts.size - 1) KDivider()
                }
            }
            KText(
                stringResource(R.string.detail_not_now), KTextToken.bodyStrong,
                modifier = Modifier.fillMaxWidth().heightIn(min = 44.dp).clickable(role = Role.Button, onClick = close).padding(top = KSpace.sm),
                color = KColors.textSecondary,
            )
        }
    }
}

/** How a quick-send button looks: a tonal capsule in the Guests card, a plain text link under a name in a list. */
internal enum class QuickSendStyle { Tonal, Plain }

/**
 * One tap from a list: makes the guest's view-only link if there is none, then opens WhatsApp (or the
 * share sheet without a phone number) with their update and the link.
 */
@Composable
internal fun GuestQuickSend(
    member: Member,
    data: KametiDetailData,
    model: KametiDetailViewModel,
    modifier: Modifier = Modifier,
    style: QuickSendStyle = QuickSendStyle.Tonal,
) {
    val context = LocalContext.current
    val uris = LocalUriHandler.current
    val scope = rememberCoroutineScope()
    val strings = rememberStrings()
    var busy by remember { mutableStateOf(false) }
    val shape = RoundedCornerShape(KRadius.pill)
    val label = stringResource(R.string.detail_share_an_update_with_s, firstName(member.name))
    Row(
        modifier
            .heightIn(min = 34.dp)
            .clip(shape)
            .background(if (style == QuickSendStyle.Tonal) KColors.positiveSubtle else Color.Transparent)
            .clickable(enabled = !busy, role = Role.Button) {
                busy = true
                scope.launch {
                    val link = model.ensureViewLink(member.id)
                    val text = GuestUpdate.text(strings, member, data, viewLink = link?.link)
                    val url = ReminderLogic.whatsAppUrl(MemberLogic.contact(member, data)?.phone, text)
                    // No WhatsApp (or no phone number): any app that can send text.
                    if (url == null || runCatching { uris.openUri(url) }.isFailure) {
                        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
                        runCatching { context.startActivity(Intent.createChooser(send, null)) }
                    }
                    busy = false
                }
            }
            .semantics { contentDescription = label }
            .alpha(if (busy) 0.5f else 1f)
            .padding(horizontal = if (style == QuickSendStyle.Tonal) KSpace.md else 0.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(KIcons.shareArrow, tint = KColors.positive, size = 16.dp)
        KText(
            stringResource(R.string.detail_share_update), KTextStyle(size = if (style == QuickSendStyle.Tonal) 13f else 14f, weight = FontWeight.SemiBold),
            color = KColors.positive, maxLines = 1,
        )
    }
}

/** "Owes Rs 1,50,000", "Ahead by Rs 25,000" or "All paid up": the guest's standing in one line. */
@Composable
internal fun guestStatusLine(member: Member, data: KametiDetailData): String {
    val balance = data.balances.firstOrNull { it.memberId == member.id } ?: return ""
    return when {
        balance.owes.isPositive -> stringResource(R.string.detail_owes_s, balance.owes.format())
        balance.credit.isPositive -> stringResource(R.string.detail_ahead_by_s, balance.credit.format())
        else -> stringResource(R.string.detail_all_paid_up)
    }
}

/**
 * Overview: the people who don't use the app, each with a one-tap update, so sharing one never means
 * going Members, tap a person, Share update. Two show first (those who owe, most first), then "Show all".
 */
@Composable
internal fun GuestsCard(data: KametiDetailData, model: KametiDetailViewModel) {
    val all = data.members.filter { AccessState.of(it, data) is AccessState.Guest }
    if (all.isEmpty()) return
    fun owes(m: Member) = data.balances.firstOrNull { it.memberId == m.id }?.owes?.rupees ?: 0
    val guests = all.sortedByDescending(::owes)
    val collapsed = 2
    var showsAll by rememberSaveable { mutableStateOf(false) }
    val shown = if (showsAll) guests else guests.take(collapsed)
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        Modifier.fillMaxWidth().clip(shape).background(KColors.surface).border(1.dp, KColors.border, shape).padding(KSpace.lg)
            .animateContentSize(),
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        KText(
            if (guests.size > 1) stringResource(R.string.detail_guests_n, guests.size) else stringResource(R.string.detail_guests),
            KTextToken.bodyStrong,
        )
        KText(stringResource(R.string.detail_they_dont_use_the_app_share_an_update), KTextToken.bodySm, color = KColors.textSecondary)
        shown.forEachIndexed { index, member ->
            Row(
                Modifier.fillMaxWidth().padding(vertical = KSpace.sm),
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KAvatar(member.name, DetailLogic.colorIndex(member, data.members), size = KAvatarSize.Medium)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    KText(member.name, KTextToken.bodyStrong, maxLines = 1)
                    KText(guestStatusLine(member, data), KTextToken.subtitleSmall, color = KColors.textSubtitle, maxLines = 1)
                }
                GuestQuickSend(member, data, model)
            }
            if (index < shown.size - 1 || guests.size > collapsed) KDivider()
        }
        if (guests.size > collapsed) {
            Row(
                Modifier.fillMaxWidth().heightIn(min = 40.dp).clickable(role = Role.Button) { showsAll = !showsAll },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KText(
                    if (showsAll) stringResource(R.string.detail_show_fewer) else stringResource(R.string.detail_show_all_n_guests, guests.size),
                    KTextToken.bodyStrong, color = KColors.brand, modifier = Modifier.weight(1f),
                )
                KIcon(if (showsAll) KIcons.chevronUp else KIcons.chevronDown, tint = KColors.brand, size = 18.dp)
            }
        }
    }
}
