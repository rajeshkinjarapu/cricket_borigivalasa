// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bowling_scorecard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BowlingScorecard {

 String get playerId; String get playerName; int get balls; int get runs; int get wickets; int get maidens; int get wides; int get noballs;
/// Create a copy of BowlingScorecard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BowlingScorecardCopyWith<BowlingScorecard> get copyWith => _$BowlingScorecardCopyWithImpl<BowlingScorecard>(this as BowlingScorecard, _$identity);

  /// Serializes this BowlingScorecard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BowlingScorecard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BowlingScorecard&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.playerName, _this.playerName) || other.playerName == _this.playerName)&&(identical(other.balls, _this.balls) || other.balls == _this.balls)&&(identical(other.runs, _this.runs) || other.runs == _this.runs)&&(identical(other.wickets, _this.wickets) || other.wickets == _this.wickets)&&(identical(other.maidens, _this.maidens) || other.maidens == _this.maidens)&&(identical(other.wides, _this.wides) || other.wides == _this.wides)&&(identical(other.noballs, _this.noballs) || other.noballs == _this.noballs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BowlingScorecard;
  return Object.hash(runtimeType,_this.playerId,_this.playerName,_this.balls,_this.runs,_this.wickets,_this.maidens,_this.wides,_this.noballs);
}

@override
String toString() {
  final _this = this as BowlingScorecard;
  return 'BowlingScorecard(playerId: ${_this.playerId}, playerName: ${_this.playerName}, balls: ${_this.balls}, runs: ${_this.runs}, wickets: ${_this.wickets}, maidens: ${_this.maidens}, wides: ${_this.wides}, noballs: ${_this.noballs})';
}


}

/// @nodoc
abstract mixin class $BowlingScorecardCopyWith<$Res>  {
  factory $BowlingScorecardCopyWith(BowlingScorecard value, $Res Function(BowlingScorecard) _then) = _$BowlingScorecardCopyWithImpl;
@useResult
$Res call({
 String playerId, String playerName, int balls, int runs, int wickets, int maidens, int wides, int noballs
});




}
/// @nodoc
class _$BowlingScorecardCopyWithImpl<$Res>
    implements $BowlingScorecardCopyWith<$Res> {
  _$BowlingScorecardCopyWithImpl(this._self, this._then);

  final BowlingScorecard _self;
  final $Res Function(BowlingScorecard) _then;

/// Create a copy of BowlingScorecard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? playerName = null,Object? balls = null,Object? runs = null,Object? wickets = null,Object? maidens = null,Object? wides = null,Object? noballs = null,}) {
  return _then(BowlingScorecard(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,balls: null == balls ? _self.balls : balls // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,wickets: null == wickets ? _self.wickets : wickets // ignore: cast_nullable_to_non_nullable
as int,maidens: null == maidens ? _self.maidens : maidens // ignore: cast_nullable_to_non_nullable
as int,wides: null == wides ? _self.wides : wides // ignore: cast_nullable_to_non_nullable
as int,noballs: null == noballs ? _self.noballs : noballs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BowlingScorecard].
extension BowlingScorecardPatterns on BowlingScorecard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BowlingScorecard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BowlingScorecard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BowlingScorecard value)  $default,){
final _that = this;
switch (_that) {
case _BowlingScorecard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BowlingScorecard value)?  $default,){
final _that = this;
switch (_that) {
case _BowlingScorecard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String playerName,  int balls,  int runs,  int wickets,  int maidens,  int wides,  int noballs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BowlingScorecard() when $default != null:
return $default(_that.playerId,_that.playerName,_that.balls,_that.runs,_that.wickets,_that.maidens,_that.wides,_that.noballs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String playerName,  int balls,  int runs,  int wickets,  int maidens,  int wides,  int noballs)  $default,) {final _that = this;
switch (_that) {
case _BowlingScorecard():
return $default(_that.playerId,_that.playerName,_that.balls,_that.runs,_that.wickets,_that.maidens,_that.wides,_that.noballs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String playerName,  int balls,  int runs,  int wickets,  int maidens,  int wides,  int noballs)?  $default,) {final _that = this;
switch (_that) {
case _BowlingScorecard() when $default != null:
return $default(_that.playerId,_that.playerName,_that.balls,_that.runs,_that.wickets,_that.maidens,_that.wides,_that.noballs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BowlingScorecard implements BowlingScorecard {
  const _BowlingScorecard({required this.playerId, required this.playerName, this.balls = 0, this.runs = 0, this.wickets = 0, this.maidens = 0, this.wides = 0, this.noballs = 0});
  factory _BowlingScorecard.fromJson(Map<String, dynamic> json) => _$BowlingScorecardFromJson(json);

@override final  String playerId;
@override final  String playerName;
@override@JsonKey() final  int balls;
@override@JsonKey() final  int runs;
@override@JsonKey() final  int wickets;
@override@JsonKey() final  int maidens;
@override@JsonKey() final  int wides;
@override@JsonKey() final  int noballs;

/// Create a copy of BowlingScorecard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BowlingScorecardCopyWith<_BowlingScorecard> get copyWith => __$BowlingScorecardCopyWithImpl<_BowlingScorecard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BowlingScorecardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BowlingScorecard&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.playerName, playerName) || other.playerName == playerName)&&(identical(other.balls, balls) || other.balls == balls)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.wickets, wickets) || other.wickets == wickets)&&(identical(other.maidens, maidens) || other.maidens == maidens)&&(identical(other.wides, wides) || other.wides == wides)&&(identical(other.noballs, noballs) || other.noballs == noballs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,playerId,playerName,balls,runs,wickets,maidens,wides,noballs);
}

@override
String toString() {
    return 'BowlingScorecard(playerId: $playerId, playerName: $playerName, balls: $balls, runs: $runs, wickets: $wickets, maidens: $maidens, wides: $wides, noballs: $noballs)';
}


}

/// @nodoc
abstract mixin class _$BowlingScorecardCopyWith<$Res> implements $BowlingScorecardCopyWith<$Res> {
  factory _$BowlingScorecardCopyWith(_BowlingScorecard value, $Res Function(_BowlingScorecard) _then) = __$BowlingScorecardCopyWithImpl;
@override @useResult
$Res call({
 String playerId, String playerName, int balls, int runs, int wickets, int maidens, int wides, int noballs
});




}
/// @nodoc
class __$BowlingScorecardCopyWithImpl<$Res>
    implements _$BowlingScorecardCopyWith<$Res> {
  __$BowlingScorecardCopyWithImpl(this._self, this._then);

  final _BowlingScorecard _self;
  final $Res Function(_BowlingScorecard) _then;

/// Create a copy of BowlingScorecard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? playerName = null,Object? balls = null,Object? runs = null,Object? wickets = null,Object? maidens = null,Object? wides = null,Object? noballs = null,}) {
  return _then(_BowlingScorecard(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,playerName: null == playerName ? _self.playerName : playerName // ignore: cast_nullable_to_non_nullable
as String,balls: null == balls ? _self.balls : balls // ignore: cast_nullable_to_non_nullable
as int,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,wickets: null == wickets ? _self.wickets : wickets // ignore: cast_nullable_to_non_nullable
as int,maidens: null == maidens ? _self.maidens : maidens // ignore: cast_nullable_to_non_nullable
as int,wides: null == wides ? _self.wides : wides // ignore: cast_nullable_to_non_nullable
as int,noballs: null == noballs ? _self.noballs : noballs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
