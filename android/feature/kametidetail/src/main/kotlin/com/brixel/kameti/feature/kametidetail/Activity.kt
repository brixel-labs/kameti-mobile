package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.AuditEntry
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.helpMessage
import java.time.LocalDate
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Loads a kameti's activity (FR-90). Row-level security decides what comes
 * back: everything for the owner, only the entries about them for a member.
 */
class ActivityViewModel(
    private val kametiId: String,
    private val userId: String,
    private val dependencies: KametiDependencies,
) : ViewModel() {
    sealed interface State {
        data object Loading : State
        data class Loaded(
            val kameti: Kameti,
            val members: List<Member>,
            val slots: List<Slot>,
            val entries: List<AuditEntry>,
            val isOwner: Boolean,
        ) : State

        data class Failed(val failure: Failure) : State
    }

    private val current = MutableStateFlow<State>(State.Loading)
    val state: StateFlow<State> = current.asStateFlow()

    /** "Today" for the day headers, from the app clock (fixed in the demo). */
    val today: LocalDate get() = dependencies.clock.today()

    fun refresh() {
        viewModelScope.launch { load() }
    }

    suspend fun load() {
        try {
            val kameti = dependencies.kametis.kameti(kametiId)
            val members = dependencies.kametis.members(kametiId)
            val slots = attempt { dependencies.kametis.slots(kametiId) }.getOrNull().orEmpty()
            val entries = dependencies.audit.audit(kametiId, limit = 300)
            current.value = State.Loaded(kameti, members, slots, entries, kameti.isOwnedBy(userId))
        } catch (failure: Failure) {
            // Keep what is on screen if a refresh fails.
            if (current.value !is State.Loaded) current.value = State.Failed(failure)
        }
    }

    /** The rows to show, newest first; empty until it has loaded. */
    internal fun items(strings: Strings): List<ActivityItem> = (current.value as? State.Loaded)?.items(strings).orEmpty()
}

internal fun ActivityViewModel.State.Loaded.items(strings: Strings): List<ActivityItem> =
    ActivityLogic.items(entries, ActivityLogic.Context(members, slots, kameti, strings))

/**
 * Activity (board AL-1 with AL-2's before → after lines): filter chips and
 * rows grouped by day.
 */
@Composable
fun ActivityScreen(model: ActivityViewModel, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val state by model.state.collectAsStateWithLifecycle()
    LaunchedEffect(Unit) { model.load() }

    Column(modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(
            title = stringResource(R.string.detail_activity),
            onBack = onBack,
            subtitle = (state as? ActivityViewModel.State.Loaded)?.kameti?.name,
        )
        when (val current = state) {
            ActivityViewModel.State.Loading -> KSkeletonRows(Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md), rows = 5)
            is ActivityViewModel.State.Failed -> KMessageCard(
                title = stringResource(R.string.detail_couldnt_load_the_activity),
                modifier = Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md),
                message = current.failure.helpMessage(),
                actionTitle = stringResource(R.string.detail_try_again),
                action = { model.refresh() },
            )
            is ActivityViewModel.State.Loaded -> ActivityList(current, model)
        }
    }
}

@Composable
private fun ActivityList(loaded: ActivityViewModel.State.Loaded, model: ActivityViewModel) {
    val strings = rememberStrings()
    val scope = rememberCoroutineScope()
    var filter by rememberSaveable { mutableStateOf(ActivityLogic.Filter.All) }
    var refreshing by remember { mutableStateOf(false) }
    val items = remember(loaded, strings) { loaded.items(strings) }
    val days = remember(items, filter) { ActivityLogic.byDay(ActivityLogic.filtered(items, filter)) }
    val today = model.today

    KRefreshable(
        isRefreshing = refreshing,
        onRefresh = {
            scope.launch {
                refreshing = true
                model.load()
                refreshing = false
            }
        },
    ) {
        LazyColumn(
            Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = KSpace.xl, end = KSpace.xl, top = KSpace.md, bottom = KSpace.xl),
        ) {
            item {
                Row(Modifier.padding(bottom = KSpace.sm), horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                    KChip(stringResource(R.string.detail_all), filter == ActivityLogic.Filter.All, onClick = { filter = ActivityLogic.Filter.All })
                    KChip(
                        stringResource(R.string.detail_money), filter == ActivityLogic.Filter.Money,
                        onClick = { filter = ActivityLogic.Filter.Money },
                    )
                    KChip(
                        stringResource(R.string.detail_members), filter == ActivityLogic.Filter.Members,
                        onClick = { filter = ActivityLogic.Filter.Members },
                    )
                    KChip(
                        stringResource(R.string.detail_changes), filter == ActivityLogic.Filter.Changes,
                        onClick = { filter = ActivityLogic.Filter.Changes },
                    )
                }
            }
            if (days.isEmpty()) {
                item {
                    KMessageCard(
                        title = stringResource(R.string.detail_nothing_here_yet),
                        modifier = Modifier.padding(top = KSpace.xl),
                        message = stringResource(
                            if (loaded.isOwner) {
                                R.string.detail_payments_payouts_member_changes_and_edits_show_up
                            } else {
                                R.string.detail_payments_and_changes_that_involve_you_show_up
                            },
                        ),
                        icon = KIcons.clock,
                    )
                }
            }
            for ((day, rows) in days) {
                item(key = "day-$day") {
                    CardLabel(NoteLogic.dayTitle(day, today, strings), Modifier.padding(top = KSpace.lg, bottom = KSpace.xs))
                }
                items(rows.size, key = { rows[it].id }) { index ->
                    ActivityRow(rows[index], showsDivider = index < rows.size - 1)
                }
            }
        }
    }
}

@Composable
private fun ActivityItem.Tone.colors(): Pair<Color, Color> = when (this) {
    ActivityItem.Tone.Positive -> KColors.positive to KColors.positiveSubtle
    ActivityItem.Tone.Negative -> KColors.negative to KColors.negativeSubtle
    ActivityItem.Tone.Info -> KColors.info to KColors.infoSubtle
    ActivityItem.Tone.Warning -> KColors.warning to KColors.warningSubtle
    ActivityItem.Tone.Brand -> KColors.brand to KColors.brandSubtle
    ActivityItem.Tone.Neutral -> KColors.textSecondary to KColors.surfaceSunken
}

/**
 * One activity row: a coloured icon, what happened, a summary, any
 * before → after lines, and the time.
 */
@Composable
private fun ActivityRow(item: ActivityItem, showsDivider: Boolean) {
    val (tint, fill) = item.tone.colors()
    Column(Modifier.semantics(mergeDescendants = true) {}) {
        Row(Modifier.padding(vertical = KSpace.md), horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            Box(Modifier.size(38.dp).background(fill, CircleShape), contentAlignment = Alignment.Center) {
                KIcon(item.icon, tint = tint, size = 18.dp)
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                KText(item.title, KTextToken.bodyStrong)
                if (!item.detail.isNullOrEmpty()) KText(item.detail, KTextToken.bodySm, color = KColors.textSecondary)
                for (change in item.changes) {
                    Row(
                        Modifier
                            .padding(top = 2.dp)
                            .background(KColors.surfaceSunken, RoundedCornerShape(8.dp))
                            .padding(horizontal = KSpace.sm, vertical = 5.dp),
                        horizontalArrangement = Arrangement.spacedBy(KSpace.xs),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        KText(change.label, KTextToken.caption, color = KColors.textSecondary, maxLines = 1)
                        KText(
                            AnnotatedString(change.before, SpanStyle(textDecoration = TextDecoration.LineThrough)),
                            KTextToken.caption, modifier = Modifier.weight(1f, fill = false), color = KColors.textSecondary, maxLines = 1,
                        )
                        KIcon(KIcons.arrowRight, tint = KColors.textTertiary, size = 12.dp)
                        KText(
                            change.after, KTextStyle(size = 12f, weight = FontWeight.SemiBold),
                            modifier = Modifier.weight(1f, fill = false), maxLines = 1,
                        )
                    }
                }
            }
            KText(ActivityLogic.time(item.at), KTextToken.caption, color = KColors.textSecondary, maxLines = 1)
        }
        if (showsDivider) KDivider()
    }
}
