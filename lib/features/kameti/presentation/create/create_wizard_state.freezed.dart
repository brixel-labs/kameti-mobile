// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_wizard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateWizardState {

 DateTime get startMonth; WizardStep get step; String? get kametiId; String get name; Money? get slotAmount; int get months; int get dueDay; List<int> get reminderDays; int get maxSlotsPerMember;/// The owner's own member row, when "I'm also a member" is on.
 String? get selfMemberId;/// Emails typed for members added in this wizard (null = none given).
/// Members don't expose contact details, so this is display only.
 Map<String, String?> get emails;/// The slot open in the split editor (step 4), if any.
 String? get editingSlotId;/// A write is in flight; buttons show a spinner and ignore taps.
 bool get busy;
/// Create a copy of CreateWizardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateWizardStateCopyWith<CreateWizardState> get copyWith => _$CreateWizardStateCopyWithImpl<CreateWizardState>(this as CreateWizardState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreateWizardState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateWizardState&&(identical(other.startMonth, _this.startMonth) || other.startMonth == _this.startMonth)&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.slotAmount, _this.slotAmount) || other.slotAmount == _this.slotAmount)&&(identical(other.months, _this.months) || other.months == _this.months)&&(identical(other.dueDay, _this.dueDay) || other.dueDay == _this.dueDay)&&const DeepCollectionEquality().equals(other.reminderDays, _this.reminderDays)&&(identical(other.maxSlotsPerMember, _this.maxSlotsPerMember) || other.maxSlotsPerMember == _this.maxSlotsPerMember)&&(identical(other.selfMemberId, _this.selfMemberId) || other.selfMemberId == _this.selfMemberId)&&const DeepCollectionEquality().equals(other.emails, _this.emails)&&(identical(other.editingSlotId, _this.editingSlotId) || other.editingSlotId == _this.editingSlotId)&&(identical(other.busy, _this.busy) || other.busy == _this.busy));
}


@override
int get hashCode {
  final _this = this as CreateWizardState;
  return Object.hash(runtimeType,_this.startMonth,_this.step,_this.kametiId,_this.name,_this.slotAmount,_this.months,_this.dueDay,const DeepCollectionEquality().hash(_this.reminderDays),_this.maxSlotsPerMember,_this.selfMemberId,const DeepCollectionEquality().hash(_this.emails),_this.editingSlotId,_this.busy);
}

@override
String toString() {
  final _this = this as CreateWizardState;
  return 'CreateWizardState(startMonth: ${_this.startMonth}, step: ${_this.step}, kametiId: ${_this.kametiId}, name: ${_this.name}, slotAmount: ${_this.slotAmount}, months: ${_this.months}, dueDay: ${_this.dueDay}, reminderDays: ${_this.reminderDays}, maxSlotsPerMember: ${_this.maxSlotsPerMember}, selfMemberId: ${_this.selfMemberId}, emails: ${_this.emails}, editingSlotId: ${_this.editingSlotId}, busy: ${_this.busy})';
}


}

/// @nodoc
abstract mixin class $CreateWizardStateCopyWith<$Res>  {
  factory $CreateWizardStateCopyWith(CreateWizardState value, $Res Function(CreateWizardState) _then) = _$CreateWizardStateCopyWithImpl;
@useResult
$Res call({
 DateTime startMonth, WizardStep step, String? kametiId, String name, Money? slotAmount, int months, int dueDay, List<int> reminderDays, int maxSlotsPerMember, String? selfMemberId, Map<String, String?> emails, String? editingSlotId, bool busy
});




}
/// @nodoc
class _$CreateWizardStateCopyWithImpl<$Res>
    implements $CreateWizardStateCopyWith<$Res> {
  _$CreateWizardStateCopyWithImpl(this._self, this._then);

  final CreateWizardState _self;
  final $Res Function(CreateWizardState) _then;

/// Create a copy of CreateWizardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startMonth = null,Object? step = null,Object? kametiId = freezed,Object? name = null,Object? slotAmount = freezed,Object? months = null,Object? dueDay = null,Object? reminderDays = null,Object? maxSlotsPerMember = null,Object? selfMemberId = freezed,Object? emails = null,Object? editingSlotId = freezed,Object? busy = null,}) {
  return _then(CreateWizardState(
startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as DateTime,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as WizardStep,kametiId: freezed == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slotAmount: freezed == slotAmount ? _self.slotAmount : slotAmount // ignore: cast_nullable_to_non_nullable
as Money?,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as int,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,reminderDays: null == reminderDays ? _self.reminderDays : reminderDays // ignore: cast_nullable_to_non_nullable
as List<int>,maxSlotsPerMember: null == maxSlotsPerMember ? _self.maxSlotsPerMember : maxSlotsPerMember // ignore: cast_nullable_to_non_nullable
as int,selfMemberId: freezed == selfMemberId ? _self.selfMemberId : selfMemberId // ignore: cast_nullable_to_non_nullable
as String?,emails: null == emails ? _self.emails : emails // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,editingSlotId: freezed == editingSlotId ? _self.editingSlotId : editingSlotId // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateWizardState].
extension CreateWizardStatePatterns on CreateWizardState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateWizardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateWizardState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateWizardState value)  $default,){
final _that = this;
switch (_that) {
case _CreateWizardState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateWizardState value)?  $default,){
final _that = this;
switch (_that) {
case _CreateWizardState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startMonth,  WizardStep step,  String? kametiId,  String name,  Money? slotAmount,  int months,  int dueDay,  List<int> reminderDays,  int maxSlotsPerMember,  String? selfMemberId,  Map<String, String?> emails,  String? editingSlotId,  bool busy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateWizardState() when $default != null:
return $default(_that.startMonth,_that.step,_that.kametiId,_that.name,_that.slotAmount,_that.months,_that.dueDay,_that.reminderDays,_that.maxSlotsPerMember,_that.selfMemberId,_that.emails,_that.editingSlotId,_that.busy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startMonth,  WizardStep step,  String? kametiId,  String name,  Money? slotAmount,  int months,  int dueDay,  List<int> reminderDays,  int maxSlotsPerMember,  String? selfMemberId,  Map<String, String?> emails,  String? editingSlotId,  bool busy)  $default,) {final _that = this;
switch (_that) {
case _CreateWizardState():
return $default(_that.startMonth,_that.step,_that.kametiId,_that.name,_that.slotAmount,_that.months,_that.dueDay,_that.reminderDays,_that.maxSlotsPerMember,_that.selfMemberId,_that.emails,_that.editingSlotId,_that.busy);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startMonth,  WizardStep step,  String? kametiId,  String name,  Money? slotAmount,  int months,  int dueDay,  List<int> reminderDays,  int maxSlotsPerMember,  String? selfMemberId,  Map<String, String?> emails,  String? editingSlotId,  bool busy)?  $default,) {final _that = this;
switch (_that) {
case _CreateWizardState() when $default != null:
return $default(_that.startMonth,_that.step,_that.kametiId,_that.name,_that.slotAmount,_that.months,_that.dueDay,_that.reminderDays,_that.maxSlotsPerMember,_that.selfMemberId,_that.emails,_that.editingSlotId,_that.busy);case _:
  return null;

}
}

}

/// @nodoc


class _CreateWizardState extends CreateWizardState {
  const _CreateWizardState({required this.startMonth, this.step = WizardStep.basics, this.kametiId, this.name = '', this.slotAmount, this.months = 12, this.dueDay = 10,  List<int> reminderDays = const [1, 5, 8, 10], this.maxSlotsPerMember = 4, this.selfMemberId,  Map<String, String?> emails = const <String, String?>{}, this.editingSlotId, this.busy = false}): _reminderDays = reminderDays,_emails = emails,super._();
  

@override final  DateTime startMonth;
@override@JsonKey() final  WizardStep step;
@override final  String? kametiId;
@override@JsonKey() final  String name;
@override final  Money? slotAmount;
@override@JsonKey() final  int months;
@override@JsonKey() final  int dueDay;
 final  List<int> _reminderDays;
@override@JsonKey() List<int> get reminderDays {
  if (_reminderDays is EqualUnmodifiableListView) return _reminderDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderDays);
}

@override@JsonKey() final  int maxSlotsPerMember;
/// The owner's own member row, when "I'm also a member" is on.
@override final  String? selfMemberId;
/// Emails typed for members added in this wizard (null = none given).
/// Members don't expose contact details, so this is display only.
 final  Map<String, String?> _emails;
/// Emails typed for members added in this wizard (null = none given).
/// Members don't expose contact details, so this is display only.
@override@JsonKey() Map<String, String?> get emails {
  if (_emails is EqualUnmodifiableMapView) return _emails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_emails);
}

/// The slot open in the split editor (step 4), if any.
@override final  String? editingSlotId;
/// A write is in flight; buttons show a spinner and ignore taps.
@override@JsonKey() final  bool busy;

/// Create a copy of CreateWizardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateWizardStateCopyWith<_CreateWizardState> get copyWith => __$CreateWizardStateCopyWithImpl<_CreateWizardState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateWizardState&&(identical(other.startMonth, startMonth) || other.startMonth == startMonth)&&(identical(other.step, step) || other.step == step)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.name, name) || other.name == name)&&(identical(other.slotAmount, slotAmount) || other.slotAmount == slotAmount)&&(identical(other.months, months) || other.months == months)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&const DeepCollectionEquality().equals(other.reminderDays, _reminderDays)&&(identical(other.maxSlotsPerMember, maxSlotsPerMember) || other.maxSlotsPerMember == maxSlotsPerMember)&&(identical(other.selfMemberId, selfMemberId) || other.selfMemberId == selfMemberId)&&const DeepCollectionEquality().equals(other.emails, _emails)&&(identical(other.editingSlotId, editingSlotId) || other.editingSlotId == editingSlotId)&&(identical(other.busy, busy) || other.busy == busy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startMonth,step,kametiId,name,slotAmount,months,dueDay,const DeepCollectionEquality().hash(_reminderDays),maxSlotsPerMember,selfMemberId,const DeepCollectionEquality().hash(_emails),editingSlotId,busy);
}

@override
String toString() {
    return 'CreateWizardState(startMonth: $startMonth, step: $step, kametiId: $kametiId, name: $name, slotAmount: $slotAmount, months: $months, dueDay: $dueDay, reminderDays: $reminderDays, maxSlotsPerMember: $maxSlotsPerMember, selfMemberId: $selfMemberId, emails: $emails, editingSlotId: $editingSlotId, busy: $busy)';
}


}

/// @nodoc
abstract mixin class _$CreateWizardStateCopyWith<$Res> implements $CreateWizardStateCopyWith<$Res> {
  factory _$CreateWizardStateCopyWith(_CreateWizardState value, $Res Function(_CreateWizardState) _then) = __$CreateWizardStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime startMonth, WizardStep step, String? kametiId, String name, Money? slotAmount, int months, int dueDay, List<int> reminderDays, int maxSlotsPerMember, String? selfMemberId, Map<String, String?> emails, String? editingSlotId, bool busy
});




}
/// @nodoc
class __$CreateWizardStateCopyWithImpl<$Res>
    implements _$CreateWizardStateCopyWith<$Res> {
  __$CreateWizardStateCopyWithImpl(this._self, this._then);

  final _CreateWizardState _self;
  final $Res Function(_CreateWizardState) _then;

/// Create a copy of CreateWizardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startMonth = null,Object? step = null,Object? kametiId = freezed,Object? name = null,Object? slotAmount = freezed,Object? months = null,Object? dueDay = null,Object? reminderDays = null,Object? maxSlotsPerMember = null,Object? selfMemberId = freezed,Object? emails = null,Object? editingSlotId = freezed,Object? busy = null,}) {
  return _then(_CreateWizardState(
startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as DateTime,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as WizardStep,kametiId: freezed == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slotAmount: freezed == slotAmount ? _self.slotAmount : slotAmount // ignore: cast_nullable_to_non_nullable
as Money?,months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as int,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,reminderDays: null == reminderDays ? _self._reminderDays : reminderDays // ignore: cast_nullable_to_non_nullable
as List<int>,maxSlotsPerMember: null == maxSlotsPerMember ? _self.maxSlotsPerMember : maxSlotsPerMember // ignore: cast_nullable_to_non_nullable
as int,selfMemberId: freezed == selfMemberId ? _self.selfMemberId : selfMemberId // ignore: cast_nullable_to_non_nullable
as String?,emails: null == emails ? _self._emails : emails // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,editingSlotId: freezed == editingSlotId ? _self.editingSlotId : editingSlotId // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
