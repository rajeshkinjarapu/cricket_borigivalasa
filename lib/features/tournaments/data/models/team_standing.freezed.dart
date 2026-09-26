// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_standing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamStanding {

 String get teamId; String get teamName; int get matchesPlayed; int get won; int get lost; int get tied; int get noResult; int get points; double get netRunRate;
/// Create a copy of TeamStanding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamStandingCopyWith<TeamStanding> get copyWith => _$TeamStandingCopyWithImpl<TeamStanding>(this as TeamStanding, _$identity);

  /// Serializes this TeamStanding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TeamStanding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamStanding&&(identical(other.teamId, _this.teamId) || other.teamId == _this.teamId)&&(identical(other.teamName, _this.teamName) || other.teamName == _this.teamName)&&(identical(other.matchesPlayed, _this.matchesPlayed) || other.matchesPlayed == _this.matchesPlayed)&&(identical(other.won, _this.won) || other.won == _this.won)&&(identical(other.lost, _this.lost) || other.lost == _this.lost)&&(identical(other.tied, _this.tied) || other.tied == _this.tied)&&(identical(other.noResult, _this.noResult) || other.noResult == _this.noResult)&&(identical(other.points, _this.points) || other.points == _this.points)&&(identical(other.netRunRate, _this.netRunRate) || other.netRunRate == _this.netRunRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TeamStanding;
  return Object.hash(runtimeType,_this.teamId,_this.teamName,_this.matchesPlayed,_this.won,_this.lost,_this.tied,_this.noResult,_this.points,_this.netRunRate);
}

@override
String toString() {
  final _this = this as TeamStanding;
  return 'TeamStanding(teamId: ${_this.teamId}, teamName: ${_this.teamName}, matchesPlayed: ${_this.matchesPlayed}, won: ${_this.won}, lost: ${_this.lost}, tied: ${_this.tied}, noResult: ${_this.noResult}, points: ${_this.points}, netRunRate: ${_this.netRunRate})';
}


}

/// @nodoc
abstract mixin class $TeamStandingCopyWith<$Res>  {
  factory $TeamStandingCopyWith(TeamStanding value, $Res Function(TeamStanding) _then) = _$TeamStandingCopyWithImpl;
@useResult
$Res call({
 String teamId, String teamName, int matchesPlayed, int won, int lost, int tied, int noResult, int points, double netRunRate
});




}
/// @nodoc
class _$TeamStandingCopyWithImpl<$Res>
    implements $TeamStandingCopyWith<$Res> {
  _$TeamStandingCopyWithImpl(this._self, this._then);

  final TeamStanding _self;
  final $Res Function(TeamStanding) _then;

/// Create a copy of TeamStanding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? teamName = null,Object? matchesPlayed = null,Object? won = null,Object? lost = null,Object? tied = null,Object? noResult = null,Object? points = null,Object? netRunRate = null,}) {
  return _then(TeamStanding(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,matchesPlayed: null == matchesPlayed ? _self.matchesPlayed : matchesPlayed // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,tied: null == tied ? _self.tied : tied // ignore: cast_nullable_to_non_nullable
as int,noResult: null == noResult ? _self.noResult : noResult // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,netRunRate: null == netRunRate ? _self.netRunRate : netRunRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamStanding].
extension TeamStandingPatterns on TeamStanding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamStanding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamStanding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamStanding value)  $default,){
final _that = this;
switch (_that) {
case _TeamStanding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamStanding value)?  $default,){
final _that = this;
switch (_that) {
case _TeamStanding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String teamId,  String teamName,  int matchesPlayed,  int won,  int lost,  int tied,  int noResult,  int points,  double netRunRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamStanding() when $default != null:
return $default(_that.teamId,_that.teamName,_that.matchesPlayed,_that.won,_that.lost,_that.tied,_that.noResult,_that.points,_that.netRunRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String teamId,  String teamName,  int matchesPlayed,  int won,  int lost,  int tied,  int noResult,  int points,  double netRunRate)  $default,) {final _that = this;
switch (_that) {
case _TeamStanding():
return $default(_that.teamId,_that.teamName,_that.matchesPlayed,_that.won,_that.lost,_that.tied,_that.noResult,_that.points,_that.netRunRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String teamId,  String teamName,  int matchesPlayed,  int won,  int lost,  int tied,  int noResult,  int points,  double netRunRate)?  $default,) {final _that = this;
switch (_that) {
case _TeamStanding() when $default != null:
return $default(_that.teamId,_that.teamName,_that.matchesPlayed,_that.won,_that.lost,_that.tied,_that.noResult,_that.points,_that.netRunRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamStanding implements TeamStanding {
  const _TeamStanding({required this.teamId, required this.teamName, this.matchesPlayed = 0, this.won = 0, this.lost = 0, this.tied = 0, this.noResult = 0, this.points = 0, this.netRunRate = 0.0});
  factory _TeamStanding.fromJson(Map<String, dynamic> json) => _$TeamStandingFromJson(json);

@override final  String teamId;
@override final  String teamName;
@override@JsonKey() final  int matchesPlayed;
@override@JsonKey() final  int won;
@override@JsonKey() final  int lost;
@override@JsonKey() final  int tied;
@override@JsonKey() final  int noResult;
@override@JsonKey() final  int points;
@override@JsonKey() final  double netRunRate;

/// Create a copy of TeamStanding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamStandingCopyWith<_TeamStanding> get copyWith => __$TeamStandingCopyWithImpl<_TeamStanding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamStandingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamStanding&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.matchesPlayed, matchesPlayed) || other.matchesPlayed == matchesPlayed)&&(identical(other.won, won) || other.won == won)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.tied, tied) || other.tied == tied)&&(identical(other.noResult, noResult) || other.noResult == noResult)&&(identical(other.points, points) || other.points == points)&&(identical(other.netRunRate, netRunRate) || other.netRunRate == netRunRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,teamId,teamName,matchesPlayed,won,lost,tied,noResult,points,netRunRate);
}

@override
String toString() {
    return 'TeamStanding(teamId: $teamId, teamName: $teamName, matchesPlayed: $matchesPlayed, won: $won, lost: $lost, tied: $tied, noResult: $noResult, points: $points, netRunRate: $netRunRate)';
}


}

/// @nodoc
abstract mixin class _$TeamStandingCopyWith<$Res> implements $TeamStandingCopyWith<$Res> {
  factory _$TeamStandingCopyWith(_TeamStanding value, $Res Function(_TeamStanding) _then) = __$TeamStandingCopyWithImpl;
@override @useResult
$Res call({
 String teamId, String teamName, int matchesPlayed, int won, int lost, int tied, int noResult, int points, double netRunRate
});




}
/// @nodoc
class __$TeamStandingCopyWithImpl<$Res>
    implements _$TeamStandingCopyWith<$Res> {
  __$TeamStandingCopyWithImpl(this._self, this._then);

  final _TeamStanding _self;
  final $Res Function(_TeamStanding) _then;

/// Create a copy of TeamStanding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? teamName = null,Object? matchesPlayed = null,Object? won = null,Object? lost = null,Object? tied = null,Object? noResult = null,Object? points = null,Object? netRunRate = null,}) {
  return _then(_TeamStanding(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,matchesPlayed: null == matchesPlayed ? _self.matchesPlayed : matchesPlayed // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,tied: null == tied ? _self.tied : tied // ignore: cast_nullable_to_non_nullable
as int,noResult: null == noResult ? _self.noResult : noResult // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,netRunRate: null == netRunRate ? _self.netRunRate : netRunRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
