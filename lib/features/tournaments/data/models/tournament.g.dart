// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tournament _$TournamentFromJson(Map<String, dynamic> json) => _Tournament(
  id: json['id'] as String,
  name: json['name'] as String,
  format: $enumDecode(_$TournamentFormatEnumMap, json['format']),
  status:
      $enumDecodeNullable(_$TournamentStatusEnumMap, json['status']) ??
      TournamentStatus.upcoming,
  startDate: json['startDate'] == null
      ? null
      : DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  venue: json['venue'] as String?,
  description: json['description'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$TournamentToJson(_Tournament instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'format': _$TournamentFormatEnumMap[instance.format]!,
      'status': _$TournamentStatusEnumMap[instance.status]!,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'venue': instance.venue,
      'description': instance.description,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$TournamentFormatEnumMap = {
  TournamentFormat.t10: 't10',
  TournamentFormat.t20: 't20',
  TournamentFormat.odi: 'odi',
};

const _$TournamentStatusEnumMap = {
  TournamentStatus.upcoming: 'upcoming',
  TournamentStatus.ongoing: 'ongoing',
  TournamentStatus.completed: 'completed',
};
