// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bowling_scorecard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BowlingScorecard _$BowlingScorecardFromJson(Map<String, dynamic> json) =>
    _BowlingScorecard(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      balls: (json['balls'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      maidens: (json['maidens'] as num?)?.toInt() ?? 0,
      wides: (json['wides'] as num?)?.toInt() ?? 0,
      noballs: (json['noballs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BowlingScorecardToJson(_BowlingScorecard instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'playerName': instance.playerName,
      'balls': instance.balls,
      'runs': instance.runs,
      'wickets': instance.wickets,
      'maidens': instance.maidens,
      'wides': instance.wides,
      'noballs': instance.noballs,
    };
