// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kameti_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Kameti {

 String get id; String get ownerId; String get name;@DateOnlyConverter() DateTime get startMonth; int get monthsN;@MoneyConverter() Money get slotAmountC; int get dueDay; List<int> get reminderDays; int get maxSlotsPerMember; KametiStatus get status; String? get description; DateTime? get startedAt;
/// Create a copy of Kameti
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KametiCopyWith<Kameti> get copyWith => _$KametiCopyWithImpl<Kameti>(this as Kameti, _$identity);

  /// Serializes this Kameti to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Kameti;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Kameti&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ownerId, _this.ownerId) || other.ownerId == _this.ownerId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.startMonth, _this.startMonth) || other.startMonth == _this.startMonth)&&(identical(other.monthsN, _this.monthsN) || other.monthsN == _this.monthsN)&&(identical(other.slotAmountC, _this.slotAmountC) || other.slotAmountC == _this.slotAmountC)&&(identical(other.dueDay, _this.dueDay) || other.dueDay == _this.dueDay)&&const DeepCollectionEquality().equals(other.reminderDays, _this.reminderDays)&&(identical(other.maxSlotsPerMember, _this.maxSlotsPerMember) || other.maxSlotsPerMember == _this.maxSlotsPerMember)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Kameti;
  return Object.hash(runtimeType,_this.id,_this.ownerId,_this.name,_this.startMonth,_this.monthsN,_this.slotAmountC,_this.dueDay,const DeepCollectionEquality().hash(_this.reminderDays),_this.maxSlotsPerMember,_this.status,_this.description,_this.startedAt);
}

@override
String toString() {
  final _this = this as Kameti;
  return 'Kameti(id: ${_this.id}, ownerId: ${_this.ownerId}, name: ${_this.name}, startMonth: ${_this.startMonth}, monthsN: ${_this.monthsN}, slotAmountC: ${_this.slotAmountC}, dueDay: ${_this.dueDay}, reminderDays: ${_this.reminderDays}, maxSlotsPerMember: ${_this.maxSlotsPerMember}, status: ${_this.status}, description: ${_this.description}, startedAt: ${_this.startedAt})';
}


}

/// @nodoc
abstract mixin class $KametiCopyWith<$Res>  {
  factory $KametiCopyWith(Kameti value, $Res Function(Kameti) _then) = _$KametiCopyWithImpl;
@useResult
$Res call({
 String id, String ownerId, String name,@DateOnlyConverter() DateTime startMonth, int monthsN,@MoneyConverter() Money slotAmountC, int dueDay, List<int> reminderDays, int maxSlotsPerMember, KametiStatus status, String? description, DateTime? startedAt
});




}
/// @nodoc
class _$KametiCopyWithImpl<$Res>
    implements $KametiCopyWith<$Res> {
  _$KametiCopyWithImpl(this._self, this._then);

  final Kameti _self;
  final $Res Function(Kameti) _then;

/// Create a copy of Kameti
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? name = null,Object? startMonth = null,Object? monthsN = null,Object? slotAmountC = null,Object? dueDay = null,Object? reminderDays = null,Object? maxSlotsPerMember = null,Object? status = null,Object? description = freezed,Object? startedAt = freezed,}) {
  return _then(Kameti(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as DateTime,monthsN: null == monthsN ? _self.monthsN : monthsN // ignore: cast_nullable_to_non_nullable
as int,slotAmountC: null == slotAmountC ? _self.slotAmountC : slotAmountC // ignore: cast_nullable_to_non_nullable
as Money,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,reminderDays: null == reminderDays ? _self.reminderDays : reminderDays // ignore: cast_nullable_to_non_nullable
as List<int>,maxSlotsPerMember: null == maxSlotsPerMember ? _self.maxSlotsPerMember : maxSlotsPerMember // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as KametiStatus,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Kameti].
extension KametiPatterns on Kameti {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Kameti value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Kameti() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Kameti value)  $default,){
final _that = this;
switch (_that) {
case _Kameti():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Kameti value)?  $default,){
final _that = this;
switch (_that) {
case _Kameti() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ownerId,  String name, @DateOnlyConverter()  DateTime startMonth,  int monthsN, @MoneyConverter()  Money slotAmountC,  int dueDay,  List<int> reminderDays,  int maxSlotsPerMember,  KametiStatus status,  String? description,  DateTime? startedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Kameti() when $default != null:
return $default(_that.id,_that.ownerId,_that.name,_that.startMonth,_that.monthsN,_that.slotAmountC,_that.dueDay,_that.reminderDays,_that.maxSlotsPerMember,_that.status,_that.description,_that.startedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ownerId,  String name, @DateOnlyConverter()  DateTime startMonth,  int monthsN, @MoneyConverter()  Money slotAmountC,  int dueDay,  List<int> reminderDays,  int maxSlotsPerMember,  KametiStatus status,  String? description,  DateTime? startedAt)  $default,) {final _that = this;
switch (_that) {
case _Kameti():
return $default(_that.id,_that.ownerId,_that.name,_that.startMonth,_that.monthsN,_that.slotAmountC,_that.dueDay,_that.reminderDays,_that.maxSlotsPerMember,_that.status,_that.description,_that.startedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ownerId,  String name, @DateOnlyConverter()  DateTime startMonth,  int monthsN, @MoneyConverter()  Money slotAmountC,  int dueDay,  List<int> reminderDays,  int maxSlotsPerMember,  KametiStatus status,  String? description,  DateTime? startedAt)?  $default,) {final _that = this;
switch (_that) {
case _Kameti() when $default != null:
return $default(_that.id,_that.ownerId,_that.name,_that.startMonth,_that.monthsN,_that.slotAmountC,_that.dueDay,_that.reminderDays,_that.maxSlotsPerMember,_that.status,_that.description,_that.startedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Kameti extends Kameti {
  const _Kameti({required this.id, required this.ownerId, required this.name, @DateOnlyConverter() required this.startMonth, required this.monthsN, @MoneyConverter() required this.slotAmountC, required this.dueDay, required  List<int> reminderDays, required this.maxSlotsPerMember, required this.status, this.description, this.startedAt}): _reminderDays = reminderDays,super._();
  factory _Kameti.fromJson(Map<String, dynamic> json) => _$KametiFromJson(json);

@override final  String id;
@override final  String ownerId;
@override final  String name;
@override@DateOnlyConverter() final  DateTime startMonth;
@override final  int monthsN;
@override@MoneyConverter() final  Money slotAmountC;
@override final  int dueDay;
 final  List<int> _reminderDays;
@override List<int> get reminderDays {
  if (_reminderDays is EqualUnmodifiableListView) return _reminderDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderDays);
}

@override final  int maxSlotsPerMember;
@override final  KametiStatus status;
@override final  String? description;
@override final  DateTime? startedAt;

/// Create a copy of Kameti
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KametiCopyWith<_Kameti> get copyWith => __$KametiCopyWithImpl<_Kameti>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KametiToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Kameti&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startMonth, startMonth) || other.startMonth == startMonth)&&(identical(other.monthsN, monthsN) || other.monthsN == monthsN)&&(identical(other.slotAmountC, slotAmountC) || other.slotAmountC == slotAmountC)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&const DeepCollectionEquality().equals(other.reminderDays, _reminderDays)&&(identical(other.maxSlotsPerMember, maxSlotsPerMember) || other.maxSlotsPerMember == maxSlotsPerMember)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,ownerId,name,startMonth,monthsN,slotAmountC,dueDay,const DeepCollectionEquality().hash(_reminderDays),maxSlotsPerMember,status,description,startedAt);
}

@override
String toString() {
    return 'Kameti(id: $id, ownerId: $ownerId, name: $name, startMonth: $startMonth, monthsN: $monthsN, slotAmountC: $slotAmountC, dueDay: $dueDay, reminderDays: $reminderDays, maxSlotsPerMember: $maxSlotsPerMember, status: $status, description: $description, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class _$KametiCopyWith<$Res> implements $KametiCopyWith<$Res> {
  factory _$KametiCopyWith(_Kameti value, $Res Function(_Kameti) _then) = __$KametiCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerId, String name,@DateOnlyConverter() DateTime startMonth, int monthsN,@MoneyConverter() Money slotAmountC, int dueDay, List<int> reminderDays, int maxSlotsPerMember, KametiStatus status, String? description, DateTime? startedAt
});




}
/// @nodoc
class __$KametiCopyWithImpl<$Res>
    implements _$KametiCopyWith<$Res> {
  __$KametiCopyWithImpl(this._self, this._then);

  final _Kameti _self;
  final $Res Function(_Kameti) _then;

/// Create a copy of Kameti
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? name = null,Object? startMonth = null,Object? monthsN = null,Object? slotAmountC = null,Object? dueDay = null,Object? reminderDays = null,Object? maxSlotsPerMember = null,Object? status = null,Object? description = freezed,Object? startedAt = freezed,}) {
  return _then(_Kameti(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startMonth: null == startMonth ? _self.startMonth : startMonth // ignore: cast_nullable_to_non_nullable
as DateTime,monthsN: null == monthsN ? _self.monthsN : monthsN // ignore: cast_nullable_to_non_nullable
as int,slotAmountC: null == slotAmountC ? _self.slotAmountC : slotAmountC // ignore: cast_nullable_to_non_nullable
as Money,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,reminderDays: null == reminderDays ? _self._reminderDays : reminderDays // ignore: cast_nullable_to_non_nullable
as List<int>,maxSlotsPerMember: null == maxSlotsPerMember ? _self.maxSlotsPerMember : maxSlotsPerMember // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as KametiStatus,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Member {

 String get id; String get kametiId; String get name; JoinStatus get joinStatus; String? get contactId; String? get profileId; String? get nickname; String? get color;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Member;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.joinStatus, _this.joinStatus) || other.joinStatus == _this.joinStatus)&&(identical(other.contactId, _this.contactId) || other.contactId == _this.contactId)&&(identical(other.profileId, _this.profileId) || other.profileId == _this.profileId)&&(identical(other.nickname, _this.nickname) || other.nickname == _this.nickname)&&(identical(other.color, _this.color) || other.color == _this.color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Member;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.name,_this.joinStatus,_this.contactId,_this.profileId,_this.nickname,_this.color);
}

@override
String toString() {
  final _this = this as Member;
  return 'Member(id: ${_this.id}, kametiId: ${_this.kametiId}, name: ${_this.name}, joinStatus: ${_this.joinStatus}, contactId: ${_this.contactId}, profileId: ${_this.profileId}, nickname: ${_this.nickname}, color: ${_this.color})';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String id, String kametiId, String name, JoinStatus joinStatus, String? contactId, String? profileId, String? nickname, String? color
});




}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? name = null,Object? joinStatus = null,Object? contactId = freezed,Object? profileId = freezed,Object? nickname = freezed,Object? color = freezed,}) {
  return _then(Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,joinStatus: null == joinStatus ? _self.joinStatus : joinStatus // ignore: cast_nullable_to_non_nullable
as JoinStatus,contactId: freezed == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String?,profileId: freezed == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kametiId,  String name,  JoinStatus joinStatus,  String? contactId,  String? profileId,  String? nickname,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.kametiId,_that.name,_that.joinStatus,_that.contactId,_that.profileId,_that.nickname,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kametiId,  String name,  JoinStatus joinStatus,  String? contactId,  String? profileId,  String? nickname,  String? color)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.id,_that.kametiId,_that.name,_that.joinStatus,_that.contactId,_that.profileId,_that.nickname,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kametiId,  String name,  JoinStatus joinStatus,  String? contactId,  String? profileId,  String? nickname,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.kametiId,_that.name,_that.joinStatus,_that.contactId,_that.profileId,_that.nickname,_that.color);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member implements Member {
  const _Member({required this.id, required this.kametiId, required this.name, required this.joinStatus, this.contactId, this.profileId, this.nickname, this.color});
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override final  String id;
@override final  String kametiId;
@override final  String name;
@override final  JoinStatus joinStatus;
@override final  String? contactId;
@override final  String? profileId;
@override final  String? nickname;
@override final  String? color;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.name, name) || other.name == name)&&(identical(other.joinStatus, joinStatus) || other.joinStatus == joinStatus)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,name,joinStatus,contactId,profileId,nickname,color);
}

@override
String toString() {
    return 'Member(id: $id, kametiId: $kametiId, name: $name, joinStatus: $joinStatus, contactId: $contactId, profileId: $profileId, nickname: $nickname, color: $color)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String kametiId, String name, JoinStatus joinStatus, String? contactId, String? profileId, String? nickname, String? color
});




}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? name = null,Object? joinStatus = null,Object? contactId = freezed,Object? profileId = freezed,Object? nickname = freezed,Object? color = freezed,}) {
  return _then(_Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,joinStatus: null == joinStatus ? _self.joinStatus : joinStatus // ignore: cast_nullable_to_non_nullable
as JoinStatus,contactId: freezed == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String?,profileId: freezed == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String?,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Slot {

 String get id; String get kametiId; int get payoutMonthIndex; String? get note;
/// Create a copy of Slot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotCopyWith<Slot> get copyWith => _$SlotCopyWithImpl<Slot>(this as Slot, _$identity);

  /// Serializes this Slot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Slot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Slot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.payoutMonthIndex, _this.payoutMonthIndex) || other.payoutMonthIndex == _this.payoutMonthIndex)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Slot;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.payoutMonthIndex,_this.note);
}

@override
String toString() {
  final _this = this as Slot;
  return 'Slot(id: ${_this.id}, kametiId: ${_this.kametiId}, payoutMonthIndex: ${_this.payoutMonthIndex}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $SlotCopyWith<$Res>  {
  factory $SlotCopyWith(Slot value, $Res Function(Slot) _then) = _$SlotCopyWithImpl;
@useResult
$Res call({
 String id, String kametiId, int payoutMonthIndex, String? note
});




}
/// @nodoc
class _$SlotCopyWithImpl<$Res>
    implements $SlotCopyWith<$Res> {
  _$SlotCopyWithImpl(this._self, this._then);

  final Slot _self;
  final $Res Function(Slot) _then;

/// Create a copy of Slot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? payoutMonthIndex = null,Object? note = freezed,}) {
  return _then(Slot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,payoutMonthIndex: null == payoutMonthIndex ? _self.payoutMonthIndex : payoutMonthIndex // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Slot].
extension SlotPatterns on Slot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Slot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Slot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Slot value)  $default,){
final _that = this;
switch (_that) {
case _Slot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Slot value)?  $default,){
final _that = this;
switch (_that) {
case _Slot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kametiId,  int payoutMonthIndex,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Slot() when $default != null:
return $default(_that.id,_that.kametiId,_that.payoutMonthIndex,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kametiId,  int payoutMonthIndex,  String? note)  $default,) {final _that = this;
switch (_that) {
case _Slot():
return $default(_that.id,_that.kametiId,_that.payoutMonthIndex,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kametiId,  int payoutMonthIndex,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _Slot() when $default != null:
return $default(_that.id,_that.kametiId,_that.payoutMonthIndex,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Slot implements Slot {
  const _Slot({required this.id, required this.kametiId, required this.payoutMonthIndex, this.note});
  factory _Slot.fromJson(Map<String, dynamic> json) => _$SlotFromJson(json);

@override final  String id;
@override final  String kametiId;
@override final  int payoutMonthIndex;
@override final  String? note;

/// Create a copy of Slot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotCopyWith<_Slot> get copyWith => __$SlotCopyWithImpl<_Slot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Slot&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.payoutMonthIndex, payoutMonthIndex) || other.payoutMonthIndex == payoutMonthIndex)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,payoutMonthIndex,note);
}

@override
String toString() {
    return 'Slot(id: $id, kametiId: $kametiId, payoutMonthIndex: $payoutMonthIndex, note: $note)';
}


}

/// @nodoc
abstract mixin class _$SlotCopyWith<$Res> implements $SlotCopyWith<$Res> {
  factory _$SlotCopyWith(_Slot value, $Res Function(_Slot) _then) = __$SlotCopyWithImpl;
@override @useResult
$Res call({
 String id, String kametiId, int payoutMonthIndex, String? note
});




}
/// @nodoc
class __$SlotCopyWithImpl<$Res>
    implements _$SlotCopyWith<$Res> {
  __$SlotCopyWithImpl(this._self, this._then);

  final _Slot _self;
  final $Res Function(_Slot) _then;

/// Create a copy of Slot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? payoutMonthIndex = null,Object? note = freezed,}) {
  return _then(_Slot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,payoutMonthIndex: null == payoutMonthIndex ? _self.payoutMonthIndex : payoutMonthIndex // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Share {

 String get id; String get kametiId; String get slotId; String get memberId;@MoneyConverter() Money get monthlyAmount; int get effectiveFromMonth; int? get effectiveToMonth;
/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShareCopyWith<Share> get copyWith => _$ShareCopyWithImpl<Share>(this as Share, _$identity);

  /// Serializes this Share to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Share;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Share&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.slotId, _this.slotId) || other.slotId == _this.slotId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.monthlyAmount, _this.monthlyAmount) || other.monthlyAmount == _this.monthlyAmount)&&(identical(other.effectiveFromMonth, _this.effectiveFromMonth) || other.effectiveFromMonth == _this.effectiveFromMonth)&&(identical(other.effectiveToMonth, _this.effectiveToMonth) || other.effectiveToMonth == _this.effectiveToMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Share;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.slotId,_this.memberId,_this.monthlyAmount,_this.effectiveFromMonth,_this.effectiveToMonth);
}

@override
String toString() {
  final _this = this as Share;
  return 'Share(id: ${_this.id}, kametiId: ${_this.kametiId}, slotId: ${_this.slotId}, memberId: ${_this.memberId}, monthlyAmount: ${_this.monthlyAmount}, effectiveFromMonth: ${_this.effectiveFromMonth}, effectiveToMonth: ${_this.effectiveToMonth})';
}


}

/// @nodoc
abstract mixin class $ShareCopyWith<$Res>  {
  factory $ShareCopyWith(Share value, $Res Function(Share) _then) = _$ShareCopyWithImpl;
@useResult
$Res call({
 String id, String kametiId, String slotId, String memberId,@MoneyConverter() Money monthlyAmount, int effectiveFromMonth, int? effectiveToMonth
});




}
/// @nodoc
class _$ShareCopyWithImpl<$Res>
    implements $ShareCopyWith<$Res> {
  _$ShareCopyWithImpl(this._self, this._then);

  final Share _self;
  final $Res Function(Share) _then;

/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? slotId = null,Object? memberId = null,Object? monthlyAmount = null,Object? effectiveFromMonth = null,Object? effectiveToMonth = freezed,}) {
  return _then(Share(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,monthlyAmount: null == monthlyAmount ? _self.monthlyAmount : monthlyAmount // ignore: cast_nullable_to_non_nullable
as Money,effectiveFromMonth: null == effectiveFromMonth ? _self.effectiveFromMonth : effectiveFromMonth // ignore: cast_nullable_to_non_nullable
as int,effectiveToMonth: freezed == effectiveToMonth ? _self.effectiveToMonth : effectiveToMonth // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Share].
extension SharePatterns on Share {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Share value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Share() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Share value)  $default,){
final _that = this;
switch (_that) {
case _Share():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Share value)?  $default,){
final _that = this;
switch (_that) {
case _Share() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kametiId,  String slotId,  String memberId, @MoneyConverter()  Money monthlyAmount,  int effectiveFromMonth,  int? effectiveToMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Share() when $default != null:
return $default(_that.id,_that.kametiId,_that.slotId,_that.memberId,_that.monthlyAmount,_that.effectiveFromMonth,_that.effectiveToMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kametiId,  String slotId,  String memberId, @MoneyConverter()  Money monthlyAmount,  int effectiveFromMonth,  int? effectiveToMonth)  $default,) {final _that = this;
switch (_that) {
case _Share():
return $default(_that.id,_that.kametiId,_that.slotId,_that.memberId,_that.monthlyAmount,_that.effectiveFromMonth,_that.effectiveToMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kametiId,  String slotId,  String memberId, @MoneyConverter()  Money monthlyAmount,  int effectiveFromMonth,  int? effectiveToMonth)?  $default,) {final _that = this;
switch (_that) {
case _Share() when $default != null:
return $default(_that.id,_that.kametiId,_that.slotId,_that.memberId,_that.monthlyAmount,_that.effectiveFromMonth,_that.effectiveToMonth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Share implements Share {
  const _Share({required this.id, required this.kametiId, required this.slotId, required this.memberId, @MoneyConverter() required this.monthlyAmount, required this.effectiveFromMonth, this.effectiveToMonth});
  factory _Share.fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);

@override final  String id;
@override final  String kametiId;
@override final  String slotId;
@override final  String memberId;
@override@MoneyConverter() final  Money monthlyAmount;
@override final  int effectiveFromMonth;
@override final  int? effectiveToMonth;

/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareCopyWith<_Share> get copyWith => __$ShareCopyWithImpl<_Share>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Share&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.monthlyAmount, monthlyAmount) || other.monthlyAmount == monthlyAmount)&&(identical(other.effectiveFromMonth, effectiveFromMonth) || other.effectiveFromMonth == effectiveFromMonth)&&(identical(other.effectiveToMonth, effectiveToMonth) || other.effectiveToMonth == effectiveToMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,slotId,memberId,monthlyAmount,effectiveFromMonth,effectiveToMonth);
}

@override
String toString() {
    return 'Share(id: $id, kametiId: $kametiId, slotId: $slotId, memberId: $memberId, monthlyAmount: $monthlyAmount, effectiveFromMonth: $effectiveFromMonth, effectiveToMonth: $effectiveToMonth)';
}


}

/// @nodoc
abstract mixin class _$ShareCopyWith<$Res> implements $ShareCopyWith<$Res> {
  factory _$ShareCopyWith(_Share value, $Res Function(_Share) _then) = __$ShareCopyWithImpl;
@override @useResult
$Res call({
 String id, String kametiId, String slotId, String memberId,@MoneyConverter() Money monthlyAmount, int effectiveFromMonth, int? effectiveToMonth
});




}
/// @nodoc
class __$ShareCopyWithImpl<$Res>
    implements _$ShareCopyWith<$Res> {
  __$ShareCopyWithImpl(this._self, this._then);

  final _Share _self;
  final $Res Function(_Share) _then;

/// Create a copy of Share
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? slotId = null,Object? memberId = null,Object? monthlyAmount = null,Object? effectiveFromMonth = null,Object? effectiveToMonth = freezed,}) {
  return _then(_Share(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,monthlyAmount: null == monthlyAmount ? _self.monthlyAmount : monthlyAmount // ignore: cast_nullable_to_non_nullable
as Money,effectiveFromMonth: null == effectiveFromMonth ? _self.effectiveFromMonth : effectiveFromMonth // ignore: cast_nullable_to_non_nullable
as int,effectiveToMonth: freezed == effectiveToMonth ? _self.effectiveToMonth : effectiveToMonth // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
