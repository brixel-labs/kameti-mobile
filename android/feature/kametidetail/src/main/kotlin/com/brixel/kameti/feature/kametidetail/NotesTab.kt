package com.brixel.kameti.feature.kametidetail

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.Note
import com.brixel.kameti.domain.NoteTarget
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.ui.KBottomSheet
import com.brixel.kameti.ui.KButton
import com.brixel.kameti.ui.KChip
import com.brixel.kameti.ui.KColors
import com.brixel.kameti.ui.KConfirmSheet
import com.brixel.kameti.ui.KIcon
import com.brixel.kameti.ui.KIconButton
import com.brixel.kameti.ui.KIcons
import com.brixel.kameti.ui.KMessageCard
import com.brixel.kameti.ui.KOption
import com.brixel.kameti.ui.KPill
import com.brixel.kameti.ui.KSegmented
import com.brixel.kameti.ui.KSpace
import com.brixel.kameti.ui.KSpinner
import com.brixel.kameti.ui.KSwipeAction
import com.brixel.kameti.ui.KSwipeRow
import com.brixel.kameti.ui.KText
import com.brixel.kameti.ui.KTextField
import com.brixel.kameti.ui.KTextStyle
import com.brixel.kameti.ui.KTextToken
import com.brixel.kameti.ui.kDismissesKeyboard
import com.brixel.kameti.ui.userMessage
import kotlinx.coroutines.launch

/**
 * Notes (board A2 · Notes tab, FR-70 to FR-72): All / Private / Shared,
 * search, and one card per note. Swipe a note left to edit, share or delete.
 */
@Composable
internal fun NotesTab(
    data: KametiDetailData,
    model: KametiDetailViewModel,
    /**
     * The one note whose swipe actions are showing (owned by the owner's
     * tabs, so a tab change closes it).
     */
    openNote: String?,
    onOpenNoteChange: (String?) -> Unit,
    /** Archived kametis: notes show without swipe actions. */
    isReadOnly: Boolean = false,
) {
    val strings = rememberStrings()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var filter by rememberSaveable { mutableStateOf(NoteLogic.Filter.All) }
    var search by rememberSaveable { mutableStateOf("") }
    var isSearching by rememberSaveable { mutableStateOf(false) }
    var editing by remember { mutableStateOf<Note?>(null) }
    var deleting by remember { mutableStateOf<Note?>(null) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val list = NoteLogic.visible(data.notes, filter, if (isSearching) search else "", data, strings)

    fun toggleVisibility(note: Note) {
        scope.launch {
            val next = if (note.visibility == NoteVisibility.Private) NoteVisibility.Shared else NoteVisibility.Private
            failure = model.updateNote(note.id, body = null, visibility = next)
        }
    }

    Column(verticalArrangement = Arrangement.spacedBy(KSpace.md)) {
        if (isSearching) {
            KTextField(
                search, { search = it }, placeholder = stringResource(R.string.detail_search_notes),
                imeAction = ImeAction.Search, leading = { KIcon(KIcons.search) },
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
            KChip(
                stringResource(R.string.detail_all_n, NoteLogic.count(data.notes, NoteLogic.Filter.All)),
                filter == NoteLogic.Filter.All, onClick = { filter = NoteLogic.Filter.All },
            )
            KChip(
                stringResource(R.string.detail_private_n, NoteLogic.count(data.notes, NoteLogic.Filter.Private)),
                filter == NoteLogic.Filter.Private, onClick = { filter = NoteLogic.Filter.Private },
            )
            KChip(
                stringResource(R.string.detail_shared_n, NoteLogic.count(data.notes, NoteLogic.Filter.Shared)),
                filter == NoteLogic.Filter.Shared, onClick = { filter = NoteLogic.Filter.Shared },
            )
            Box(Modifier.weight(1f))
            KIconButton(
                if (isSearching) KIcons.close else KIcons.search,
                stringResource(if (isSearching) R.string.detail_close_search else R.string.detail_search_notes),
                onClick = { isSearching = !isSearching },
                tint = KColors.textPrimary,
            )
        }
        FailureLine(failure)
        if (list.isEmpty()) {
            KMessageCard(
                title = stringResource(if (data.notes.isEmpty()) R.string.detail_no_notes_yet else R.string.detail_no_matching_notes),
                message = stringResource(
                    if (data.notes.isEmpty()) {
                        R.string.detail_keep_track_of_promises_cash_handovers_and_anything
                    } else {
                        R.string.detail_try_another_filter_or_search
                    },
                ),
                icon = KIcons.note,
            )
        } else {
            for (note in list) {
                if (isReadOnly) {
                    NoteCard(note, data)
                } else {
                    val isPrivate = note.visibility == NoteVisibility.Private
                    KSwipeRow(
                        id = note.id, openRow = openNote, onOpenRowChange = onOpenNoteChange,
                        actions = listOf(
                            KSwipeAction(stringResource(R.string.detail_edit), KIcons.edit, KColors.brand) { editing = note },
                            KSwipeAction(
                                stringResource(if (isPrivate) R.string.detail_share_with_the_people_involved else R.string.detail_make_private),
                                if (isPrivate) KIcons.peopleFilled else KIcons.lockFilled, KColors.info,
                            ) { toggleVisibility(note) },
                            KSwipeAction(stringResource(R.string.detail_delete), KIcons.trashFilled, KColors.negative) { deleting = note },
                        ),
                    ) {
                        NoteCard(note, data)
                    }
                }
            }
        }
    }

    editing?.let { note -> EditNoteSheet(note, model) { editing = null } }
    deleting?.let { note ->
        KConfirmSheet(
            title = stringResource(R.string.detail_delete_this_note),
            confirmTitle = stringResource(R.string.detail_delete),
            onDismiss = { deleting = null },
            onConfirm = {
                confirmOutcome(model.deleteNote(note.id), context.getString(R.string.detail_couldnt_delete_this_note), context)
            },
            message = stringResource(R.string.detail_its_removed_for_everyone_who_could_see_it),
            isDestructive = true,
        )
    }
}

/** One note: what it's about, private or shared, the day, then the text. */
@Composable
internal fun NoteCard(note: Note, data: KametiDetailData, modifier: Modifier = Modifier) {
    val strings = rememberStrings()
    val shape = RoundedCornerShape(14.dp)
    Column(
        modifier.fillMaxWidth().background(KColors.surface, shape).border(1.dp, KColors.border, shape).padding(KSpace.lg),
        verticalArrangement = Arrangement.spacedBy(KSpace.sm),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.CenterVertically) {
            KText(
                "@ ${NoteLogic.targetLabel(note, data, strings)}",
                KTextStyle(size = 12f, weight = FontWeight.SemiBold),
                modifier = Modifier
                    .weight(1f, fill = false)
                    .background(KColors.brandSubtle, RoundedCornerShape(6.dp))
                    .padding(horizontal = KSpace.sm, vertical = 3.dp),
                color = KColors.onBrandSubtle, maxLines = 1,
            )
            VisibilityTag(note.visibility)
            Box(Modifier.weight(1f))
            KText(
                NoteLogic.dayText(note.createdAt, data.today, strings) +
                    if (note.isEdited) stringResource(R.string.detail_edited) else "",
                KTextToken.caption, color = KColors.textSecondary, maxLines = 1,
            )
        }
        KText(note.body, KTextToken.body)
        val author = note.authorName
        if (!data.isOwner && author != null) {
            KText(stringResource(R.string.detail_from_s, author), KTextToken.caption, color = KColors.textSecondary)
        }
    }
}

@Composable
internal fun VisibilityTag(visibility: NoteVisibility) {
    when (visibility) {
        NoteVisibility.Private ->
            KPill(stringResource(R.string.detail_private), KColors.textSecondary, KColors.surfaceSunken, icon = KIcons.lockFilled)
        NoteVisibility.Shared ->
            KPill(stringResource(R.string.detail_shared), KColors.info, KColors.infoSubtle, icon = KIcons.peopleFilled)
    }
}

/**
 * The composer pinned under the Notes tab (board A2 · Notes): what the note
 * is about, private or shared, the text and Save.
 */
@Composable
internal fun NoteComposer(data: KametiDetailData, model: KametiDetailViewModel, modifier: Modifier = Modifier) {
    val strings = rememberStrings()
    val scope = rememberCoroutineScope()
    var target by remember { mutableStateOf(NoteLogic.kametiTarget(strings)) }
    var visibility by remember { mutableStateOf(NoteVisibility.Private) }
    var text by rememberSaveable { mutableStateOf("") }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    var pickingTarget by remember { mutableStateOf(false) }
    val trimmed = text.trim()
    val isPrivate = visibility == NoteVisibility.Private

    Column(modifier.fillMaxWidth().background(KColors.surface)) {
        Box(Modifier.fillMaxWidth().heightIn(min = 1.dp).background(KColors.border))
        Column(
            Modifier.padding(horizontal = KSpace.lg).padding(top = KSpace.md, bottom = KSpace.sm),
            verticalArrangement = Arrangement.spacedBy(KSpace.sm),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm)) {
                SmallPill("@ ${target.label}", KIcons.chevronDown, iconTrailing = true) { pickingTarget = true }
                val switches = stringResource(R.string.detail_switches_between_private_and_shared)
                SmallPill(
                    stringResource(if (isPrivate) R.string.detail_private else R.string.detail_shared),
                    if (isPrivate) KIcons.lockFilled else KIcons.peopleFilled,
                    modifier = Modifier.semantics { stateDescription = switches },
                ) {
                    visibility = if (isPrivate) NoteVisibility.Shared else NoteVisibility.Private
                }
            }
            AnimatedVisibility(!isPrivate) {
                KText(
                    when (target.type) {
                        NoteTarget.Kameti -> stringResource(R.string.detail_every_joined_member_will_see_this_note)
                        NoteTarget.Member -> stringResource(R.string.detail_s_will_see_this_note, target.label)
                        NoteTarget.Slot -> stringResource(R.string.detail_the_people_in_the_s_slot_will_see, target.label)
                        NoteTarget.Payment, NoteTarget.Payout -> stringResource(R.string.detail_the_person_its_about_will_see_this_note)
                    },
                    KTextToken.caption, color = KColors.info,
                )
            }
            failure?.let { KText(it.userMessage(), KTextToken.caption, color = KColors.negative) }
            Row(horizontalArrangement = Arrangement.spacedBy(KSpace.sm), verticalAlignment = Alignment.Bottom) {
                KTextField(
                    text, { text = it }, Modifier.weight(1f), placeholder = stringResource(R.string.detail_write_a_note),
                    imeAction = ImeAction.Default,
                )
                val canSave = trimmed.isNotEmpty() && !isBusy
                val label = stringResource(R.string.detail_save_note)
                Box(
                    Modifier
                        .size(48.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(if (trimmed.isEmpty()) KColors.textTertiary else KColors.brand)
                        .clickable(enabled = canSave, role = Role.Button) {
                            isBusy = true
                            failure = null
                            scope.launch {
                                val result = model.addNote(NewNote(trimmed, visibility, target.type, target.id))
                                isBusy = false
                                if (result != null) failure = result else text = ""
                            }
                        }
                        .semantics { contentDescription = label },
                    contentAlignment = Alignment.Center,
                ) {
                    if (isBusy) KSpinner(color = KColors.textOnBrand) else KIcon(KIcons.sendFilled, tint = KColors.textOnBrand)
                }
            }
        }
    }

    if (pickingTarget) {
        KBottomSheet(stringResource(R.string.detail_note), onDismiss = { pickingTarget = false }) { close ->
            val members = remember { NoteLogic.memberTargets(data) }
            val slots = remember { NoteLogic.slotTargets(data, strings) }

            @Composable
            fun row(item: NoteLogic.Target) {
                Row(
                    Modifier.fillMaxWidth().clickable(role = Role.RadioButton) {
                        target = item
                        close()
                    }.padding(horizontal = KSpace.xl, vertical = KSpace.md),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    KText(item.label, KTextToken.body, modifier = Modifier.weight(1f))
                    if (item == target) KIcon(KIcons.check, tint = KColors.brand)
                }
            }
            LazyColumn(Modifier.weight(1f, fill = false)) {
                item { row(NoteLogic.kametiTarget(strings)) }
                item { CardLabel(stringResource(R.string.detail_members), Modifier.padding(horizontal = KSpace.xl, vertical = KSpace.sm)) }
                items(members, key = { "m" + it.id }) { row(it) }
                item { CardLabel(stringResource(R.string.detail_months), Modifier.padding(horizontal = KSpace.xl, vertical = KSpace.sm)) }
                items(slots, key = { "s" + it.id }) { row(it) }
            }
        }
    }
}

@Composable
private fun SmallPill(
    title: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    iconTrailing: Boolean = false,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(8.dp)
    Row(
        modifier
            .heightIn(min = 32.dp)
            .clip(shape)
            .background(KColors.background)
            .border(1.dp, KColors.border, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = KSpace.md),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (!iconTrailing) KIcon(icon, tint = KColors.textPrimary, size = 14.dp)
        KText(title, KTextStyle(size = 13f, weight = FontWeight.Medium), maxLines = 1)
        if (iconTrailing) KIcon(icon, tint = KColors.textPrimary, size = 14.dp)
    }
}

/** Edit a note's text and who can see it. */
@Composable
private fun EditNoteSheet(note: Note, model: KametiDetailViewModel, onDismiss: () -> Unit) {
    var text by remember { mutableStateOf(note.body) }
    var visibility by remember { mutableStateOf(note.visibility) }
    var isBusy by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<Failure?>(null) }
    val scope = rememberCoroutineScope()
    val trimmed = text.trim()
    val changed = trimmed != note.body || visibility != note.visibility

    KBottomSheet(stringResource(R.string.detail_edit_note), onDismiss, dismissDisabled = isBusy) { close ->
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).kDismissesKeyboard()
                .padding(horizontal = KSpace.xl).padding(top = KSpace.xxs, bottom = KSpace.xl),
            verticalArrangement = Arrangement.spacedBy(KSpace.lg),
        ) {
            KTextField(text, { text = it }, placeholder = stringResource(R.string.detail_note), lines = 4)
            KSegmented(
                listOf(
                    KOption(NoteVisibility.Private, stringResource(R.string.detail_private)),
                    KOption(NoteVisibility.Shared, stringResource(R.string.detail_shared)),
                ),
                visibility, { visibility = it },
            )
            KText(
                stringResource(
                    if (visibility == NoteVisibility.Private) {
                        R.string.detail_only_you_can_see_private_notes
                    } else {
                        R.string.detail_the_members_this_note_is_about_can_see
                    },
                ),
                KTextToken.caption, color = KColors.textSecondary,
            )
            FailureLine(failure)
            KButton(
                stringResource(R.string.detail_save_note),
                onClick = {
                    isBusy = true
                    failure = null
                    scope.launch {
                        val result = model.updateNote(
                            note.id, body = trimmed.takeIf { it != note.body }, visibility = visibility.takeIf { it != note.visibility },
                        )
                        isBusy = false
                        if (result != null) failure = result else close()
                    }
                },
                enabled = changed && trimmed.isNotEmpty(), isLoading = isBusy,
            )
        }
    }
}
