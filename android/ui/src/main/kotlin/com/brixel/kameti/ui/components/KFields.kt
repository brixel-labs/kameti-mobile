package com.brixel.kameti.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Money

// Shared input controls. Every feature uses these, never raw text fields.

/**
 * Tapping empty space hides the keyboard; tapping another field keeps it up
 * (the field takes the tap first). Put it on a screen's or sheet's root.
 */
@Composable
fun Modifier.kDismissesKeyboard(): Modifier {
    val focus = LocalFocusManager.current
    return pointerInput(Unit) { detectTapGestures { focus.clearFocus() } }
}

/** The label above a field and the error or helper line under it. */
@Composable
private fun KFieldColumn(
    title: String?,
    error: String?,
    helper: String?,
    modifier: Modifier,
    field: @Composable () -> Unit,
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
        if (title != null) KText(title, KTextToken.bodyStrong, color = KColors.textSecondary)
        field()
        if (error != null) {
            KText(error, KTextToken.caption, color = KColors.negative)
        } else if (helper != null) {
            KText(helper, KTextToken.subtitleSmall, color = KColors.textSubtitle)
        }
    }
}

/** The rounded, bordered box every field sits in. The border turns brand green with focus. */
@Composable
private fun Modifier.kFieldBox(isError: Boolean, isFocused: Boolean, minHeight: androidx.compose.ui.unit.Dp = KSize.fieldHeight): Modifier {
    val shape = RoundedCornerShape(KRadius.input)
    val border = when {
        isError -> KColors.negative
        isFocused -> KColors.brand
        else -> KColors.border
    }
    return fillMaxWidth()
        .heightIn(min = minHeight)
        .background(KColors.surface, shape)
        .border(if (isFocused && !isError) 1.5.dp else 1.dp, border, shape)
}

/**
 * A text field with the design's look: label above, rounded box, error or
 * helper below. [lines] above 1 makes a multi-line box (notes, reasons).
 */
@Composable
fun KTextField(
    text: String,
    onTextChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    placeholder: String = "",
    error: String? = null,
    helper: String? = null,
    lines: Int = 1,
    maxLength: Int? = null,
    enabled: Boolean = true,
    keyboardType: KeyboardType = KeyboardType.Text,
    capitalization: KeyboardCapitalization = KeyboardCapitalization.Sentences,
    imeAction: ImeAction = if (lines > 1) ImeAction.Default else ImeAction.Next,
    onImeAction: (() -> Unit)? = null,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    var focused by remember { mutableStateOf(false) }
    val focus = LocalFocusManager.current
    KFieldColumn(title, error, helper, modifier) {
        Row(
            modifier = Modifier
                .kFieldBox(error != null, focused, if (lines > 1) (24 * lines + 32).dp else KSize.fieldHeight)
                .padding(horizontal = KSpace.md, vertical = if (lines > 1) KSpace.md else 0.dp),
            verticalAlignment = if (lines > 1) Alignment.Top else Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        ) {
            leading?.invoke()
            Box(Modifier.weight(1f)) {
                if (text.isEmpty()) KText(placeholder, KTextToken.body, color = KColors.textTertiary, maxLines = lines)
                BasicTextField(
                    value = text,
                    onValueChange = { new -> onTextChange(if (maxLength != null) new.take(maxLength) else new) },
                    modifier = Modifier.fillMaxWidth().onFocusChanged { focused = it.isFocused },
                    enabled = enabled,
                    singleLine = lines == 1,
                    minLines = lines,
                    textStyle = KTextToken.body.toTextStyle().copy(color = KColors.textPrimary),
                    cursorBrush = SolidColor(KColors.brand),
                    keyboardOptions = KeyboardOptions(capitalization = capitalization, keyboardType = keyboardType, imeAction = imeAction),
                    keyboardActions = KeyboardActions(
                        onDone = { focus.clearFocus(); onImeAction?.invoke() },
                        onSearch = { focus.clearFocus(); onImeAction?.invoke() },
                        onGo = { focus.clearFocus(); onImeAction?.invoke() },
                    ),
                )
            }
            trailing?.invoke()
        }
    }
}

object KAmount {
    /** `250000` becomes `2,50,000`; empty (or anything that isn't a number) stays empty. */
    fun grouped(digits: String): String = digits.toLongOrNull()?.let { Money(it).format(symbol = false) } ?: ""

    /** What the user typed, as digits only: no leading zeros, at most 10 digits. */
    fun digits(typed: String): String = typed.filter { it.isDigit() }.dropWhile { it == '0' }.take(10)
}

/**
 * Just the grouped number input (no title, no frame), for rows with an
 * amount. [digits] holds only the digits; the field shows them in lakh/crore
 * grouping as you type (`2,50,000`).
 */
@Composable
fun KAmountInput(
    digits: String,
    onDigitsChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    prompt: String = "0",
    style: KTextStyle = KTextToken.title,
    imeAction: ImeAction = ImeAction.Done,
    onFocusChange: (Boolean) -> Unit = {},
) {
    val shown = KAmount.grouped(digits)
    val focus = LocalFocusManager.current
    Box(modifier) {
        if (shown.isEmpty()) KText(prompt, style, color = KColors.textTertiary)
        BasicTextField(
            // The caret stays at the end: the commas move as digits are typed.
            value = TextFieldValue(shown, TextRange(shown.length)),
            onValueChange = { onDigitsChange(KAmount.digits(it.text)) },
            modifier = Modifier.fillMaxWidth().onFocusChanged { onFocusChange(it.isFocused) },
            singleLine = true,
            textStyle = style.copy(tabular = true).toTextStyle().copy(color = KColors.textPrimary),
            cursorBrush = SolidColor(KColors.brand),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = imeAction),
            keyboardActions = KeyboardActions(onDone = { focus.clearFocus() }),
        )
    }
}

/** A rupee amount field: a label, "Rs" and the grouped number. */
@Composable
fun KAmountField(
    title: String,
    digits: String,
    onDigitsChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "0",
    error: String? = null,
    helper: String? = null,
) {
    var focused by remember { mutableStateOf(false) }
    KFieldColumn(title, error, helper, modifier) {
        Row(
            modifier = Modifier.kFieldBox(error != null, focused).padding(horizontal = KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        ) {
            KText(stringResource(R.string.ui_rs), KTextToken.body, color = KColors.textSecondary)
            KAmountInput(digits, onDigitsChange, Modifier.weight(1f), prompt = placeholder, onFocusChange = { focused = it })
        }
    }
}

/** A field that looks like an input but opens something when tapped (a sheet of options, a calendar). */
@Composable
fun KFieldButton(
    value: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    placeholder: String = "",
    error: String? = null,
    helper: String? = null,
    leading: (@Composable () -> Unit)? = null,
) {
    val focus = LocalFocusManager.current
    KFieldColumn(title, error, helper, modifier) {
        Row(
            modifier = Modifier
                .kFieldBox(error != null, isFocused = false)
                .clip(RoundedCornerShape(KRadius.input))
                .clickable { focus.clearFocus(); onClick() }
                .padding(horizontal = KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
        ) {
            leading?.invoke()
            if (value.isEmpty()) {
                KText(placeholder, KTextToken.body, color = KColors.textTertiary, modifier = Modifier.weight(1f), maxLines = 1)
            } else {
                KText(value, KTextToken.body, modifier = Modifier.weight(1f), maxLines = 1)
            }
            KIcon(KIcons.chevronDown, size = 20.dp)
        }
    }
}
