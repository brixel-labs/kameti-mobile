package com.brixel.kameti.feature.kametidetail

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.ui.KAvatar
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
        if (progress.needsApproval) R.string.detail_someone_is_waiting_for_your_approval else R.string.detail_invite_them_so_they_can_see_their_payments,
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
    val shape = RoundedCornerShape(if (prominent) 12.dp else 18.dp)
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
        KIcon(KIcons.message, tint = foreground, size = 16.dp)
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
