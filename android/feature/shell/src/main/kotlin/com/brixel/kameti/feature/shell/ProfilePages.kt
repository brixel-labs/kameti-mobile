package com.brixel.kameti.feature.shell

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.compose.LifecycleResumeEffect
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.NotificationPreferences
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KToggle
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.launch

/** Whether this phone lets Kameti show notifications. */
internal fun notificationsAllowed(context: Context): Boolean = NotificationManagerCompat.from(context).areNotificationsEnabled()

/** Search over the saved people: name, email or phone. */
internal fun matchingPeople(people: List<Contact>, search: String): List<Contact> {
    val query = search.trim()
    if (query.isEmpty()) return people
    return people.filter {
        it.name.contains(query, ignoreCase = true) || it.email.orEmpty().contains(query, ignoreCase = true) ||
            it.phone.orEmpty().contains(query)
    }
}

/** "My people": the owner's saved people, picked from when adding members. */
@Composable
internal fun PeopleScreen(people: List<Contact>, onBack: () -> Unit) {
    var search by rememberSaveable { mutableStateOf("") }
    val shown = remember(people, search) { matchingPeople(people, search) }
    Column(Modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(stringResource(R.string.shell_my_people), onBack)
        if (people.isEmpty()) {
            KMessageCard(
                title = stringResource(R.string.shell_no_saved_people_yet),
                modifier = Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md),
                message = stringResource(R.string.shell_people_you_add_to_a_kameti_are_saved),
                icon = KIcons.people,
            )
            return@Column
        }
        KTextField(
            search, { search = it }, Modifier.padding(horizontal = KSpace.xl).padding(bottom = KSpace.sm),
            placeholder = stringResource(R.string.shell_search_people),
            capitalization = KeyboardCapitalization.Words, imeAction = ImeAction.Search, leading = { KIcon(KIcons.search) },
        )
        LazyColumn(contentPadding = PaddingValues(start = KSpace.xl, end = KSpace.xl, bottom = KSpace.xl)) {
            itemsIndexed(shown, key = { _, person -> person.id }) { index, person ->
                Row(
                    Modifier.fillMaxWidth().padding(vertical = KSpace.sm + 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically,
                ) {
                    KAvatar(person.name, colorIndex = person.name.sumOf { it.code } % 6)
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        KText(person.name, KTextToken.bodyStrong)
                        KText(
                            person.email ?: person.phone ?: stringResource(R.string.shell_no_email_or_phone),
                            KTextToken.subtitleSmall, color = KColors.textSubtitle,
                        )
                    }
                }
                if (index < shown.size - 1) KDivider()
            }
        }
    }
}

/** Completed and cancelled kametis; each opens its read-only view. */
@Composable
internal fun PastKametisScreen(kametis: List<Kameti>, onBack: () -> Unit, onOpen: (String) -> Unit) {
    Column(Modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(stringResource(R.string.shell_past_kametis), onBack)
        if (kametis.isEmpty()) {
            KMessageCard(
                title = stringResource(R.string.shell_no_past_kametis),
                modifier = Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md),
                message = stringResource(R.string.shell_kametis_that_finish_or_are_cancelled_move_here),
                icon = KIcons.archive,
            )
            return@Column
        }
        LazyColumn(contentPadding = PaddingValues(horizontal = KSpace.xl, vertical = KSpace.sm)) {
            item {
                Group {
                    kametis.forEachIndexed { index, kameti ->
                        val months = stringResource(R.string.shell_n_months_s_per_slot, kameti.monthsN, kameti.slotAmountC.format())
                        val status = when (kameti.status) {
                            KametiStatus.Completed -> stringResource(R.string.shell_completed)
                            KametiStatus.Archived -> stringResource(R.string.shell_archived)
                            KametiStatus.Cancelled -> stringResource(R.string.shell_cancelled)
                            else -> null
                        }
                        // The whole row opens the kameti, not just the arrow.
                        Row(
                            Modifier.fillMaxWidth().clickable(role = Role.Button) { onOpen(kameti.id) }
                                .padding(horizontal = KSpace.lg, vertical = KSpace.md),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                KText(kameti.name, KTextToken.bodyStrong)
                                KText(
                                    listOfNotNull(status, months).joinToString(" · "), KTextToken.subtitleSmall,
                                    color = KColors.textSubtitle,
                                )
                            }
                            KIcon(KIcons.chevronRight, tint = KColors.textTertiary, size = 18.dp)
                        }
                        if (index < kametis.size - 1) KDivider(Modifier.padding(horizontal = KSpace.lg))
                    }
                }
            }
        }
    }
}

/** Profile → Notifications (board AN-5): is this phone allowed, and what to push. */
@Composable
internal fun NotificationSettingsScreen(userId: String, dependencies: KametiDependencies, onBack: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val cache = dependencies.profileCache
    var preferences by remember { mutableStateOf<NotificationPreferences?>(null) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var allowed by remember { mutableStateOf(notificationsAllowed(context)) }
    // Asked once here; after a "no" Android won't ask again, so the button opens the phone's settings.
    var asked by rememberSaveable { mutableStateOf(false) }
    val request = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        asked = true
        allowed = granted || notificationsAllowed(context)
    }
    // Back from the phone's settings: show the new state.
    LifecycleResumeEffect(Unit) {
        allowed = notificationsAllowed(context)
        onPauseOrDispose {}
    }

    LaunchedEffect(Unit) {
        // Saved settings show at once; the server is asked only the first time.
        val saved = cache.load(userId).notificationPreferences
        if (saved != null) {
            preferences = saved
        } else {
            try {
                val fetched = dependencies.notifications.preferences(userId)
                preferences = fetched
                cache.update(userId) { it.copy(notificationPreferences = fetched) }
            } catch (caught: Failure) {
                failure = caught
            }
        }
    }

    fun change(updated: NotificationPreferences) {
        val previous = preferences ?: return
        preferences = updated
        scope.launch {
            try {
                dependencies.notifications.updatePreferences(userId, updated)
                cache.update(userId) { it.copy(notificationPreferences = updated) }
                failure = null
            } catch (caught: Failure) {
                preferences = previous
                failure = caught
            }
        }
    }

    Column(Modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(stringResource(R.string.shell_notifications), onBack)
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl, vertical = KSpace.md),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            if (allowed) {
                Row(
                    Modifier.fillMaxWidth().background(KColors.brandSubtle, RoundedCornerShape(14.dp)).padding(KSpace.md),
                    horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically,
                ) {
                    KIcon(KIcons.check, tint = KColors.brand)
                    KText(stringResource(R.string.shell_android_notifications_are_on_for_this_phone), KTextToken.bodyStrong, color = KColors.brand)
                }
            } else {
                val canAsk = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !asked
                Column(
                    Modifier.fillMaxWidth().background(KColors.warningSubtle, RoundedCornerShape(14.dp)).padding(KSpace.md),
                    verticalArrangement = Arrangement.spacedBy(KSpace.sm),
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                        KIcon(KIcons.bellOff, tint = KColors.warning)
                        KText(
                            stringResource(R.string.shell_android_notifications_are_off_for_this_phone), KTextToken.bodyStrong,
                            color = KColors.warning,
                        )
                    }
                    KText(
                        stringResource(if (canAsk) R.string.shell_turn_on else R.string.shell_android_open_settings),
                        KTextToken.bodyStrong,
                        modifier = Modifier.clickable(role = Role.Button) {
                            if (canAsk && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                request.launch(Manifest.permission.POST_NOTIFICATIONS)
                            } else {
                                openNotificationSettings(context)
                            }
                        }.padding(vertical = KSpace.xs),
                        color = KColors.brand,
                    )
                }
            }

            KText(
                stringResource(R.string.shell_android_send_me).uppercase(), KTextToken.label,
                modifier = Modifier.padding(top = KSpace.sm), color = KColors.textSecondary,
            )
            // Off for this phone: the switches can't do anything until it's on.
            Group(Modifier.alpha(if (allowed) 1f else 0.45f)) {
                val current = preferences
                val enabled = allowed && current != null

                @Composable
                fun toggle(
                    title: Int, detail: Int, isOn: Boolean, isLast: Boolean = false,
                    update: (NotificationPreferences, Boolean) -> NotificationPreferences,
                ) {
                    KToggle(
                        isOn = isOn, onChange = { value -> current?.let { change(update(it, value)) } },
                        modifier = Modifier.fillMaxWidth().padding(horizontal = KSpace.lg, vertical = KSpace.md), enabled = enabled,
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            KText(stringResource(title), KTextToken.bodyStrong)
                            KText(stringResource(detail), KTextToken.bodySm, color = KColors.textSecondary)
                        }
                    }
                    if (!isLast) KDivider(Modifier.padding(horizontal = KSpace.lg))
                }
                toggle(
                    R.string.shell_payment_reminders, R.string.shell_before_your_dues_are_due_on_the_days,
                    current?.notifyReminders ?: true,
                ) { it, value -> it.copy(notifyReminders = value) }
                toggle(
                    R.string.shell_payments_and_payouts, R.string.shell_a_payment_recorded_for_you_your_payout_next,
                    current?.notifyPayments ?: true,
                ) { it, value -> it.copy(notifyPayments = value) }
                toggle(
                    R.string.shell_invites_and_joining, R.string.shell_invitations_to_you_for_kametis_you_run_join,
                    current?.notifyInvites ?: true,
                ) { it, value -> it.copy(notifyInvites = value) }
                toggle(
                    R.string.shell_changes_to_a_kameti, R.string.shell_payout_order_changed_a_share_transferred,
                    current?.notifyChanges ?: true, isLast = true,
                ) { it, value -> it.copy(notifyChanges = value) }
            }
            failure?.let { KText(it.userMessage(), KTextToken.bodySm, color = KColors.negative) }
            KText(
                stringResource(
                    if (allowed) R.string.shell_android_everything_also_shows_in_your_inbox else R.string.shell_android_turn_notifications_on_to_choose,
                ),
                KTextToken.bodySm, modifier = Modifier.padding(horizontal = KSpace.xxs), color = KColors.textSecondary,
            )
        }
    }
}

private fun openNotificationSettings(context: Context) {
    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
        .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    runCatching { context.startActivity(intent) }
}
