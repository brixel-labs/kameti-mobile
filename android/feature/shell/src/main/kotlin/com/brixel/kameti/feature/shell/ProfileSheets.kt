package com.brixel.kameti.feature.shell

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.AccountDeletionCheck
import com.brixel.kameti.domain.SignInMethod
import com.brixel.kameti.ui.KAppleLogo
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KButtonStyle
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KSheetMessage
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.KTonalButton
import com.brixel.kameti.ui.KTonalStyle
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.launch

@Composable
private fun FailureLine(failure: Failure?) {
    if (failure == null) return
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
        KIcon(KIcons.warning, tint = KColors.negative, size = 18.dp)
        KText(failure.userMessage(), KTextToken.bodySm, color = KColors.negative)
    }
}

/**
 * The name other people see (1–80 characters). Used to edit it from Profile,
 * and, with [startsEmpty], to ask for it after signing in with Apple or
 * Google: Apple's "Hide My Email" gives no name, so the account may only
 * have a placeholder.
 */
@Composable
internal fun EditNameSheet(
    title: String,
    current: String,
    startsEmpty: Boolean,
    save: suspend (String) -> Failure?,
    onDismiss: () -> Unit,
    /** The prompt after sign-in accepts the name as it is; the edit sheet needs a change. */
    allowsUnchanged: Boolean = false,
) {
    var name by remember { mutableStateOf(if (startsEmpty) "" else current) }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val scope = rememberCoroutineScope()
    val focus = remember { FocusRequester() }
    val trimmed = name.trim()
    val isValid = trimmed.length in 1..80

    KBottomSheet(title, onDismiss, dismissDisabled = isBusy) { close ->
        fun submit() {
            if (!isValid || isBusy) return
            // Unchanged: nothing to save.
            if (trimmed == current) {
                if (allowsUnchanged) close()
                return
            }
            isBusy = true
            failure = null
            scope.launch {
                val result = save(trimmed)
                isBusy = false
                if (result != null) failure = result else close()
            }
        }
        Column(
            Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.lg),
            verticalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            KTextField(
                name, { name = it }, Modifier.focusRequester(focus),
                placeholder = stringResource(if (allowsUnchanged) R.string.shell_your_full_name else R.string.shell_your_name),
                error = if (!isValid && name.isNotEmpty()) "" else null,
                capitalization = KeyboardCapitalization.Words, imeAction = ImeAction.Done, onImeAction = { submit() },
            )
            KText(stringResource(R.string.shell_members_see_this_name_on_kametis_you_run), KTextToken.bodySm, color = KColors.textSecondary)
            FailureLine(failure)
            KButton(
                stringResource(R.string.shell_save), onClick = { submit() },
                modifier = Modifier.padding(top = KSpace.sm),
                enabled = isValid && (allowsUnchanged || trimmed != current), isLoading = isBusy,
            )
        }
        LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }
    }
}

internal fun SignInMethod.Provider.title(): Int = when (this) {
    SignInMethod.Provider.Apple -> R.string.shell_apple
    SignInMethod.Provider.Google -> R.string.shell_google
    SignInMethod.Provider.Email -> R.string.shell_email
}

/** Which sign-in methods the account has, and the email each uses. */
@Composable
internal fun SignInMethodsList(methods: List<SignInMethod>) {
    Column(
        Modifier.padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        if (methods.isEmpty()) {
            KText(stringResource(R.string.shell_we_couldnt_read_your_sign_in_methods_pull), KTextToken.body, color = KColors.textSecondary)
            return@Column
        }
        Group {
            methods.forEachIndexed { index, method ->
                Row(
                    Modifier.padding(horizontal = KSpace.lg, vertical = KSpace.md),
                    horizontalArrangement = Arrangement.spacedBy(KSpace.md), verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(Modifier.size(32.dp).background(KColors.surfaceSunken, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
                        when (method.provider) {
                            SignInMethod.Provider.Apple -> KAppleLogo(Modifier.size(18.dp))
                            SignInMethod.Provider.Google -> KText("G", KTextToken.bodyStrong)
                            SignInMethod.Provider.Email -> KIcon(KIcons.envelope, tint = KColors.textPrimary, size = 18.dp)
                        }
                    }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        KText(stringResource(method.provider.title()), KTextToken.bodyStrong)
                        method.email?.let { KText(it, KTextToken.subtitleSmall, color = KColors.textSubtitle) }
                    }
                    KIcon(KIcons.checkCircleFilled, tint = KColors.positive)
                }
                if (index < methods.size - 1) KDivider(Modifier.padding(horizontal = KSpace.lg))
            }
        }
        KText(stringResource(R.string.shell_invites_are_matched_to_the_email_you_sign), KTextToken.bodySm, color = KColors.textSecondary)
    }
}

/**
 * Delete account (REQUIREMENTS §5.5): asks the backend what would happen,
 * then either lists the running kametis that block it, or explains what is
 * deleted and kept and asks the user to type DELETE before going ahead.
 */
@Composable
internal fun DeleteAccountSheet(model: ProfileViewModel, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current
    var check by remember { mutableStateOf<Attempt<AccountDeletionCheck>?>(null) }
    var typed by remember { mutableStateOf("") }
    var isDeleting by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var archiving by remember { mutableStateOf<AccountDeletionCheck.KametiRef?>(null) }
    val word = stringResource(R.string.shell_android_delete_word)

    suspend fun load() {
        check = null
        check = model.deletionCheck()
    }
    LaunchedEffect(Unit) { load() }

    KBottomSheet(stringResource(R.string.shell_delete_account), onDismiss, expanded = true, dismissDisabled = isDeleting) { close ->
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).kDismissesKeyboard()
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            when (val result = check) {
                null -> Box(Modifier.fillMaxWidth().padding(vertical = KSpace.xxl), contentAlignment = Alignment.Center) { KSpinner() }
                is Attempt.Failed -> {
                    KText(result.failure.userMessage(), KTextToken.body, color = KColors.negative)
                    KButton(stringResource(R.string.shell_try_again), onClick = { scope.launch { load() } }, style = KButtonStyle.Secondary)
                }
                is Attempt.Success -> if (!result.value.canDelete) {
                    // Blocked: other people's money is still being recorded.
                    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
                        KIcon(KIcons.lockFilled, tint = KColors.warning)
                        KText(stringResource(R.string.shell_you_still_run_a_kameti), KTextToken.title, color = KColors.warning)
                    }
                    KText(stringResource(R.string.shell_other_peoples_money_is_still_being_recorded_in), KTextToken.body, color = KColors.textSecondary)
                    Group {
                        val blocking = result.value.blockingKametis
                        blocking.forEachIndexed { index, kameti ->
                            Row(
                                Modifier.padding(horizontal = KSpace.lg, vertical = KSpace.md),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                KText(kameti.name, KTextToken.bodyStrong, modifier = Modifier.weight(1f))
                                KTonalButton(stringResource(R.string.shell_archive), onClick = { archiving = kameti }, style = KTonalStyle.Neutral)
                            }
                            if (index < blocking.size - 1) KDivider(Modifier.padding(horizontal = KSpace.lg))
                        }
                    }
                    KButton(stringResource(R.string.shell_ok), onClick = close, style = KButtonStyle.Secondary)
                } else {
                    val allowed = result.value
                    KText(stringResource(R.string.shell_this_cant_be_undone), KTextToken.title, color = KColors.negative)
                    Group {
                        Column(Modifier.padding(KSpace.lg), verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
                            Point(KIcons.trash, stringResource(R.string.shell_your_sign_in_and_profile_are_deleted))
                            if (allowed.draftsToDelete.isNotEmpty()) {
                                Point(
                                    KIcons.editSetup,
                                    if (allowed.draftsToDelete.size == 1) {
                                        stringResource(R.string.shell_1_draft_kameti_is_deleted)
                                    } else {
                                        stringResource(R.string.shell_n_draft_kametis_are_deleted, allowed.draftsToDelete.size)
                                    },
                                )
                            }
                            if (allowed.contactsToDelete > 0) {
                                Point(KIcons.people, stringResource(R.string.shell_your_n_saved_people_are_deleted, allowed.contactsToDelete))
                            }
                            if (allowed.membershipsToUnlink > 0) {
                                Point(
                                    KIcons.swap,
                                    stringResource(R.string.shell_youre_removed_from_the_app_in_n_kametis, allowed.membershipsToUnlink),
                                )
                            }
                            if (allowed.ownedKametisKept.isNotEmpty()) {
                                Point(KIcons.archive, stringResource(R.string.shell_your_past_kametis_stay_for_their_members_shown))
                            }
                        }
                    }
                    KTextField(
                        typed, { typed = it }, title = stringResource(R.string.shell_type_s_to_confirm, word), placeholder = word,
                        capitalization = KeyboardCapitalization.Characters, imeAction = ImeAction.Done,
                    )
                    FailureLine(failure)
                    KButton(
                        stringResource(R.string.shell_delete_my_account),
                        onClick = {
                            focus.clearFocus()
                            isDeleting = true
                            failure = null
                            scope.launch {
                                val deleteFailure = model.deleteAccount()
                                isDeleting = false
                                if (deleteFailure != null) failure = deleteFailure else close()
                            }
                        },
                        style = KButtonStyle.Destructive,
                        enabled = typed.trim().uppercase() == word, isLoading = isDeleting,
                    )
                }
            }
        }
    }

    archiving?.let { kameti ->
        KConfirmSheet(
            title = stringResource(R.string.shell_archive_s, kameti.name),
            confirmTitle = stringResource(R.string.shell_archive),
            onDismiss = { archiving = null },
            onConfirm = {
                val archiveFailure = model.archiveKameti(kameti.id)
                load()
                if (archiveFailure == null) {
                    KConfirmOutcome.Dismiss
                } else {
                    KConfirmOutcome.Result(
                        KSheetMessage(
                            context.getString(R.string.shell_couldnt_archive_this_kameti), archiveFailure.userMessage(context),
                            KSheetMessage.Tone.Error,
                        ),
                    )
                }
            },
            message = stringResource(R.string.shell_it_becomes_read_only_for_you_and_every),
            isDestructive = true,
        )
    }
}

@Composable
private fun Point(icon: ImageVector, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
        KIcon(icon)
        KText(text, KTextToken.body, modifier = Modifier.weight(1f))
    }
}

/** "Know when it matters" (board AN-4): asked once, soon after signing in. */
@Composable
internal fun PushPermissionSheet(onAllow: () -> Unit, onDismiss: () -> Unit) {
    KBottomSheet(title = "", onDismiss = onDismiss, expanded = true) { close ->
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(horizontal = KSpace.xl).padding(bottom = KSpace.lg),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            Box(Modifier.size(56.dp).background(KColors.brandSubtle, RoundedCornerShape(16.dp)), contentAlignment = Alignment.Center) {
                KIcon(KIcons.bell, tint = KColors.brand, size = 28.dp)
            }
            KText(stringResource(R.string.shell_know_when_it_matters), KTextToken.titleLg)
            KText(stringResource(R.string.shell_kameti_tells_you_when_a_payment_is_due), KTextToken.body, color = KColors.textSecondary)
            Column(verticalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                Example(KIcons.check, stringResource(R.string.shell_office_kameti), stringResource(R.string.shell_hira_paid_rs_50_000_for_november))
                Example(
                    KIcons.personFilled, stringResource(R.string.shell_office_kameti),
                    stringResource(R.string.shell_muhammad_hassan_wants_to_join_tap_to_review),
                )
                Example(KIcons.clock, stringResource(R.string.shell_family_kameti), stringResource(R.string.shell_rs_25_000_is_due_by_the_10th))
            }
            KButton(
                stringResource(R.string.shell_turn_on_notifications),
                onClick = {
                    onAllow()
                    close()
                },
            )
            KButton(stringResource(R.string.shell_not_now), onClick = close, style = KButtonStyle.Secondary)
        }
    }
}

@Composable
private fun Example(icon: ImageVector, title: String, body: String) {
    Row(
        Modifier.fillMaxWidth().background(KColors.surface, RoundedCornerShape(14.dp)).padding(KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
    ) {
        Box(Modifier.size(30.dp).background(KColors.brand, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
            KIcon(icon, tint = KColors.textOnBrand, size = 16.dp)
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            KText(title, KTextToken.bodyStrong)
            KText(body, KTextToken.bodySm)
        }
    }
}
