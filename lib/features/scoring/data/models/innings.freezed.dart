// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'innings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Innings {

 int get inningsNumber; String get battingTeamId; String get battingTeamName; String get battingTeamShort; String get bowlingTeamId; String get bowlingTeamName; String get bowlingTeamShort; String get openingStrikerId; String get openingStrikerName; String get openingNonStrikerId; String get openingNonStrikerName; int get runs; int get wickets; int get legalBalls; int get wides; int get noballs; int get byes; int get legbyes; String? get strikerId; String? get strikerName; String? get nonStrikerId; String? get nonStrikerName; String? get currentBowlerId; String? get currentBowlerName; int? get targetRuns; bool get isComplete; String? get completionReason; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Innings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InningsCopyWith<Innings> get copyWith => _$InningsCopyWithImpl<Innings>(this as Innings, _$identity);

  /// Serializes this Innings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Innings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Innings&&(identical(other.inningsNumber, _this.inningsNumber) || other.inningsNumber == _this.inningsNumber)&&(identical(other.battingTeamId, _this.battingTeamId) || other.battingTeamId == _this.battingTeamId)&&(identical(other.battingTeamName, _this.battingTeamName) || other.battingTeamName == _this.battingTeamName)&&(identical(other.battingTeamShort, _this.battingTeamShort) || other.battingTeamShort == _this.battingTeamShort)&&(identical(other.bowlingTeamId, _this.bowlingTeamId) || other.bowlingTeamId == _this.bowlingTeamId)&&(identical(other.bowlingTeamName, _this.bowlingTeamName) || other.bowlingTeamName == _this.bowlingTeamName)&&(identical(other.bowlingTeamShort, _this.bowlingTeamShort) || other.bowlingTeamShort == _this.bowlingTeamShort)&&(identical(other.openingStrikerId, _this.openingStrikerId) || other.openingStrikerId == _this.openingStrikerId)&&(identical(other.openingStrikerName, _this.openingStrikerName) || other.openingStrikerName == _this.openingStrikerName)&&(identical(other.openingNonStrikerId, _this.openingNonStrikerId) || other.openingNonStrikerId == _this.openingNonStrikerId)&&(identical(other.openingNonStrikerName, _this.openingNonStrikerName) || other.openingNonStrikerName == _this.openingNonStrikerName)&&(identical(other.runs, _this.runs) || other.runs == _this.runs)&&(identical(other.wickets, _this.wickets) || other.wickets == _this.wickets)&&(identical(other.legalBalls, _this.legalBalls) || other.legalBalls == _this.legalBalls)&&(identical(other.wides, _this.wides) || other.wides == _this.wides)&&(identical(other.noballs, _this.noballs) || other.noballs == _this.noballs)&&(identical(other.byes, _this.byes) || other.byes == _this.byes)&&(identical(other.legbyes, _this.legbyes) || other.legbyes == _this.legbyes)&&(identical(other.strikerId, _this.strikerId) || other.strikerId == _this.strikerId)&&(identical(other.strikerName, _this.strikerName) || other.strikerName == _this.strikerName)&&(identical(other.nonStrikerId, _this.nonStrikerId) || other.nonStrikerId == _this.nonStrikerId)&&(identical(other.nonStrikerName, _this.nonStrikerName) || other.nonStrikerName == _this.nonStrikerName)&&(identical(other.currentBowlerId, _this.currentBowlerId) || other.currentBowlerId == _this.currentBowlerId)&&(identical(other.currentBowlerName, _this.currentBowlerName) || other.currentBowlerName == _this.currentBowlerName)&&(identical(other.targetRuns, _this.targetRuns) || other.targetRuns == _this.targetRuns)&&(identical(other.isComplete, _this.isComplete) || other.isComplete == _this.isComplete)&&(identical(other.completionReason, _this.completionReason) || other.completionReason == _this.completionReason)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Innings;
  return Object.hashAll([runtimeType,_this.inningsNumber,_this.battingTeamId,_this.battingTeamName,_this.battingTeamShort,_this.bowlingTeamId,_this.bowlingTeamName,_this.bowlingTeamShort,_this.openingStrikerId,_this.openingStrikerName,_this.openingNonStrikerId,_this.openingNonStrikerName,_this.runs,_this.wickets,_this.legalBalls,_this.wides,_this.noballs,_this.byes,_this.legbyes,_this.strikerId,_this.strikerName,_this.nonStrikerId,_this.nonStrikerName,_this.currentBowlerId,_this.currentBowlerName,_this.targetRuns,_this.isComplete,_this.completionReason,_this.createdAt,_this.updatedAt]);
}

@override
String toString() {
  final _this = this as Innings;
  return 'Innings(inningsNumber: ${_this.inningsNumber}, battingTeamId: ${_this.battingTeamId}, battingTeamName: ${_this.battingTeamName}, battingTeamShort: ${_this.battingTeamShort}, bowlingTeamId: ${_this.bowlingTeamId}, bowlingTeamName: ${_this.bowlingTeamName}, bowlingTeamShort: ${_this.bowlingTeamShort}, openingStrikerId: ${_this.openingStrikerId}, openingStrikerName: ${_this.openingStrikerName}, openingNonStrikerId: ${_this.openingNonStrikerId}, openingNonStrikerName: ${_this.openingNonStrikerName}, runs: ${_this.runs}, wickets: ${_this.wickets}, legalBalls: ${_this.legalBalls}, wides: ${_this.wides}, noballs: ${_this.noballs}, byes: ${_this.byes}, legbyes: ${_this.legbyes}, strikerId: ${_this.strikerId}, strikerName: ${_this.strikerName}, nonStrikerId: ${_this.nonStrikerId}, nonStrikerName: ${_this.nonStrikerName}, currentBowlerId: ${_this.currentBowlerId}, currentBowlerName: ${_this.currentBowlerName}, targetRuns: ${_this.targetRuns}, isComplete: ${_this.isComplete}, completionReason: ${_this.completionReason}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $InningsCopyWith<$Res>  {
  factory $InningsCopyWith(Innings value, $Res Function(Innings) _then) = _$InningsCopyWithImpl;
@useResult
$Res call({
 int inningsNumber, String battingTeamId, String battingTeamName, String battingTeamShort, String bowlingTeamId, String bowlingTeamName, String bowlingTeamShort, String openingStrikerId, String openingStrikerName, String openingNonStrikerId, String openingNonStrikerName, int runs, int wickets, int legalBalls, int wides, int noballs, int byes, int legbyes, String? strikerId, String? strikerName, String? nonStrikerId, String? nonStrikerName, String? currentBowlerId, String? currentBowlerName, int? targetRuns, bool isComplete, String? completionReason, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$InningsCopyWithImpl<$Res>
    implements $InningsCopyWith<$Res> {
  _$InningsCopyWithImpl(this._self, this._then);

  final Innings _self;
  final $Res Function(Innings) _then;

/// Create a copy of Innings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inningsNumber = null,Object? battingTeamId = null,Object? battingTeamName = null,Object? battingTeamShort = null,Object? bowlingTeamId = null,Object? bowlingTeamName = null,Object? bowlingTeamShort = null,Object? openingStrikerId = null,Object? openingStrikerName = null,Object? openingNonStrikerId = null,Object? openingNonStrikerName = null,Object? runs = null,Object? wickets = null,Object? legalBalls = null,Object? wides = null,Object? noballs = null,Object? byes = null,Object? legbyes = null,Object? strikerId = freezed,Object? strikerName = freezed,Object? nonStrikerId = freezed,Object? nonStrikerName = freezed,Object? currentBowlerId = freezed,Object? currentBowlerName = freezed,Object? targetRuns = freezed,Object? isComplete = null,Object? completionReason = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(Innings(
inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,battingTeamId: null == battingTeamId ? _self.battingTeamId : battingTeamId // ignore: cast_nullable_to_non_nullable
as String,battingTeamName: null == battingTeamName ? _self.battingTeamName : battingTeamName // ignore: cast_nullable_to_non_nullable
as String,battingTeamShort: null == battingTeamShort ? _self.battingTeamShort : battingTeamShort // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamId: null == bowlingTeamId ? _self.bowlingTeamId : bowlingTeamId // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamName: null == bowlingTeamName ? _self.bowlingTeamName : bowlingTeamName // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamShort: null == bowlingTeamShort ? _self.bowlingTeamShort : bowlingTeamShort // ignore: cast_nullable_to_non_nullable
as String,openingStrikerId: null == openingStrikerId ? _self.openingStrikerId : openingStrikerId // ignore: cast_nullable_to_non_nullable
as String,openingStrikerName: null == openingStrikerName ? _self.openingStrikerName : openingStrikerName // ignore: cast_nullable_to_non_nullable
as String,openingNonStrikerId: null == openingNonStrikerId ? _self.openingNonStrikerId : openingNonStrikerId // ignore: cast_nullable_to_non_nullable
as String,openingNonStrikerName: null == openingNonStrikerName ? _self.openingNonStrikerName : openingNonStrikerName // ignore: cast_nullable_to_non_nullable
as String,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,wickets: null == wickets ? _self.wickets : wickets // ignore: cast_nullable_to_non_nullable
as int,legalBalls: null == legalBalls ? _self.legalBalls : legalBalls // ignore: cast_nullable_to_non_nullable
as int,wides: null == wides ? _self.wides : wides // ignore: cast_nullable_to_non_nullable
as int,noballs: null == noballs ? _self.noballs : noballs // ignore: cast_nullable_to_non_nullable
as int,byes: null == byes ? _self.byes : byes // ignore: cast_nullable_to_non_nullable
as int,legbyes: null == legbyes ? _self.legbyes : legbyes // ignore: cast_nullable_to_non_nullable
as int,strikerId: freezed == strikerId ? _self.strikerId : strikerId // ignore: cast_nullable_to_non_nullable
as String?,strikerName: freezed == strikerName ? _self.strikerName : strikerName // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerId: freezed == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerName: freezed == nonStrikerName ? _self.nonStrikerName : nonStrikerName // ignore: cast_nullable_to_non_nullable
as String?,currentBowlerId: freezed == currentBowlerId ? _self.currentBowlerId : currentBowlerId // ignore: cast_nullable_to_non_nullable
as String?,currentBowlerName: freezed == currentBowlerName ? _self.currentBowlerName : currentBowlerName // ignore: cast_nullable_to_non_nullable
as String?,targetRuns: freezed == targetRuns ? _self.targetRuns : targetRuns // ignore: cast_nullable_to_non_nullable
as int?,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,completionReason: freezed == completionReason ? _self.completionReason : completionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Innings].
extension InningsPatterns on Innings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Innings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Innings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Innings value)  $default,){
final _that = this;
switch (_that) {
case _Innings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Innings value)?  $default,){
final _that = this;
switch (_that) {
case _Innings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int inningsNumber,  String battingTeamId,  String battingTeamName,  String battingTeamShort,  String bowlingTeamId,  String bowlingTeamName,  String bowlingTeamShort,  String openingStrikerId,  String openingStrikerName,  String openingNonStrikerId,  String openingNonStrikerName,  int runs,  int wickets,  int legalBalls,  int wides,  int noballs,  int byes,  int legbyes,  String? strikerId,  String? strikerName,  String? nonStrikerId,  String? nonStrikerName,  String? currentBowlerId,  String? currentBowlerName,  int? targetRuns,  bool isComplete,  String? completionReason,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Innings() when $default != null:
return $default(_that.inningsNumber,_that.battingTeamId,_that.battingTeamName,_that.battingTeamShort,_that.bowlingTeamId,_that.bowlingTeamName,_that.bowlingTeamShort,_that.openingStrikerId,_that.openingStrikerName,_that.openingNonStrikerId,_that.openingNonStrikerName,_that.runs,_that.wickets,_that.legalBalls,_that.wides,_that.noballs,_that.byes,_that.legbyes,_that.strikerId,_that.strikerName,_that.nonStrikerId,_that.nonStrikerName,_that.currentBowlerId,_that.currentBowlerName,_that.targetRuns,_that.isComplete,_that.completionReason,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int inningsNumber,  String battingTeamId,  String battingTeamName,  String battingTeamShort,  String bowlingTeamId,  String bowlingTeamName,  String bowlingTeamShort,  String openingStrikerId,  String openingStrikerName,  String openingNonStrikerId,  String openingNonStrikerName,  int runs,  int wickets,  int legalBalls,  int wides,  int noballs,  int byes,  int legbyes,  String? strikerId,  String? strikerName,  String? nonStrikerId,  String? nonStrikerName,  String? currentBowlerId,  String? currentBowlerName,  int? targetRuns,  bool isComplete,  String? completionReason,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Innings():
return $default(_that.inningsNumber,_that.battingTeamId,_that.battingTeamName,_that.battingTeamShort,_that.bowlingTeamId,_that.bowlingTeamName,_that.bowlingTeamShort,_that.openingStrikerId,_that.openingStrikerName,_that.openingNonStrikerId,_that.openingNonStrikerName,_that.runs,_that.wickets,_that.legalBalls,_that.wides,_that.noballs,_that.byes,_that.legbyes,_that.strikerId,_that.strikerName,_that.nonStrikerId,_that.nonStrikerName,_that.currentBowlerId,_that.currentBowlerName,_that.targetRuns,_that.isComplete,_that.completionReason,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int inningsNumber,  String battingTeamId,  String battingTeamName,  String battingTeamShort,  String bowlingTeamId,  String bowlingTeamName,  String bowlingTeamShort,  String openingStrikerId,  String openingStrikerName,  String openingNonStrikerId,  String openingNonStrikerName,  int runs,  int wickets,  int legalBalls,  int wides,  int noballs,  int byes,  int legbyes,  String? strikerId,  String? strikerName,  String? nonStrikerId,  String? nonStrikerName,  String? currentBowlerId,  String? currentBowlerName,  int? targetRuns,  bool isComplete,  String? completionReason,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Innings() when $default != null:
return $default(_that.inningsNumber,_that.battingTeamId,_that.battingTeamName,_that.battingTeamShort,_that.bowlingTeamId,_that.bowlingTeamName,_that.bowlingTeamShort,_that.openingStrikerId,_that.openingStrikerName,_that.openingNonStrikerId,_that.openingNonStrikerName,_that.runs,_that.wickets,_that.legalBalls,_that.wides,_that.noballs,_that.byes,_that.legbyes,_that.strikerId,_that.strikerName,_that.nonStrikerId,_that.nonStrikerName,_that.currentBowlerId,_that.currentBowlerName,_that.targetRuns,_that.isComplete,_that.completionReason,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Innings implements Innings {
  const _Innings({required this.inningsNumber, required this.battingTeamId, required this.battingTeamName, required this.battingTeamShort, required this.bowlingTeamId, required this.bowlingTeamName, required this.bowlingTeamShort, required this.openingStrikerId, required this.openingStrikerName, required this.openingNonStrikerId, required this.openingNonStrikerName, this.runs = 0, this.wickets = 0, this.legalBalls = 0, this.wides = 0, this.noballs = 0, this.byes = 0, this.legbyes = 0, this.strikerId, this.strikerName, this.nonStrikerId, this.nonStrikerName, this.currentBowlerId, this.currentBowlerName, this.targetRuns, this.isComplete = false, this.completionReason, this.createdAt, this.updatedAt});
  factory _Innings.fromJson(Map<String, dynamic> json) => _$InningsFromJson(json);

@override final  int inningsNumber;
@override final  String battingTeamId;
@override final  String battingTeamName;
@override final  String battingTeamShort;
@override final  String bowlingTeamId;
@override final  String bowlingTeamName;
@override final  String bowlingTeamShort;
@override final  String openingStrikerId;
@override final  String openingStrikerName;
@override final  String openingNonStrikerId;
@override final  String openingNonStrikerName;
@override@JsonKey() final  int runs;
@override@JsonKey() final  int wickets;
@override@JsonKey() final  int legalBalls;
@override@JsonKey() final  int wides;
@override@JsonKey() final  int noballs;
@override@JsonKey() final  int byes;
@override@JsonKey() final  int legbyes;
@override final  String? strikerId;
@override final  String? strikerName;
@override final  String? nonStrikerId;
@override final  String? nonStrikerName;
@override final  String? currentBowlerId;
@override final  String? currentBowlerName;
@override final  int? targetRuns;
@override@JsonKey() final  bool isComplete;
@override final  String? completionReason;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Innings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InningsCopyWith<_Innings> get copyWith => __$InningsCopyWithImpl<_Innings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InningsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Innings&&(identical(other.inningsNumber, inningsNumber) || other.inningsNumber == inningsNumber)&&(identical(other.battingTeamId, battingTeamId) || other.battingTeamId == battingTeamId)&&(identical(other.battingTeamName, battingTeamName) || other.battingTeamName == battingTeamName)&&(identical(other.battingTeamShort, battingTeamShort) || other.battingTeamShort == battingTeamShort)&&(identical(other.bowlingTeamId, bowlingTeamId) || other.bowlingTeamId == bowlingTeamId)&&(identical(other.bowlingTeamName, bowlingTeamName) || other.bowlingTeamName == bowlingTeamName)&&(identical(other.bowlingTeamShort, bowlingTeamShort) || other.bowlingTeamShort == bowlingTeamShort)&&(identical(other.openingStrikerId, openingStrikerId) || other.openingStrikerId == openingStrikerId)&&(identical(other.openingStrikerName, openingStrikerName) || other.openingStrikerName == openingStrikerName)&&(identical(other.openingNonStrikerId, openingNonStrikerId) || other.openingNonStrikerId == openingNonStrikerId)&&(identical(other.openingNonStrikerName, openingNonStrikerName) || other.openingNonStrikerName == openingNonStrikerName)&&(identical(other.runs, runs) || other.runs == runs)&&(identical(other.wickets, wickets) || other.wickets == wickets)&&(identical(other.legalBalls, legalBalls) || other.legalBalls == legalBalls)&&(identical(other.wides, wides) || other.wides == wides)&&(identical(other.noballs, noballs) || other.noballs == noballs)&&(identical(other.byes, byes) || other.byes == byes)&&(identical(other.legbyes, legbyes) || other.legbyes == legbyes)&&(identical(other.strikerId, strikerId) || other.strikerId == strikerId)&&(identical(other.strikerName, strikerName) || other.strikerName == strikerName)&&(identical(other.nonStrikerId, nonStrikerId) || other.nonStrikerId == nonStrikerId)&&(identical(other.nonStrikerName, nonStrikerName) || other.nonStrikerName == nonStrikerName)&&(identical(other.currentBowlerId, currentBowlerId) || other.currentBowlerId == currentBowlerId)&&(identical(other.currentBowlerName, currentBowlerName) || other.currentBowlerName == currentBowlerName)&&(identical(other.targetRuns, targetRuns) || other.targetRuns == targetRuns)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.completionReason, completionReason) || other.completionReason == completionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,inningsNumber,battingTeamId,battingTeamName,battingTeamShort,bowlingTeamId,bowlingTeamName,bowlingTeamShort,openingStrikerId,openingStrikerName,openingNonStrikerId,openingNonStrikerName,runs,wickets,legalBalls,wides,noballs,byes,legbyes,strikerId,strikerName,nonStrikerId,nonStrikerName,currentBowlerId,currentBowlerName,targetRuns,isComplete,completionReason,createdAt,updatedAt]);
}

@override
String toString() {
    return 'Innings(inningsNumber: $inningsNumber, battingTeamId: $battingTeamId, battingTeamName: $battingTeamName, battingTeamShort: $battingTeamShort, bowlingTeamId: $bowlingTeamId, bowlingTeamName: $bowlingTeamName, bowlingTeamShort: $bowlingTeamShort, openingStrikerId: $openingStrikerId, openingStrikerName: $openingStrikerName, openingNonStrikerId: $openingNonStrikerId, openingNonStrikerName: $openingNonStrikerName, runs: $runs, wickets: $wickets, legalBalls: $legalBalls, wides: $wides, noballs: $noballs, byes: $byes, legbyes: $legbyes, strikerId: $strikerId, strikerName: $strikerName, nonStrikerId: $nonStrikerId, nonStrikerName: $nonStrikerName, currentBowlerId: $currentBowlerId, currentBowlerName: $currentBowlerName, targetRuns: $targetRuns, isComplete: $isComplete, completionReason: $completionReason, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$InningsCopyWith<$Res> implements $InningsCopyWith<$Res> {
  factory _$InningsCopyWith(_Innings value, $Res Function(_Innings) _then) = __$InningsCopyWithImpl;
@override @useResult
$Res call({
 int inningsNumber, String battingTeamId, String battingTeamName, String battingTeamShort, String bowlingTeamId, String bowlingTeamName, String bowlingTeamShort, String openingStrikerId, String openingStrikerName, String openingNonStrikerId, String openingNonStrikerName, int runs, int wickets, int legalBalls, int wides, int noballs, int byes, int legbyes, String? strikerId, String? strikerName, String? nonStrikerId, String? nonStrikerName, String? currentBowlerId, String? currentBowlerName, int? targetRuns, bool isComplete, String? completionReason, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$InningsCopyWithImpl<$Res>
    implements _$InningsCopyWith<$Res> {
  __$InningsCopyWithImpl(this._self, this._then);

  final _Innings _self;
  final $Res Function(_Innings) _then;

/// Create a copy of Innings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inningsNumber = null,Object? battingTeamId = null,Object? battingTeamName = null,Object? battingTeamShort = null,Object? bowlingTeamId = null,Object? bowlingTeamName = null,Object? bowlingTeamShort = null,Object? openingStrikerId = null,Object? openingStrikerName = null,Object? openingNonStrikerId = null,Object? openingNonStrikerName = null,Object? runs = null,Object? wickets = null,Object? legalBalls = null,Object? wides = null,Object? noballs = null,Object? byes = null,Object? legbyes = null,Object? strikerId = freezed,Object? strikerName = freezed,Object? nonStrikerId = freezed,Object? nonStrikerName = freezed,Object? currentBowlerId = freezed,Object? currentBowlerName = freezed,Object? targetRuns = freezed,Object? isComplete = null,Object? completionReason = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Innings(
inningsNumber: null == inningsNumber ? _self.inningsNumber : inningsNumber // ignore: cast_nullable_to_non_nullable
as int,battingTeamId: null == battingTeamId ? _self.battingTeamId : battingTeamId // ignore: cast_nullable_to_non_nullable
as String,battingTeamName: null == battingTeamName ? _self.battingTeamName : battingTeamName // ignore: cast_nullable_to_non_nullable
as String,battingTeamShort: null == battingTeamShort ? _self.battingTeamShort : battingTeamShort // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamId: null == bowlingTeamId ? _self.bowlingTeamId : bowlingTeamId // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamName: null == bowlingTeamName ? _self.bowlingTeamName : bowlingTeamName // ignore: cast_nullable_to_non_nullable
as String,bowlingTeamShort: null == bowlingTeamShort ? _self.bowlingTeamShort : bowlingTeamShort // ignore: cast_nullable_to_non_nullable
as String,openingStrikerId: null == openingStrikerId ? _self.openingStrikerId : openingStrikerId // ignore: cast_nullable_to_non_nullable
as String,openingStrikerName: null == openingStrikerName ? _self.openingStrikerName : openingStrikerName // ignore: cast_nullable_to_non_nullable
as String,openingNonStrikerId: null == openingNonStrikerId ? _self.openingNonStrikerId : openingNonStrikerId // ignore: cast_nullable_to_non_nullable
as String,openingNonStrikerName: null == openingNonStrikerName ? _self.openingNonStrikerName : openingNonStrikerName // ignore: cast_nullable_to_non_nullable
as String,runs: null == runs ? _self.runs : runs // ignore: cast_nullable_to_non_nullable
as int,wickets: null == wickets ? _self.wickets : wickets // ignore: cast_nullable_to_non_nullable
as int,legalBalls: null == legalBalls ? _self.legalBalls : legalBalls // ignore: cast_nullable_to_non_nullable
as int,wides: null == wides ? _self.wides : wides // ignore: cast_nullable_to_non_nullable
as int,noballs: null == noballs ? _self.noballs : noballs // ignore: cast_nullable_to_non_nullable
as int,byes: null == byes ? _self.byes : byes // ignore: cast_nullable_to_non_nullable
as int,legbyes: null == legbyes ? _self.legbyes : legbyes // ignore: cast_nullable_to_non_nullable
as int,strikerId: freezed == strikerId ? _self.strikerId : strikerId // ignore: cast_nullable_to_non_nullable
as String?,strikerName: freezed == strikerName ? _self.strikerName : strikerName // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerId: freezed == nonStrikerId ? _self.nonStrikerId : nonStrikerId // ignore: cast_nullable_to_non_nullable
as String?,nonStrikerName: freezed == nonStrikerName ? _self.nonStrikerName : nonStrikerName // ignore: cast_nullable_to_non_nullable
as String?,currentBowlerId: freezed == currentBowlerId ? _self.currentBowlerId : currentBowlerId // ignore: cast_nullable_to_non_nullable
as String?,currentBowlerName: freezed == currentBowlerName ? _self.currentBowlerName : currentBowlerName // ignore: cast_nullable_to_non_nullable
as String?,targetRuns: freezed == targetRuns ? _self.targetRuns : targetRuns // ignore: cast_nullable_to_non_nullable
as int?,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,completionReason: freezed == completionReason ? _self.completionReason : completionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
