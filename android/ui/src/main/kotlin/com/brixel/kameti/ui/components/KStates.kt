package com.brixel.kameti.ui

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

/**
 * Whether the phone has a connection, watched once for the whole app
 * ([start] from the Application).
 *
 * Two signals: the system's default network (validated internet), and the
 * app's own requests, so a request that fails for lack of a connection shows
 * the offline state even if the network still looks fine. [isOnline] is
 * Compose state: a screen that reads it redraws when it changes.
 */
object KConnectivity {
    private var networkOnline by mutableStateOf(true)
    private var requestsFailing by mutableStateOf(false)
    private var started = false

    val isOnline: Boolean get() = networkOnline && !requestsFailing

    fun start(context: Context) {
        if (started) return
        started = true
        val manager = context.applicationContext.getSystemService(ConnectivityManager::class.java) ?: return
        networkOnline = manager.getNetworkCapabilities(manager.activeNetwork).hasInternet()
        manager.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                networkOnline = capabilities.hasInternet()
                // A fresh connection gets a fresh chance.
                if (networkOnline) requestsFailing = false
            }

            override fun onLost(network: Network) {
                networkOnline = false
            }
        })
    }

    private fun NetworkCapabilities?.hasInternet(): Boolean =
        this != null && hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)

    /** Call after a load: a network failure means offline, success (`null`) means online. */
    fun record(failure: Failure?) {
        if (failure == Failure.Network) requestsFailing = true else if (failure == null) requestsFailing = false
    }
}

@Composable
private fun KBanner(text: String, icon: ImageVector, foreground: Color, background: Color, modifier: Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(background, RoundedCornerShape(12.dp))
            .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        KIcon(icon, tint = foreground, size = 18.dp)
        KText(text, KTextToken.bodySm, color = foreground)
    }
}

/**
 * "You're offline. Showing data from 10:42 AM." (board AF-States): shown
 * above a screen whose data is still on screen from the last load.
 */
@Composable
fun KOfflineBanner(since: Instant?, modifier: Modifier = Modifier) {
    val text = if (since == null) {
        stringResource(R.string.ui_youre_offline_some_information_may_be_out_of)
    } else {
        val time = DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT).format(since.atZone(ZoneId.systemDefault()))
        stringResource(R.string.ui_youre_offline_showing_data_from_s, time)
    }
    KBanner(text, KIcons.offline, KColors.textSecondary, KColors.surfaceSunken, modifier)
}

/**
 * "Can't record payments offline. Connect and try again." (AF-States): in a
 * sheet whose action needs a connection.
 */
@Composable
fun KOfflineActionBanner(text: String, modifier: Modifier = Modifier) {
    KBanner(text, KIcons.error, KColors.negative, KColors.negativeSubtle, modifier)
}

/**
 * Grey placeholder rows while a list loads (AF-States · Loading), instead
 * of a spinner, so the screen keeps its shape.
 */
@Composable
fun KSkeletonRows(modifier: Modifier = Modifier, rows: Int = 3) {
    val pulse by rememberInfiniteTransition(label = "skeleton").animateFloat(
        initialValue = 1f, targetValue = 0.55f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "dim",
    )
    val loading = stringResource(R.string.ui_loading)
    val grey = KColors.surfaceSunken
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .alpha(pulse)
            .background(KColors.surface, shape)
            .border(1.dp, KColors.border, shape)
            .padding(KSpace.lg)
            .clearAndSetSemantics { contentDescription = loading },
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        repeat(rows) { index ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                Box(Modifier.size(36.dp).background(grey, CircleShape))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Box(Modifier.width(if (index % 2 == 0) 180.dp else 150.dp).height(12.dp).background(grey, RoundedCornerShape(6.dp)))
                    Box(Modifier.width(110.dp).height(10.dp).background(grey, RoundedCornerShape(6.dp)))
                }
                Box(Modifier.size(width = 56.dp, height = 20.dp).background(grey, CircleShape))
            }
        }
    }
}

/**
 * A centred card with a title, a line of help and an optional action:
 * errors ("Couldn't load this kameti" + Try again), an expired invite, or an
 * empty list (AF-States).
 */
@Composable
fun KMessageCard(
    title: String,
    modifier: Modifier = Modifier,
    message: String? = null,
    icon: ImageVector? = null,
    tint: Color = KColors.textSecondary,
    actionTitle: String? = null,
    action: (() -> Unit)? = null,
) {
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(KColors.surface, shape)
            .border(1.dp, KColors.border, shape)
            .padding(vertical = KSpace.xl, horizontal = KSpace.lg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        if (icon != null) {
            KIcon(icon, tint = tint, size = 28.dp)
            Spacer(Modifier.height(KSpace.xxs))
        }
        KText(title, KTextToken.bodyStrong, textAlign = TextAlign.Center)
        if (message != null) KText(message, KTextToken.bodySm, color = KColors.textSecondary, textAlign = TextAlign.Center)
        if (actionTitle != null && action != null) {
            Box(
                modifier = Modifier
                    .padding(top = KSpace.xs)
                    .heightIn(min = 40.dp)
                    .clip(CircleShape)
                    .border(1.dp, KColors.brand, CircleShape)
                    .clickable(role = Role.Button, onClick = action)
                    .padding(horizontal = KSpace.xl),
                contentAlignment = Alignment.Center,
            ) {
                KText(actionTitle, KTextToken.bodyStrong, color = KColors.brand)
            }
        }
    }
}
