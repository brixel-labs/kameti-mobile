// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_rows.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberBalanceRow {

 String get kametiId; String get memberId; int get currentMonthIndex;@MoneyConverter() Money get monthlyDue;@MoneyConverter() Money get dueToDate;@MoneyConverter() Money get totalPaid;@MoneyConverter() Money get balance;@MoneyConverter() Money get owes;@MoneyConverter() Money get credit;
/// Create a copy of MemberBalanceRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberBalanceRowCopyWith<MemberBalanceRow> get copyWith => _$MemberBalanceRowCopyWithImpl<MemberBalanceRow>(this as MemberBalanceRow, _$identity);

  /// Serializes this MemberBalanceRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberBalanceRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberBalanceRow&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.currentMonthIndex, _this.currentMonthIndex) || other.currentMonthIndex == _this.currentMonthIndex)&&(identical(other.monthlyDue, _this.monthlyDue) || other.monthlyDue == _this.monthlyDue)&&(identical(other.dueToDate, _this.dueToDate) || other.dueToDate == _this.dueToDate)&&(identical(other.totalPaid, _this.totalPaid) || other.totalPaid == _this.totalPaid)&&(identical(other.balance, _this.balance) || other.balance == _this.balance)&&(identical(other.owes, _this.owes) || other.owes == _this.owes)&&(identical(other.credit, _this.credit) || other.credit == _this.credit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberBalanceRow;
  return Object.hash(runtimeType,_this.kametiId,_this.memberId,_this.currentMonthIndex,_this.monthlyDue,_this.dueToDate,_this.totalPaid,_this.balance,_this.owes,_this.credit);
}

@override
String toString() {
  final _this = this as MemberBalanceRow;
  return 'MemberBalanceRow(kametiId: ${_this.kametiId}, memberId: ${_this.memberId}, currentMonthIndex: ${_this.currentMonthIndex}, monthlyDue: ${_this.monthlyDue}, dueToDate: ${_this.dueToDate}, totalPaid: ${_this.totalPaid}, balance: ${_this.balance}, owes: ${_this.owes}, credit: ${_this.credit})';
}


}

/// @nodoc
abstract mixin class $MemberBalanceRowCopyWith<$Res>  {
  factory $MemberBalanceRowCopyWith(MemberBalanceRow value, $Res Function(MemberBalanceRow) _then) = _$MemberBalanceRowCopyWithImpl;
@useResult
$Res call({
 String kametiId, String memberId, int currentMonthIndex,@MoneyConverter() Money monthlyDue,@MoneyConverter() Money dueToDate,@MoneyConverter() Money totalPaid,@MoneyConverter() Money balance,@MoneyConverter() Money owes,@MoneyConverter() Money credit
});




}
/// @nodoc
class _$MemberBalanceRowCopyWithImpl<$Res>
    implements $MemberBalanceRowCopyWith<$Res> {
  _$MemberBalanceRowCopyWithImpl(this._self, this._then);

  final MemberBalanceRow _self;
  final $Res Function(MemberBalanceRow) _then;

/// Create a copy of MemberBalanceRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kametiId = null,Object? memberId = null,Object? currentMonthIndex = null,Object? monthlyDue = null,Object? dueToDate = null,Object? totalPaid = null,Object? balance = null,Object? owes = null,Object? credit = null,}) {
  return _then(MemberBalanceRow(
kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,currentMonthIndex: null == currentMonthIndex ? _self.currentMonthIndex : currentMonthIndex // ignore: cast_nullable_to_non_nullable
as int,monthlyDue: null == monthlyDue ? _self.monthlyDue : monthlyDue // ignore: cast_nullable_to_non_nullable
as Money,dueToDate: null == dueToDate ? _self.dueToDate : dueToDate // ignore: cast_nullable_to_non_nullable
as Money,totalPaid: null == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as Money,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Money,owes: null == owes ? _self.owes : owes // ignore: cast_nullable_to_non_nullable
as Money,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberBalanceRow].
extension MemberBalanceRowPatterns on MemberBalanceRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberBalanceRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberBalanceRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberBalanceRow value)  $default,){
final _that = this;
switch (_that) {
case _MemberBalanceRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberBalanceRow value)?  $default,){
final _that = this;
switch (_that) {
case _MemberBalanceRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kametiId,  String memberId,  int currentMonthIndex, @MoneyConverter()  Money monthlyDue, @MoneyConverter()  Money dueToDate, @MoneyConverter()  Money totalPaid, @MoneyConverter()  Money balance, @MoneyConverter()  Money owes, @MoneyConverter()  Money credit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberBalanceRow() when $default != null:
return $default(_that.kametiId,_that.memberId,_that.currentMonthIndex,_that.monthlyDue,_that.dueToDate,_that.totalPaid,_that.balance,_that.owes,_that.credit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kametiId,  String memberId,  int currentMonthIndex, @MoneyConverter()  Money monthlyDue, @MoneyConverter()  Money dueToDate, @MoneyConverter()  Money totalPaid, @MoneyConverter()  Money balance, @MoneyConverter()  Money owes, @MoneyConverter()  Money credit)  $default,) {final _that = this;
switch (_that) {
case _MemberBalanceRow():
return $default(_that.kametiId,_that.memberId,_that.currentMonthIndex,_that.monthlyDue,_that.dueToDate,_that.totalPaid,_that.balance,_that.owes,_that.credit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kametiId,  String memberId,  int currentMonthIndex, @MoneyConverter()  Money monthlyDue, @MoneyConverter()  Money dueToDate, @MoneyConverter()  Money totalPaid, @MoneyConverter()  Money balance, @MoneyConverter()  Money owes, @MoneyConverter()  Money credit)?  $default,) {final _that = this;
switch (_that) {
case _MemberBalanceRow() when $default != null:
return $default(_that.kametiId,_that.memberId,_that.currentMonthIndex,_that.monthlyDue,_that.dueToDate,_that.totalPaid,_that.balance,_that.owes,_that.credit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberBalanceRow implements MemberBalanceRow {
  const _MemberBalanceRow({required this.kametiId, required this.memberId, required this.currentMonthIndex, @MoneyConverter() required this.monthlyDue, @MoneyConverter() required this.dueToDate, @MoneyConverter() required this.totalPaid, @MoneyConverter() required this.balance, @MoneyConverter() required this.owes, @MoneyConverter() required this.credit});
  factory _MemberBalanceRow.fromJson(Map<String, dynamic> json) => _$MemberBalanceRowFromJson(json);

@override final  String kametiId;
@override final  String memberId;
@override final  int currentMonthIndex;
@override@MoneyConverter() final  Money monthlyDue;
@override@MoneyConverter() final  Money dueToDate;
@override@MoneyConverter() final  Money totalPaid;
@override@MoneyConverter() final  Money balance;
@override@MoneyConverter() final  Money owes;
@override@MoneyConverter() final  Money credit;

/// Create a copy of MemberBalanceRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberBalanceRowCopyWith<_MemberBalanceRow> get copyWith => __$MemberBalanceRowCopyWithImpl<_MemberBalanceRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberBalanceRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberBalanceRow&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.currentMonthIndex, currentMonthIndex) || other.currentMonthIndex == currentMonthIndex)&&(identical(other.monthlyDue, monthlyDue) || other.monthlyDue == monthlyDue)&&(identical(other.dueToDate, dueToDate) || other.dueToDate == dueToDate)&&(identical(other.totalPaid, totalPaid) || other.totalPaid == totalPaid)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.owes, owes) || other.owes == owes)&&(identical(other.credit, credit) || other.credit == credit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kametiId,memberId,currentMonthIndex,monthlyDue,dueToDate,totalPaid,balance,owes,credit);
}

@override
String toString() {
    return 'MemberBalanceRow(kametiId: $kametiId, memberId: $memberId, currentMonthIndex: $currentMonthIndex, monthlyDue: $monthlyDue, dueToDate: $dueToDate, totalPaid: $totalPaid, balance: $balance, owes: $owes, credit: $credit)';
}


}

/// @nodoc
abstract mixin class _$MemberBalanceRowCopyWith<$Res> implements $MemberBalanceRowCopyWith<$Res> {
  factory _$MemberBalanceRowCopyWith(_MemberBalanceRow value, $Res Function(_MemberBalanceRow) _then) = __$MemberBalanceRowCopyWithImpl;
@override @useResult
$Res call({
 String kametiId, String memberId, int currentMonthIndex,@MoneyConverter() Money monthlyDue,@MoneyConverter() Money dueToDate,@MoneyConverter() Money totalPaid,@MoneyConverter() Money balance,@MoneyConverter() Money owes,@MoneyConverter() Money credit
});




}
/// @nodoc
class __$MemberBalanceRowCopyWithImpl<$Res>
    implements _$MemberBalanceRowCopyWith<$Res> {
  __$MemberBalanceRowCopyWithImpl(this._self, this._then);

  final _MemberBalanceRow _self;
  final $Res Function(_MemberBalanceRow) _then;

/// Create a copy of MemberBalanceRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kametiId = null,Object? memberId = null,Object? currentMonthIndex = null,Object? monthlyDue = null,Object? dueToDate = null,Object? totalPaid = null,Object? balance = null,Object? owes = null,Object? credit = null,}) {
  return _then(_MemberBalanceRow(
kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,currentMonthIndex: null == currentMonthIndex ? _self.currentMonthIndex : currentMonthIndex // ignore: cast_nullable_to_non_nullable
as int,monthlyDue: null == monthlyDue ? _self.monthlyDue : monthlyDue // ignore: cast_nullable_to_non_nullable
as Money,dueToDate: null == dueToDate ? _self.dueToDate : dueToDate // ignore: cast_nullable_to_non_nullable
as Money,totalPaid: null == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as Money,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Money,owes: null == owes ? _self.owes : owes // ignore: cast_nullable_to_non_nullable
as Money,credit: null == credit ? _self.credit : credit // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}


}


/// @nodoc
mixin _$MemberMonthRow {

 String get kametiId; String get memberId; int get monthIndex;@DateOnlyConverter() DateTime get monthStart; bool get isCurrent;@MoneyConverter() Money get due;@MoneyConverter() Money get allocated;@MoneyConverter() Money get remaining; MonthStatusCode get status;
/// Create a copy of MemberMonthRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberMonthRowCopyWith<MemberMonthRow> get copyWith => _$MemberMonthRowCopyWithImpl<MemberMonthRow>(this as MemberMonthRow, _$identity);

  /// Serializes this MemberMonthRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberMonthRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberMonthRow&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.monthIndex, _this.monthIndex) || other.monthIndex == _this.monthIndex)&&(identical(other.monthStart, _this.monthStart) || other.monthStart == _this.monthStart)&&(identical(other.isCurrent, _this.isCurrent) || other.isCurrent == _this.isCurrent)&&(identical(other.due, _this.due) || other.due == _this.due)&&(identical(other.allocated, _this.allocated) || other.allocated == _this.allocated)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberMonthRow;
  return Object.hash(runtimeType,_this.kametiId,_this.memberId,_this.monthIndex,_this.monthStart,_this.isCurrent,_this.due,_this.allocated,_this.remaining,_this.status);
}

@override
String toString() {
  final _this = this as MemberMonthRow;
  return 'MemberMonthRow(kametiId: ${_this.kametiId}, memberId: ${_this.memberId}, monthIndex: ${_this.monthIndex}, monthStart: ${_this.monthStart}, isCurrent: ${_this.isCurrent}, due: ${_this.due}, allocated: ${_this.allocated}, remaining: ${_this.remaining}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $MemberMonthRowCopyWith<$Res>  {
  factory $MemberMonthRowCopyWith(MemberMonthRow value, $Res Function(MemberMonthRow) _then) = _$MemberMonthRowCopyWithImpl;
@useResult
$Res call({
 String kametiId, String memberId, int monthIndex,@DateOnlyConverter() DateTime monthStart, bool isCurrent,@MoneyConverter() Money due,@MoneyConverter() Money allocated,@MoneyConverter() Money remaining, MonthStatusCode status
});




}
/// @nodoc
class _$MemberMonthRowCopyWithImpl<$Res>
    implements $MemberMonthRowCopyWith<$Res> {
  _$MemberMonthRowCopyWithImpl(this._self, this._then);

  final MemberMonthRow _self;
  final $Res Function(MemberMonthRow) _then;

/// Create a copy of MemberMonthRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kametiId = null,Object? memberId = null,Object? monthIndex = null,Object? monthStart = null,Object? isCurrent = null,Object? due = null,Object? allocated = null,Object? remaining = null,Object? status = null,}) {
  return _then(MemberMonthRow(
kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,monthIndex: null == monthIndex ? _self.monthIndex : monthIndex // ignore: cast_nullable_to_non_nullable
as int,monthStart: null == monthStart ? _self.monthStart : monthStart // ignore: cast_nullable_to_non_nullable
as DateTime,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as Money,allocated: null == allocated ? _self.allocated : allocated // ignore: cast_nullable_to_non_nullable
as Money,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MonthStatusCode,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberMonthRow].
extension MemberMonthRowPatterns on MemberMonthRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberMonthRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberMonthRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberMonthRow value)  $default,){
final _that = this;
switch (_that) {
case _MemberMonthRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberMonthRow value)?  $default,){
final _that = this;
switch (_that) {
case _MemberMonthRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kametiId,  String memberId,  int monthIndex, @DateOnlyConverter()  DateTime monthStart,  bool isCurrent, @MoneyConverter()  Money due, @MoneyConverter()  Money allocated, @MoneyConverter()  Money remaining,  MonthStatusCode status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberMonthRow() when $default != null:
return $default(_that.kametiId,_that.memberId,_that.monthIndex,_that.monthStart,_that.isCurrent,_that.due,_that.allocated,_that.remaining,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kametiId,  String memberId,  int monthIndex, @DateOnlyConverter()  DateTime monthStart,  bool isCurrent, @MoneyConverter()  Money due, @MoneyConverter()  Money allocated, @MoneyConverter()  Money remaining,  MonthStatusCode status)  $default,) {final _that = this;
switch (_that) {
case _MemberMonthRow():
return $default(_that.kametiId,_that.memberId,_that.monthIndex,_that.monthStart,_that.isCurrent,_that.due,_that.allocated,_that.remaining,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kametiId,  String memberId,  int monthIndex, @DateOnlyConverter()  DateTime monthStart,  bool isCurrent, @MoneyConverter()  Money due, @MoneyConverter()  Money allocated, @MoneyConverter()  Money remaining,  MonthStatusCode status)?  $default,) {final _that = this;
switch (_that) {
case _MemberMonthRow() when $default != null:
return $default(_that.kametiId,_that.memberId,_that.monthIndex,_that.monthStart,_that.isCurrent,_that.due,_that.allocated,_that.remaining,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberMonthRow implements MemberMonthRow {
  const _MemberMonthRow({required this.kametiId, required this.memberId, required this.monthIndex, @DateOnlyConverter() required this.monthStart, required this.isCurrent, @MoneyConverter() required this.due, @MoneyConverter() required this.allocated, @MoneyConverter() required this.remaining, required this.status});
  factory _MemberMonthRow.fromJson(Map<String, dynamic> json) => _$MemberMonthRowFromJson(json);

@override final  String kametiId;
@override final  String memberId;
@override final  int monthIndex;
@override@DateOnlyConverter() final  DateTime monthStart;
@override final  bool isCurrent;
@override@MoneyConverter() final  Money due;
@override@MoneyConverter() final  Money allocated;
@override@MoneyConverter() final  Money remaining;
@override final  MonthStatusCode status;

/// Create a copy of MemberMonthRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberMonthRowCopyWith<_MemberMonthRow> get copyWith => __$MemberMonthRowCopyWithImpl<_MemberMonthRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberMonthRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberMonthRow&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.monthIndex, monthIndex) || other.monthIndex == monthIndex)&&(identical(other.monthStart, monthStart) || other.monthStart == monthStart)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.due, due) || other.due == due)&&(identical(other.allocated, allocated) || other.allocated == allocated)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kametiId,memberId,monthIndex,monthStart,isCurrent,due,allocated,remaining,status);
}

@override
String toString() {
    return 'MemberMonthRow(kametiId: $kametiId, memberId: $memberId, monthIndex: $monthIndex, monthStart: $monthStart, isCurrent: $isCurrent, due: $due, allocated: $allocated, remaining: $remaining, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MemberMonthRowCopyWith<$Res> implements $MemberMonthRowCopyWith<$Res> {
  factory _$MemberMonthRowCopyWith(_MemberMonthRow value, $Res Function(_MemberMonthRow) _then) = __$MemberMonthRowCopyWithImpl;
@override @useResult
$Res call({
 String kametiId, String memberId, int monthIndex,@DateOnlyConverter() DateTime monthStart, bool isCurrent,@MoneyConverter() Money due,@MoneyConverter() Money allocated,@MoneyConverter() Money remaining, MonthStatusCode status
});




}
/// @nodoc
class __$MemberMonthRowCopyWithImpl<$Res>
    implements _$MemberMonthRowCopyWith<$Res> {
  __$MemberMonthRowCopyWithImpl(this._self, this._then);

  final _MemberMonthRow _self;
  final $Res Function(_MemberMonthRow) _then;

/// Create a copy of MemberMonthRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kametiId = null,Object? memberId = null,Object? monthIndex = null,Object? monthStart = null,Object? isCurrent = null,Object? due = null,Object? allocated = null,Object? remaining = null,Object? status = null,}) {
  return _then(_MemberMonthRow(
kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,monthIndex: null == monthIndex ? _self.monthIndex : monthIndex // ignore: cast_nullable_to_non_nullable
as int,monthStart: null == monthStart ? _self.monthStart : monthStart // ignore: cast_nullable_to_non_nullable
as DateTime,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as Money,allocated: null == allocated ? _self.allocated : allocated // ignore: cast_nullable_to_non_nullable
as Money,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as Money,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MonthStatusCode,
  ));
}


}


/// @nodoc
mixin _$MonthCollectionRow {

 String get kametiId; int get monthIndex;@DateOnlyConverter() DateTime get monthStart; bool get isCurrent;@MoneyConverter() Money get target;@MoneyConverter() Money get received;@MoneyConverter() Money get covered; int get paidCount; int get memberCount;@MoneyConverter() Money get payoutShortfall;@MoneyConverter() Money get paidOut; int get recipients; int get recipientsPaid;@MoneyConverter() Money get paidOutShortBy; MonthCollectionState get state;
/// Create a copy of MonthCollectionRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthCollectionRowCopyWith<MonthCollectionRow> get copyWith => _$MonthCollectionRowCopyWithImpl<MonthCollectionRow>(this as MonthCollectionRow, _$identity);

  /// Serializes this MonthCollectionRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MonthCollectionRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthCollectionRow&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.monthIndex, _this.monthIndex) || other.monthIndex == _this.monthIndex)&&(identical(other.monthStart, _this.monthStart) || other.monthStart == _this.monthStart)&&(identical(other.isCurrent, _this.isCurrent) || other.isCurrent == _this.isCurrent)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.received, _this.received) || other.received == _this.received)&&(identical(other.covered, _this.covered) || other.covered == _this.covered)&&(identical(other.paidCount, _this.paidCount) || other.paidCount == _this.paidCount)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&(identical(other.payoutShortfall, _this.payoutShortfall) || other.payoutShortfall == _this.payoutShortfall)&&(identical(other.paidOut, _this.paidOut) || other.paidOut == _this.paidOut)&&(identical(other.recipients, _this.recipients) || other.recipients == _this.recipients)&&(identical(other.recipientsPaid, _this.recipientsPaid) || other.recipientsPaid == _this.recipientsPaid)&&(identical(other.paidOutShortBy, _this.paidOutShortBy) || other.paidOutShortBy == _this.paidOutShortBy)&&(identical(other.state, _this.state) || other.state == _this.state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MonthCollectionRow;
  return Object.hash(runtimeType,_this.kametiId,_this.monthIndex,_this.monthStart,_this.isCurrent,_this.target,_this.received,_this.covered,_this.paidCount,_this.memberCount,_this.payoutShortfall,_this.paidOut,_this.recipients,_this.recipientsPaid,_this.paidOutShortBy,_this.state);
}

@override
String toString() {
  final _this = this as MonthCollectionRow;
  return 'MonthCollectionRow(kametiId: ${_this.kametiId}, monthIndex: ${_this.monthIndex}, monthStart: ${_this.monthStart}, isCurrent: ${_this.isCurrent}, target: ${_this.target}, received: ${_this.received}, covered: ${_this.covered}, paidCount: ${_this.paidCount}, memberCount: ${_this.memberCount}, payoutShortfall: ${_this.payoutShortfall}, paidOut: ${_this.paidOut}, recipients: ${_this.recipients}, recipientsPaid: ${_this.recipientsPaid}, paidOutShortBy: ${_this.paidOutShortBy}, state: ${_this.state})';
}


}

/// @nodoc
abstract mixin class $MonthCollectionRowCopyWith<$Res>  {
  factory $MonthCollectionRowCopyWith(MonthCollectionRow value, $Res Function(MonthCollectionRow) _then) = _$MonthCollectionRowCopyWithImpl;
@useResult
$Res call({
 String kametiId, int monthIndex,@DateOnlyConverter() DateTime monthStart, bool isCurrent,@MoneyConverter() Money target,@MoneyConverter() Money received,@MoneyConverter() Money covered, int paidCount, int memberCount,@MoneyConverter() Money payoutShortfall,@MoneyConverter() Money paidOut, int recipients, int recipientsPaid,@MoneyConverter() Money paidOutShortBy, MonthCollectionState state
});




}
/// @nodoc
class _$MonthCollectionRowCopyWithImpl<$Res>
    implements $MonthCollectionRowCopyWith<$Res> {
  _$MonthCollectionRowCopyWithImpl(this._self, this._then);

  final MonthCollectionRow _self;
  final $Res Function(MonthCollectionRow) _then;

/// Create a copy of MonthCollectionRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kametiId = null,Object? monthIndex = null,Object? monthStart = null,Object? isCurrent = null,Object? target = null,Object? received = null,Object? covered = null,Object? paidCount = null,Object? memberCount = null,Object? payoutShortfall = null,Object? paidOut = null,Object? recipients = null,Object? recipientsPaid = null,Object? paidOutShortBy = null,Object? state = null,}) {
  return _then(MonthCollectionRow(
kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,monthIndex: null == monthIndex ? _self.monthIndex : monthIndex // ignore: cast_nullable_to_non_nullable
as int,monthStart: null == monthStart ? _self.monthStart : monthStart // ignore: cast_nullable_to_non_nullable
as DateTime,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as Money,received: null == received ? _self.received : received // ignore: cast_nullable_to_non_nullable
as Money,covered: null == covered ? _self.covered : covered // ignore: cast_nullable_to_non_nullable
as Money,paidCount: null == paidCount ? _self.paidCount : paidCount // ignore: cast_nullable_to_non_nullable
as int,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,payoutShortfall: null == payoutShortfall ? _self.payoutShortfall : payoutShortfall // ignore: cast_nullable_to_non_nullable
as Money,paidOut: null == paidOut ? _self.paidOut : paidOut // ignore: cast_nullable_to_non_nullable
as Money,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as int,recipientsPaid: null == recipientsPaid ? _self.recipientsPaid : recipientsPaid // ignore: cast_nullable_to_non_nullable
as int,paidOutShortBy: null == paidOutShortBy ? _self.paidOutShortBy : paidOutShortBy // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as MonthCollectionState,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthCollectionRow].
extension MonthCollectionRowPatterns on MonthCollectionRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthCollectionRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthCollectionRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthCollectionRow value)  $default,){
final _that = this;
switch (_that) {
case _MonthCollectionRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthCollectionRow value)?  $default,){
final _that = this;
switch (_that) {
case _MonthCollectionRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kametiId,  int monthIndex, @DateOnlyConverter()  DateTime monthStart,  bool isCurrent, @MoneyConverter()  Money target, @MoneyConverter()  Money received, @MoneyConverter()  Money covered,  int paidCount,  int memberCount, @MoneyConverter()  Money payoutShortfall, @MoneyConverter()  Money paidOut,  int recipients,  int recipientsPaid, @MoneyConverter()  Money paidOutShortBy,  MonthCollectionState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthCollectionRow() when $default != null:
return $default(_that.kametiId,_that.monthIndex,_that.monthStart,_that.isCurrent,_that.target,_that.received,_that.covered,_that.paidCount,_that.memberCount,_that.payoutShortfall,_that.paidOut,_that.recipients,_that.recipientsPaid,_that.paidOutShortBy,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kametiId,  int monthIndex, @DateOnlyConverter()  DateTime monthStart,  bool isCurrent, @MoneyConverter()  Money target, @MoneyConverter()  Money received, @MoneyConverter()  Money covered,  int paidCount,  int memberCount, @MoneyConverter()  Money payoutShortfall, @MoneyConverter()  Money paidOut,  int recipients,  int recipientsPaid, @MoneyConverter()  Money paidOutShortBy,  MonthCollectionState state)  $default,) {final _that = this;
switch (_that) {
case _MonthCollectionRow():
return $default(_that.kametiId,_that.monthIndex,_that.monthStart,_that.isCurrent,_that.target,_that.received,_that.covered,_that.paidCount,_that.memberCount,_that.payoutShortfall,_that.paidOut,_that.recipients,_that.recipientsPaid,_that.paidOutShortBy,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kametiId,  int monthIndex, @DateOnlyConverter()  DateTime monthStart,  bool isCurrent, @MoneyConverter()  Money target, @MoneyConverter()  Money received, @MoneyConverter()  Money covered,  int paidCount,  int memberCount, @MoneyConverter()  Money payoutShortfall, @MoneyConverter()  Money paidOut,  int recipients,  int recipientsPaid, @MoneyConverter()  Money paidOutShortBy,  MonthCollectionState state)?  $default,) {final _that = this;
switch (_that) {
case _MonthCollectionRow() when $default != null:
return $default(_that.kametiId,_that.monthIndex,_that.monthStart,_that.isCurrent,_that.target,_that.received,_that.covered,_that.paidCount,_that.memberCount,_that.payoutShortfall,_that.paidOut,_that.recipients,_that.recipientsPaid,_that.paidOutShortBy,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthCollectionRow implements MonthCollectionRow {
  const _MonthCollectionRow({required this.kametiId, required this.monthIndex, @DateOnlyConverter() required this.monthStart, required this.isCurrent, @MoneyConverter() required this.target, @MoneyConverter() required this.received, @MoneyConverter() required this.covered, required this.paidCount, required this.memberCount, @MoneyConverter() required this.payoutShortfall, @MoneyConverter() required this.paidOut, required this.recipients, required this.recipientsPaid, @MoneyConverter() required this.paidOutShortBy, required this.state});
  factory _MonthCollectionRow.fromJson(Map<String, dynamic> json) => _$MonthCollectionRowFromJson(json);

@override final  String kametiId;
@override final  int monthIndex;
@override@DateOnlyConverter() final  DateTime monthStart;
@override final  bool isCurrent;
@override@MoneyConverter() final  Money target;
@override@MoneyConverter() final  Money received;
@override@MoneyConverter() final  Money covered;
@override final  int paidCount;
@override final  int memberCount;
@override@MoneyConverter() final  Money payoutShortfall;
@override@MoneyConverter() final  Money paidOut;
@override final  int recipients;
@override final  int recipientsPaid;
@override@MoneyConverter() final  Money paidOutShortBy;
@override final  MonthCollectionState state;

/// Create a copy of MonthCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthCollectionRowCopyWith<_MonthCollectionRow> get copyWith => __$MonthCollectionRowCopyWithImpl<_MonthCollectionRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthCollectionRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthCollectionRow&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.monthIndex, monthIndex) || other.monthIndex == monthIndex)&&(identical(other.monthStart, monthStart) || other.monthStart == monthStart)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.target, target) || other.target == target)&&(identical(other.received, received) || other.received == received)&&(identical(other.covered, covered) || other.covered == covered)&&(identical(other.paidCount, paidCount) || other.paidCount == paidCount)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.payoutShortfall, payoutShortfall) || other.payoutShortfall == payoutShortfall)&&(identical(other.paidOut, paidOut) || other.paidOut == paidOut)&&(identical(other.recipients, recipients) || other.recipients == recipients)&&(identical(other.recipientsPaid, recipientsPaid) || other.recipientsPaid == recipientsPaid)&&(identical(other.paidOutShortBy, paidOutShortBy) || other.paidOutShortBy == paidOutShortBy)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kametiId,monthIndex,monthStart,isCurrent,target,received,covered,paidCount,memberCount,payoutShortfall,paidOut,recipients,recipientsPaid,paidOutShortBy,state);
}

@override
String toString() {
    return 'MonthCollectionRow(kametiId: $kametiId, monthIndex: $monthIndex, monthStart: $monthStart, isCurrent: $isCurrent, target: $target, received: $received, covered: $covered, paidCount: $paidCount, memberCount: $memberCount, payoutShortfall: $payoutShortfall, paidOut: $paidOut, recipients: $recipients, recipientsPaid: $recipientsPaid, paidOutShortBy: $paidOutShortBy, state: $state)';
}


}

/// @nodoc
abstract mixin class _$MonthCollectionRowCopyWith<$Res> implements $MonthCollectionRowCopyWith<$Res> {
  factory _$MonthCollectionRowCopyWith(_MonthCollectionRow value, $Res Function(_MonthCollectionRow) _then) = __$MonthCollectionRowCopyWithImpl;
@override @useResult
$Res call({
 String kametiId, int monthIndex,@DateOnlyConverter() DateTime monthStart, bool isCurrent,@MoneyConverter() Money target,@MoneyConverter() Money received,@MoneyConverter() Money covered, int paidCount, int memberCount,@MoneyConverter() Money payoutShortfall,@MoneyConverter() Money paidOut, int recipients, int recipientsPaid,@MoneyConverter() Money paidOutShortBy, MonthCollectionState state
});




}
/// @nodoc
class __$MonthCollectionRowCopyWithImpl<$Res>
    implements _$MonthCollectionRowCopyWith<$Res> {
  __$MonthCollectionRowCopyWithImpl(this._self, this._then);

  final _MonthCollectionRow _self;
  final $Res Function(_MonthCollectionRow) _then;

/// Create a copy of MonthCollectionRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kametiId = null,Object? monthIndex = null,Object? monthStart = null,Object? isCurrent = null,Object? target = null,Object? received = null,Object? covered = null,Object? paidCount = null,Object? memberCount = null,Object? payoutShortfall = null,Object? paidOut = null,Object? recipients = null,Object? recipientsPaid = null,Object? paidOutShortBy = null,Object? state = null,}) {
  return _then(_MonthCollectionRow(
kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,monthIndex: null == monthIndex ? _self.monthIndex : monthIndex // ignore: cast_nullable_to_non_nullable
as int,monthStart: null == monthStart ? _self.monthStart : monthStart // ignore: cast_nullable_to_non_nullable
as DateTime,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as Money,received: null == received ? _self.received : received // ignore: cast_nullable_to_non_nullable
as Money,covered: null == covered ? _self.covered : covered // ignore: cast_nullable_to_non_nullable
as Money,paidCount: null == paidCount ? _self.paidCount : paidCount // ignore: cast_nullable_to_non_nullable
as int,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,payoutShortfall: null == payoutShortfall ? _self.payoutShortfall : payoutShortfall // ignore: cast_nullable_to_non_nullable
as Money,paidOut: null == paidOut ? _self.paidOut : paidOut // ignore: cast_nullable_to_non_nullable
as Money,recipients: null == recipients ? _self.recipients : recipients // ignore: cast_nullable_to_non_nullable
as int,recipientsPaid: null == recipientsPaid ? _self.recipientsPaid : recipientsPaid // ignore: cast_nullable_to_non_nullable
as int,paidOutShortBy: null == paidOutShortBy ? _self.paidOutShortBy : paidOutShortBy // ignore: cast_nullable_to_non_nullable
as Money,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as MonthCollectionState,
  ));
}


}

// dart format on
