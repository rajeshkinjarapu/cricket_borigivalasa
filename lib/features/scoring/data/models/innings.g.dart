// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'innings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Innings _$InningsFromJson(Map<String, dynamic> json) => _Innings(
  inningsNumber: (json['inningsNumber'] as num).toInt(),
  battingTeamId: json['battingTeamId'] as String,
  battingTeamName: json['battingTeamName'] as String,
  battingTeamShort: json['battingTeamShort'] as String,
  bowlingTeamId: json['bowlingTeamId'] as String,
  bowlingTeamName: json['bowlingTeamName'] as String,
  bowlingTeamShort: json['bowlingTeamShort'] as String,
  openingStrikerId: json['openingStrikerId'] as String,
  openingStrikerName: json['openingStrikerName'] as String,
  openingNonStrikerId: json['openingNonStrikerId'] as String,
  openingNonStrikerName: json['openingNonStrikerName'] as String,
  runs: (json['runs'] as num?)?.toInt() ?? 0,
  wickets: (json['wickets'] as num?)?.toInt() ?? 0,
  legalBalls: (json['legalBalls'] as num?)?.toInt() ?? 0,
  wides: (json['wides'] as num?)?.toInt() ?? 0,
  noballs: (json['noballs'] as num?)?.toInt() ?? 0,
  byes: (json['byes'] as num?)?.toInt() ?? 0,
  legbyes: (json['legbyes'] as num?)?.toInt() ?? 0,
  strikerId: json['strikerId'] as String?,
  strikerName: json['strikerName'] as String?,
  nonStrikerId: json['nonStrikerId'] as String?,
  nonStrikerName: json['nonStrikerName'] as String?,
  currentBowlerId: json['currentBowlerId'] as String?,
  currentBowlerName: json['currentBowlerName'] as String?,
  targetRuns: (json['targetRuns'] as num?)?.toInt(),
  isComplete: json['isComplete'] as bool? ?? false,
  completionReason: json['completionReason'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$InningsToJson(_Innings instance) => <String, dynamic>{
  'inningsNumber': instance.inningsNumber,
  'battingTeamId': instance.battingTeamId,
  'battingTeamName': instance.battingTeamName,
  'battingTeamShort': instance.battingTeamShort,
  'bowlingTeamId': instance.bowlingTeamId,
  'bowlingTeamName': instance.bowlingTeamName,
  'bowlingTeamShort': instance.bowlingTeamShort,
  'openingStrikerId': instance.openingStrikerId,
  'openingStrikerName': instance.openingStrikerName,
  'openingNonStrikerId': instance.openingNonStrikerId,
  'openingNonStrikerName': instance.openingNonStrikerName,
  'runs': instance.runs,
  'wickets': instance.wickets,
  'legalBalls': instance.legalBalls,
  'wides': instance.wides,
  'noballs': instance.noballs,
  'byes': instance.byes,
  'legbyes': instance.legbyes,
  'strikerId': instance.strikerId,
  'strikerName': instance.strikerName,
  'nonStrikerId': instance.nonStrikerId,
  'nonStrikerName': instance.nonStrikerName,
  'currentBowlerId': instance.currentBowlerId,
  'currentBowlerName': instance.currentBowlerName,
  'targetRuns': instance.targetRuns,
  'isComplete': instance.isComplete,
  'completionReason': instance.completionReason,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
