package com.brixel.kameti.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import com.brixel.kameti.core.ReminderTime

/**
 * The hours reminders can go out at (06:00 to 22:00, Pakistan time) as a list of rows with a
 * tick on the chosen one. The whole row is the button. Shown in a sheet, in the create wizard
 * and in Edit kameti.
 */
@Composable
fun KReminderTimeList(selection: Int, onPick: (Int) -> Unit, modifier: Modifier = Modifier) {
    LazyColumn(modifier) {
        items(ReminderTime.HOURS.toList()) { hour ->
            Row(
                Modifier
                    .fillMaxWidth()
                    .clickable(role = Role.RadioButton) { onPick(hour) }
                    .semantics { selected = hour == selection }
                    .padding(horizontal = KSpace.xl, vertical = KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                KText(ReminderTime.label(hour), KTextToken.body, modifier = Modifier.weight(1f))
                if (hour == selection) KIcon(KIcons.check, tint = KColors.brand)
            }
            KDivider(Modifier.padding(start = KSpace.xl))
        }
    }
}
