// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ball_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BallEvent {

 int get batRuns; int get extraRuns; ExtraType get extraType; bool get isWicket; WicketType? get wicketType; String? get dismissedPlayerId; String? get dismissedPlayerName; String? get fielderId; String? get fielderName; String get batsmanId; String get batsmanName; String get bowlerId; String get bowlerName; String? get newBatsmanId; String? get newBatsmanName; DateTime get timestamp;
/// Create a copy of BallEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BallEventCopyWith<BallEvent> get copyWith => _$BallEventCopyWithImpl<BallEvent>(this as BallEvent, _$identity);

  /// Serializes this BallEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BallEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BallEvent&&(identical(other.batRuns, _this.batRuns) || other.batRuns == _this.batRuns)&&(identical(other.extraRuns, _this.extraRuns) || other.extraRuns == _this.extraRuns)&&(identical(other.extraType, _this.extraType) || other.extraType == _this.extraType)&&(identical(other.isWicket, _this.isWicket) || other.isWicket == _this.isWicket)&&(identical(other.wicketType, _this.wicketType) || other.wicketType == _this.wicketType)&&(identical(other.dismissedPlayerId, _this.dismissedPlayerId) || other.dismissedPlayerId == _this.dismissedPlayerId)&&(identical(other.dismissedPlayerName, _this.dismissedPlayerName) || other.dismissedPlayerName == _this.dismissedPlayerName)&&(identical(other.fielderId, _this.fielderId) || other.fielderId == _this.fielderId)&&(identical(other.fielderName, _this.fielderName) || other.fielderName == _this.fielderName)&&(identical(other.batsmanId, _this.batsmanId) || other.batsmanId == _this.batsmanId)&&(identical(other.batsmanName, _this.batsmanName) || other.batsmanName == _this.batsmanName)&&(identical(other.bowlerId, _this.bowlerId) || other.bowlerId == _this.bowlerId)&&(identical(other.bowlerName, _this.bowlerName) || other.bowlerName == _this.bowlerName)&&(identical(other.newBatsmanId, _this.newBatsmanId) || other.newBatsmanId == _this.newBatsmanId)&&(identical(other.newBatsmanName, _this.newBatsmanName) || other.newBatsmanName == _this.newBatsmanName)&&(identical(other.timestamp, _this.timestamp) || other.timestamp == _this.timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BallEvent;
  return Object.hash(runtimeType,_this.batRuns,_this.extraRuns,_this.extraType,_this.isWicket,_this.wicketType,_this.dismissedPlayerId,_this.dismissedPlayerName,_this.fielderId,_this.fielderName,_this.batsmanId,_this.batsmanName,_this.bowlerId,_this.bowlerName,_this.newBatsmanId,_this.newBatsmanName,_this.timestamp);
}

@override
String toString() {
  final _this = this as BallEvent;
  return 'BallEvent(batRuns: ${_this.batRuns}, extraRuns: ${_this.extraRuns}, extraType: ${_this.extraType}, isWicket: ${_this.isWicket}, wicketType: ${_this.wicketType}, dismissedPlayerId: ${_this.dismissedPlayerId}, dismissedPlayerName: ${_this.dismissedPlayerName}, fielderId: ${_this.fielderId}, fielderName: ${_this.fielderName}, batsmanId: ${_this.batsmanId}, batsmanName: ${_this.batsmanName}, bowlerId: ${_this.bowlerId}, bowlerName: ${_this.bowlerName}, newBatsmanId: ${_this.newBatsmanId}, newBatsmanName: ${_this.newBatsmanName}, timestamp: ${_this.timestamp})';
}


}

/// @nodoc
abstract mixin class $BallEventCopyWith<$Res>  {
  factory $BallEventCopyWith(BallEvent value, $Res Function(BallEvent) _then) = _$BallEventCopyWithImpl;
@useResult
$Res call({
 int batRuns, int extraRuns, ExtraType extraType, bool isWicket, WicketType? wicketType, String? dismissedPlayerId, String? dismissedPlayerName, String? fielderId, String? fielderName, String batsmanId, String batsmanName, String bowlerId, String bowlerName, String? newBatsmanId, String? newBatsmanName, DateTime timestamp
});




}
/// @nodoc
class _$BallEventCopyWithImpl<$Res>
    implements $BallEventCopyWith<$Res> {
  _$BallEventCopyWithImpl(this._self, this._then);

  final BallEvent _self;
  final $Res Function(BallEvent) _then;

/// Create a copy of BallEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? batRuns = null,Object? extraRuns = null,Object? extraType = null,Object? isWicket = null,Object? wicketType = freezed,Object? dismissedPlayerId = freezed,Object? dismissedPlayerName = freezed,Object? fielderId = freezed,Object? fielderName = freezed,Object? batsmanId = null,Object? batsmanName = null,Object? bowlerId = null,Object? bowlerName = null,Object? newBatsmanId = freezed,Object? newBatsmanName = freezed,Object? timestamp = null,}) {
  return _then(BallEvent(
batRuns: null == batRuns ? _self.batRuns : batRuns // ignore: cast_nullable_to_non_nullable
as int,extraRuns: null == extraRuns ? _self.extraRuns : extraRuns // ignore: cast_nullable_to_non_nullable
as int,extraType: null == extraType ? _self.extraType : extraType // ignore: cast_nullable_to_non_nullable
as ExtraType,isWicket: null == isWicket ? _self.isWicket : isWicket // ignore: cast_nullable_to_non_nullable
as bool,wicketType: freezed == wicketType ? _self.wicketType : wicketType // ignore: cast_nullable_to_non_nullable
as WicketType?,dismissedPlayerId: freezed == dismissedPlayerId ? _self.dismissedPlayerId : dismissedPlayerId // ignore: cast_nullable_to_non_nullable
as String?,dismissedPlayerName: freezed == dismissedPlayerName ? _self.dismissedPlayerName : dismissedPlayerName // ignore: cast_nullable_to_non_nullable
as String?,fielderId: freezed == fielderId ? _self.fielderId : fielderId // ignore: cast_nullable_to_non_nullable
as String?,fielderName: freezed == fielderName ? _self.fielderName : fielderName // ignore: cast_nullable_to_non_nullable
as String?,batsmanId: null == batsmanId ? _self.batsmanId : batsmanId // ignore: cast_nullable_to_non_nullable
as String,batsmanName: null == batsmanName ? _self.batsmanName : batsmanName // ignore: cast_nullable_to_non_nullable
as String,bowlerId: null == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String,bowlerName: null == bowlerName ? _self.bowlerName : bowlerName // ignore: cast_nullable_to_non_nullable
as String,newBatsmanId: freezed == newBatsmanId ? _self.newBatsmanId : newBatsmanId // ignore: cast_nullable_to_non_nullable
as String?,newBatsmanName: freezed == newBatsmanName ? _self.newBatsmanName : newBatsmanName // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BallEvent].
extension BallEventPatterns on BallEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BallEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BallEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BallEvent value)  $default,){
final _that = this;
switch (_that) {
case _BallEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BallEvent value)?  $default,){
final _that = this;
switch (_that) {
case _BallEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int batRuns,  int extraRuns,  ExtraType extraType,  bool isWicket,  WicketType? wicketType,  String? dismissedPlayerId,  String? dismissedPlayerName,  String? fielderId,  String? fielderName,  String batsmanId,  String batsmanName,  String bowlerId,  String bowlerName,  String? newBatsmanId,  String? newBatsmanName,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BallEvent() when $default != null:
return $default(_that.batRuns,_that.extraRuns,_that.extraType,_that.isWicket,_that.wicketType,_that.dismissedPlayerId,_that.dismissedPlayerName,_that.fielderId,_that.fielderName,_that.batsmanId,_that.batsmanName,_that.bowlerId,_that.bowlerName,_that.newBatsmanId,_that.newBatsmanName,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int batRuns,  int extraRuns,  ExtraType extraType,  bool isWicket,  WicketType? wicketType,  String? dismissedPlayerId,  String? dismissedPlayerName,  String? fielderId,  String? fielderName,  String batsmanId,  String batsmanName,  String bowlerId,  String bowlerName,  String? newBatsmanId,  String? newBatsmanName,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _BallEvent():
return $default(_that.batRuns,_that.extraRuns,_that.extraType,_that.isWicket,_that.wicketType,_that.dismissedPlayerId,_that.dismissedPlayerName,_that.fielderId,_that.fielderName,_that.batsmanId,_that.batsmanName,_that.bowlerId,_that.bowlerName,_that.newBatsmanId,_that.newBatsmanName,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int batRuns,  int extraRuns,  ExtraType extraType,  bool isWicket,  WicketType? wicketType,  String? dismissedPlayerId,  String? dismissedPlayerName,  String? fielderId,  String? fielderName,  String batsmanId,  String batsmanName,  String bowlerId,  String bowlerName,  String? newBatsmanId,  String? newBatsmanName,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _BallEvent() when $default != null:
return $default(_that.batRuns,_that.extraRuns,_that.extraType,_that.isWicket,_that.wicketType,_that.dismissedPlayerId,_that.dismissedPlayerName,_that.fielderId,_that.fielderName,_that.batsmanId,_that.batsmanName,_that.bowlerId,_that.bowlerName,_that.newBatsmanId,_that.newBatsmanName,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BallEvent implements BallEvent {
  const _BallEvent({this.batRuns = 0, this.extraRuns = 0, this.extraType = ExtraType.none, this.isWicket = false, this.wicketType, this.dismissedPlayerId, this.dismissedPlayerName, this.fielderId, this.fielderName, required this.batsmanId, required this.batsmanName, required this.bowlerId, required this.bowlerName, this.newBatsmanId, this.newBatsmanName, required this.timestamp});
  factory _BallEvent.fromJson(Map<String, dynamic> json) => _$BallEventFromJson(json);

@override@JsonKey() final  int batRuns;
@override@JsonKey() final  int extraRuns;
@override@JsonKey() final  ExtraType extraType;
@override@JsonKey() final  bool isWicket;
@override final  WicketType? wicketType;
@override final  String? dismissedPlayerId;
@override final  String? dismissedPlayerName;
@override final  String? fielderId;
@override final  String? fielderName;
@override final  String batsmanId;
@override final  String batsmanName;
@override final  String bowlerId;
@override final  String bowlerName;
@override final  String? newBatsmanId;
@override final  String? newBatsmanName;
@override final  DateTime timestamp;

/// Create a copy of BallEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BallEventCopyWith<_BallEvent> get copyWith => __$BallEventCopyWithImpl<_BallEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BallEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BallEvent&&(identical(other.batRuns, batRuns) || other.batRuns == batRuns)&&(identical(other.extraRuns, extraRuns) || other.extraRuns == extraRuns)&&(identical(other.extraType, extraType) || other.extraType == extraType)&&(identical(other.isWicket, isWicket) || other.isWicket == isWicket)&&(identical(other.wicketType, wicketType) || other.wicketType == wicketType)&&(identical(other.dismissedPlayerId, dismissedPlayerId) || other.dismissedPlayerId == dismissedPlayerId)&&(identical(other.dismissedPlayerName, dismissedPlayerName) || other.dismissedPlayerName == dismissedPlayerName)&&(identical(other.fielderId, fielderId) || other.fielderId == fielderId)&&(identical(other.fielderName, fielderName) || other.fielderName == fielderName)&&(identical(other.batsmanId, batsmanId) || other.batsmanId == batsmanId)&&(identical(other.batsmanName, batsmanName) || other.batsmanName == batsmanName)&&(identical(other.bowlerId, bowlerId) || other.bowlerId == bowlerId)&&(identical(other.bowlerName, bowlerName) || other.bowlerName == bowlerName)&&(identical(other.newBatsmanId, newBatsmanId) || other.newBatsmanId == newBatsmanId)&&(identical(other.newBatsmanName, newBatsmanName) || other.newBatsmanName == newBatsmanName)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,batRuns,extraRuns,extraType,isWicket,wicketType,dismissedPlayerId,dismissedPlayerName,fielderId,fielderName,batsmanId,batsmanName,bowlerId,bowlerName,newBatsmanId,newBatsmanName,timestamp);
}

@override
String toString() {
    return 'BallEvent(batRuns: $batRuns, extraRuns: $extraRuns, extraType: $extraType, isWicket: $isWicket, wicketType: $wicketType, dismissedPlayerId: $dismissedPlayerId, dismissedPlayerName: $dismissedPlayerName, fielderId: $fielderId, fielderName: $fielderName, batsmanId: $batsmanId, batsmanName: $batsmanName, bowlerId: $bowlerId, bowlerName: $bowlerName, newBatsmanId: $newBatsmanId, newBatsmanName: $newBatsmanName, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$BallEventCopyWith<$Res> implements $BallEventCopyWith<$Res> {
  factory _$BallEventCopyWith(_BallEvent value, $Res Function(_BallEvent) _then) = __$BallEventCopyWithImpl;
@override @useResult
$Res call({
 int batRuns, int extraRuns, ExtraType extraType, bool isWicket, WicketType? wicketType, String? dismissedPlayerId, String? dismissedPlayerName, String? fielderId, String? fielderName, String batsmanId, String batsmanName, String bowlerId, String bowlerName, String? newBatsmanId, String? newBatsmanName, DateTime timestamp
});




}
/// @nodoc
class __$BallEventCopyWithImpl<$Res>
    implements _$BallEventCopyWith<$Res> {
  __$BallEventCopyWithImpl(this._self, this._then);

  final _BallEvent _self;
  final $Res Function(_BallEvent) _then;

/// Create a copy of BallEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? batRuns = null,Object? extraRuns = null,Object? extraType = null,Object? isWicket = null,Object? wicketType = freezed,Object? dismissedPlayerId = freezed,Object? dismissedPlayerName = freezed,Object? fielderId = freezed,Object? fielderName = freezed,Object? batsmanId = null,Object? batsmanName = null,Object? bowlerId = null,Object? bowlerName = null,Object? newBatsmanId = freezed,Object? newBatsmanName = freezed,Object? timestamp = null,}) {
  return _then(_BallEvent(
batRuns: null == batRuns ? _self.batRuns : batRuns // ignore: cast_nullable_to_non_nullable
as int,extraRuns: null == extraRuns ? _self.extraRuns : extraRuns // ignore: cast_nullable_to_non_nullable
as int,extraType: null == extraType ? _self.extraType : extraType // ignore: cast_nullable_to_non_nullable
as ExtraType,isWicket: null == isWicket ? _self.isWicket : isWicket // ignore: cast_nullable_to_non_nullable
as bool,wicketType: freezed == wicketType ? _self.wicketType : wicketType // ignore: cast_nullable_to_non_nullable
as WicketType?,dismissedPlayerId: freezed == dismissedPlayerId ? _self.dismissedPlayerId : dismissedPlayerId // ignore: cast_nullable_to_non_nullable
as String?,dismissedPlayerName: freezed == dismissedPlayerName ? _self.dismissedPlayerName : dismissedPlayerName // ignore: cast_nullable_to_non_nullable
as String?,fielderId: freezed == fielderId ? _self.fielderId : fielderId // ignore: cast_nullable_to_non_nullable
as String?,fielderName: freezed == fielderName ? _self.fielderName : fielderName // ignore: cast_nullable_to_non_nullable
as String?,batsmanId: null == batsmanId ? _self.batsmanId : batsmanId // ignore: cast_nullable_to_non_nullable
as String,batsmanName: null == batsmanName ? _self.batsmanName : batsmanName // ignore: cast_nullable_to_non_nullable
as String,bowlerId: null == bowlerId ? _self.bowlerId : bowlerId // ignore: cast_nullable_to_non_nullable
as String,bowlerName: null == bowlerName ? _self.bowlerName : bowlerName // ignore: cast_nullable_to_non_nullable
as String,newBatsmanId: freezed == newBatsmanId ? _self.newBatsmanId : newBatsmanId // ignore: cast_nullable_to_non_nullable
as String?,newBatsmanName: freezed == newBatsmanName ? _self.newBatsmanName : newBatsmanName // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
