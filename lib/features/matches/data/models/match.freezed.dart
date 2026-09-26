// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Match {

 String get id; String get teamAId; String get teamAName; String get teamAShort; String get teamBId; String get teamBName; String get teamBShort; DateTime get scheduledAt; MatchStatus get status; int? get matchNumber; String? get venue; String? get tossWinnerTeamId; TossDecision? get tossDecision; String? get resultText; String? get winnerTeamId; bool get isTie; DateTime? get startedAt; DateTime? get completedAt; DateTime? get createdAt;
/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchCopyWith<Match> get copyWith => _$MatchCopyWithImpl<Match>(this as Match, _$identity);

  /// Serializes this Match to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Match;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Match&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.teamAId, _this.teamAId) || other.teamAId == _this.teamAId)&&(identical(other.teamAName, _this.teamAName) || other.teamAName == _this.teamAName)&&(identical(other.teamAShort, _this.teamAShort) || other.teamAShort == _this.teamAShort)&&(identical(other.teamBId, _this.teamBId) || other.teamBId == _this.teamBId)&&(identical(other.teamBName, _this.teamBName) || other.teamBName == _this.teamBName)&&(identical(other.teamBShort, _this.teamBShort) || other.teamBShort == _this.teamBShort)&&(identical(other.scheduledAt, _this.scheduledAt) || other.scheduledAt == _this.scheduledAt)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.matchNumber, _this.matchNumber) || other.matchNumber == _this.matchNumber)&&(identical(other.venue, _this.venue) || other.venue == _this.venue)&&(identical(other.tossWinnerTeamId, _this.tossWinnerTeamId) || other.tossWinnerTeamId == _this.tossWinnerTeamId)&&(identical(other.tossDecision, _this.tossDecision) || other.tossDecision == _this.tossDecision)&&(identical(other.resultText, _this.resultText) || other.resultText == _this.resultText)&&(identical(other.winnerTeamId, _this.winnerTeamId) || other.winnerTeamId == _this.winnerTeamId)&&(identical(other.isTie, _this.isTie) || other.isTie == _this.isTie)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Match;
  return Object.hashAll([runtimeType,_this.id,_this.teamAId,_this.teamAName,_this.teamAShort,_this.teamBId,_this.teamBName,_this.teamBShort,_this.scheduledAt,_this.status,_this.matchNumber,_this.venue,_this.tossWinnerTeamId,_this.tossDecision,_this.resultText,_this.winnerTeamId,_this.isTie,_this.startedAt,_this.completedAt,_this.createdAt]);
}

@override
String toString() {
  final _this = this as Match;
  return 'Match(id: ${_this.id}, teamAId: ${_this.teamAId}, teamAName: ${_this.teamAName}, teamAShort: ${_this.teamAShort}, teamBId: ${_this.teamBId}, teamBName: ${_this.teamBName}, teamBShort: ${_this.teamBShort}, scheduledAt: ${_this.scheduledAt}, status: ${_this.status}, matchNumber: ${_this.matchNumber}, venue: ${_this.venue}, tossWinnerTeamId: ${_this.tossWinnerTeamId}, tossDecision: ${_this.tossDecision}, resultText: ${_this.resultText}, winnerTeamId: ${_this.winnerTeamId}, isTie: ${_this.isTie}, startedAt: ${_this.startedAt}, completedAt: ${_this.completedAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $MatchCopyWith<$Res>  {
  factory $MatchCopyWith(Match value, $Res Function(Match) _then) = _$MatchCopyWithImpl;
@useResult
$Res call({
 String id, String teamAId, String teamAName, String teamAShort, String teamBId, String teamBName, String teamBShort, DateTime scheduledAt, MatchStatus status, int? matchNumber, String? venue, String? tossWinnerTeamId, TossDecision? tossDecision, String? resultText, String? winnerTeamId, bool isTie, DateTime? startedAt, DateTime? completedAt, DateTime? createdAt
});




}
/// @nodoc
class _$MatchCopyWithImpl<$Res>
    implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._self, this._then);

  final Match _self;
  final $Res Function(Match) _then;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? teamAId = null,Object? teamAName = null,Object? teamAShort = null,Object? teamBId = null,Object? teamBName = null,Object? teamBShort = null,Object? scheduledAt = null,Object? status = null,Object? matchNumber = freezed,Object? venue = freezed,Object? tossWinnerTeamId = freezed,Object? tossDecision = freezed,Object? resultText = freezed,Object? winnerTeamId = freezed,Object? isTie = null,Object? startedAt = freezed,Object? completedAt = freezed,Object? createdAt = freezed,}) {
  return _then(Match(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teamAId: null == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String,teamAName: null == teamAName ? _self.teamAName : teamAName // ignore: cast_nullable_to_non_nullable
as String,teamAShort: null == teamAShort ? _self.teamAShort : teamAShort // ignore: cast_nullable_to_non_nullable
as String,teamBId: null == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String,teamBName: null == teamBName ? _self.teamBName : teamBName // ignore: cast_nullable_to_non_nullable
as String,teamBShort: null == teamBShort ? _self.teamBShort : teamBShort // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,matchNumber: freezed == matchNumber ? _self.matchNumber : matchNumber // ignore: cast_nullable_to_non_nullable
as int?,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String?,tossWinnerTeamId: freezed == tossWinnerTeamId ? _self.tossWinnerTeamId : tossWinnerTeamId // ignore: cast_nullable_to_non_nullable
as String?,tossDecision: freezed == tossDecision ? _self.tossDecision : tossDecision // ignore: cast_nullable_to_non_nullable
as TossDecision?,resultText: freezed == resultText ? _self.resultText : resultText // ignore: cast_nullable_to_non_nullable
as String?,winnerTeamId: freezed == winnerTeamId ? _self.winnerTeamId : winnerTeamId // ignore: cast_nullable_to_non_nullable
as String?,isTie: null == isTie ? _self.isTie : isTie // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Match].
extension MatchPatterns on Match {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Match value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Match() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Match value)  $default,){
final _that = this;
switch (_that) {
case _Match():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Match value)?  $default,){
final _that = this;
switch (_that) {
case _Match() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String teamAId,  String teamAName,  String teamAShort,  String teamBId,  String teamBName,  String teamBShort,  DateTime scheduledAt,  MatchStatus status,  int? matchNumber,  String? venue,  String? tossWinnerTeamId,  TossDecision? tossDecision,  String? resultText,  String? winnerTeamId,  bool isTie,  DateTime? startedAt,  DateTime? completedAt,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Match() when $default != null:
return $default(_that.id,_that.teamAId,_that.teamAName,_that.teamAShort,_that.teamBId,_that.teamBName,_that.teamBShort,_that.scheduledAt,_that.status,_that.matchNumber,_that.venue,_that.tossWinnerTeamId,_that.tossDecision,_that.resultText,_that.winnerTeamId,_that.isTie,_that.startedAt,_that.completedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String teamAId,  String teamAName,  String teamAShort,  String teamBId,  String teamBName,  String teamBShort,  DateTime scheduledAt,  MatchStatus status,  int? matchNumber,  String? venue,  String? tossWinnerTeamId,  TossDecision? tossDecision,  String? resultText,  String? winnerTeamId,  bool isTie,  DateTime? startedAt,  DateTime? completedAt,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Match():
return $default(_that.id,_that.teamAId,_that.teamAName,_that.teamAShort,_that.teamBId,_that.teamBName,_that.teamBShort,_that.scheduledAt,_that.status,_that.matchNumber,_that.venue,_that.tossWinnerTeamId,_that.tossDecision,_that.resultText,_that.winnerTeamId,_that.isTie,_that.startedAt,_that.completedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String teamAId,  String teamAName,  String teamAShort,  String teamBId,  String teamBName,  String teamBShort,  DateTime scheduledAt,  MatchStatus status,  int? matchNumber,  String? venue,  String? tossWinnerTeamId,  TossDecision? tossDecision,  String? resultText,  String? winnerTeamId,  bool isTie,  DateTime? startedAt,  DateTime? completedAt,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Match() when $default != null:
return $default(_that.id,_that.teamAId,_that.teamAName,_that.teamAShort,_that.teamBId,_that.teamBName,_that.teamBShort,_that.scheduledAt,_that.status,_that.matchNumber,_that.venue,_that.tossWinnerTeamId,_that.tossDecision,_that.resultText,_that.winnerTeamId,_that.isTie,_that.startedAt,_that.completedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Match implements Match {
  const _Match({required this.id, required this.teamAId, required this.teamAName, required this.teamAShort, required this.teamBId, required this.teamBName, required this.teamBShort, required this.scheduledAt, this.status = MatchStatus.scheduled, this.matchNumber, this.venue, this.tossWinnerTeamId, this.tossDecision, this.resultText, this.winnerTeamId, this.isTie = false, this.startedAt, this.completedAt, this.createdAt});
  factory _Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

@override final  String id;
@override final  String teamAId;
@override final  String teamAName;
@override final  String teamAShort;
@override final  String teamBId;
@override final  String teamBName;
@override final  String teamBShort;
@override final  DateTime scheduledAt;
@override@JsonKey() final  MatchStatus status;
@override final  int? matchNumber;
@override final  String? venue;
@override final  String? tossWinnerTeamId;
@override final  TossDecision? tossDecision;
@override final  String? resultText;
@override final  String? winnerTeamId;
@override@JsonKey() final  bool isTie;
@override final  DateTime? startedAt;
@override final  DateTime? completedAt;
@override final  DateTime? createdAt;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchCopyWith<_Match> get copyWith => __$MatchCopyWithImpl<_Match>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MatchToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Match&&(identical(other.id, id) || other.id == id)&&(identical(other.teamAId, teamAId) || other.teamAId == teamAId)&&(identical(other.teamAName, teamAName) || other.teamAName == teamAName)&&(identical(other.teamAShort, teamAShort) || other.teamAShort == teamAShort)&&(identical(other.teamBId, teamBId) || other.teamBId == teamBId)&&(identical(other.teamBName, teamBName) || other.teamBName == teamBName)&&(identical(other.teamBShort, teamBShort) || other.teamBShort == teamBShort)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.matchNumber, matchNumber) || other.matchNumber == matchNumber)&&(identical(other.venue, venue) || other.venue == venue)&&(identical(other.tossWinnerTeamId, tossWinnerTeamId) || other.tossWinnerTeamId == tossWinnerTeamId)&&(identical(other.tossDecision, tossDecision) || other.tossDecision == tossDecision)&&(identical(other.resultText, resultText) || other.resultText == resultText)&&(identical(other.winnerTeamId, winnerTeamId) || other.winnerTeamId == winnerTeamId)&&(identical(other.isTie, isTie) || other.isTie == isTie)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,teamAId,teamAName,teamAShort,teamBId,teamBName,teamBShort,scheduledAt,status,matchNumber,venue,tossWinnerTeamId,tossDecision,resultText,winnerTeamId,isTie,startedAt,completedAt,createdAt]);
}

@override
String toString() {
    return 'Match(id: $id, teamAId: $teamAId, teamAName: $teamAName, teamAShort: $teamAShort, teamBId: $teamBId, teamBName: $teamBName, teamBShort: $teamBShort, scheduledAt: $scheduledAt, status: $status, matchNumber: $matchNumber, venue: $venue, tossWinnerTeamId: $tossWinnerTeamId, tossDecision: $tossDecision, resultText: $resultText, winnerTeamId: $winnerTeamId, isTie: $isTie, startedAt: $startedAt, completedAt: $completedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MatchCopyWith<$Res> implements $MatchCopyWith<$Res> {
  factory _$MatchCopyWith(_Match value, $Res Function(_Match) _then) = __$MatchCopyWithImpl;
@override @useResult
$Res call({
 String id, String teamAId, String teamAName, String teamAShort, String teamBId, String teamBName, String teamBShort, DateTime scheduledAt, MatchStatus status, int? matchNumber, String? venue, String? tossWinnerTeamId, TossDecision? tossDecision, String? resultText, String? winnerTeamId, bool isTie, DateTime? startedAt, DateTime? completedAt, DateTime? createdAt
});




}
/// @nodoc
class __$MatchCopyWithImpl<$Res>
    implements _$MatchCopyWith<$Res> {
  __$MatchCopyWithImpl(this._self, this._then);

  final _Match _self;
  final $Res Function(_Match) _then;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? teamAId = null,Object? teamAName = null,Object? teamAShort = null,Object? teamBId = null,Object? teamBName = null,Object? teamBShort = null,Object? scheduledAt = null,Object? status = null,Object? matchNumber = freezed,Object? venue = freezed,Object? tossWinnerTeamId = freezed,Object? tossDecision = freezed,Object? resultText = freezed,Object? winnerTeamId = freezed,Object? isTie = null,Object? startedAt = freezed,Object? completedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_Match(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,teamAId: null == teamAId ? _self.teamAId : teamAId // ignore: cast_nullable_to_non_nullable
as String,teamAName: null == teamAName ? _self.teamAName : teamAName // ignore: cast_nullable_to_non_nullable
as String,teamAShort: null == teamAShort ? _self.teamAShort : teamAShort // ignore: cast_nullable_to_non_nullable
as String,teamBId: null == teamBId ? _self.teamBId : teamBId // ignore: cast_nullable_to_non_nullable
as String,teamBName: null == teamBName ? _self.teamBName : teamBName // ignore: cast_nullable_to_non_nullable
as String,teamBShort: null == teamBShort ? _self.teamBShort : teamBShort // ignore: cast_nullable_to_non_nullable
as String,scheduledAt: null == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,matchNumber: freezed == matchNumber ? _self.matchNumber : matchNumber // ignore: cast_nullable_to_non_nullable
as int?,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as String?,tossWinnerTeamId: freezed == tossWinnerTeamId ? _self.tossWinnerTeamId : tossWinnerTeamId // ignore: cast_nullable_to_non_nullable
as String?,tossDecision: freezed == tossDecision ? _self.tossDecision : tossDecision // ignore: cast_nullable_to_non_nullable
as TossDecision?,resultText: freezed == resultText ? _self.resultText : resultText // ignore: cast_nullable_to_non_nullable
as String?,winnerTeamId: freezed == winnerTeamId ? _self.winnerTeamId : winnerTeamId // ignore: cast_nullable_to_non_nullable
as String?,isTie: null == isTie ? _self.isTie : isTie // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
