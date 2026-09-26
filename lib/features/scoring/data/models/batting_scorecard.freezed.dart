// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batting_scorecard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BattingScorecard {

 String get playerId; String get playerName; int get battingOrder; int get runs; int get balls; int get fours; int get sixes; bool get isOut; String? get dismissalText; bool get isStriker; bool get isNonStriker;
/// Create a copy of BattingScorecard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BattingScorecardCopyWith<BattingScorecard> get copyWith => _$BattingScorecardCopyWithImpl<BattingScorecard>(this as BattingScorecard, _$identity);

  /// Serializes this BattingScorecard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BattingScorecard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BattingScorecard&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.playerName, _this.playerName) || other.playerName == _this.playerName)&&(identical(other.battingOrder, _this.battingOrder) || other.battingOrder == _this.battingOrder)&&(identical(other.runs, _this.runs) || other.runs == _this.runs)&&(identical(other.balls, _this.balls) || other.balls == _this.balls)&&(identical(other.fours, _this.fours) || other.fours == _this.fours)&&(identical(other.sixes, _this.sixes) || other.sixes == _this.sixes)&&(identical(other.isOut, _this.isOut) || other.isOut == _this.isOut)&&(identical(other.dismissalText, _this.dismissalText) || other.dismissalText == _this.dismissalText)&&(identical(other.isStriker, _this.isStriker) || other.isStriker == _this.isStriker)&&(identical(other.isNonStriker, _this.isNonStriker) || other.isNonStriker == _this.isNonStriker));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BattingScorecard;
  return Object.hash(runtimeType,_this.playerId,_this.playerName,_this.battingOrder,_this.runs,_this.balls,_this.fours,_this.sixes,_this.isOut,_this.dismissalText,_this.isStriker,_this.isNonStriker);
}

@override
String toString() {
  final _this = this as BattingScorecard;
  return 'BattingScorecard(playerId: ${_this.playerId}, playerName: ${_this.playerName}, battingOrder: ${_this.battingOrder}, runs: ${_this.runs}, balls: ${_this.balls}, fours: ${_this.fours}, sixes: ${_this.sixes}, isOut: ${_this.isOut}, dismissalText: ${_this.dismissalText}, isStriker: ${_this.isStriker}, isNonStriker: ${_this.isNonStriker})';
}


}

/// @nodoc
abstract mixin class $BattingScorecardCopyWith<$Res>  {
  factory $BattingScorecardCopyWith(BattingScorecard value, $Res Function(BattingScorecard) _then) = _$BattingScorecardCopyWithImpl;
@useResult
$Res call({
 String playerId, String playerName, int battingOrder, int runs, int balls, int fours, int sixes, bool isOut, String? dismissalText, bool isStriker, bool isNonStriker
});




}
/// @nodoc
class _$BattingScorecardCopyWithImpl<$Res>
    implements $BattingScorecardCopyWith<$Res> {
  _$BattingScorecardCopyWithImpl(this._self, this._then);

  final BattingScorecard _self;
  final $Res Function(BattingScorecard) _then;

/// Create a copy of BattingScorecard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? playerName = null,Object? battingOrder = null,Object? runs = null,Object? balls = null,Object? fours = null,Object? sixes = null,Object? isOut = null,Object? dismissalText = freezed,Object? isStriker = null,Object? isNonStriker = null,}) {
  return _then(BattingScorecard(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,battingOrder: null == battingOrder ? _self.battingOrder : battingOrder // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,balls: null == balls ? _self.balls : balls // ignore: cast_nullable_to_non_nullable
as int,fours: null == fours ? _self.fours : fours // ignore: cast_nullable_to_non_nullable
as int,sixes: null == sixes ? _self.sixes : sixes // ignore: cast_nullable_to_non_nullable
as int,isOut: null == isOut ? _self.isOut : isOut // ignore: cast_nullable_to_non_nullable
as bool,dismissalText: freezed == dismissalText ? _self.dismissalText : dismissalText // ignore: cast_nullable_to_non_nullable
as String?,isStriker: null == isStriker ? _self.isStriker : isStriker // ignore: cast_nullable_to_non_nullable
as bool,isNonStriker: null == isNonStriker ? _self.isNonStriker : isNonStriker // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BattingScorecard].
extension BattingScorecardPatterns on BattingScorecard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BattingScorecard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BattingScorecard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BattingScorecard value)  $default,){
final _that = this;
switch (_that) {
case _BattingScorecard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BattingScorecard value)?  $default,){
final _that = this;
switch (_that) {
case _BattingScorecard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String playerName,  int battingOrder,  int runs,  int balls,  int fours,  int sixes,  bool isOut,  String? dismissalText,  bool isStriker,  bool isNonStriker)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BattingScorecard() when $default != null:
return $default(_that.playerId,_that.playerName,_that.battingOrder,_that.runs,_that.balls,_that.fours,_that.sixes,_that.isOut,_that.dismissalText,_that.isStriker,_that.isNonStriker);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String playerName,  int battingOrder,  int runs,  int balls,  int fours,  int sixes,  bool isOut,  String? dismissalText,  bool isStriker,  bool isNonStriker)  $default,) {final _that = this;
switch (_that) {
case _BattingScorecard():
return $default(_that.playerId,_that.playerName,_that.battingOrder,_that.runs,_that.balls,_that.fours,_that.sixes,_that.isOut,_that.dismissalText,_that.isStriker,_that.isNonStriker);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String playerName,  int battingOrder,  int runs,  int balls,  int fours,  int sixes,  bool isOut,  String? dismissalText,  bool isStriker,  bool isNonStriker)?  $default,) {final _that = this;
switch (_that) {
case _BattingScorecard() when $default != null:
return $default(_that.playerId,_that.playerName,_that.battingOrder,_that.runs,_that.balls,_that.fours,_that.sixes,_that.isOut,_that.dismissalText,_that.isStriker,_that.isNonStriker);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BattingScorecard implements BattingScorecard {
  const _BattingScorecard({required this.playerId, required this.playerName, required this.battingOrder, this.runs = 0, this.balls = 0, this.fours = 0, this.sixes = 0, this.isOut = false, this.dismissalText, this.isStriker = false, this.isNonStriker = false});
  factory _BattingScorecard.fromJson(Map<String, dynamic> json) => _$BattingScorecardFromJson(json);

@override final  String playerId;
@override final  String playerName;
@override final  int battingOrder;
@override@JsonKey() final  int runs;
@override@JsonKey() final  int balls;
@override@JsonKey() final  int fours;
@override@JsonKey() final  int sixes;
@override@JsonKey() final  bool isOut;
@override final  String? dismissalText;
@override@JsonKey() final  bool isStriker;
@override@JsonKey() final  bool isNonStriker;

/// Create a copy of BattingScorecard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BattingScorecardCopyWith<_BattingScorecard> get copyWith => __$BattingScorecardCopyWithImpl<_BattingScorecard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BattingScorecardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BattingScorecard&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.battingOrder, battingOrder) || other.battingOrder == battingOrder)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.balls, balls) || other.balls == balls)&&(identical(other.fours, fours) || other.fours == fours)&&(identical(other.sixes, sixes) || other.sixes == sixes)&&(identical(other.isOut, isOut) || other.isOut == isOut)&&(identical(other.dismissalText, dismissalText) || other.dismissalText == dismissalText)&&(identical(other.isStriker, isStriker) || other.isStriker == isStriker)&&(identical(other.isNonStriker, isNonStriker) || other.isNonStriker == isNonStriker));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,playerId,playerName,battingOrder,runs,balls,fours,sixes,isOut,dismissalText,isStriker,isNonStriker);
}

@override
String toString() {
    return 'BattingScorecard(playerId: $playerId, playerName: $playerName, battingOrder: $battingOrder, runs: $runs, balls: $balls, fours: $fours, sixes: $sixes, isOut: $isOut, dismissalText: $dismissalText, isStriker: $isStriker, isNonStriker: $isNonStriker)';
}


}

/// @nodoc
abstract mixin class _$BattingScorecardCopyWith<$Res> implements $BattingScorecardCopyWith<$Res> {
  factory _$BattingScorecardCopyWith(_BattingScorecard value, $Res Function(_BattingScorecard) _then) = __$BattingScorecardCopyWithImpl;
@override @useResult
$Res call({
 String playerId, String playerName, int battingOrder, int runs, int balls, int fours, int sixes, bool isOut, String? dismissalText, bool isStriker, bool isNonStriker
});




}
/// @nodoc
class __$BattingScorecardCopyWithImpl<$Res>
    implements _$BattingScorecardCopyWith<$Res> {
  __$BattingScorecardCopyWithImpl(this._self, this._then);

  final _BattingScorecard _self;
  final $Res Function(_BattingScorecard) _then;

/// Create a copy of BattingScorecard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? playerName = null,Object? battingOrder = null,Object? runs = null,Object? balls = null,Object? fours = null,Object? sixes = null,Object? isOut = null,Object? dismissalText = freezed,Object? isStriker = null,Object? isNonStriker = null,}) {
  return _then(_BattingScorecard(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,battingOrder: null == battingOrder ? _self.battingOrder : battingOrder // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,balls: null == balls ? _self.balls : balls // ignore: cast_nullable_to_non_nullable
as int,fours: null == fours ? _self.fours : fours // ignore: cast_nullable_to_non_nullable
as int,sixes: null == sixes ? _self.sixes : sixes // ignore: cast_nullable_to_non_nullable
as int,isOut: null == isOut ? _self.isOut : isOut // ignore: cast_nullable_to_non_nullable
as bool,dismissalText: freezed == dismissalText ? _self.dismissalText : dismissalText // ignore: cast_nullable_to_non_nullable
as String?,isStriker: null == isStriker ? _self.isStriker : isStriker // ignore: cast_nullable_to_non_nullable
as bool,isNonStriker: null == isNonStriker ? _self.isNonStriker : isNonStriker // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
