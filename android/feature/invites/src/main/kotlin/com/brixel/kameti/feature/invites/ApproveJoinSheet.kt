package com.brixel.kameti.feature.invites

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSize
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.launch

/**
 * Approve a join (board AF-Approve-Join): someone accepted an invite with a
 * different email than the one it was sent to, so the owner checks it's
 * really them. Used from the member sheet and from Inbox. [approve] and
 * [reject] return the failure to show, or `null` when they worked.
 */
@Composable
fun ApproveJoinSheet(
    memberName: String,
    invitedEmail: String?,
    acceptedEmail: String?,
    approve: suspend () -> Failure?,
    reject: suspend () -> Failure?,
    onDismiss: () -> Unit,
) {
    // Which button is working: true = approve, false = reject.
    var busy by remember { mutableStateOf<Boolean?>(null) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val scope = rememberCoroutineScope()
    val firstName = memberName.split(" ").firstOrNull { it.isNotEmpty() } ?: memberName

    KBottomSheet(stringResource(R.string.invites_join_request), onDismiss, dismissDisabled = busy != null) { close ->
        fun run(approving: Boolean) {
            busy = approving
            failure = null
            scope.launch {
                val result = if (approving) approve() else reject()
                busy = null
                if (result != null) failure = result else close()
            }
        }
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState())
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically) {
                KAvatar(memberName, colorIndex = 1)
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    KText(stringResource(R.string.invites_s_wants_to_join, memberName), KTextToken.title)
                    KText(stringResource(R.string.invites_accepted_your_invite), KTextToken.subtitleSmall, color = KColors.textSubtitle)
                }
            }
            Row(
                Modifier.fillMaxWidth().background(KColors.warningSubtle, RoundedCornerShape(12.dp)).padding(KSpace.md),
                horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
            ) {
                KIcon(KIcons.error, tint = KColors.warning, size = 18.dp)
                KText(
                    stringResource(R.string.invites_they_signed_in_with_a_different_email_than, firstName),
                    KTextToken.bodySm, color = KColors.warning,
                )
            }
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                EmailBox(stringResource(R.string.invites_you_invited), invitedEmail)
                EmailBox(stringResource(R.string.invites_signed_in_as), acceptedEmail?.let(InviteLogic::masked))
            }
            KText(
                stringResource(R.string.invites_until_you_approve_they_cant_see_anything_in),
                KTextToken.bodySm, color = KColors.textSecondary,
            )
            failure?.let {
                Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                    KIcon(KIcons.warning, tint = KColors.negative, size = 18.dp)
                    KText(it.userMessage(), KTextToken.bodySm, color = KColors.negative)
                }
            }
            // Reject takes a third of the width, Approve the rest.
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                val shape = RoundedCornerShape(KRadius.button)
                Box(
                    Modifier.weight(1f).height(KSize.buttonHeight).clip(shape)
                        .border(1.dp, KColors.negative.copy(alpha = 0.4f), shape)
                        .clickable(enabled = busy == null, role = Role.Button) { run(false) },
                    contentAlignment = Alignment.Center,
                ) {
                    if (busy == false) {
                        KSpinner(size = 20.dp, color = KColors.negative)
                    } else {
                        KText(stringResource(R.string.invites_reject), KTextToken.bodyStrong, color = KColors.negative)
                    }
                }
                KButton(
                    stringResource(R.string.invites_approve_s, firstName), { run(true) }, Modifier.weight(2f),
                    enabled = busy != false, isLoading = busy == true,
                )
            }
        }
    }
}

@Composable
private fun EmailBox(title: String, email: String?) {
    Column(
        Modifier.fillMaxWidth().background(KColors.surfaceSunken, RoundedCornerShape(12.dp)).padding(KSpace.md),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        KText(title, KTextStyle(size = 12f, weight = FontWeight.SemiBold), color = KColors.textSecondary)
        SelectionContainer { KText(email ?: stringResource(R.string.invites_not_known), KTextToken.bodyStrong) }
    }
}
