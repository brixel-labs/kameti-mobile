// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payment {

 String get id; String get kametiId; String get memberId;@MoneyConverter() Money get amount;@DateOnlyConverter() DateTime get receivedOn; PaymentMethod get method; DateTime get createdAt; String? get reference; String? get note; String? get paidByName; DateTime? get voidedAt; String? get voidReason;
/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCopyWith<Payment> get copyWith => _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Payment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.receivedOn, _this.receivedOn) || other.receivedOn == _this.receivedOn)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.paidByName, _this.paidByName) || other.paidByName == _this.paidByName)&&(identical(other.voidedAt, _this.voidedAt) || other.voidedAt == _this.voidedAt)&&(identical(other.voidReason, _this.voidReason) || other.voidReason == _this.voidReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Payment;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.memberId,_this.amount,_this.receivedOn,_this.method,_this.createdAt,_this.reference,_this.note,_this.paidByName,_this.voidedAt,_this.voidReason);
}

@override
String toString() {
  final _this = this as Payment;
  return 'Payment(id: ${_this.id}, kametiId: ${_this.kametiId}, memberId: ${_this.memberId}, amount: ${_this.amount}, receivedOn: ${_this.receivedOn}, method: ${_this.method}, createdAt: ${_this.createdAt}, reference: ${_this.reference}, note: ${_this.note}, paidByName: ${_this.paidByName}, voidedAt: ${_this.voidedAt}, voidReason: ${_this.voidReason})';
}


}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res>  {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) = _$PaymentCopyWithImpl;
@useResult
$Res call({
 String id, String kametiId, String memberId,@MoneyConverter() Money amount,@DateOnlyConverter() DateTime receivedOn, PaymentMethod method, DateTime createdAt, String? reference, String? note, String? paidByName, DateTime? voidedAt, String? voidReason
});




}
/// @nodoc
class _$PaymentCopyWithImpl<$Res>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? memberId = null,Object? amount = null,Object? receivedOn = null,Object? method = null,Object? createdAt = null,Object? reference = freezed,Object? note = freezed,Object? paidByName = freezed,Object? voidedAt = freezed,Object? voidReason = freezed,}) {
  return _then(Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,receivedOn: null == receivedOn ? _self.receivedOn : receivedOn // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,paidByName: freezed == paidByName ? _self.paidByName : paidByName // ignore: cast_nullable_to_non_nullable
as String?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payment value)  $default,){
final _that = this;
switch (_that) {
case _Payment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payment value)?  $default,){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kametiId,  String memberId, @MoneyConverter()  Money amount, @DateOnlyConverter()  DateTime receivedOn,  PaymentMethod method,  DateTime createdAt,  String? reference,  String? note,  String? paidByName,  DateTime? voidedAt,  String? voidReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.kametiId,_that.memberId,_that.amount,_that.receivedOn,_that.method,_that.createdAt,_that.reference,_that.note,_that.paidByName,_that.voidedAt,_that.voidReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kametiId,  String memberId, @MoneyConverter()  Money amount, @DateOnlyConverter()  DateTime receivedOn,  PaymentMethod method,  DateTime createdAt,  String? reference,  String? note,  String? paidByName,  DateTime? voidedAt,  String? voidReason)  $default,) {final _that = this;
switch (_that) {
case _Payment():
return $default(_that.id,_that.kametiId,_that.memberId,_that.amount,_that.receivedOn,_that.method,_that.createdAt,_that.reference,_that.note,_that.paidByName,_that.voidedAt,_that.voidReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kametiId,  String memberId, @MoneyConverter()  Money amount, @DateOnlyConverter()  DateTime receivedOn,  PaymentMethod method,  DateTime createdAt,  String? reference,  String? note,  String? paidByName,  DateTime? voidedAt,  String? voidReason)?  $default,) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.kametiId,_that.memberId,_that.amount,_that.receivedOn,_that.method,_that.createdAt,_that.reference,_that.note,_that.paidByName,_that.voidedAt,_that.voidReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payment extends Payment {
  const _Payment({required this.id, required this.kametiId, required this.memberId, @MoneyConverter() required this.amount, @DateOnlyConverter() required this.receivedOn, required this.method, required this.createdAt, this.reference, this.note, this.paidByName, this.voidedAt, this.voidReason}): super._();
  factory _Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

@override final  String id;
@override final  String kametiId;
@override final  String memberId;
@override@MoneyConverter() final  Money amount;
@override@DateOnlyConverter() final  DateTime receivedOn;
@override final  PaymentMethod method;
@override final  DateTime createdAt;
@override final  String? reference;
@override final  String? note;
@override final  String? paidByName;
@override final  DateTime? voidedAt;
@override final  String? voidReason;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCopyWith<_Payment> get copyWith => __$PaymentCopyWithImpl<_Payment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.receivedOn, receivedOn) || other.receivedOn == receivedOn)&&(identical(other.method, method) || other.method == method)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.note, note) || other.note == note)&&(identical(other.paidByName, paidByName) || other.paidByName == paidByName)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,memberId,amount,receivedOn,method,createdAt,reference,note,paidByName,voidedAt,voidReason);
}

@override
String toString() {
    return 'Payment(id: $id, kametiId: $kametiId, memberId: $memberId, amount: $amount, receivedOn: $receivedOn, method: $method, createdAt: $createdAt, reference: $reference, note: $note, paidByName: $paidByName, voidedAt: $voidedAt, voidReason: $voidReason)';
}


}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) = __$PaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String kametiId, String memberId,@MoneyConverter() Money amount,@DateOnlyConverter() DateTime receivedOn, PaymentMethod method, DateTime createdAt, String? reference, String? note, String? paidByName, DateTime? voidedAt, String? voidReason
});




}
/// @nodoc
class __$PaymentCopyWithImpl<$Res>
    implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? memberId = null,Object? amount = null,Object? receivedOn = null,Object? method = null,Object? createdAt = null,Object? reference = freezed,Object? note = freezed,Object? paidByName = freezed,Object? voidedAt = freezed,Object? voidReason = freezed,}) {
  return _then(_Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,receivedOn: null == receivedOn ? _self.receivedOn : receivedOn // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,paidByName: freezed == paidByName ? _self.paidByName : paidByName // ignore: cast_nullable_to_non_nullable
as String?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Payout {

 String get id; String get kametiId; String get slotId; String get memberId;@MoneyConverter() Money get amount;@DateOnlyConverter() DateTime get paidOn; PaymentMethod get method; String? get reference; String? get note; DateTime? get voidedAt; String? get voidReason;
/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutCopyWith<Payout> get copyWith => _$PayoutCopyWithImpl<Payout>(this as Payout, _$identity);

  /// Serializes this Payout to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Payout;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payout&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.slotId, _this.slotId) || other.slotId == _this.slotId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.paidOn, _this.paidOn) || other.paidOn == _this.paidOn)&&(identical(other.method, _this.method) || other.method == _this.method)&&(identical(other.reference, _this.reference) || other.reference == _this.reference)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.voidedAt, _this.voidedAt) || other.voidedAt == _this.voidedAt)&&(identical(other.voidReason, _this.voidReason) || other.voidReason == _this.voidReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Payout;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.slotId,_this.memberId,_this.amount,_this.paidOn,_this.method,_this.reference,_this.note,_this.voidedAt,_this.voidReason);
}

@override
String toString() {
  final _this = this as Payout;
  return 'Payout(id: ${_this.id}, kametiId: ${_this.kametiId}, slotId: ${_this.slotId}, memberId: ${_this.memberId}, amount: ${_this.amount}, paidOn: ${_this.paidOn}, method: ${_this.method}, reference: ${_this.reference}, note: ${_this.note}, voidedAt: ${_this.voidedAt}, voidReason: ${_this.voidReason})';
}


}

/// @nodoc
abstract mixin class $PayoutCopyWith<$Res>  {
  factory $PayoutCopyWith(Payout value, $Res Function(Payout) _then) = _$PayoutCopyWithImpl;
@useResult
$Res call({
 String id, String kametiId, String slotId, String memberId,@MoneyConverter() Money amount,@DateOnlyConverter() DateTime paidOn, PaymentMethod method, String? reference, String? note, DateTime? voidedAt, String? voidReason
});




}
/// @nodoc
class _$PayoutCopyWithImpl<$Res>
    implements $PayoutCopyWith<$Res> {
  _$PayoutCopyWithImpl(this._self, this._then);

  final Payout _self;
  final $Res Function(Payout) _then;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? slotId = null,Object? memberId = null,Object? amount = null,Object? paidOn = null,Object? method = null,Object? reference = freezed,Object? note = freezed,Object? voidedAt = freezed,Object? voidReason = freezed,}) {
  return _then(Payout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,paidOn: null == paidOn ? _self.paidOn : paidOn // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payout].
extension PayoutPatterns on Payout {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payout value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payout() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payout value)  $default,){
final _that = this;
switch (_that) {
case _Payout():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payout value)?  $default,){
final _that = this;
switch (_that) {
case _Payout() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kametiId,  String slotId,  String memberId, @MoneyConverter()  Money amount, @DateOnlyConverter()  DateTime paidOn,  PaymentMethod method,  String? reference,  String? note,  DateTime? voidedAt,  String? voidReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that.id,_that.kametiId,_that.slotId,_that.memberId,_that.amount,_that.paidOn,_that.method,_that.reference,_that.note,_that.voidedAt,_that.voidReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kametiId,  String slotId,  String memberId, @MoneyConverter()  Money amount, @DateOnlyConverter()  DateTime paidOn,  PaymentMethod method,  String? reference,  String? note,  DateTime? voidedAt,  String? voidReason)  $default,) {final _that = this;
switch (_that) {
case _Payout():
return $default(_that.id,_that.kametiId,_that.slotId,_that.memberId,_that.amount,_that.paidOn,_that.method,_that.reference,_that.note,_that.voidedAt,_that.voidReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kametiId,  String slotId,  String memberId, @MoneyConverter()  Money amount, @DateOnlyConverter()  DateTime paidOn,  PaymentMethod method,  String? reference,  String? note,  DateTime? voidedAt,  String? voidReason)?  $default,) {final _that = this;
switch (_that) {
case _Payout() when $default != null:
return $default(_that.id,_that.kametiId,_that.slotId,_that.memberId,_that.amount,_that.paidOn,_that.method,_that.reference,_that.note,_that.voidedAt,_that.voidReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Payout extends Payout {
  const _Payout({required this.id, required this.kametiId, required this.slotId, required this.memberId, @MoneyConverter() required this.amount, @DateOnlyConverter() required this.paidOn, required this.method, this.reference, this.note, this.voidedAt, this.voidReason}): super._();
  factory _Payout.fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);

@override final  String id;
@override final  String kametiId;
@override final  String slotId;
@override final  String memberId;
@override@MoneyConverter() final  Money amount;
@override@DateOnlyConverter() final  DateTime paidOn;
@override final  PaymentMethod method;
@override final  String? reference;
@override final  String? note;
@override final  DateTime? voidedAt;
@override final  String? voidReason;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutCopyWith<_Payout> get copyWith => __$PayoutCopyWithImpl<_Payout>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayoutToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payout&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.slotId, slotId) || other.slotId == slotId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.paidOn, paidOn) || other.paidOn == paidOn)&&(identical(other.method, method) || other.method == method)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.note, note) || other.note == note)&&(identical(other.voidedAt, voidedAt) || other.voidedAt == voidedAt)&&(identical(other.voidReason, voidReason) || other.voidReason == voidReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,slotId,memberId,amount,paidOn,method,reference,note,voidedAt,voidReason);
}

@override
String toString() {
    return 'Payout(id: $id, kametiId: $kametiId, slotId: $slotId, memberId: $memberId, amount: $amount, paidOn: $paidOn, method: $method, reference: $reference, note: $note, voidedAt: $voidedAt, voidReason: $voidReason)';
}


}

/// @nodoc
abstract mixin class _$PayoutCopyWith<$Res> implements $PayoutCopyWith<$Res> {
  factory _$PayoutCopyWith(_Payout value, $Res Function(_Payout) _then) = __$PayoutCopyWithImpl;
@override @useResult
$Res call({
 String id, String kametiId, String slotId, String memberId,@MoneyConverter() Money amount,@DateOnlyConverter() DateTime paidOn, PaymentMethod method, String? reference, String? note, DateTime? voidedAt, String? voidReason
});




}
/// @nodoc
class __$PayoutCopyWithImpl<$Res>
    implements _$PayoutCopyWith<$Res> {
  __$PayoutCopyWithImpl(this._self, this._then);

  final _Payout _self;
  final $Res Function(_Payout) _then;

/// Create a copy of Payout
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? slotId = null,Object? memberId = null,Object? amount = null,Object? paidOn = null,Object? method = null,Object? reference = freezed,Object? note = freezed,Object? voidedAt = freezed,Object? voidReason = freezed,}) {
  return _then(_Payout(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,slotId: null == slotId ? _self.slotId : slotId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,paidOn: null == paidOn ? _self.paidOn : paidOn // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,voidedAt: freezed == voidedAt ? _self.voidedAt : voidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,voidReason: freezed == voidReason ? _self.voidReason : voidReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
