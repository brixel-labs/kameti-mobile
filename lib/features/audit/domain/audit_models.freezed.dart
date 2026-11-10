// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditEntry {

 int get id; String get kametiId; String get action; String get entity; DateTime get at; String? get memberId; String? get actorId; String? get entityId; Map<String, dynamic>? get before; Map<String, dynamic>? get after;
/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditEntryCopyWith<AuditEntry> get copyWith => _$AuditEntryCopyWithImpl<AuditEntry>(this as AuditEntry, _$identity);

  /// Serializes this AuditEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuditEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kametiId, _this.kametiId) || other.kametiId == _this.kametiId)&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.entity, _this.entity) || other.entity == _this.entity)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.memberId, _this.memberId) || other.memberId == _this.memberId)&&(identical(other.actorId, _this.actorId) || other.actorId == _this.actorId)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&const DeepCollectionEquality().equals(other.before, _this.before)&&const DeepCollectionEquality().equals(other.after, _this.after));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuditEntry;
  return Object.hash(runtimeType,_this.id,_this.kametiId,_this.action,_this.entity,_this.at,_this.memberId,_this.actorId,_this.entityId,const DeepCollectionEquality().hash(_this.before),const DeepCollectionEquality().hash(_this.after));
}

@override
String toString() {
  final _this = this as AuditEntry;
  return 'AuditEntry(id: ${_this.id}, kametiId: ${_this.kametiId}, action: ${_this.action}, entity: ${_this.entity}, at: ${_this.at}, memberId: ${_this.memberId}, actorId: ${_this.actorId}, entityId: ${_this.entityId}, before: ${_this.before}, after: ${_this.after})';
}


}

/// @nodoc
abstract mixin class $AuditEntryCopyWith<$Res>  {
  factory $AuditEntryCopyWith(AuditEntry value, $Res Function(AuditEntry) _then) = _$AuditEntryCopyWithImpl;
@useResult
$Res call({
 int id, String kametiId, String action, String entity, DateTime at, String? memberId, String? actorId, String? entityId, Map<String, dynamic>? before, Map<String, dynamic>? after
});




}
/// @nodoc
class _$AuditEntryCopyWithImpl<$Res>
    implements $AuditEntryCopyWith<$Res> {
  _$AuditEntryCopyWithImpl(this._self, this._then);

  final AuditEntry _self;
  final $Res Function(AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kametiId = null,Object? action = null,Object? entity = null,Object? at = null,Object? memberId = freezed,Object? actorId = freezed,Object? entityId = freezed,Object? before = freezed,Object? after = freezed,}) {
  return _then(AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,before: freezed == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,after: freezed == after ? _self.after : after // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditEntry].
extension AuditEntryPatterns on AuditEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditEntry value)  $default,){
final _that = this;
switch (_that) {
case _AuditEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditEntry value)?  $default,){
final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String kametiId,  String action,  String entity,  DateTime at,  String? memberId,  String? actorId,  String? entityId,  Map<String, dynamic>? before,  Map<String, dynamic>? after)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.kametiId,_that.action,_that.entity,_that.at,_that.memberId,_that.actorId,_that.entityId,_that.before,_that.after);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String kametiId,  String action,  String entity,  DateTime at,  String? memberId,  String? actorId,  String? entityId,  Map<String, dynamic>? before,  Map<String, dynamic>? after)  $default,) {final _that = this;
switch (_that) {
case _AuditEntry():
return $default(_that.id,_that.kametiId,_that.action,_that.entity,_that.at,_that.memberId,_that.actorId,_that.entityId,_that.before,_that.after);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String kametiId,  String action,  String entity,  DateTime at,  String? memberId,  String? actorId,  String? entityId,  Map<String, dynamic>? before,  Map<String, dynamic>? after)?  $default,) {final _that = this;
switch (_that) {
case _AuditEntry() when $default != null:
return $default(_that.id,_that.kametiId,_that.action,_that.entity,_that.at,_that.memberId,_that.actorId,_that.entityId,_that.before,_that.after);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditEntry implements AuditEntry {
  const _AuditEntry({required this.id, required this.kametiId, required this.action, required this.entity, required this.at, this.memberId, this.actorId, this.entityId,  Map<String, dynamic>? before,  Map<String, dynamic>? after}): _before = before,_after = after;
  factory _AuditEntry.fromJson(Map<String, dynamic> json) => _$AuditEntryFromJson(json);

@override final  int id;
@override final  String kametiId;
@override final  String action;
@override final  String entity;
@override final  DateTime at;
@override final  String? memberId;
@override final  String? actorId;
@override final  String? entityId;
 final  Map<String, dynamic>? _before;
@override Map<String, dynamic>? get before {
  final value = _before;
  if (value == null) return null;
  if (_before is EqualUnmodifiableMapView) return _before;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _after;
@override Map<String, dynamic>? get after {
  final value = _after;
  if (value == null) return null;
  if (_after is EqualUnmodifiableMapView) return _after;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditEntryCopyWith<_AuditEntry> get copyWith => __$AuditEntryCopyWithImpl<_AuditEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.kametiId, kametiId) || other.kametiId == kametiId)&&(identical(other.action, action) || other.action == action)&&(identical(other.entity, entity) || other.entity == entity)&&(identical(other.at, at) || other.at == at)&&(identical(other.memberId, memberId) || other.memberId == memberId)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&const DeepCollectionEquality().equals(other.before, _before)&&const DeepCollectionEquality().equals(other.after, _after));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kametiId,action,entity,at,memberId,actorId,entityId,const DeepCollectionEquality().hash(_before),const DeepCollectionEquality().hash(_after));
}

@override
String toString() {
    return 'AuditEntry(id: $id, kametiId: $kametiId, action: $action, entity: $entity, at: $at, memberId: $memberId, actorId: $actorId, entityId: $entityId, before: $before, after: $after)';
}


}

/// @nodoc
abstract mixin class _$AuditEntryCopyWith<$Res> implements $AuditEntryCopyWith<$Res> {
  factory _$AuditEntryCopyWith(_AuditEntry value, $Res Function(_AuditEntry) _then) = __$AuditEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String kametiId, String action, String entity, DateTime at, String? memberId, String? actorId, String? entityId, Map<String, dynamic>? before, Map<String, dynamic>? after
});




}
/// @nodoc
class __$AuditEntryCopyWithImpl<$Res>
    implements _$AuditEntryCopyWith<$Res> {
  __$AuditEntryCopyWithImpl(this._self, this._then);

  final _AuditEntry _self;
  final $Res Function(_AuditEntry) _then;

/// Create a copy of AuditEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kametiId = null,Object? action = null,Object? entity = null,Object? at = null,Object? memberId = freezed,Object? actorId = freezed,Object? entityId = freezed,Object? before = freezed,Object? after = freezed,}) {
  return _then(_AuditEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kametiId: null == kametiId ? _self.kametiId : kametiId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,memberId: freezed == memberId ? _self.memberId : memberId // ignore: cast_nullable_to_non_nullable
as String?,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,before: freezed == before ? _self._before : before // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,after: freezed == after ? _self._after : after // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
