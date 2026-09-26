// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Match _$MatchFromJson(Map<String, dynamic> json) => _Match(
  id: json['id'] as String,
  teamAId: json['teamAId'] as String,
  teamAName: json['teamAName'] as String,
  teamAShort: json['teamAShort'] as String,
  teamBId: json['teamBId'] as String,
  teamBName: json['teamBName'] as String,
  teamBShort: json['teamBShort'] as String,
  scheduledAt: DateTime.parse(json['scheduledAt'] as String),
  status:
      $enumDecodeNullable(_$MatchStatusEnumMap, json['status']) ??
      MatchStatus.scheduled,
  matchNumber: (json['matchNumber'] as num?)?.toInt(),
  venue: json['venue'] as String?,
  tossWinnerTeamId: json['tossWinnerTeamId'] as String?,
  tossDecision: $enumDecodeNullable(
    _$TossDecisionEnumMap,
    json['tossDecision'],
  ),
  resultText: json['resultText'] as String?,
  winnerTeamId: json['winnerTeamId'] as String?,
  isTie: json['isTie'] as bool? ?? false,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MatchToJson(_Match instance) => <String, dynamic>{
  'id': instance.id,
  'teamAId': instance.teamAId,
  'teamAName': instance.teamAName,
  'teamAShort': instance.teamAShort,
  'teamBId': instance.teamBId,
  'teamBName': instance.teamBName,
  'teamBShort': instance.teamBShort,
  'scheduledAt': instance.scheduledAt.toIso8601String(),
  'status': _$MatchStatusEnumMap[instance.status]!,
  'matchNumber': instance.matchNumber,
  'venue': instance.venue,
  'tossWinnerTeamId': instance.tossWinnerTeamId,
  'tossDecision': _$TossDecisionEnumMap[instance.tossDecision],
  'resultText': instance.resultText,
  'winnerTeamId': instance.winnerTeamId,
  'isTie': instance.isTie,
  'startedAt': instance.startedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$MatchStatusEnumMap = {
  MatchStatus.scheduled: 'scheduled',
  MatchStatus.live: 'live',
  MatchStatus.completed: 'completed',
  MatchStatus.abandoned: 'abandoned',
};

const _$TossDecisionEnumMap = {
  TossDecision.bat: 'bat',
  TossDecision.bowl: 'bowl',
};
