package com.brixel.kameti.feature.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.feature.kametidetail.DetailLogic
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KAvatarStack
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KPaidOutStrip
import com.brixel.kameti.ui.KPaymentStatus
import com.brixel.kameti.ui.KPerson
import com.brixel.kameti.ui.KPill
import com.brixel.kameti.ui.KPotHeadline
import com.brixel.kameti.ui.KPotProgress
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSize
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KStatusChip
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import java.time.LocalDate

/** "You" for the signed-in user, their name for everyone else. */
@Composable
private fun HomeKametiSummary.Person.shownName(): String =
    if (isMe) stringResource(R.string.home_android_you) else name

@Composable
private fun List<HomeKametiSummary.Person>.asKPeople(): List<KPerson> = map { KPerson(it.shownName(), it.colorIndex) }

@Composable
private fun memberCountText(count: Int): String =
    if (count == 1) stringResource(R.string.home_1_member) else stringResource(R.string.home_n_members, count)

/**
 * A kameti on Home (FR-2, board A · Home): name, role, month, this month's
 * pot and recipients, or for a kameti I'm a member of, what I owe and my
 * turn. The whole card opens the kameti; the people row opens the members
 * sheet.
 */
@Composable
internal fun HomeKametiCard(item: HomeKametiSummary, currentMonth: LocalDate, onLongClick: (() -> Unit)? = null, onClick: () -> Unit) {
    KCard(onClick = onClick, onLongClick = onLongClick) {
        if (HomeViewModel.isPast(item.kameti.status)) {
            PastBody(item)
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
                Row(verticalAlignment = Alignment.Top) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
                        KText(item.kameti.name, KTextToken.titleLg)
                        KText(subtitle(item), KTextToken.body, color = KColors.textSecondary)
                    }
                    Spacer(Modifier.width(KSpace.sm))
                    RolePill(item)
                }
                if (item.isOwner) OwnerBody(item) else MemberBody(item, currentMonth)
                PeopleRow(item)
            }
        }
    }
}

@Composable
private fun subtitle(item: HomeKametiSummary): String {
    val month = item.currentMonth ?: return stringResource(R.string.home_not_started_yet)
    return stringResource(
        R.string.home_month_n_of_n_s,
        month.monthIndex,
        item.kameti.monthsN,
        DetailLogic.monthName(month.monthStart),
    )
}

@Composable
private fun RolePill(item: HomeKametiSummary) {
    when {
        item.isOwner && item.currentMonth?.state == MonthCollectionState.PaidOutShort ->
            KPill(stringResource(R.string.home_paid_out_short), KColors.warning, KColors.warningSubtle)
        item.isOwner && item.isPaidOut ->
            KPill(stringResource(R.string.home_paid_out), KColors.positive, KColors.positiveSubtle)
        item.isOwner -> KPill(stringResource(R.string.home_owner), KColors.onBrandSubtle, KColors.brandSubtle)
        else -> KPill(stringResource(R.string.home_view_only), KColors.textSecondary, KColors.surfaceSunken)
    }
}

// People

/**
 * Everyone in it: up to five faces in turn order, "+N" for the rest, and the
 * count. Its own tap: the members sheet.
 */
@Composable
private fun PeopleRow(item: HomeKametiSummary) {
    if (item.people.isEmpty()) return
    var showsPeople by remember { mutableStateOf(false) }
    val countText = memberCountText(item.people.size)
    val hint = stringResource(R.string.home_shows_everyone_in_this_kameti)
    KDivider()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = KSize.minTouch)
            .clickable(role = Role.Button, onClickLabel = hint) { showsPeople = true },
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KAvatarStack(item.people.asKPeople(), limit = 5, showsOverflow = true, size = KAvatarSize.Small)
        KText(countText, KTextToken.bodyStrong, modifier = Modifier.weight(1f), color = KColors.brand)
        KIcon(KIcons.chevronRight, size = 18.dp)
    }
    if (showsPeople) {
        KBottomSheet(title = stringResource(R.string.home_members), onDismiss = { showsPeople = false }) {
            HomeMembersSheet(item, countText)
        }
    }
}

/**
 * Everyone in a kameti, in turn order (tapped from a card's avatar row):
 * face, name, turn month(s) and payout; "This month" on the current recipients.
 */
@Composable
private fun HomeMembersSheet(item: HomeKametiSummary, countText: String) {
    Column(
        Modifier
            .verticalScroll(rememberScrollState())
            .padding(horizontal = KSpace.xl)
            .padding(bottom = KSpace.xl),
    ) {
        KText(
            stringResource(R.string.home_s_s, item.kameti.name, countText),
            KTextToken.body,
            modifier = Modifier.padding(bottom = KSpace.sm),
            color = KColors.textSecondary,
        )
        item.people.forEachIndexed { index, person ->
            if (index > 0) KDivider()
            Row(
                modifier = Modifier.padding(vertical = KSpace.md).semantics(mergeDescendants = true) {},
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KAvatar(person.shownName(), person.colorIndex, size = KAvatarSize.Medium)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    KText(person.shownName(), KTextToken.bodyStrong)
                    KText(turnsText(person), KTextToken.bodySm, color = KColors.textSecondary)
                }
                if (person.isThisMonth) {
                    KPill(stringResource(R.string.home_this_month_fef3), KColors.textOnBrand, KColors.brand)
                }
            }
        }
    }
}

@Composable
private fun turnsText(person: HomeKametiSummary.Person): String {
    if (person.turns.isEmpty()) return stringResource(R.string.home_no_share_yet)
    val months = person.turns.joinToString(" + ") { DetailLogic.monthTitle(it) }
    return stringResource(R.string.home_s_s, months, person.payout.format())
}

// Owner

@Composable
private fun OwnerBody(item: HomeKametiSummary) {
    val month = item.currentMonth
    if (month != null) {
        KPotProgress(
            collected = month.received,
            target = month.target,
            caption = stringResource(R.string.home_n_of_n_paid, month.paidCount, month.memberCount),
            trailingCaption = item.dueDate?.let { stringResource(R.string.home_due_by_s, DetailLogic.dayMonth(it)) },
            headline = KPotHeadline.OfTarget,
        )
    }
    if (month != null && item.isPaidOut) {
        PaidOutStrip(item, month)
    } else if (item.recipients.isNotEmpty()) {
        KDivider()
        val names = item.recipients.map { it.shownName() }.joinToString(" + ")
        val label = stringResource(R.string.home_this_month_68f9)
        val secondary = KColors.textSecondary
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically) {
            KAvatarStack(item.recipients.asKPeople())
            KText(
                buildAnnotatedString {
                    withStyle(SpanStyle(color = secondary)) { append(label) }
                    withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(names) }
                },
                KTextToken.body,
            )
        }
    }
}

/** After a payout: a green strip (amber when short) with who was paid, how much and when. */
@Composable
private fun PaidOutStrip(item: HomeKametiSummary, month: MonthCollectionRow) {
    val short = month.state == MonthCollectionState.PaidOutShort && month.paidOutShortBy.isPositive
    val people = item.recipients.map { it.shownName() }.joinToString(" + ")
    KPaidOutStrip(
        people = item.recipients.asKPeople(),
        title = if (short) {
            stringResource(R.string.home_paid_out_s_short_s, month.paidOut.format(), month.paidOutShortBy.format())
        } else {
            stringResource(R.string.home_paid_out_s, month.paidOut.format())
        },
        subtitle = item.payoutDate?.let { stringResource(R.string.home_s_s, people, DetailLogic.dayMonth(it)) } ?: people,
        isShort = short,
    )
}

// Member

@Composable
private fun MemberBody(item: HomeKametiSummary, currentMonth: LocalDate) {
    val kameti = item.kameti
    // Before its first month nothing is due yet, so it isn't "paid up".
    val startsLater = item.currentMonth == null && kameti.status == KametiStatus.Active && kameti.startMonth > currentMonth
    val first = item.monthlyDue
    val owes = item.owes
    when {
        // Back in setup ("Edit setup"): nothing is due until it starts again.
        kameti.status == KametiStatus.Draft ->
            KPill(stringResource(R.string.home_being_updated_by_the_owner), KColors.info, KColors.infoSubtle)
        startsLater && first != null && first.isPositive -> NoticeRow(
            icon = KIcons.calendar,
            text = stringResource(R.string.home_first_due_s, first.format()),
            trailing = stringResource(R.string.home_by_s, DetailLogic.dayMonth(DetailLogic.dueDate(kameti, 1))),
            foreground = KColors.info,
            background = KColors.infoSubtle,
        )
        owes != null && owes.isPositive -> NoticeRow(
            icon = KIcons.clock,
            text = stringResource(R.string.home_you_owe_s, owes.format()),
            trailing = item.dueDate?.let { stringResource(R.string.home_due_s, DetailLogic.dayMonth(it)) },
            foreground = KColors.warning,
            background = KColors.warningSubtle,
        )
        // Owing nothing because there's no share yet isn't "paid up".
        owes != null && first != null && !first.isPositive ->
            KPill(stringResource(R.string.home_no_share_yet), KColors.textSecondary, KColors.surfaceSunken)
        owes != null -> KStatusChip(KPaymentStatus.Paid, stringResource(R.string.home_paid_up))
    }
    val turn = item.nextTurn
    if (kameti.status != KametiStatus.Draft && turn != null) {
        val label = stringResource(R.string.home_your_turn)
        val amount = stringResource(R.string.home_s, turn.payout.format())
        val secondary = KColors.textSecondary
        KText(
            buildAnnotatedString {
                withStyle(SpanStyle(color = secondary)) { append(label) }
                withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(DetailLogic.monthTitle(turn.month)) }
                withStyle(SpanStyle(color = secondary)) { append(amount) }
            },
            KTextToken.body,
        )
    }
}

/** A tinted row: an icon and what it says on the left, a date on the right. */
@Composable
private fun NoticeRow(icon: ImageVector, text: String, trailing: String?, foreground: Color, background: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(background, RoundedCornerShape(KRadius.input))
            .padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(icon, tint = foreground, size = 18.dp)
        KText(text, KTextToken.bodyStrong, modifier = Modifier.weight(1f), color = foreground)
        if (trailing != null) KText(trailing, KTextToken.body, color = foreground)
    }
}

// Past

@Composable
private fun PastBody(item: HomeKametiSummary) {
    val kameti = item.kameti
    val status = when (kameti.status) {
        KametiStatus.Completed -> stringResource(R.string.home_completed)
        KametiStatus.Archived -> stringResource(R.string.home_archived)
        KametiStatus.Cancelled -> stringResource(R.string.home_cancelled)
        KametiStatus.Draft, KametiStatus.Active -> ""
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
            KText(kameti.name, KTextToken.titleLg)
            KText(
                stringResource(
                    R.string.home_s_s,
                    status,
                    DetailLogic.monthTitle(DetailLogic.monthStart(kameti, kameti.monthsN)),
                ),
                KTextToken.body,
                color = KColors.textSecondary,
            )
        }
        if (kameti.status == KametiStatus.Completed) {
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.xs), verticalAlignment = Alignment.CenterVertically) {
                KIcon(KIcons.check, tint = KColors.positive, size = 18.dp)
                KText(stringResource(R.string.home_settled), KTextToken.bodyStrong, color = KColors.positive)
            }
        }
    }
}
