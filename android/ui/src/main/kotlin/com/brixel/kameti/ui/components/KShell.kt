package com.brixel.kameti.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.PullToRefreshDefaults
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** The Apple logo for "Continue with Apple", in the colour of the button's text. */
@Composable
fun KAppleLogo(modifier: Modifier = Modifier, tint: Color = KColors.textOnBrand) {
    Image(
        painterResource(R.drawable.k_apple_logo),
        contentDescription = null,
        modifier = modifier.size(20.dp),
        colorFilter = ColorFilter.tint(tint),
    )
}

/** The app's spinner, for a short wait with nothing else to show. */
@Composable
fun KSpinner(modifier: Modifier = Modifier, size: Dp = 28.dp, color: Color = KColors.brand) {
    val loading = stringResource(R.string.ui_loading)
    CircularProgressIndicator(
        modifier = modifier.size(size).semantics { contentDescription = loading },
        color = color,
        strokeWidth = 2.5.dp,
    )
}

/** A whole screen that is still loading: the spinner centred on the background. */
@Composable
fun KLoadingScreen(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().background(KColors.background), contentAlignment = Alignment.Center) { KSpinner() }
}

/** One tab of [KTabBar]. [badge] above zero shows a count on the icon. */
data class KTabItem(val title: String, val icon: ImageVector, val badge: Int = 0)

/**
 * The bottom tab bar of the signed-in app. The whole tab is the touch target,
 * and it sits above the system navigation bar.
 */
@Composable
fun KTabBar(items: List<KTabItem>, selectedIndex: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth().background(KColors.surface)) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(KColors.divider))
        Row(
            Modifier.fillMaxWidth().navigationBarsPadding().height(60.dp).selectableGroup(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            items.forEachIndexed { index, item ->
                val selected = index == selectedIndex
                val color = if (selected) KColors.brand else KColors.textSecondary
                val newCount = if (item.badge > 0) stringResource(R.string.ui_android_n_new, item.badge) else null
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxSize()
                        .selectable(selected = selected, role = Role.Tab, onClick = { onSelect(index) })
                        .semantics(mergeDescendants = true) {
                            if (newCount != null) contentDescription = "${item.title}, $newCount"
                        },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Box {
                        KIcon(item.icon, tint = color, size = 24.dp)
                        if (item.badge > 0) {
                            Box(
                                Modifier
                                    .align(Alignment.TopEnd)
                                    .offset(x = 10.dp, y = (-4).dp)
                                    .defaultMinSize(minWidth = 16.dp, minHeight = 16.dp)
                                    .clip(RoundedCornerShape(KRadius.pill))
                                    .background(KColors.negative)
                                    .padding(horizontal = 4.dp),
                                contentAlignment = Alignment.Center,
                            ) {
                                KText(
                                    if (item.badge > 99) "99+" else item.badge.toString(),
                                    KTextStyle(size = 10f, weight = FontWeight.SemiBold, tabular = true),
                                    color = KColors.textOnBrand,
                                    maxLines = 1,
                                )
                            }
                        }
                    }
                    Spacer(Modifier.height(2.dp))
                    KText(
                        item.title,
                        KTextStyle(size = 11f, weight = if (selected) FontWeight.SemiBold else FontWeight.Medium),
                        color = color,
                        maxLines = 1,
                    )
                }
            }
        }
    }
}

/**
 * The bar at the top of a pushed screen: a back arrow, the screen's title
 * (and a line under it), and room for one trailing control.
 */
@Composable
fun KTopBar(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        modifier.fillMaxWidth().height(56.dp).padding(horizontal = KSpace.xs),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KIconButton(KIcons.chevronLeft, stringResource(R.string.ui_android_back), onBack, tint = KColors.textPrimary)
        Column(Modifier.weight(1f).padding(end = KSpace.sm)) {
            KText(title, KTextToken.title, maxLines = 1)
            if (!subtitle.isNullOrEmpty()) {
                KText(subtitle, KTextToken.subtitleSmall, color = KColors.textSubtitle, maxLines = 1)
            }
        }
        trailing?.invoke()
    }
}

/** A hairline between rows of a card or a sheet. */
@Composable
fun KDivider(modifier: Modifier = Modifier, color: Color = KColors.divider) {
    Box(modifier.fillMaxWidth().height(1.dp).background(color))
}

/**
 * Pull down to reload. [isRefreshing] is true only while a reload the user
 * pulled for is running; the content must be scrollable.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KRefreshable(
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit,
) {
    val state = rememberPullToRefreshState()
    PullToRefreshBox(
        isRefreshing = isRefreshing,
        onRefresh = onRefresh,
        modifier = modifier,
        state = state,
        indicator = {
            PullToRefreshDefaults.Indicator(
                state = state,
                isRefreshing = isRefreshing,
                modifier = Modifier.align(Alignment.TopCenter),
                containerColor = KColors.surface,
                color = KColors.brand,
            )
        },
        content = content,
    )
}
