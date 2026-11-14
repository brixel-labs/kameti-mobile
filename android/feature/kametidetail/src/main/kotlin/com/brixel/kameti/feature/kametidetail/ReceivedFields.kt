package com.brixel.kameti.feature.kametidetail

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.ui.KAmountInput
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KCalendarPicker
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KChipStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KFlowRow
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import java.time.LocalDate

/** Today, yesterday or a day the owner picks. */
internal enum class DateChoice {
    Today, Yesterday, Custom;

    /** The day the money came in. */
    fun date(today: LocalDate, custom: LocalDate): LocalDate = when (this) {
        Today -> today
        Yesterday -> today.minusDays(1)
        Custom -> custom
    }
}

/**
 * Days the owner can pick: from the kameti's first day to today (never an
 * empty range, even if the phone's date is before the kameti started).
 */
internal fun pickableRange(earliest: LocalDate, today: LocalDate): ClosedRange<LocalDate> = minOf(earliest, today)..today

/** The grey label above a field in a recording sheet. */
@Composable
internal fun FieldLabel(text: String, modifier: Modifier = Modifier) {
    KText(text, KTextToken.bodyStrong, modifier = modifier, color = KColors.textSecondary)
}

/** A failed write, said under the form. */
@Composable
internal fun FailureLine(failure: Failure?) {
    if (failure == null) return
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
        KIcon(KIcons.warning, tint = KColors.negative, size = 18.dp)
        KText(failure.userMessage(), KTextToken.bodySm, color = KColors.negative)
    }
}

/** A tinted note with an icon (what a payment will do, a shortfall, a hint). */
@Composable
internal fun NoteBanner(text: String, icon: ImageVector, foreground: Color, background: Color, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth().background(background, RoundedCornerShape(12.dp)).padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIcon(icon, tint = foreground, size = 18.dp)
        KText(text, KTextToken.bodySm, color = foreground)
    }
}

/** The big "Rs 4,50,000" input in a brand-bordered box. */
@Composable
internal fun AmountBox(digits: String, onDigitsChange: (String) -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(12.dp)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(60.dp)
            .border(2.dp, KColors.brand, shape)
            .padding(horizontal = KSpace.lg),
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KText("Rs", KTextStyle(size = 20f, weight = FontWeight.SemiBold), color = KColors.textSecondary)
        KAmountInput(
            digits, onDigitsChange, Modifier.weight(1f),
            style = KTextStyle(size = 26f, weight = FontWeight.Bold, tabular = true),
        )
    }
}

/** "Date received": quick chips and a calendar sheet. */
@Composable
internal fun ReceivedDateChooser(
    choice: DateChoice,
    custom: LocalDate,
    today: LocalDate,
    /** The first day that can be picked: when the kameti started. */
    earliest: LocalDate,
    onChange: (DateChoice, LocalDate) -> Unit,
) {
    var picking by remember { mutableStateOf(false) }
    val focus = LocalFocusManager.current
    Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        FieldLabel(stringResource(R.string.detail_date_received))
        KFlowRow {
            KChip(
                stringResource(R.string.detail_today), choice == DateChoice.Today,
                onClick = { onChange(DateChoice.Today, custom) }, style = KChipStyle.Outlined,
            )
            KChip(
                stringResource(R.string.detail_yesterday), choice == DateChoice.Yesterday,
                onClick = { onChange(DateChoice.Yesterday, custom) }, style = KChipStyle.Outlined,
            )
            KChip(
                if (choice == DateChoice.Custom) DetailLogic.dayMonth(custom) else stringResource(R.string.detail_pick_a_date),
                choice == DateChoice.Custom,
                onClick = {
                    focus.clearFocus()
                    picking = true
                },
                icon = KIcons.calendar, style = KChipStyle.Outlined,
            )
        }
    }
    if (picking) {
        KBottomSheet(title = stringResource(R.string.detail_date_received), onDismiss = { picking = false }) { close ->
            // Tap a day and the sheet closes.
            KCalendarPicker(custom, pickableRange(earliest, today), onPick = {
                onChange(DateChoice.Custom, it)
                close()
            })
        }
    }
}

internal fun PaymentMethod.icon(): ImageVector? = when (this) {
    PaymentMethod.Cash -> KIcons.cash
    PaymentMethod.BankTransfer -> KIcons.bank
    PaymentMethod.Other -> null
}

/** "Cash", "Bank transfer" or "Other", as in the chooser. */
@Composable
internal fun PaymentMethod.fullLabel(): String = stringResource(
    when (this) {
        PaymentMethod.Cash -> R.string.detail_cash_4a87
        PaymentMethod.BankTransfer -> R.string.detail_bank_transfer
        PaymentMethod.Other -> R.string.detail_other_1a24
    },
)

/** "Method": cash, bank transfer or other, with a reference for a bank transfer. */
@Composable
internal fun MethodChooser(
    method: PaymentMethod,
    onMethodChange: (PaymentMethod) -> Unit,
    reference: String,
    onReferenceChange: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
        FieldLabel(stringResource(R.string.detail_method))
        KFlowRow {
            for (option in PaymentMethod.entries) {
                KChip(
                    option.fullLabel(), method == option, onClick = { onMethodChange(option) },
                    icon = option.icon(), style = KChipStyle.Outlined,
                )
            }
        }
        AnimatedVisibility(method == PaymentMethod.BankTransfer) {
            KTextField(reference, onReferenceChange, placeholder = stringResource(R.string.detail_reference_no_optional))
        }
    }
}

/**
 * "Received [Today ⌄] by [Cash ⌄]": the date opens a calendar (tap a day and it
 * closes), the method opens a short list; a bank transfer shows a reference field.
 */
@Composable
internal fun DateMethodBar(
    /** "Received" or "Paid". */
    prefix: String,
    date: LocalDate,
    onDateChange: (LocalDate) -> Unit,
    method: PaymentMethod,
    onMethodChange: (PaymentMethod) -> Unit,
    reference: String,
    onReferenceChange: (String) -> Unit,
    today: LocalDate,
    earliest: LocalDate,
) {
    var pickingDate by remember { mutableStateOf(false) }
    var pickingMethod by remember { mutableStateOf(false) }
    val focus = LocalFocusManager.current
    Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
        // Wraps to a second row with large text instead of squeezing the pills.
        KFlowRow(Modifier.fillMaxWidth()) {
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                KText(prefix, KTextToken.subtitle, color = KColors.textSubtitle, maxLines = 1)
                BarPill(
                    if (date == today) stringResource(R.string.detail_today) else DetailLogic.dayMonth(date),
                    KIcons.calendar,
                ) {
                    focus.clearFocus()
                    pickingDate = true
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                KText(stringResource(R.string.detail_by), KTextToken.subtitle, color = KColors.textSubtitle, maxLines = 1)
                BarPill(method.fullLabel(), method.icon()) {
                    focus.clearFocus()
                    pickingMethod = true
                }
            }
        }
        AnimatedVisibility(method == PaymentMethod.BankTransfer) {
            KTextField(reference, onReferenceChange, placeholder = stringResource(R.string.detail_reference_no_optional))
        }
    }
    if (pickingDate) {
        KBottomSheet(title = stringResource(R.string.detail_date_received), onDismiss = { pickingDate = false }) { close ->
            // One level: tap a day and the sheet closes, even for the day already shown.
            KCalendarPicker(date, pickableRange(earliest, today), onPick = {
                onDateChange(it)
                close()
            })
        }
    }
    if (pickingMethod) {
        KBottomSheet(title = stringResource(R.string.detail_method), onDismiss = { pickingMethod = false }) { close ->
            Column(Modifier.padding(horizontal = KSpace.xl).padding(bottom = KSpace.xl)) {
                for (option in PaymentMethod.entries) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = 52.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .clickable(role = Role.RadioButton) {
                                onMethodChange(option)
                                close()
                            },
                        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KIcon(option.icon() ?: KIcons.more, tint = KColors.textSecondary)
                        KText(option.fullLabel(), KTextToken.body, modifier = Modifier.weight(1f))
                        if (option == method) KIcon(KIcons.check, tint = KColors.brand)
                    }
                }
            }
        }
    }
}

@Composable
private fun BarPill(title: String, icon: ImageVector?, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .heightIn(min = 38.dp)
            .clip(CircleShape)
            .background(KColors.surface)
            .border(1.dp, KColors.border, CircleShape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) KIcon(icon, tint = KColors.textPrimary, size = 16.dp)
        KText(title, KTextStyle(size = 14f, weight = FontWeight.SemiBold), maxLines = 1)
        KIcon(KIcons.chevronDown, tint = KColors.textPrimary, size = 16.dp)
    }
}
