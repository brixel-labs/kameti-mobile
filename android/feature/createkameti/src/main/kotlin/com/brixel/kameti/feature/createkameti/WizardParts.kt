package com.brixel.kameti.feature.createkameti

import android.icu.text.ListFormatter
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.brixel.kameti.domain.Member
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSize
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import java.time.LocalDate

/** Title and subtitle at the top of a step. */
@Composable
internal fun WizardHeading(title: String, subtitle: String, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(KSpace.xs)) {
        KText(title, KTextToken.titleLg)
        if (subtitle.isNotEmpty()) KText(subtitle, KTextToken.body, color = KColors.textSecondary)
    }
}

/** A small label above a control. */
@Composable
internal fun WizardLabel(text: String, modifier: Modifier = Modifier) {
    KText(text, KTextToken.bodyStrong, modifier = modifier, color = KColors.textSecondary)
}

/** A segmented progress bar; the "Step 2 of 6" label sits under it. */
@Composable
internal fun WizardProgress(step: WizardStep, modifier: Modifier = Modifier) {
    val spoken = stringResource(R.string.create_step_n_of_n, step.ordinal + 1, WizardStep.entries.size)
    Row(
        modifier.fillMaxWidth().clearAndSetSemantics { contentDescription = spoken },
        horizontalArrangement = Arrangement.spacedBy(KSpace.xs),
    ) {
        WizardStep.entries.forEach { item ->
            Box(
                Modifier.weight(1f).height(4.dp)
                    .background(if (item.ordinal <= step.ordinal) KColors.brand else KColors.border, CircleShape),
            )
        }
    }
}

/**
 * The actions pinned to the bottom of a step: a Back button beside the
 * primary one, or the primary alone on the first step.
 */
@Composable
internal fun WizardFooter(
    primaryTitle: String,
    action: () -> Unit,
    modifier: Modifier = Modifier,
    isEnabled: Boolean = true,
    isLoading: Boolean = false,
    onBack: (() -> Unit)? = null,
    backTitle: String? = null,
    backIsDestructive: Boolean = false,
    secondary: (@Composable () -> Unit)? = null,
) {
    Column(
        modifier.fillMaxWidth().background(KColors.background).padding(horizontal = KSpace.xl, vertical = KSpace.md),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            if (onBack != null) {
                val shape = RoundedCornerShape(KRadius.button)
                Box(
                    modifier = Modifier
                        .height(KSize.buttonHeight)
                        .clip(shape)
                        .background(KColors.surface)
                        .border(1.dp, KColors.borderStrong, shape)
                        .clickable(role = Role.Button, onClick = onBack)
                        .padding(horizontal = KSpace.xl),
                    contentAlignment = Alignment.Center,
                ) {
                    KText(
                        backTitle ?: stringResource(R.string.create_previous), KTextToken.bodyStrong,
                        color = if (backIsDestructive) KColors.negative else KColors.textPrimary, maxLines = 1,
                    )
                }
            }
            KButton(primaryTitle, action, Modifier.weight(1f), enabled = isEnabled, isLoading = isLoading)
        }
        secondary?.invoke()
    }
}

/** A key and value on one line inside a card. */
@Composable
internal fun KeyValueRow(key: String, value: String, emphasis: Boolean = false) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        KText(key, KTextToken.body, color = KColors.textSecondary)
        KText(
            value, if (emphasis) KTextToken.bodyStrong else KTextToken.body,
            modifier = Modifier.weight(1f), textAlign = TextAlign.End,
        )
    }
}

/** "1st", "2nd", "3rd", "10th". */
internal fun ordinal(day: Int): String {
    val suffix = when {
        day % 100 in 11..13 -> "th"
        day % 10 == 1 -> "st"
        day % 10 == 2 -> "nd"
        day % 10 == 3 -> "rd"
        else -> "th"
    }
    return "$day$suffix"
}

/** The month [offset] months after [month]. */
internal fun addingMonths(offset: Int, month: LocalDate): LocalDate = month.plusMonths(offset.toLong())

/** "Ali, Sara and Hira", in the phone's language. */
internal fun listAnd(names: List<String>): String = ListFormatter.getInstance().format(names)

/** The member's stored colour index, else their position in the list. */
internal fun colorIndex(member: Member, members: List<Member>): Int =
    member.color?.toIntOrNull() ?: maxOf(members.indexOf(member), 0)
