package com.brixel.kameti.feature.shell

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.ui.KAppearance
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KAvatarSize
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KRefreshable
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTheme
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.launch

/** The website pages the stores require, on Kameti's own site (kameti-mobile/legal-site). */
private const val SUPPORT_URL = "https://kameti.fhbtechservices.com/support"
private const val PRIVACY_URL = "https://kameti.fhbtechservices.com/privacy"

/** The colour of a row's small icon tile. */
internal enum class RowTint { Amber, Blue, Green, Grey, Red }

@Composable
private fun RowTint.colors(): Pair<Color, Color> = when (this) {
    RowTint.Amber -> KColors.warning to KColors.warningSubtle
    RowTint.Blue -> KColors.info to KColors.infoSubtle
    RowTint.Green -> KColors.onBrandSubtle to KColors.brandSubtle
    RowTint.Grey -> KColors.textSecondary to KColors.surfaceSunken
    RowTint.Red -> KColors.negative to KColors.negativeSubtle
}

/**
 * Profile and settings (board AF · Profile, icon list option): who you are,
 * notification and appearance settings, account rows, help, and sign out.
 */
@Composable
internal fun ProfileScreen(
    model: ProfileViewModel,
    settings: ShellSettings,
    /** Whether this phone lets Kameti show notifications. */
    notificationsOn: Boolean,
    onOpenNotifications: () -> Unit,
    onOpenPeople: () -> Unit,
    onOpenPast: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val state by model.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val uris = LocalUriHandler.current
    var refreshing by remember { mutableStateOf(false) }
    var editingName by remember { mutableStateOf(false) }
    var showingSignIn by remember { mutableStateOf(false) }
    var deletingAccount by remember { mutableStateOf(false) }
    var confirmingSignOut by remember { mutableStateOf(false) }
    var choosingAppearance by remember { mutableStateOf(false) }
    var choosingIcon by remember { mutableStateOf(false) }
    var appIcon by remember { mutableStateOf(settings.appIcons?.current) }

    LaunchedEffect(Unit) { model.load() }

    Column(modifier.fillMaxSize().background(KColors.background)) {
        KText(
            stringResource(R.string.shell_profile), KTextToken.display,
            modifier = Modifier.padding(start = KSpace.xl, end = KSpace.xl, top = KSpace.lg, bottom = KSpace.sm),
        )
        KRefreshable(
            isRefreshing = refreshing,
            onRefresh = {
                scope.launch {
                    refreshing = true
                    model.refresh()
                    refreshing = false
                }
            },
        ) {
            Column(
                Modifier.fillMaxSize().verticalScroll(rememberScrollState())
                    .padding(horizontal = KSpace.xl).padding(top = KSpace.sm, bottom = KSpace.xl),
                verticalArrangement = Arrangement.spacedBy(KSpace.lg),
            ) {
                val profile = state.profile
                val failure = state.failure
                when {
                    profile != null -> ProfileCard(profile, state) { editingName = true }
                    failure != null -> KMessageCard(
                        title = failure.userMessage(), icon = KIcons.warning,
                        actionTitle = stringResource(R.string.shell_try_again), action = { model.onRefresh() },
                    )
                    else -> Box(Modifier.fillMaxWidth().padding(vertical = KSpace.xl), contentAlignment = Alignment.Center) { KSpinner() }
                }
                Group {
                    val hasIcons = settings.appIcons != null
                    SettingsRow(
                        stringResource(R.string.shell_notifications), KIcons.bell, RowTint.Amber,
                        value = stringResource(if (notificationsOn) R.string.shell_on else R.string.shell_off),
                        onClick = onOpenNotifications,
                    )
                    SettingsRow(
                        stringResource(R.string.shell_appearance), KIcons.moon, RowTint.Blue,
                        value = stringResource(settings.appearance.titleRes), isLast = !hasIcons,
                    ) { choosingAppearance = true }
                    if (hasIcons) {
                        SettingsRow(
                            stringResource(R.string.shell_app_icon), KIcons.appIcon, RowTint.Green,
                            value = appIcon?.let { stringResource(it.title) }, isLast = true,
                        ) { choosingIcon = true }
                    }
                }
                Group {
                    SettingsRow(
                        stringResource(R.string.shell_my_people), KIcons.people, RowTint.Green,
                        value = state.peopleCount.toString(), onClick = onOpenPeople,
                    )
                    SettingsRow(
                        stringResource(R.string.shell_sign_in_methods), KIcons.key, RowTint.Grey,
                        value = state.signInMethods.firstOrNull()?.let { stringResource(it.provider.title()) },
                    ) { showingSignIn = true }
                    SettingsRow(
                        stringResource(R.string.shell_past_kametis), KIcons.archive, RowTint.Blue,
                        value = state.pastCount.toString(), isLast = true, onClick = onOpenPast,
                    )
                }
                Group {
                    SettingsRow(stringResource(R.string.shell_support), KIcons.help, RowTint.Green) {
                        runCatching { uris.openUri(SUPPORT_URL) }
                    }
                    SettingsRow(stringResource(R.string.shell_privacy_policy), KIcons.shield, RowTint.Grey, isLast = true) {
                        runCatching { uris.openUri(PRIVACY_URL) }
                    }
                }
                Group {
                    SettingsRow(stringResource(R.string.shell_sign_out), KIcons.signOut, RowTint.Grey, showsChevron = false) {
                        confirmingSignOut = true
                    }
                    SettingsRow(
                        stringResource(R.string.shell_delete_account), KIcons.trash, RowTint.Red, color = KColors.negative,
                        showsChevron = false, isLast = true,
                    ) { deletingAccount = true }
                }
            }
        }
    }

    if (confirmingSignOut) {
        KConfirmSheet(
            title = stringResource(R.string.shell_sign_out_of_kameti),
            confirmTitle = stringResource(R.string.shell_sign_out),
            onDismiss = { confirmingSignOut = false },
            onConfirm = {
                model.signOut()
                KConfirmOutcome.Dismiss
            },
            message = stringResource(R.string.shell_youll_need_to_sign_in_again_to_see),
            isDestructive = true,
        )
    }
    if (choosingAppearance) {
        KBottomSheet(stringResource(R.string.shell_appearance), onDismiss = { choosingAppearance = false }) {
            AppearancePicker(settings.appearance, settings.onAppearance)
        }
    }
    val icons = settings.appIcons
    if (choosingIcon && icons != null) {
        KBottomSheet(stringResource(R.string.shell_app_icon), onDismiss = { choosingIcon = false }) {
            AppIconPicker(appIcon ?: icons.current, icons) { appIcon = it }
        }
    }
    if (editingName) {
        EditNameSheet(
            title = stringResource(R.string.shell_your_name), current = state.profile?.displayName.orEmpty(),
            startsEmpty = false, save = { model.updateName(it) }, onDismiss = { editingName = false },
        )
    }
    if (showingSignIn) {
        KBottomSheet(stringResource(R.string.shell_sign_in_methods), onDismiss = { showingSignIn = false }) {
            SignInMethodsList(state.signInMethods)
        }
    }
    if (deletingAccount) DeleteAccountSheet(model) { deletingAccount = false }
}

@Composable
private fun ProfileCard(profile: Profile, state: ProfileUiState, onClick: () -> Unit) {
    val shape = RoundedCornerShape(KRadius.card)
    // The whole card opens the name sheet, not just the arrow.
    Row(
        Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(KColors.surface)
            .border(1.dp, KColors.border, shape)
            .clickable(role = Role.Button, onClickLabel = stringResource(R.string.shell_edit_your_name), onClick = onClick)
            .padding(KSpace.lg),
        horizontalArrangement = Arrangement.spacedBy(KSpace.lg),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        KAvatar(profile.displayName, colorIndex = 0, size = KAvatarSize.Large)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(profile.displayName, KTextToken.titleLg)
            // The account's email (from its sign-in method), so it's clear
            // which account this is, and which email invites must go to.
            state.signInMethods.firstNotNullOfOrNull { it.email }?.let {
                KText(it, KTextToken.bodySm, color = KColors.textSecondary, maxLines = 1)
            }
            KText(
                stringResource(R.string.shell_n_kametis_run_n_joined, state.runningCount, state.memberCount),
                KTextToken.subtitle, color = KColors.textSubtitle,
            )
        }
        KIcon(KIcons.chevronRight, tint = KColors.textTertiary)
    }
}

/** A white rounded box of rows. */
@Composable
internal fun Group(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        modifier.fillMaxWidth().clip(shape).background(KColors.surface).border(1.dp, KColors.border, shape),
    ) {
        content()
    }
}

@Composable
internal fun IconTile(icon: ImageVector, tint: RowTint) {
    val (foreground, background) = tint.colors()
    Box(Modifier.size(30.dp).background(background, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
        KIcon(icon, tint = foreground, size = 17.dp)
    }
}

@Composable
private fun SettingsRow(
    title: String,
    icon: ImageVector,
    tint: RowTint,
    value: String? = null,
    color: Color = KColors.textPrimary,
    showsChevron: Boolean = true,
    isLast: Boolean = false,
    onClick: () -> Unit,
) {
    Column(Modifier.clickable(role = Role.Button, onClick = onClick).padding(horizontal = KSpace.lg)) {
        Row(
            Modifier.heightIn(min = 52.dp),
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconTile(icon, tint)
            KText(title, KTextToken.body, modifier = Modifier.weight(1f), color = color)
            if (value != null) KText(value, KTextToken.subtitle, color = KColors.textSubtitle)
            if (showsChevron) KIcon(KIcons.chevronRight, tint = KColors.textTertiary, size = 18.dp)
        }
        if (!isLast) KDivider(Modifier.padding(start = 42.dp))
    }
}

/**
 * Appearance as three cards with a small phone preview each: System, Light
 * and Dark. Tapping one applies it at once; the sheet stays open so the
 * change can be seen and compared.
 */
@Composable
private fun AppearancePicker(selection: KAppearance, onSelect: (KAppearance) -> Unit) {
    Column(
        Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.xs, bottom = KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.lg),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
            for (option in KAppearance.entries) {
                val isOn = option == selection
                val shape = RoundedCornerShape(14.dp)
                Column(
                    Modifier
                        .weight(1f)
                        .clip(shape)
                        .clickable(role = Role.RadioButton) { onSelect(option) }
                        .semantics { selected = isOn },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(KSpace.sm),
                ) {
                    Row(
                        Modifier.fillMaxWidth().height(116.dp).clip(shape)
                            .border(if (isOn) 2.5.dp else 1.dp, if (isOn) KColors.brand else KColors.border, shape),
                    ) {
                        // A tiny screen drawn with the app's own colours in that look; System is half light, half dark.
                        when (option) {
                            KAppearance.Light -> MiniScreen(dark = false, Modifier.weight(1f))
                            KAppearance.Dark -> MiniScreen(dark = true, Modifier.weight(1f))
                            KAppearance.System -> {
                                MiniScreen(dark = false, Modifier.weight(1f))
                                MiniScreen(dark = true, Modifier.weight(1f))
                            }
                        }
                    }
                    KText(stringResource(option.titleRes), KTextToken.bodyStrong, color = if (isOn) KColors.brand else KColors.textPrimary)
                    KIcon(
                        if (isOn) KIcons.checkCircleFilled else KIcons.circle,
                        tint = if (isOn) KColors.brand else KColors.textTertiary, size = 22.dp,
                    )
                }
            }
        }
        KText(stringResource(R.string.shell_android_system_follows_your_phone), KTextToken.bodySm, color = KColors.textSecondary)
    }
}

@Composable
private fun MiniScreen(dark: Boolean, modifier: Modifier = Modifier) {
    KTheme(dark = dark) {
        Column(
            modifier.height(116.dp).background(KColors.background).padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Box(Modifier.size(28.dp, 5.dp).background(KColors.textPrimary.copy(alpha = 0.85f), CircleShape))
            Column(
                Modifier.fillMaxWidth().height(34.dp).background(KColors.surface, RoundedCornerShape(5.dp)).padding(6.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Box(Modifier.size(22.dp, 4.dp).background(KColors.brand, CircleShape))
                Box(Modifier.width(30.dp).height(3.dp).background(KColors.textSecondary.copy(alpha = 0.5f), CircleShape))
            }
            Box(Modifier.fillMaxWidth().height(22.dp).background(KColors.surface, RoundedCornerShape(5.dp)))
        }
    }
}

/**
 * The icons as a list (board: App icon sheet A): preview, name and a short
 * description, a ticked circle on the chosen one. Tapping a row changes the
 * home-screen icon.
 */
@Composable
private fun AppIconPicker(selection: KAppIcon, icons: AppIconSwitcher, onSelected: (KAppIcon) -> Unit) {
    var failed by remember { mutableStateOf(false) }
    Column(
        Modifier.verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(top = KSpace.xs, bottom = KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        for (icon in KAppIcon.entries) {
            val isOn = icon == selection
            val shape = RoundedCornerShape(KRadius.card)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(shape)
                    .background(KColors.surface)
                    .border(if (isOn) 2.dp else 1.dp, if (isOn) KColors.brand else KColors.border, shape)
                    .clickable(role = Role.RadioButton) {
                        if (icon != selection) {
                            failed = !icons.select(icon)
                            if (!failed) onSelected(icon)
                        }
                    }
                    .semantics { selected = isOn }
                    .padding(horizontal = KSpace.md, vertical = KSpace.sm + 2.dp),
                horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    painterResource(icon.preview), contentDescription = null,
                    modifier = Modifier.size(48.dp).clip(RoundedCornerShape(11.dp)),
                )
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    KText(stringResource(icon.title), KTextToken.bodyStrong)
                    KText(stringResource(icon.detail), KTextToken.bodySm, color = KColors.textSecondary)
                }
                KIcon(
                    if (isOn) KIcons.checkCircleFilled else KIcons.circle,
                    tint = if (isOn) KColors.brand else KColors.textTertiary, size = 24.dp,
                )
            }
        }
        if (failed) {
            Row(
                Modifier.fillMaxWidth().padding(top = KSpace.xs)
                    .background(KColors.negativeSubtle, RoundedCornerShape(KRadius.input)).padding(KSpace.md),
                horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically,
            ) {
                KIcon(KIcons.errorFilled, tint = KColors.negative)
                KText(stringResource(R.string.shell_the_icon_couldnt_be_changed_try_again), KTextToken.bodySm, color = KColors.negative)
            }
        } else {
            KText(
                stringResource(R.string.shell_android_the_icon_changes_in_a_moment), KTextToken.bodySm,
                modifier = Modifier.padding(top = KSpace.xs), color = KColors.textSecondary,
            )
        }
    }
}
