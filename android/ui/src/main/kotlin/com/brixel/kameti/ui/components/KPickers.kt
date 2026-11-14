package com.brixel.kameti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.WeekFields
import java.util.Locale

/** Month and day names as the app shows them. */
object KDates {
    /** "April 2027". */
    fun monthLabel(month: LocalDate): String = month.format(DateTimeFormatter.ofPattern("MMMM yyyy", Locale.getDefault()))

    /** "Apr 2027". */
    fun shortMonthLabel(month: LocalDate): String = month.format(DateTimeFormatter.ofPattern("MMM yyyy", Locale.getDefault()))

    /** "Apr". */
    fun monthName(month: LocalDate): String = month.month.getDisplayName(TextStyle.SHORT, Locale.getDefault())
}

/**
 * A month calendar for picking one day inside [range]. Tapping a day, even
 * the one already selected, calls [onPick], so a sheet can close on the tap.
 * Days outside the range are dimmed and not tappable.
 */
@Composable
fun KCalendarPicker(
    selection: LocalDate,
    range: ClosedRange<LocalDate>,
    onPick: (LocalDate) -> Unit,
    modifier: Modifier = Modifier,
) {
    var month by remember { mutableStateOf(selection.withDayOfMonth(1)) }
    val locale = LocalConfiguration.current.locales[0]
    val firstDay = WeekFields.of(locale).firstDayOfWeek
    fun canGo(step: Long): Boolean {
        val next = month.plusMonths(step)
        return !next.isBefore(range.start.withDayOfMonth(1)) && !next.isAfter(range.endInclusive.withDayOfMonth(1))
    }

    @Composable
    fun arrow(icon: androidx.compose.ui.graphics.vector.ImageVector, step: Long) {
        val enabled = canGo(step)
        Box(
            modifier = Modifier.size(KSize.minTouch).clip(CircleShape).clickable(enabled = enabled) { month = month.plusMonths(step) },
            contentAlignment = Alignment.Center,
        ) {
            KIcon(icon, tint = if (enabled) KColors.brand else KColors.textTertiary, size = 24.dp)
        }
    }

    // The same side padding as a sheet's title, so the month lines up with it.
    Column(modifier.fillMaxWidth().padding(horizontal = KSpace.xl), verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            KText(KDates.monthLabel(month), KTextToken.bodyStrong, modifier = Modifier.weight(1f))
            arrow(KIcons.chevronLeft, -1)
            arrow(KIcons.chevronRight, 1)
        }
        Row {
            repeat(7) { offset ->
                KText(
                    firstDay.plus(offset.toLong()).getDisplayName(TextStyle.SHORT, locale).uppercase(),
                    KTextToken.label, color = KColors.textSecondary,
                    modifier = Modifier.weight(1f), textAlign = TextAlign.Center, maxLines = 1,
                )
            }
        }
        // The month's days, with blanks before the first one.
        val lead = (month.dayOfWeek.value - firstDay.value + 7) % 7
        val cells: List<LocalDate?> = List(lead) { null } + (1..month.lengthOfMonth()).map { month.withDayOfMonth(it) }
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            cells.chunked(7).forEach { week ->
                Row {
                    week.forEach { day ->
                        Box(Modifier.weight(1f).height(44.dp), contentAlignment = Alignment.Center) {
                            if (day != null) {
                                val enabled = day in range
                                val isSelected = day == selection
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(if (isSelected) KColors.brand else androidx.compose.ui.graphics.Color.Transparent)
                                        .clickable(enabled = enabled, role = Role.Button) { onPick(day) }
                                        .semantics { selected = isSelected },
                                    contentAlignment = Alignment.Center,
                                ) {
                                    KText(
                                        "${day.dayOfMonth}", KTextToken.body.copy(tabular = true),
                                        color = when {
                                            isSelected -> KColors.textOnBrand
                                            enabled -> KColors.textPrimary
                                            else -> KColors.textTertiary.copy(alpha = 0.6f)
                                        },
                                    )
                                }
                            }
                        }
                    }
                    repeat(7 - week.size) { Spacer(Modifier.weight(1f)) }
                }
            }
        }
        Spacer(Modifier.height(KSpace.sm))
    }
}

/**
 * A month field that opens the month grid (board AP-2): one section per year,
 * three months a row, the chosen month filled green. Months outside
 * [months] are shown greyed out and can't be picked. A month is its first day.
 * [runLength] is the kameti's length, for "Runs Apr 2027 → Sep 2027 · 6 months".
 */
@Composable
fun KMonthField(
    title: String,
    selection: LocalDate,
    months: List<LocalDate>,
    onSelect: (LocalDate) -> Unit,
    modifier: Modifier = Modifier,
    runLength: Int? = null,
) {
    var isOpen by remember { mutableStateOf(false) }
    KFieldButton(value = KDates.monthLabel(selection), onClick = { isOpen = true }, modifier = modifier, title = title)
    if (isOpen) {
        KBottomSheet(title = title, onDismiss = { isOpen = false }) { close ->
            KMonthGrid(selection, months, runLength, Modifier.weight(1f, fill = false)) { onSelect(it); close() }
        }
    }
}

/** The month sheet's content: years, each a 3-column grid of months. */
@Composable
fun KMonthGrid(
    selection: LocalDate,
    months: List<LocalDate>,
    runLength: Int?,
    modifier: Modifier = Modifier,
    onPick: (LocalDate) -> Unit,
) {
    val years = remember(months) { months.map { it.year }.distinct().sorted() }
    val allowed = remember(months) { months.toSet() }
    val list = rememberLazyListState(initialFirstVisibleItemIndex = years.indexOf(selection.year).coerceAtLeast(0))
    Column {
        LazyColumn(state = list, modifier = modifier.fillMaxWidth().padding(horizontal = KSpace.xl)) {
            items(years) { year ->
                KText(
                    "$year", KTextToken.bodyStrong,
                    modifier = Modifier.padding(top = KSpace.lg, bottom = KSpace.sm).padding(horizontal = KSpace.xxs),
                )
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    (1..12).chunked(3).forEach { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            row.forEach { number ->
                                val month = LocalDate.of(year, number, 1)
                                val isOn = month == selection
                                val canPick = month in allowed
                                val shape = RoundedCornerShape(14.dp)
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .heightIn(min = 52.dp)
                                        .clip(shape)
                                        .background(
                                            when {
                                                isOn -> KColors.brand
                                                canPick -> KColors.surface
                                                else -> KColors.surfaceSunken
                                            },
                                        )
                                        .border(1.dp, if (isOn) KColors.brand else KColors.border, shape)
                                        .clickable(enabled = canPick, role = Role.Button) { onPick(month) }
                                        .semantics { selected = isOn },
                                    contentAlignment = Alignment.Center,
                                ) {
                                    KText(
                                        KDates.monthName(month), if (isOn) KTextToken.bodyStrong else KTextToken.body,
                                        color = when {
                                            isOn -> KColors.textOnBrand
                                            canPick -> KColors.textPrimary
                                            else -> KColors.textTertiary
                                        },
                                    )
                                }
                            }
                        }
                    }
                }
            }
            item { Spacer(Modifier.height(KSpace.lg)) }
        }
        if (runLength != null) {
            KText(
                stringResource(
                    R.string.ui_runs_s_s_n_months, KDates.shortMonthLabel(selection),
                    KDates.shortMonthLabel(selection.plusMonths(runLength - 1L)), runLength,
                ),
                KTextToken.bodySm, color = KColors.textSecondary,
                modifier = Modifier.fillMaxWidth().padding(horizontal = KSpace.xl, vertical = KSpace.md),
            )
        }
    }
}
