package com.brixel.kameti.feature.kametidetail

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConnectivity
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KOfflineBanner
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSkeletonRows
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KTopBar
import com.brixel.kameti.ui.helpMessage
import kotlinx.coroutines.launch

/**
 * One kameti: the owner's tabs or the member's read-only view. Owner or
 * member is decided once, from the loaded kameti; the member branch builds
 * no write controls at all.
 */
@Composable
fun KametiDetailScreen(
    model: KametiDetailViewModel,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    onResumeDraft: ((String) -> Unit)? = null,
) {
    val state by model.state.collectAsStateWithLifecycle()
    // The kameti to name the screen after: the loaded one, else what Home passed.
    val known = (state as? KametiDetailViewModel.State.Loaded)?.data?.kameti ?: model.preview

    LaunchedEffect(Unit) { model.load() }

    Column(modifier.fillMaxSize().background(KColors.background)) {
        KTopBar(
            title = known?.name ?: stringResource(R.string.detail_kameti),
            onBack = onBack,
            subtitle = known?.let {
                stringResource(R.string.detail_n_months_s_per_slot, it.monthsN, it.slotAmountC.format())
            },
        )
        when (val current = state) {
            KametiDetailViewModel.State.Loading -> Column(
                Modifier.verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(top = KSpace.md),
                verticalArrangement = Arrangement.spacedBy(KSpace.md),
            ) {
                KSkeletonRows(rows = 2)
                KSkeletonRows(rows = 4)
            }
            is KametiDetailViewModel.State.Failed -> Box(Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md)) {
                KMessageCard(
                    title = stringResource(R.string.detail_couldnt_load_this_kameti),
                    message = current.failure.helpMessage(),
                    actionTitle = stringResource(R.string.detail_try_again),
                    action = { model.refresh() },
                )
            }
            is KametiDetailViewModel.State.Loaded -> {
                // Offline: the last loaded data stays, with a note on how old it is.
                if (!KConnectivity.isOnline) {
                    KOfflineBanner(
                        since = model.loadedAt,
                        modifier = Modifier.padding(horizontal = KSpace.xl, vertical = KSpace.sm),
                    )
                }
                Loaded(current.data, model, onResumeDraft)
            }
        }
    }
}

@Composable
private fun Loaded(data: KametiDetailData, model: KametiDetailViewModel, onResumeDraft: ((String) -> Unit)?) {
    val scope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }
    when {
        !data.isOwner -> KRefreshable(
            isRefreshing = refreshing,
            onRefresh = {
                scope.launch {
                    refreshing = true
                    model.load()
                    refreshing = false
                }
            },
        ) {
            MemberView(data)
        }
        data.kameti.status == KametiStatus.Draft -> Column(
            Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.md),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            KMessageCard(
                title = stringResource(R.string.detail_this_kameti_is_a_draft),
                message = stringResource(R.string.detail_finish_setting_it_up_to_start_collecting),
                icon = KIcons.editSetup,
            )
            if (onResumeDraft != null) {
                KButton(stringResource(R.string.detail_continue_setting_up), onClick = { onResumeDraft(data.kameti.id) })
            }
        }
        else -> OwnerTabs(data, model)
    }
}
