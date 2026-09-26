// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Team _$TeamFromJson(Map<String, dynamic> json) => _Team(
  id: json['id'] as String,
  name: json['name'] as String,
  shortName: json['shortName'] as String,
  logoUrl: json['logoUrl'] as String?,
  captainId: json['captainId'] as String?,
  captainName: json['captainName'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$TeamToJson(_Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'shortName': instance.shortName,
  'logoUrl': instance.logoUrl,
  'captainId': instance.captainId,
  'captainName': instance.captainName,
  'createdAt': instance.createdAt?.toIso8601String(),
};
