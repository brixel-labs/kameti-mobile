package com.brixel.kameti.feature.createkameti

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.brixel.kameti.domain.Member
import com.brixel.kameti.ui.KAvatar
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KCheckbox
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmOutcome
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KDivider
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIconButton
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KRadius
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.subtitle
import com.brixel.kameti.ui.subtitleSmall
import com.brixel.kameti.ui.textSubtitle

private enum class MemberMode { FromPeople, NewPerson }

/** What was typed for a new person, and whether it can be added. */
internal object NewPersonRules {
    fun nameValid(name: String): Boolean = name.trim().isNotEmpty()

    fun emailValid(email: String): Boolean {
        val trimmed = email.trim()
        return trimmed.isEmpty() || ("@" in trimmed && "." in trimmed && " " !in trimmed)
    }

    /** Same rule as the member sheet: digits, spaces, dashes, one leading +, 7 to 15 digits. */
    fun phoneValid(phone: String): Boolean {
        val value = phone.trim()
        if (value.isEmpty()) return true
        if (!value.all { it in "+0123456789 -" } || "+" in value.drop(1)) return false
        return value.count { it.isDigit() } in 7..15
    }
}

/**
 * Step 3 (AC-3): who is in. Pick from "My people" (the owner's saved
 * contacts) or add someone new; anyone added is saved to My people for next
 * time. Invites go out after the kameti starts.
 */
@Composable
internal fun MembersStep(state: WizardState, model: CreateWizardViewModel) {
    var mode by rememberSaveable { mutableStateOf(MemberMode.NewPerson) }
    var chosenMode by rememberSaveable { mutableStateOf(false) }
    var removing by remember { mutableStateOf<Member?>(null) }

    LaunchedEffect(Unit) {
        model.loadContacts()
        // Start on My people only when there is someone saved to pick.
        if (!chosenMode && model.state.value.availableContacts.isNotEmpty()) mode = MemberMode.FromPeople
    }

    Column(Modifier.fillMaxSize()) {
        StepBody(Modifier.weight(1f)) {
            WizardHeading(
                stringResource(R.string.create_whos_in),
                stringResource(R.string.create_add_everyone_who_pays_invites_go_out_after),
            )
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.md)) {
                ModeButton(stringResource(R.string.create_from_my_people), KIcons.people, mode == MemberMode.FromPeople, Modifier.weight(1f)) {
                    chosenMode = true
                    mode = MemberMode.FromPeople
                }
                ModeButton(stringResource(R.string.create_add_new_person), KIcons.personAdd, mode == MemberMode.NewPerson, Modifier.weight(1f)) {
                    chosenMode = true
                    mode = MemberMode.NewPerson
                }
            }
            when (mode) {
                MemberMode.NewPerson -> NewPersonCard(model)
                MemberMode.FromPeople -> PeopleCard(state, model) {
                    chosenMode = true
                    mode = MemberMode.NewPerson
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                KText(
                    stringResource(R.string.create_n_added, state.members.size), KTextToken.bodyStrong,
                    modifier = Modifier.weight(1f), color = KColors.textSecondary,
                )
                val me = state.selfMember
                KCheckbox(
                    isOn = me != null,
                    // Ignored while my own row is still saving.
                    onChange = { included -> if (me == null || !state.isPending(me)) model.launch { setSelfMember(included) } },
                ) {
                    KText(stringResource(R.string.create_im_also_a_member), KTextToken.body)
                }
            }
            if (state.members.isEmpty()) {
                KText(
                    stringResource(R.string.create_add_the_people_who_pay_into_this_kameti), KTextToken.subtitle,
                    modifier = Modifier.fillMaxWidth().padding(vertical = KSpace.lg),
                    color = KColors.textSubtitle, textAlign = TextAlign.Center,
                )
            } else {
                Column {
                    state.members.forEach { member ->
                        key(state.rowKey(member)) {
                            MemberRow(member, state, divider = member.id != state.members.last().id) { removing = member }
                        }
                    }
                }
            }
        }
        WizardFooter(
            stringResource(R.string.create_next_slots), action = { model.goTo(WizardStep.Slots) },
            isEnabled = state.members.isNotEmpty(), isLoading = state.isSavingMembers, onBack = { model.back() },
        )
    }

    removing?.let { member ->
        KConfirmSheet(
            title = stringResource(R.string.create_remove_this_person),
            confirmTitle = stringResource(R.string.create_remove),
            onDismiss = { removing = null },
            onConfirm = {
                // Optimistic: the row goes at once and saves behind it.
                model.launch { removeMember(member.id) }
                KConfirmOutcome.Dismiss
            },
            message = stringResource(R.string.create_s_will_be_taken_out_of_this_kameti, member.name),
            isDestructive = true,
        )
    }
}

@Composable
private fun ModeButton(title: String, icon: ImageVector, isOn: Boolean, modifier: Modifier, onClick: () -> Unit) {
    val shape = RoundedCornerShape(KRadius.input)
    val foreground = if (isOn) KColors.onBrandSubtle else KColors.textPrimary
    Row(
        modifier
            .heightIn(min = 52.dp)
            .clip(shape)
            .background(if (isOn) KColors.brandSubtle else KColors.surface)
            .border(if (isOn) 1.5.dp else 1.dp, if (isOn) KColors.brand else KColors.border, shape)
            .clickable(role = Role.Tab, onClick = onClick)
            .semantics { selected = isOn }
            .padding(horizontal = KSpace.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KSpace.xs, Alignment.CenterHorizontally),
    ) {
        KIcon(icon, tint = foreground, size = 18.dp)
        KText(title, KTextToken.bodyStrong, color = foreground, maxLines = 1)
    }
}

/** The card both modes sit in: white with a brand border. */
@Composable
private fun ModeCard(content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(KRadius.card)
    Column(
        Modifier.fillMaxWidth().background(KColors.surface, shape).border(1.5.dp, KColors.brand, shape).padding(KSpace.lg),
        verticalArrangement = Arrangement.spacedBy(KSpace.md),
    ) { content() }
}

@Composable
private fun NewPersonCard(model: CreateWizardViewModel) {
    var name by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var phone by rememberSaveable { mutableStateOf("") }
    var submitted by rememberSaveable { mutableStateOf(false) }
    val nameValid = NewPersonRules.nameValid(name)

    fun add() {
        submitted = true
        if (!nameValid || !NewPersonRules.emailValid(email) || !NewPersonRules.phoneValid(phone)) return
        val typed = Triple(name, email, phone)
        name = ""; email = ""; phone = ""; submitted = false
        model.launch { addMember(typed.first, typed.second, typed.third) }
    }

    ModeCard {
        KText(stringResource(R.string.create_new_person), KTextToken.bodyStrong, color = KColors.textSecondary)
        KTextField(
            name, { name = it }, placeholder = stringResource(R.string.create_name),
            error = if (submitted && !nameValid) stringResource(R.string.create_enter_a_name) else null,
            capitalization = KeyboardCapitalization.Words,
        )
        KTextField(
            email, { email = it }, placeholder = stringResource(R.string.create_email_for_the_invite_optional),
            error = if (submitted && !NewPersonRules.emailValid(email)) {
                stringResource(R.string.create_enter_a_valid_email_or_leave_it_empty)
            } else {
                null
            },
            keyboardType = KeyboardType.Email, capitalization = KeyboardCapitalization.None,
        )
        KTextField(
            phone, { phone = it }, placeholder = stringResource(R.string.create_phone_for_whatsapp_reminders_optional),
            error = if (submitted && !NewPersonRules.phoneValid(phone)) {
                stringResource(R.string.create_enter_a_valid_phone_number_or_leave_it)
            } else {
                null
            },
            keyboardType = KeyboardType.Phone, capitalization = KeyboardCapitalization.None,
            imeAction = ImeAction.Done, onImeAction = { add() },
        )
        KButton(
            if (nameValid) {
                stringResource(R.string.create_add_s, name.trim().substringBefore(" "))
            } else {
                stringResource(R.string.create_add_person)
            },
            onClick = { add() },
        )
    }
}

@Composable
private fun PeopleCard(state: WizardState, model: CreateWizardViewModel, onAddNew: () -> Unit) {
    val list = state.availableContacts
    ModeCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            KText(stringResource(R.string.create_my_people), KTextToken.bodyStrong, modifier = Modifier.weight(1f), color = KColors.textSecondary)
            if (list.isNotEmpty()) {
                KText(
                    stringResource(R.string.create_select_all), KTextToken.bodyStrong, color = KColors.brand,
                    modifier = Modifier.clip(RoundedCornerShape(KRadius.sm))
                        .clickable(role = Role.Button) { model.launch { addMembers(list) } }
                        .padding(KSpace.xs),
                )
            }
        }
        when {
            state.contacts.isEmpty() -> EmptyPeople(
                stringResource(R.string.create_no_saved_people_yet),
                stringResource(R.string.create_people_you_add_to_a_kameti_are_saved), onAddNew,
            )
            list.isEmpty() -> EmptyPeople(
                stringResource(R.string.create_everyone_is_already_in),
                stringResource(R.string.create_all_your_saved_people_are_in_this_kameti), onAddNew,
            )
            else -> Column {
                list.forEachIndexed { index, contact ->
                    // The whole row adds the person, not just the plus.
                    Row(
                        Modifier.fillMaxWidth()
                            .clickable(role = Role.Button) { model.launch { addMember(contact) } }
                            .padding(vertical = KSpace.sm),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(KSpace.md),
                    ) {
                        KAvatar(contact.name, colorIndex = contact.name.sumOf { it.code } % 6)
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            KText(contact.name, KTextToken.bodyStrong)
                            KText(
                                contact.email ?: stringResource(R.string.create_no_email),
                                KTextToken.subtitleSmall, color = KColors.textSubtitle,
                            )
                        }
                        KIcon(KIcons.plusCircleFilled, tint = KColors.brand, size = 26.dp)
                    }
                    if (index < list.size - 1) KDivider()
                }
            }
        }
    }
}

@Composable
private fun EmptyPeople(title: String, message: String, onAddNew: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().padding(vertical = KSpace.md),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        KText(title, KTextToken.bodyStrong)
        KText(message, KTextToken.subtitle, color = KColors.textSubtitle, textAlign = TextAlign.Center)
        KButton(stringResource(R.string.create_add_new_person), onAddNew, icon = KIcons.personAdd, expand = false)
    }
}

@Composable
private fun MemberRow(member: Member, state: WizardState, divider: Boolean, onRemove: () -> Unit) {
    val isMe = member.profileId != null
    Column {
        Row(
            Modifier.fillMaxWidth().padding(vertical = KSpace.md),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(KSpace.md),
        ) {
            KAvatar(member.name, colorIndex(member, state.members))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                KText(if (isMe) stringResource(R.string.create_you_s, member.name) else member.name, KTextToken.bodyStrong)
                val email = state.emails[member.id]
                when {
                    isMe -> KText(stringResource(R.string.create_owner), KTextToken.subtitleSmall, color = KColors.textSubtitle)
                    email != null -> KText(email, KTextToken.subtitleSmall, color = KColors.textSubtitle)
                    else -> KText(stringResource(R.string.create_no_email_cant_get_the_app_invite), KTextToken.caption, color = KColors.warning)
                }
            }
            // Fixed size, so the spinner and the ✕ swap without moving the row.
            Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                when {
                    state.isPending(member) -> KSpinner(size = 18.dp)
                    !isMe -> KIconButton(KIcons.close, stringResource(R.string.create_remove), onRemove)
                }
            }
        }
        if (divider) KDivider()
    }
}
