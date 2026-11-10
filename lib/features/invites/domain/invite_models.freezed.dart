// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Invite {

 String get id; String get kametiId; String get memberId; InviteStatus get status; DateTime get expiresAt; int get sendCount; String? get email; DateTime? get sentAt;/// The email the invitee signed in with. Show it masked.
 String? get acceptedEmail;
/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCopyWith<Invite> get copyWith => _$InviteCopyWithImpl<Invite>(this as Invite, _$identity);

  /// Serializes this Invite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Invite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invite&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.sendCount, _this.sendCount) || other.sendCount == _this.sendCount)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.sentAt, _this.sentAt) || other.sentAt == _this.sentAt)&&(identical(other.acceptedEmail, _this.acceptedEmail) || other.acceptedEmail == _this.acceptedEmail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Invite;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.memberId,_this.status,_this.expiresAt,_this.sendCount,_this.email,_this.sentAt,_this.acceptedEmail);
}

@override
String toString() {
  final _this = this as Invite;
  return 'Invite(id: ${_this.id}, kametiId: ${_this.kametiId}, memberId: ${_this.memberId}, status: ${_this.status}, expiresAt: ${_this.expiresAt}, sendCount: ${_this.sendCount}, email: ${_this.email}, sentAt: ${_this.sentAt}, acceptedEmail: ${_this.acceptedEmail})';
}


}

/// @nodoc
abstract mixin class $InviteCopyWith<$Res>  {
  factory $InviteCopyWith(Invite value, $Res Function(Invite) _then) = _$InviteCopyWithImpl;
@useResult
$Res call({
 String id, String kametiId, String memberId, InviteStatus status, DateTime expiresAt, int sendCount, String? email, DateTime? sentAt, String? acceptedEmail
});




}
/// @nodoc
class _$InviteCopyWithImpl<$Res>
    implements $InviteCopyWith<$Res> {
  _$InviteCopyWithImpl(this._self, this._then);

  final Invite _self;
  final $Res Function(Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? memberId = null,Object? status = null,Object? expiresAt = null,Object? sendCount = null,Object? email = freezed,Object? sentAt = freezed,Object? acceptedEmail = freezed,}) {
  return _then(Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,sendCount: null == sendCount ? _self.sendCount : sendCount // ignore: cast_nullable_to_non_nullable
as int,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedEmail: freezed == acceptedEmail ? _self.acceptedEmail : acceptedEmail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Invite].
extension InvitePatterns on Invite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invite value)  $default,){
final _that = this;
switch (_that) {
case _Invite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invite value)?  $default,){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kametiId,  String memberId,  InviteStatus status,  DateTime expiresAt,  int sendCount,  String? email,  DateTime? sentAt,  String? acceptedEmail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.kametiId,_that.memberId,_that.status,_that.expiresAt,_that.sendCount,_that.email,_that.sentAt,_that.acceptedEmail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kametiId,  String memberId,  InviteStatus status,  DateTime expiresAt,  int sendCount,  String? email,  DateTime? sentAt,  String? acceptedEmail)  $default,) {final _that = this;
switch (_that) {
case _Invite():
return $default(_that.id,_that.kametiId,_that.memberId,_that.status,_that.expiresAt,_that.sendCount,_that.email,_that.sentAt,_that.acceptedEmail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kametiId,  String memberId,  InviteStatus status,  DateTime expiresAt,  int sendCount,  String? email,  DateTime? sentAt,  String? acceptedEmail)?  $default,) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.kametiId,_that.memberId,_that.status,_that.expiresAt,_that.sendCount,_that.email,_that.sentAt,_that.acceptedEmail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invite extends Invite {
  const _Invite({required this.id, required this.kametiId, required this.memberId, required this.status, required this.expiresAt, required this.sendCount, this.email, this.sentAt, this.acceptedEmail}): super._();
  factory _Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

@override final  String id;
@override final  String kametiId;
@override final  String memberId;
@override final  InviteStatus status;
@override final  DateTime expiresAt;
@override final  int sendCount;
@override final  String? email;
@override final  DateTime? sentAt;
/// The email the invitee signed in with. Show it masked.
@override final  String? acceptedEmail;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCopyWith<_Invite> get copyWith => __$InviteCopyWithImpl<_Invite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.sendCount, sendCount) || other.sendCount == sendCount)&&(identical(other.email, email) || other.email == email)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.acceptedEmail, acceptedEmail) || other.acceptedEmail == acceptedEmail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,memberId,status,expiresAt,sendCount,email,sentAt,acceptedEmail);
}

@override
String toString() {
    return 'Invite(id: $id, kametiId: $kametiId, memberId: $memberId, status: $status, expiresAt: $expiresAt, sendCount: $sendCount, email: $email, sentAt: $sentAt, acceptedEmail: $acceptedEmail)';
}


}

/// @nodoc
abstract mixin class _$InviteCopyWith<$Res> implements $InviteCopyWith<$Res> {
  factory _$InviteCopyWith(_Invite value, $Res Function(_Invite) _then) = __$InviteCopyWithImpl;
@override @useResult
$Res call({
 String id, String kametiId, String memberId, InviteStatus status, DateTime expiresAt, int sendCount, String? email, DateTime? sentAt, String? acceptedEmail
});




}
/// @nodoc
class __$InviteCopyWithImpl<$Res>
    implements _$InviteCopyWith<$Res> {
  __$InviteCopyWithImpl(this._self, this._then);

  final _Invite _self;
  final $Res Function(_Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? memberId = null,Object? status = null,Object? expiresAt = null,Object? sendCount = null,Object? email = freezed,Object? sentAt = freezed,Object? acceptedEmail = freezed,}) {
  return _then(_Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,sendCount: null == sendCount ? _self.sendCount : sendCount // ignore: cast_nullable_to_non_nullable
as int,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedEmail: freezed == acceptedEmail ? _self.acceptedEmail : acceptedEmail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InviteLink {

 String get inviteId; String get memberId; String get token; String get code; String get link; DateTime get expiresAt; String? get email;
/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteLinkCopyWith<InviteLink> get copyWith => _$InviteLinkCopyWithImpl<InviteLink>(this as InviteLink, _$identity);

  /// Serializes this InviteLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InviteLink;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteLink&&(identical(other.inviteId, _this.inviteId) || other.inviteId == _this.inviteId)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.link, _this.link) || other.link == _this.link)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.email, _this.email) || other.email == _this.email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InviteLink;
  return Object.hash(runtimeType,_this.inviteId,_this.memberId,_this.token,_this.code,_this.link,_this.expiresAt,_this.email);
}

@override
String toString() {
  final _this = this as InviteLink;
  return 'InviteLink(inviteId: ${_this.inviteId}, memberId: ${_this.memberId}, token: ${_this.token}, code: ${_this.code}, link: ${_this.link}, expiresAt: ${_this.expiresAt}, email: ${_this.email})';
}


}

/// @nodoc
abstract mixin class $InviteLinkCopyWith<$Res>  {
  factory $InviteLinkCopyWith(InviteLink value, $Res Function(InviteLink) _then) = _$InviteLinkCopyWithImpl;
@useResult
$Res call({
 String inviteId, String memberId, String token, String code, String link, DateTime expiresAt, String? email
});




}
/// @nodoc
class _$InviteLinkCopyWithImpl<$Res>
    implements $InviteLinkCopyWith<$Res> {
  _$InviteLinkCopyWithImpl(this._self, this._then);

  final InviteLink _self;
  final $Res Function(InviteLink) _then;

/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inviteId = null,Object? memberId = null,Object? token = null,Object? code = null,Object? link = null,Object? expiresAt = null,Object? email = freezed,}) {
  return _then(InviteLink(
inviteId: null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteLink].
extension InviteLinkPatterns on InviteLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteLink value)  $default,){
final _that = this;
switch (_that) {
case _InviteLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteLink value)?  $default,){
final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String inviteId,  String memberId,  String token,  String code,  String link,  DateTime expiresAt,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
return $default(_that.inviteId,_that.memberId,_that.token,_that.code,_that.link,_that.expiresAt,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String inviteId,  String memberId,  String token,  String code,  String link,  DateTime expiresAt,  String? email)  $default,) {final _that = this;
switch (_that) {
case _InviteLink():
return $default(_that.inviteId,_that.memberId,_that.token,_that.code,_that.link,_that.expiresAt,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String inviteId,  String memberId,  String token,  String code,  String link,  DateTime expiresAt,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
return $default(_that.inviteId,_that.memberId,_that.token,_that.code,_that.link,_that.expiresAt,_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteLink implements InviteLink {
  const _InviteLink({required this.inviteId, required this.memberId, required this.token, required this.code, required this.link, required this.expiresAt, this.email});
  factory _InviteLink.fromJson(Map<String, dynamic> json) => _$InviteLinkFromJson(json);

@override final  String inviteId;
@override final  String memberId;
@override final  String token;
@override final  String code;
@override final  String link;
@override final  DateTime expiresAt;
@override final  String? email;

/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteLinkCopyWith<_InviteLink> get copyWith => __$InviteLinkCopyWithImpl<_InviteLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteLinkToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteLink&&(identical(other.inviteId, inviteId) || other.inviteId == inviteId)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.token, token) || other.token == token)&&(identical(other.code, code) || other.code == code)&&(identical(other.link, link) || other.link == link)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,inviteId,memberId,token,code,link,expiresAt,email);
}

@override
String toString() {
    return 'InviteLink(inviteId: $inviteId, memberId: $memberId, token: $token, code: $code, link: $link, expiresAt: $expiresAt, email: $email)';
}


}

/// @nodoc
abstract mixin class _$InviteLinkCopyWith<$Res> implements $InviteLinkCopyWith<$Res> {
  factory _$InviteLinkCopyWith(_InviteLink value, $Res Function(_InviteLink) _then) = __$InviteLinkCopyWithImpl;
@override @useResult
$Res call({
 String inviteId, String memberId, String token, String code, String link, DateTime expiresAt, String? email
});




}
/// @nodoc
class __$InviteLinkCopyWithImpl<$Res>
    implements _$InviteLinkCopyWith<$Res> {
  __$InviteLinkCopyWithImpl(this._self, this._then);

  final _InviteLink _self;
  final $Res Function(_InviteLink) _then;

/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inviteId = null,Object? memberId = null,Object? token = null,Object? code = null,Object? link = null,Object? expiresAt = null,Object? email = freezed,}) {
  return _then(_InviteLink(
inviteId: null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,memberId: null == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InviteShare {

 int get payoutMonthIndex;@MoneyConverter() Money get monthlyAmount;
/// Create a copy of InviteShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteShareCopyWith<InviteShare> get copyWith => _$InviteShareCopyWithImpl<InviteShare>(this as InviteShare, _$identity);

  /// Serializes this InviteShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InviteShare;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteShare&&(identical(other.payoutMonthIndex, _this.payoutMonthIndex) || other.payoutMonthIndex == _this.payoutMonthIndex)&&(identical(other.monthlyAmount, _this.monthlyAmount) || other.monthlyAmount == _this.monthlyAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InviteShare;
  return Object.hash(runtimeType,_this.payoutMonthIndex,_this.monthlyAmount);
}

@override
String toString() {
  final _this = this as InviteShare;
  return 'InviteShare(payoutMonthIndex: ${_this.payoutMonthIndex}, monthlyAmount: ${_this.monthlyAmount})';
}


}

/// @nodoc
abstract mixin class $InviteShareCopyWith<$Res>  {
  factory $InviteShareCopyWith(InviteShare value, $Res Function(InviteShare) _then) = _$InviteShareCopyWithImpl;
@useResult
$Res call({
 int payoutMonthIndex,@MoneyConverter() Money monthlyAmount
});




}
/// @nodoc
class _$InviteShareCopyWithImpl<$Res>
    implements $InviteShareCopyWith<$Res> {
  _$InviteShareCopyWithImpl(this._self, this._then);

  final InviteShare _self;
  final $Res Function(InviteShare) _then;

/// Create a copy of InviteShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payoutMonthIndex = null,Object? monthlyAmount = null,}) {
  return _then(InviteShare(
payoutMonthIndex: null == payoutMonthIndex ? _self.payoutMonthIndex : payoutMonthIndex // ignore: cast_nullable_to_non_nullable
as int,monthlyAmount: null == monthlyAmount ? _self.monthlyAmount : monthlyAmount // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteShare].
extension InviteSharePatterns on InviteShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteShare value)  $default,){
final _that = this;
switch (_that) {
case _InviteShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteShare value)?  $default,){
final _that = this;
switch (_that) {
case _InviteShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int payoutMonthIndex, @MoneyConverter()  Money monthlyAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteShare() when $default != null:
return $default(_that.payoutMonthIndex,_that.monthlyAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int payoutMonthIndex, @MoneyConverter()  Money monthlyAmount)  $default,) {final _that = this;
switch (_that) {
case _InviteShare():
return $default(_that.payoutMonthIndex,_that.monthlyAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int payoutMonthIndex, @MoneyConverter()  Money monthlyAmount)?  $default,) {final _that = this;
switch (_that) {
case _InviteShare() when $default != null:
return $default(_that.payoutMonthIndex,_that.monthlyAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteShare implements InviteShare {
  const _InviteShare({required this.payoutMonthIndex, @MoneyConverter() required this.monthlyAmount});
  factory _InviteShare.fromJson(Map<String, dynamic> json) => _$InviteShareFromJson(json);

@override final  int payoutMonthIndex;
@override@MoneyConverter() final  Money monthlyAmount;

/// Create a copy of InviteShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteShareCopyWith<_InviteShare> get copyWith => __$InviteShareCopyWithImpl<_InviteShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteShare&&(identical(other.payoutMonthIndex, payoutMonthIndex) || other.payoutMonthIndex == payoutMonthIndex)&&(identical(other.monthlyAmount, monthlyAmount) || other.monthlyAmount == monthlyAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,payoutMonthIndex,monthlyAmount);
}

@override
String toString() {
    return 'InviteShare(payoutMonthIndex: $payoutMonthIndex, monthlyAmount: $monthlyAmount)';
}


}

/// @nodoc
abstract mixin class _$InviteShareCopyWith<$Res> implements $InviteShareCopyWith<$Res> {
  factory _$InviteShareCopyWith(_InviteShare value, $Res Function(_InviteShare) _then) = __$InviteShareCopyWithImpl;
@override @useResult
$Res call({
 int payoutMonthIndex,@MoneyConverter() Money monthlyAmount
});




}
/// @nodoc
class __$InviteShareCopyWithImpl<$Res>
    implements _$InviteShareCopyWith<$Res> {
  __$InviteShareCopyWithImpl(this._self, this._then);

  final _InviteShare _self;
  final $Res Function(_InviteShare) _then;

/// Create a copy of InviteShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payoutMonthIndex = null,Object? monthlyAmount = null,}) {
  return _then(_InviteShare(
payoutMonthIndex: null == payoutMonthIndex ? _self.payoutMonthIndex : payoutMonthIndex // ignore: cast_nullable_to_non_nullable
as int,monthlyAmount: null == monthlyAmount ? _self.monthlyAmount : monthlyAmount // ignore: cast_nullable_to_non_nullable
as Money,
  ));
}


}


/// @nodoc
mixin _$InvitePreview {

 String get inviteId; String get status; bool get expired; DateTime get expiresAt; bool get emailMatches; String get kametiName; String get ownerName; String get memberName; List<InviteShare> get shares;
/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitePreviewCopyWith<InvitePreview> get copyWith => _$InvitePreviewCopyWithImpl<InvitePreview>(this as InvitePreview, _$identity);

  /// Serializes this InvitePreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitePreview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitePreview&&(identical(other.inviteId, _this.inviteId) || other.inviteId == _this.inviteId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.expired, _this.expired) || other.expired == _this.expired)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.emailMatches, _this.emailMatches) || other.emailMatches == _this.emailMatches)&&(identical(other.kametiName, _this.kametiName) || other.kametiName == _this.kametiName)&&(identical(other.ownerName, _this.ownerName) || other.ownerName == _this.ownerName)&&(identical(other.memberName, _this.memberName) || other.memberName == _this.memberName)&&const DeepCollectionEquality().equals(other.shares, _this.shares));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitePreview;
  return Object.hash(runtimeType,_this.inviteId,_this.status,_this.expired,_this.expiresAt,_this.emailMatches,_this.kametiName,_this.ownerName,_this.memberName,const DeepCollectionEquality().hash(_this.shares));
}

@override
String toString() {
  final _this = this as InvitePreview;
  return 'InvitePreview(inviteId: ${_this.inviteId}, status: ${_this.status}, expired: ${_this.expired}, expiresAt: ${_this.expiresAt}, emailMatches: ${_this.emailMatches}, kametiName: ${_this.kametiName}, ownerName: ${_this.ownerName}, memberName: ${_this.memberName}, shares: ${_this.shares})';
}


}

/// @nodoc
abstract mixin class $InvitePreviewCopyWith<$Res>  {
  factory $InvitePreviewCopyWith(InvitePreview value, $Res Function(InvitePreview) _then) = _$InvitePreviewCopyWithImpl;
@useResult
$Res call({
 String inviteId, String status, bool expired, DateTime expiresAt, bool emailMatches, String kametiName, String ownerName, String memberName, List<InviteShare> shares
});




}
/// @nodoc
class _$InvitePreviewCopyWithImpl<$Res>
    implements $InvitePreviewCopyWith<$Res> {
  _$InvitePreviewCopyWithImpl(this._self, this._then);

  final InvitePreview _self;
  final $Res Function(InvitePreview) _then;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inviteId = null,Object? status = null,Object? expired = null,Object? expiresAt = null,Object? emailMatches = null,Object? kametiName = null,Object? ownerName = null,Object? memberName = null,Object? shares = null,}) {
  return _then(InvitePreview(
inviteId: null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,emailMatches: null == emailMatches ? _self.emailMatches : emailMatches // ignore: cast_nullable_to_non_nullable
as bool,kametiName: null == kametiName ? _self.kametiName : kametiName // ignore: cast_nullable_to_non_nullable
as String,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,memberName: null == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String,shares: null == shares ? _self.shares : shares // ignore: cast_nullable_to_non_nullable
as List<InviteShare>,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitePreview].
extension InvitePreviewPatterns on InvitePreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitePreview value)  $default,){
final _that = this;
switch (_that) {
case _InvitePreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitePreview value)?  $default,){
final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String inviteId,  String status,  bool expired,  DateTime expiresAt,  bool emailMatches,  String kametiName,  String ownerName,  String memberName,  List<InviteShare> shares)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that.inviteId,_that.status,_that.expired,_that.expiresAt,_that.emailMatches,_that.kametiName,_that.ownerName,_that.memberName,_that.shares);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String inviteId,  String status,  bool expired,  DateTime expiresAt,  bool emailMatches,  String kametiName,  String ownerName,  String memberName,  List<InviteShare> shares)  $default,) {final _that = this;
switch (_that) {
case _InvitePreview():
return $default(_that.inviteId,_that.status,_that.expired,_that.expiresAt,_that.emailMatches,_that.kametiName,_that.ownerName,_that.memberName,_that.shares);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String inviteId,  String status,  bool expired,  DateTime expiresAt,  bool emailMatches,  String kametiName,  String ownerName,  String memberName,  List<InviteShare> shares)?  $default,) {final _that = this;
switch (_that) {
case _InvitePreview() when $default != null:
return $default(_that.inviteId,_that.status,_that.expired,_that.expiresAt,_that.emailMatches,_that.kametiName,_that.ownerName,_that.memberName,_that.shares);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitePreview extends InvitePreview {
  const _InvitePreview({required this.inviteId, required this.status, required this.expired, required this.expiresAt, required this.emailMatches, required this.kametiName, required this.ownerName, required this.memberName,  List<InviteShare> shares = const <InviteShare>[]}): _shares = shares,super._();
  factory _InvitePreview.fromJson(Map<String, dynamic> json) => _$InvitePreviewFromJson(json);

@override final  String inviteId;
@override final  String status;
@override final  bool expired;
@override final  DateTime expiresAt;
@override final  bool emailMatches;
@override final  String kametiName;
@override final  String ownerName;
@override final  String memberName;
 final  List<InviteShare> _shares;
@override@JsonKey() List<InviteShare> get shares {
  if (_shares is EqualUnmodifiableListView) return _shares;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shares);
}


/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitePreviewCopyWith<_InvitePreview> get copyWith => __$InvitePreviewCopyWithImpl<_InvitePreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitePreviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitePreview&&(identical(other.inviteId, inviteId) || other.inviteId == inviteId)&&(identical(other.status, status) || other.status == status)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.emailMatches, emailMatches) || other.emailMatches == emailMatches)&&(identical(other.kametiName, kametiName) || other.kametiName == kametiName)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&const DeepCollectionEquality().equals(other.shares, _shares));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,inviteId,status,expired,expiresAt,emailMatches,kametiName,ownerName,memberName,const DeepCollectionEquality().hash(_shares));
}

@override
String toString() {
    return 'InvitePreview(inviteId: $inviteId, status: $status, expired: $expired, expiresAt: $expiresAt, emailMatches: $emailMatches, kametiName: $kametiName, ownerName: $ownerName, memberName: $memberName, shares: $shares)';
}


}

/// @nodoc
abstract mixin class _$InvitePreviewCopyWith<$Res> implements $InvitePreviewCopyWith<$Res> {
  factory _$InvitePreviewCopyWith(_InvitePreview value, $Res Function(_InvitePreview) _then) = __$InvitePreviewCopyWithImpl;
@override @useResult
$Res call({
 String inviteId, String status, bool expired, DateTime expiresAt, bool emailMatches, String kametiName, String ownerName, String memberName, List<InviteShare> shares
});




}
/// @nodoc
class __$InvitePreviewCopyWithImpl<$Res>
    implements _$InvitePreviewCopyWith<$Res> {
  __$InvitePreviewCopyWithImpl(this._self, this._then);

  final _InvitePreview _self;
  final $Res Function(_InvitePreview) _then;

/// Create a copy of InvitePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inviteId = null,Object? status = null,Object? expired = null,Object? expiresAt = null,Object? emailMatches = null,Object? kametiName = null,Object? ownerName = null,Object? memberName = null,Object? shares = null,}) {
  return _then(_InvitePreview(
inviteId: null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,emailMatches: null == emailMatches ? _self.emailMatches : emailMatches // ignore: cast_nullable_to_non_nullable
as bool,kametiName: null == kametiName ? _self.kametiName : kametiName // ignore: cast_nullable_to_non_nullable
as String,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,memberName: null == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String,shares: null == shares ? _self._shares : shares // ignore: cast_nullable_to_non_nullable
as List<InviteShare>,
  ));
}


}


/// @nodoc
mixin _$MyInvitation {

 String get inviteId; String get kametiName; String get ownerName; String get memberName; DateTime get expiresAt; DateTime get createdAt;
/// Create a copy of MyInvitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyInvitationCopyWith<MyInvitation> get copyWith => _$MyInvitationCopyWithImpl<MyInvitation>(this as MyInvitation, _$identity);

  /// Serializes this MyInvitation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MyInvitation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyInvitation&&(identical(other.inviteId, _this.inviteId) || other.inviteId == _this.inviteId)&&(identical(other.kametiName, _this.kametiName) || other.kametiName == _this.kametiName)&&(identical(other.ownerName, _this.ownerName) || other.ownerName == _this.ownerName)&&(identical(other.memberName, _this.memberName) || other.memberName == _this.memberName)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MyInvitation;
  return Object.hash(runtimeType,_this.inviteId,_this.kametiName,_this.ownerName,_this.memberName,_this.expiresAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as MyInvitation;
  return 'MyInvitation(inviteId: ${_this.inviteId}, kametiName: ${_this.kametiName}, ownerName: ${_this.ownerName}, memberName: ${_this.memberName}, expiresAt: ${_this.expiresAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MyInvitationCopyWith<$Res>  {
  factory $MyInvitationCopyWith(MyInvitation value, $Res Function(MyInvitation) _then) = _$MyInvitationCopyWithImpl;
@useResult
$Res call({
 String inviteId, String kametiName, String ownerName, String memberName, DateTime expiresAt, DateTime createdAt
});




}
/// @nodoc
class _$MyInvitationCopyWithImpl<$Res>
    implements $MyInvitationCopyWith<$Res> {
  _$MyInvitationCopyWithImpl(this._self, this._then);

  final MyInvitation _self;
  final $Res Function(MyInvitation) _then;

/// Create a copy of MyInvitation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inviteId = null,Object? kametiName = null,Object? ownerName = null,Object? memberName = null,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(MyInvitation(
inviteId: null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,kametiName: null == kametiName ? _self.kametiName : kametiName // ignore: cast_nullable_to_non_nullable
as String,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,memberName: null == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MyInvitation].
extension MyInvitationPatterns on MyInvitation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyInvitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyInvitation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyInvitation value)  $default,){
final _that = this;
switch (_that) {
case _MyInvitation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyInvitation value)?  $default,){
final _that = this;
switch (_that) {
case _MyInvitation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String inviteId,  String kametiName,  String ownerName,  String memberName,  DateTime expiresAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyInvitation() when $default != null:
return $default(_that.inviteId,_that.kametiName,_that.ownerName,_that.memberName,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String inviteId,  String kametiName,  String ownerName,  String memberName,  DateTime expiresAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MyInvitation():
return $default(_that.inviteId,_that.kametiName,_that.ownerName,_that.memberName,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String inviteId,  String kametiName,  String ownerName,  String memberName,  DateTime expiresAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MyInvitation() when $default != null:
return $default(_that.inviteId,_that.kametiName,_that.ownerName,_that.memberName,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyInvitation implements MyInvitation {
  const _MyInvitation({required this.inviteId, required this.kametiName, required this.ownerName, required this.memberName, required this.expiresAt, required this.createdAt});
  factory _MyInvitation.fromJson(Map<String, dynamic> json) => _$MyInvitationFromJson(json);

@override final  String inviteId;
@override final  String kametiName;
@override final  String ownerName;
@override final  String memberName;
@override final  DateTime expiresAt;
@override final  DateTime createdAt;

/// Create a copy of MyInvitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyInvitationCopyWith<_MyInvitation> get copyWith => __$MyInvitationCopyWithImpl<_MyInvitation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyInvitationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyInvitation&&(identical(other.inviteId, inviteId) || other.inviteId == inviteId)&&(identical(other.kametiName, kametiName) || other.kametiName == kametiName)&&(identical(other.ownerName, ownerName) || other.ownerName == ownerName)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,inviteId,kametiName,ownerName,memberName,expiresAt,createdAt);
}

@override
String toString() {
    return 'MyInvitation(inviteId: $inviteId, kametiName: $kametiName, ownerName: $ownerName, memberName: $memberName, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MyInvitationCopyWith<$Res> implements $MyInvitationCopyWith<$Res> {
  factory _$MyInvitationCopyWith(_MyInvitation value, $Res Function(_MyInvitation) _then) = __$MyInvitationCopyWithImpl;
@override @useResult
$Res call({
 String inviteId, String kametiName, String ownerName, String memberName, DateTime expiresAt, DateTime createdAt
});




}
/// @nodoc
class __$MyInvitationCopyWithImpl<$Res>
    implements _$MyInvitationCopyWith<$Res> {
  __$MyInvitationCopyWithImpl(this._self, this._then);

  final _MyInvitation _self;
  final $Res Function(_MyInvitation) _then;

/// Create a copy of MyInvitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inviteId = null,Object? kametiName = null,Object? ownerName = null,Object? memberName = null,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(_MyInvitation(
inviteId: null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,kametiName: null == kametiName ? _self.kametiName : kametiName // ignore: cast_nullable_to_non_nullable
as String,ownerName: null == ownerName ? _self.ownerName : ownerName // ignore: cast_nullable_to_non_nullable
as String,memberName: null == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
