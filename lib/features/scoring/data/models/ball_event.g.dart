// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BallEvent _$BallEventFromJson(Map<String, dynamic> json) => _BallEvent(
  batRuns: (json['batRuns'] as num?)?.toInt() ?? 0,
  extraRuns: (json['extraRuns'] as num?)?.toInt() ?? 0,
  extraType:
      $enumDecodeNullable(_$ExtraTypeEnumMap, json['extraType']) ??
      ExtraType.none,
  isWicket: json['isWicket'] as bool? ?? false,
  wicketType: $enumDecodeNullable(_$WicketTypeEnumMap, json['wicketType']),
  dismissedPlayerId: json['dismissedPlayerId'] as String?,
  dismissedPlayerName: json['dismissedPlayerName'] as String?,
  fielderId: json['fielderId'] as String?,
  fielderName: json['fielderName'] as String?,
  batsmanId: json['batsmanId'] as String,
  batsmanName: json['batsmanName'] as String,
  bowlerId: json['bowlerId'] as String,
  bowlerName: json['bowlerName'] as String,
  newBatsmanId: json['newBatsmanId'] as String?,
  newBatsmanName: json['newBatsmanName'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$BallEventToJson(_BallEvent instance) =>
    <String, dynamic>{
      'batRuns': instance.batRuns,
      'extraRuns': instance.extraRuns,
      'extraType': _$ExtraTypeEnumMap[instance.extraType]!,
      'isWicket': instance.isWicket,
      'wicketType': _$WicketTypeEnumMap[instance.wicketType],
      'dismissedPlayerId': instance.dismissedPlayerId,
      'dismissedPlayerName': instance.dismissedPlayerName,
      'fielderId': instance.fielderId,
      'fielderName': instance.fielderName,
      'batsmanId': instance.batsmanId,
      'batsmanName': instance.batsmanName,
      'bowlerId': instance.bowlerId,
      'bowlerName': instance.bowlerName,
      'newBatsmanId': instance.newBatsmanId,
      'newBatsmanName': instance.newBatsmanName,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$ExtraTypeEnumMap = {
  ExtraType.none: 'none',
  ExtraType.wide: 'wide',
  ExtraType.noball: 'noball',
  ExtraType.bye: 'bye',
  ExtraType.legbye: 'legbye',
};

const _$WicketTypeEnumMap = {
  WicketType.bowled: 'bowled',
  WicketType.caught: 'caught',
  WicketType.lbw: 'lbw',
  WicketType.runOut: 'runOut',
  WicketType.stumped: 'stumped',
  WicketType.hitWicket: 'hitWicket',
  WicketType.retiredHurt: 'retiredHurt',
  WicketType.obstructingField: 'obstructingField',
};
