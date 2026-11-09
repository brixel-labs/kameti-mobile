import 'package:kameti/core/money/money.dart';
import 'package:kameti/core/result/failure.dart';
import 'package:kameti/core/result/result.dart';
import 'package:kameti/core/time/kameti_clock.dart';
import 'package:kameti/features/kameti/data/kameti_providers.dart';
import 'package:kameti/features/kameti/domain/kameti_models.dart';
import 'package:kameti/features/kameti/domain/kameti_repository.dart';
import 'package:kameti/features/kameti/presentation/create/create_wizard_state.dart';
import 'package:kameti/features/ledger/domain/kameti_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_wizard_controller.g.dart';

/// "Now" for the wizard's default first month. Tests override it.
@riverpod
KametiClock createWizardClock(Ref ref) => KametiClock();

/// Kameti name length (FR-10).
const nameMinLength = 3;
const nameMaxLength = 40;

/// Drives the create-kameti wizard (board AC-1…AC-6, FR-10–FR-12).
///
/// Step 1 creates the draft on the server (`createKameti`); later saves
/// update it (`updateKametiDraft`) and use the real kameti id. Every write
/// returns the [Failure] to show, or null on success, and invalidates the
/// kameti providers it touched.
@riverpod
class CreateWizard extends _$CreateWizard {
  @override
  CreateWizardState build() => CreateWizardState(
    startMonth: ref.read(createWizardClockProvider).currentMonth(),
  );

  KametiRepository get _repo => ref.read(kametiRepositoryProvider);

  // ---- Local edits (no server call) ----

  void setName(String name) => state = state.copyWith(name: name);

  void setSlotAmount(Money? amount) =>
      state = state.copyWith(slotAmount: amount);

  void setMonths(int months) =>
      state = state.copyWith(months: months.clamp(minMonths, maxMonths));

  void setStartMonth(DateTime month) =>
      state = state.copyWith(startMonth: month);

  /// Also drops reminder days after the new due day.
  void setDueDay(int day) => state = state.copyWith(
    dueDay: day,
    reminderDays: [
      for (final d in state.reminderDays)
        if (d <= day) d,
    ],
  );

  void toggleReminderDay(int day) {
    final days = {...state.reminderDays};
    if (!days.remove(day)) days.add(day);
    state = state.copyWith(reminderDays: days.toList()..sort());
  }

  void setMaxSlotsPerMember(int value) =>
      state = state.copyWith(maxSlotsPerMember: value.clamp(1, maxSlotsLimit));

  void goTo(WizardStep step) =>
      state = state.copyWith(step: step, editingSlotId: null);

  void back() {
    if (state.editingSlotId != null) {
      state = state.copyWith(editingSlotId: null);
    } else if (state.step.index > 0) {
      goTo(WizardStep.values[state.step.index - 1]);
    }
  }

  void editSlot(String? slotId) =>
      state = state.copyWith(editingSlotId: slotId);

  // ---- Validation for step 1 ----

  bool get nameValid {
    final length = state.name.trim().length;
    return length >= nameMinLength && length <= nameMaxLength;
  }

  bool get slotAmountValid {
    final amount = state.slotAmount;
    return amount != null &&
        amount >= const Money(1000) &&
        amount.isMultipleOf(const Money(1000));
  }

  // ---- Server writes ----

  /// Step 1: creates the draft, or updates it when it already exists.
  Future<Failure?> saveBasics() async {
    if (!nameValid || !slotAmountValid) return null;
    final s = state;
    final id = s.kametiId;
    return await _write(
      () => id == null
          ? _repo.createKameti(
              name: s.name.trim(),
              startMonth: s.startMonth,
              months: s.months,
              slotAmount: s.slotAmount!,
              dueDay: s.dueDay,
              reminderDays: s.reminderDays,
              maxSlotsPerMember: s.maxSlotsPerMember,
            )
          : _repo.updateKametiDraft(
              id,
              name: s.name.trim(),
              startMonth: s.startMonth,
              months: s.months,
              slotAmount: s.slotAmount,
            ),
      onOk: (kameti) {
        state = state.copyWith(kametiId: kameti.id, step: WizardStep.dates);
        _invalidateKameti(kameti.id, slots: true);
      },
    );
  }

  /// Step 2: due day, reminder days and the slot limit.
  Future<Failure?> saveDates() async {
    final id = state.kametiId;
    if (id == null) return null;
    final s = state;
    return await _write(
      () => _repo.updateKametiDraft(
        id,
        dueDay: s.dueDay,
        reminderDays: s.reminderDays,
        maxSlotsPerMember: s.maxSlotsPerMember,
      ),
      onOk: (_) {
        state = state.copyWith(step: WizardStep.members);
        _invalidateKameti(id);
      },
    );
  }

  Future<Failure?> addMember({required String name, String? email}) async {
    final id = state.kametiId;
    if (id == null) return null;
    final cleanEmail = (email?.trim().isEmpty ?? true) ? null : email!.trim();
    return await _write(
      () => _repo.addMember(id, name: name.trim(), email: cleanEmail),
      onOk: (member) {
        state = state.copyWith(
          emails: {...state.emails, member.id: cleanEmail},
        );
        ref.invalidate(kametiMembersProvider(id));
      },
    );
  }

  /// "I'm also a member": adds or removes the owner's own member row.
  Future<Failure?> setSelfMember({required bool include}) async {
    final id = state.kametiId;
    if (id == null) return null;
    final selfId = state.selfMemberId;
    if (include && selfId == null) {
      return await _write(
        () => _repo.addMember(id, isSelf: true),
        onOk: (member) {
          state = state.copyWith(selfMemberId: member.id);
          ref.invalidate(kametiMembersProvider(id));
        },
      );
    }
    if (!include && selfId != null) return await removeMember(selfId);
    return null;
  }

  Future<Failure?> removeMember(String memberId) async {
    final id = state.kametiId;
    if (id == null) return null;
    return await _write(
      () => _repo.removeMember(memberId),
      onOk: (_) {
        state = state.copyWith(
          selfMemberId: state.selfMemberId == memberId
              ? null
              : state.selfMemberId,
          emails: {...state.emails}..remove(memberId),
        );
        ref
          ..invalidate(kametiMembersProvider(id))
          ..invalidate(kametiSharesProvider(id));
      },
    );
  }

  /// Saves one slot's split and closes the split editor.
  Future<Failure?> saveSlotShares(
    String slotId,
    List<ShareInput> shares,
  ) async {
    final id = state.kametiId!;
    return await _write(
      () => _repo.setSlotShares(slotId, shares),
      onOk: (_) {
        state = state.copyWith(editingSlotId: null);
        ref.invalidate(kametiSharesProvider(id));
      },
    );
  }

  /// Step 5: saves the payout order (only when it changed) and moves on.
  Future<Failure?> saveOrder({
    required List<String> original,
    required List<String> ordered,
  }) async {
    final id = state.kametiId!;
    var same = original.length == ordered.length;
    for (var i = 0; same && i < original.length; i++) {
      same = original[i] == ordered[i];
    }
    if (same) {
      goTo(WizardStep.review);
      return null;
    }
    return await _write(
      () => _repo.reorderSlots(id, ordered),
      onOk: (_) {
        state = state.copyWith(step: WizardStep.review);
        ref.invalidate(kametiSlotsProvider(id));
      },
    );
  }

  /// Step 6: asks the server to start (it re-checks FR-12).
  /// Returns the kameti id on success.
  Future<Result<String>> start() async {
    final id = state.kametiId!;
    if (state.busy) return const Err(UnknownFailure('busy'));
    state = state.copyWith(busy: true);
    final result = await _repo.startKameti(id);
    if (ref.mounted) {
      state = state.copyWith(busy: false);
      if (result.isOk) _invalidateKameti(id, slots: true);
    }
    return switch (result) {
      Ok(:final value) => Ok(value.id),
      Err(:final failure) => Err(failure),
    };
  }

  /// Draft is already on the server: refresh lists so Home shows it.
  void finishAsDraft() {
    final id = state.kametiId;
    if (id != null) _invalidateKameti(id);
  }

  Future<Failure?> _write<T>(
    Future<Result<T>> Function() call, {
    required void Function(T value) onOk,
  }) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true);
    final result = await call();
    if (!ref.mounted) return null;
    state = state.copyWith(busy: false);
    switch (result) {
      case Ok(:final value):
        onOk(value);
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  void _invalidateKameti(String id, {bool slots = false}) {
    ref
      ..invalidate(myKametisProvider)
      ..invalidate(kametiProvider(id));
    if (slots) {
      ref
        ..invalidate(kametiSlotsProvider(id))
        ..invalidate(kametiSharesProvider(id));
    }
  }
}

/// The active shares of [slotId], in the order they were added.
List<Share> sharesOfSlot(List<Share> shares, String slotId) => [
  for (final s in shares)
    if (s.slotId == slotId && s.effectiveToMonth == null) s,
];

/// The draft as a ledger plan, for `validatePlanForStart` (FR-12).
KametiPlan planOf({
  required int months,
  required Money slotAmount,
  required int maxSlotsPerMember,
  required List<Slot> slots,
  required List<Share> shares,
}) => KametiPlan(
  months: months,
  slotAmount: slotAmount,
  maxSlotsPerMember: maxSlotsPerMember,
  slots: [
    for (final slot in slots)
      SlotPlan(
        payoutMonth: slot.payoutMonthIndex,
        shares: [
          for (final s in sharesOfSlot(shares, slot.id))
            SharePlan(memberId: s.memberId, monthly: s.monthlyAmount),
        ],
      ),
  ],
);
