package com.brixel.kameti.feature.invites

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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.domain.MyInvitation
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSize
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import java.time.Instant

/**
 * An invitation on Home (board AI-1b): who invited me to which kameti,
 * with Decline and Review and join.
 */
@Composable
fun InvitationCard(
    invitation: MyInvitation,
    now: Instant,
    onDecline: () -> Unit,
    onReview: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(KColors.surface, shape)
            .border(2.dp, KColors.brand, shape)
            .padding(KSpace.lg),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).background(KColors.brandSubtle, CircleShape), contentAlignment = Alignment.Center) {
                KText(
                    InviteLogic.initials(invitation.ownerName),
                    KTextStyle(size = 15f, weight = FontWeight.Bold),
                    color = KColors.onBrandSubtle,
                )
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(invitation.kametiName, KTextToken.title)
                KText(
                    stringResource(
                        R.string.invites_s_invited_you_s,
                        invitation.ownerName,
                        InviteLogic.expiryText(invitation.expiresAt, now),
                    ),
                    KTextToken.subtitleSmall,
                    color = KColors.textSubtitle,
                )
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            val capsule = CircleShape
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = KSize.minTouch)
                    .clip(capsule)
                    .border(1.dp, KColors.border, capsule)
                    .clickable(role = Role.Button, onClick = onDecline),
                contentAlignment = Alignment.Center,
            ) {
                KText(stringResource(R.string.invites_decline), KTextToken.bodyStrong)
            }
            Box(
                Modifier
                    .weight(1f)
                    .heightIn(min = KSize.minTouch)
                    .clip(capsule)
                    .background(KColors.brand)
                    .clickable(role = Role.Button, onClick = onReview),
                contentAlignment = Alignment.Center,
            ) {
                KText(stringResource(R.string.invites_review_and_join), KTextToken.bodyStrong, color = KColors.textOnBrand)
            }
        }
    }
}
