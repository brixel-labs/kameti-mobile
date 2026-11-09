import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kameti/core/money/money.dart';

part 'create_wizard_state.freezed.dart';

/// The six steps of the create-kameti wizard (FR-10).
enum WizardStep { basics, dates, members, slots, order, review }

/// Shortest and longest kameti, in months (REQUIREMENTS §3.2).
const minMonths = 2;
const maxMonths = 60;

/// Slots per member: per-kameti limit, max 6 (§3.2).
const maxSlotsLimit = 6;

/// What the create wizard holds while the owner moves between steps.
///
/// The kameti, its members, slots and shares live on the server as a draft
/// once step 1 is saved ([kametiId] is set). The basics and due-date
/// fields are kept here so Back and Next keep what was typed.
@freezed
abstract class CreateWizardState with _$CreateWizardState {
  const factory({
    required DateTime startMonth,
    @Default(WizardStep.basics) WizardStep step,
    String? kametiId,
    @Default('') String name,
    Money? slotAmount,
    @Default(12) int months,
    @Default(10) int dueDay,
    @Default([1, 5, 8, 10]) List<int> reminderDays,
    @Default(4) int maxSlotsPerMember,

    /// The owner's own member row, when "I'm also a member" is on.
    String? selfMemberId,

    /// Emails typed for members added in this wizard (null = none given).
    /// Members don't expose contact details, so this is display only.
    @Default(<String, String?>{}) Map<String, String?> emails,

    /// The slot open in the split editor (step 4), if any.
    String? editingSlotId,

    /// A write is in flight; buttons show a spinner and ignore taps.
    @Default(false) bool busy,
  }) = _CreateWizardState;

  const new _();

  /// 1-based step number for `KWizardProgress`.
  int get stepNumber => step.index + 1;

  /// The last month of the kameti (first month + N − 1).
  DateTime get endMonth =>
      DateTime.utc(startMonth.year, startMonth.month + months - 1);
}
