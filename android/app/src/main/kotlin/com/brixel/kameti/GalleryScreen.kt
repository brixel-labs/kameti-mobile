package com.brixel.kameti

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.ui.KAmountField
import com.brixel.kameti.ui.KAppearance
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KAvatarStack
import com.brixel.kameti.ui.KBalancePill
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KButtonStyle
import com.brixel.kameti.ui.KCalendarPicker
import com.brixel.kameti.ui.KCard
import com.brixel.kameti.ui.KCheckbox
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KCompactStepper
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDayTile
import com.brixel.kameti.ui.KEmptyIllustration
import com.brixel.kameti.ui.KFailureSheet
import com.brixel.kameti.ui.KFieldButton
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KGoogleLogo
import com.brixel.kameti.ui.KGripHandle
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KMoneyStyle
import com.brixel.kameti.ui.KMoneyText
import com.brixel.kameti.ui.KMonthField
import com.brixel.kameti.ui.KOfflineActionBanner
import com.brixel.kameti.ui.KOfflineBanner
import com.brixel.kameti.ui.KOption
import com.brixel.kameti.ui.KPaidOutStrip
import com.brixel.kameti.ui.KPaymentStatus
import com.brixel.kameti.ui.KPerson
import com.brixel.kameti.ui.KPotProgress
import com.brixel.kameti.ui.KReorderList
import com.brixel.kameti.ui.KSectionHeader
import com.brixel.kameti.ui.KSegmented
import com.brixel.kameti.ui.KSelectField
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KStatusChip
import com.brixel.kameti.ui.KStepper
import com.brixel.kameti.ui.KSwipeAction
import com.brixel.kameti.ui.KSwipeRow
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KToggle
import com.brixel.kameti.ui.KTonalButton
import com.brixel.kameti.ui.KTonalStyle
import com.brixel.kameti.ui.KUnderlineTabs
import com.brixel.kameti.ui.kDismissesKeyboard
import kotlinx.coroutines.delay

/**
 * Temporary first screen: every design-system component on one page, in
 * light or dark, to compare with the iOS app. Its text is not localised
 * because it never ships; sign-in and the tabs replace it.
 */
@Composable
fun GalleryScreen(appearance: KAppearance, onAppearance: (KAppearance) -> Unit) {
    val people = listOf(KPerson("Ali Raza", 0), KPerson("Sara Khan", 1), KPerson("Naveed Ahmed", 2), KPerson("Hira Malik", 3))
    var tab by rememberSaveable { mutableStateOf("Components") }
    Column(Modifier.fillMaxSize().background(KColors.background).safeDrawingPadding().kDismissesKeyboard()) {
        Column(Modifier.padding(horizontal = KSpace.gutter).padding(top = KSpace.md), verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            KText("Design system", KTextToken.titleLg)
            KSegmented(KAppearance.entries.map { KOption(it, stringResource(it.titleRes)) }, appearance, onAppearance)
        }
        KUnderlineTabs(
            listOf("Components", "Inputs", "Sheets", "Lists").map { KOption(it, it) }, tab, { tab = it }, inset = KSpace.gutter,
        )
        if (tab == "Lists") {
            ListsPage(people)
        } else {
            Column(
                Modifier.verticalScroll(rememberScrollState()).padding(KSpace.gutter),
                verticalArrangement = Arrangement.spacedBy(KSpace.lg),
            ) {
                when (tab) {
                    "Components" -> ComponentsPage(people)
                    "Inputs" -> InputsPage()
                    else -> SheetsPage(people)
                }
                Spacer(Modifier.height(KSpace.xxl))
            }
        }
    }
}

@Composable
private fun ComponentsPage(people: List<KPerson>) {
    KSectionHeader("This month", actionTitle = "See all", showsChevron = true) {}
    KCard(onClick = {}) {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                KAvatarStack(people, showsOverflow = true)
                Column(Modifier.weight(1f)) {
                    KText("Family kameti", KTextToken.title)
                    KText("Month 2 of 6 · due on the 10th", KTextToken.bodySm, color = KColors.textSecondary)
                }
                KBalancePill(Money(250_000))
            }
            KPotProgress(Money(1_000_000), Money(1_500_000), marked = Money(250_000), caption = "3 of 6 paid", trailingCaption = "Due 10 Nov")
        }
    }
    KPaidOutStrip(people.take(2), "Paid out Rs 15,00,000", "To Ali Raza and Sara Khan · 12 Oct")
    KPaidOutStrip(people.take(1), "Paid out Rs 14,70,000", "Short by Rs 30,000 · 12 Oct", isShort = true)

    KSectionHeader("Status")
    KFlowRow {
        KStatusChip(KPaymentStatus.Paid, "Paid")
        KStatusChip(KPaymentStatus.Partial, "Partial")
        KStatusChip(KPaymentStatus.Unpaid, "Unpaid")
        KStatusChip(KPaymentStatus.Overdue, "Overdue")
        KStatusChip(KPaymentStatus.Credit, "Advance")
        KStatusChip(KPaymentStatus.Upcoming, "Upcoming")
        KBalancePill(Money.ZERO)
        KBalancePill(Money(-125_000))
    }

    KSectionHeader("Money and text")
    KCard {
        Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            KMoneyText(Money(5_000_000), style = KMoneyStyle.DisplayLg)
            KMoneyText(Money(2_500_000), style = KMoneyStyle.Title)
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.lg)) {
                KMoneyText(Money(125_000))
                KMoneyText(Money(125_000), compact = true)
                KMoneyText(Money(24_000_000), compact = true)
            }
            KText("Title large", KTextToken.titleLg)
            KText("Title", KTextToken.title)
            KText("Body text for a sentence or two.", KTextToken.body)
            KText("Small body", KTextToken.bodySm, color = KColors.textSecondary)
            KText("LABEL", KTextToken.label, color = KColors.textTertiary)
        }
    }

    KSectionHeader("Avatars")
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        KAvatar("Ali Raza", 0, size = KAvatarSize.Small)
        KAvatar("Sara Khan", 1)
        KAvatar("Hassan", 4, size = KAvatarSize.Large)
        KAvatarStack(people.take(2), showsCheck = true)
        KGripHandle()
        KGoogleLogo()
    }

    KSectionHeader("Buttons")
    KButton("Record payment", {}, icon = KIcons.plus)
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        KButton("Cancel", {}, Modifier.weight(1f), style = KButtonStyle.Secondary)
        KButton("Void", {}, Modifier.weight(1f), style = KButtonStyle.Destructive)
    }
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        KButton("Saving", {}, Modifier.weight(1f), isLoading = true)
        KButton("Disabled", {}, Modifier.weight(1f), enabled = false)
    }
    KButton("Continue with Google", {}, style = KButtonStyle.Secondary, leading = { KGoogleLogo() })
    KFlowRow {
        KTonalButton("Remind", {}, icon = KIcons.bell)
        KTonalButton("Share link", {}, icon = KIcons.share, style = KTonalStyle.Neutral)
    }

    KSectionHeader("States")
    KOfflineBanner(since = null)
    KOfflineActionBanner("Can't record payments offline. Connect and try again.")
    KSkeletonRows(rows = 2)
    KMessageCard("Couldn't load this kameti", message = "Check your connection and try again.", icon = KIcons.cloudProblem, actionTitle = "Try again") {}
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) { KEmptyIllustration() }
}

@Composable
private fun InputsPage() {
    var name by rememberSaveable { mutableStateOf("") }
    var note by rememberSaveable { mutableStateOf("") }
    var digits by rememberSaveable { mutableStateOf("250000") }
    var months by rememberSaveable { mutableIntStateOf(6) }
    var slots by rememberSaveable { mutableIntStateOf(4) }
    var dueDay by rememberSaveable { mutableIntStateOf(10) }
    var method by rememberSaveable { mutableStateOf("Cash") }
    var remind by rememberSaveable { mutableStateOf(true) }
    var agree by rememberSaveable { mutableStateOf(false) }
    var day by rememberSaveable { mutableIntStateOf(5) }
    var startMonth by remember { mutableStateOf(DateOnly.make(2026, 12)) }

    KTextField(name, { name = it }, title = "Kameti name", placeholder = "e.g. Family kameti", helper = "3 to 40 characters")
    KAmountField("Slot amount", digits, { digits = it }, helper = "Each month's pot is this times the months")
    KAmountField("With an error", "", {}, error = "Enter an amount above zero.")
    KTextField(note, { note = it }, title = "Note", placeholder = "Add a note", lines = 3)
    KMonthField("Start month", startMonth, (0..17).map { DateOnly.make(2026, 12).plusMonths(it.toLong()) }, { startMonth = it }, runLength = months)
    KSelectField("Due day", dueDay, (1..28).map { KOption(it, "Day $it") }, { dueDay = it }, sheetTitle = "Due day of the month")
    KText("Months", KTextToken.bodyStrong, color = KColors.textSecondary)
    KStepper(months, 2..24, "Fewer months", "More months", { months = it })
    Row(verticalAlignment = Alignment.CenterVertically) {
        KText("Slots per member", KTextToken.body, modifier = Modifier.weight(1f))
        KCompactStepper(slots, 1..6, "Fewer slots", "More slots", { slots = it })
    }
    KSegmented(listOf("Cash", "Bank", "Other").map { KOption(it, it) }, method, { method = it })
    KFlowRow {
        listOf(1, 5, 10, 15).forEach { KChip("Day $it", isOn = day == it, onClick = { day = it }) }
        KChip("Outlined", isOn = true, onClick = {}, style = KChipStyle.Outlined, icon = KIcons.check)
    }
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        (1..5).forEach { KDayTile("$it", isOn = day == it, onClick = { day = it }, modifier = Modifier.weight(1f)) }
    }
    KToggle(remind, { remind = it }) {
        Column {
            KText("Remind members", KTextToken.body)
            KText("On the due day and after", KTextToken.bodySm, color = KColors.textSecondary)
        }
    }
    KCheckbox(agree, { agree = it }) { KText("Email invites when the kameti starts", KTextToken.body) }
}

@Composable
private fun SheetsPage(people: List<KPerson>) {
    var sheet by remember { mutableStateOf("") }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var message by remember { mutableStateOf<KSheetMessage?>(null) }
    var date by remember { mutableStateOf(DateOnly.make(2026, 11, 10)) }

    KButton("Confirm sheet", { sheet = "confirm" }, style = KButtonStyle.Secondary)
    KButton("Destructive confirm with details", { sheet = "void" }, style = KButtonStyle.Secondary)
    KButton("Message sheet", { message = KSheetMessage("Payment recorded", "Rs 2,50,000 from Ali Raza.", KSheetMessage.Tone.Success) }, style = KButtonStyle.Secondary)
    KButton("Failure sheet", { failure = Failure.Server("kameti_not_ready") }, style = KButtonStyle.Secondary)
    KFieldButton("${date.dayOfMonth} ${date.month.name.lowercase().replaceFirstChar { it.uppercase() }} ${date.year}", { sheet = "calendar" }, title = "Received on")

    if (sheet == "confirm") {
        KConfirmSheet(
            title = "Start this kameti?", confirmTitle = "Start", onDismiss = { sheet = "" },
            message = "Members will see it, and the slot amounts can't change after the first month.",
            onConfirm = {
                delay(1200)
                KConfirmOutcome.Result(KSheetMessage("Kameti started", "Everyone can see it now.", KSheetMessage.Tone.Success))
            },
        )
    }
    if (sheet == "void") {
        KConfirmSheet(
            title = "Remove these members?", confirmTitle = "Remove", onDismiss = { sheet = "" }, isDestructive = true,
            message = "They leave the kameti. This can't be undone.",
            details = {
                Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    people.take(2).forEach {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                            KAvatar(it.name, it.colorIndex)
                            KText(it.name, KTextToken.body)
                        }
                    }
                }
            },
            onConfirm = { delay(1200); KConfirmOutcome.Dismiss },
        )
    }
    if (sheet == "calendar") {
        KBottomSheet("Received on", onDismiss = { sheet = "" }) { close ->
            KCalendarPicker(date, DateOnly.make(2026, 9, 15)..DateOnly.make(2026, 11, 10), onPick = { date = it; close() })
        }
    }
    KMessageSheet(message) { message = null }
    KFailureSheet(failure, title = "Couldn't start the kameti", onDismiss = { failure = null })
}

@Composable
private fun KMessageSheet(message: KSheetMessage?, onDismiss: () -> Unit) = com.brixel.kameti.ui.KMessageSheet(message, onDismiss)

@Composable
private fun ListsPage(people: List<KPerson>) {
    var ids by remember { mutableStateOf(listOf("Ali Raza", "Sara Khan", "Naveed Ahmed", "Osama Sheikh", "Hira Malik")) }
    var openRow by remember { mutableStateOf<String?>(null) }
    Column {
        Column(Modifier.padding(horizontal = KSpace.gutter).padding(top = KSpace.lg), verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
            KText("Swipe a note left for its actions", KTextToken.bodySm, color = KColors.textSecondary)
            listOf("Payments by the 10th please.", "Ali pays November when he's back.").forEachIndexed { index, text ->
                KSwipeRow(
                    id = "note$index", openRow = openRow, onOpenRowChange = { openRow = it },
                    actions = listOf(
                        KSwipeAction("Edit", KIcons.edit, KColors.brand) {},
                        KSwipeAction("Delete", KIcons.trash, KColors.negative) {},
                    ),
                ) {
                    KCard { KText(text, KTextToken.body) }
                }
            }
            KText("Press and hold a row, then drag to reorder", KTextToken.bodySm, color = KColors.textSecondary, modifier = Modifier.padding(top = KSpace.md))
        }
        KReorderList(ids, { ids = it }) { index, id ->
            KCard {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                    KText("${index + 1}", KTextToken.bodyStrong, color = KColors.textSecondary, modifier = Modifier.width(20.dp))
                    KAvatar(id, people.indexOfFirst { it.name == id }.coerceAtLeast(4))
                    KText(id, KTextToken.body, modifier = Modifier.weight(1f))
                    KGripHandle()
                }
            }
        }
    }
}
