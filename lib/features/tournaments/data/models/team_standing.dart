import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_standing.freezed.dart';
part 'team_standing.g.dart';

@freezed
abstract class TeamStanding with _$TeamStanding {
  const factory TeamStanding({
    required String teamId,
    required String teamName,
    @Default(0) int matchesPlayed,
    @Default(0) int won,
    @Default(0) int lost,
    @Default(0) int tied,
    @Default(0) int noResult,
    @Default(0) int points,
    @Default(0.0) double netRunRate,
  }) = _TeamStanding;

  factory TeamStanding.fromJson(Map<String, dynamic> json) => _$TeamStandingFromJson(json);
}
