// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_standing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamStanding _$TeamStandingFromJson(Map<String, dynamic> json) =>
    _TeamStanding(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      won: (json['won'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      tied: (json['tied'] as num?)?.toInt() ?? 0,
      noResult: (json['noResult'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      netRunRate: (json['netRunRate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TeamStandingToJson(_TeamStanding instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'matchesPlayed': instance.matchesPlayed,
      'won': instance.won,
      'lost': instance.lost,
      'tied': instance.tied,
      'noResult': instance.noResult,
      'points': instance.points,
      'netRunRate': instance.netRunRate,
    };
