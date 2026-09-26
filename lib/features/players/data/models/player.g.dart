// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Player _$PlayerFromJson(Map<String, dynamic> json) => _Player(
  id: json['id'] as String,
  name: json['name'] as String,
  role: $enumDecode(_$PlayerRoleEnumMap, json['role']),
  battingStyle:
      $enumDecodeNullable(_$BattingStyleEnumMap, json['battingStyle']) ??
      BattingStyle.rightHand,
  bowlingStyle:
      $enumDecodeNullable(_$BowlingStyleEnumMap, json['bowlingStyle']) ??
      BowlingStyle.none,
  jerseyNumber: (json['jerseyNumber'] as num?)?.toInt(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PlayerToJson(_Player instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'role': _$PlayerRoleEnumMap[instance.role]!,
  'battingStyle': _$BattingStyleEnumMap[instance.battingStyle]!,
  'bowlingStyle': _$BowlingStyleEnumMap[instance.bowlingStyle]!,
  'jerseyNumber': instance.jerseyNumber,
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$PlayerRoleEnumMap = {
  PlayerRole.batter: 'batter',
  PlayerRole.bowler: 'bowler',
  PlayerRole.allRounder: 'allRounder',
  PlayerRole.wicketKeeper: 'wicketKeeper',
};

const _$BattingStyleEnumMap = {
  BattingStyle.rightHand: 'rightHand',
  BattingStyle.leftHand: 'leftHand',
};

const _$BowlingStyleEnumMap = {
  BowlingStyle.none: 'none',
  BowlingStyle.rightArmFast: 'rightArmFast',
  BowlingStyle.rightArmMedium: 'rightArmMedium',
  BowlingStyle.rightArmOffSpin: 'rightArmOffSpin',
  BowlingStyle.rightArmLegSpin: 'rightArmLegSpin',
  BowlingStyle.leftArmFast: 'leftArmFast',
  BowlingStyle.leftArmMedium: 'leftArmMedium',
  BowlingStyle.leftArmOrthodox: 'leftArmOrthodox',
  BowlingStyle.leftArmChinaman: 'leftArmChinaman',
};
