// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batting_scorecard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BattingScorecard _$BattingScorecardFromJson(Map<String, dynamic> json) =>
    _BattingScorecard(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      battingOrder: (json['battingOrder'] as num).toInt(),
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      balls: (json['balls'] as num?)?.toInt() ?? 0,
      fours: (json['fours'] as num?)?.toInt() ?? 0,
      sixes: (json['sixes'] as num?)?.toInt() ?? 0,
      isOut: json['isOut'] as bool? ?? false,
      dismissalText: json['dismissalText'] as String?,
      isStriker: json['isStriker'] as bool? ?? false,
      isNonStriker: json['isNonStriker'] as bool? ?? false,
    );

Map<String, dynamic> _$BattingScorecardToJson(_BattingScorecard instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'playerName': instance.playerName,
      'battingOrder': instance.battingOrder,
      'runs': instance.runs,
      'balls': instance.balls,
      'fours': instance.fours,
      'sixes': instance.sixes,
      'isOut': instance.isOut,
      'dismissalText': instance.dismissalText,
      'isStriker': instance.isStriker,
      'isNonStriker': instance.isNonStriker,
    };
