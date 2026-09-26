
import '../../../../core/constants/cricket_enums.dart';

class Match {
  final String id;
  final String tournamentId;
  final String teamAId;
  final String teamBId;
  final String teamA;
  final String teamB;
  final MatchStatus status;
  final DateTime matchDate;
  final String venue;
  final int totalOvers;
  final int? matchNumber;
  final String? tossWinnerId;
  final TossDecision? tossDecision;
  final Map<String, dynamic>? liveScore;
  final String? winnerTeamId;
  final String? resultText;
  final bool isTie;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final String? manOfTheMatchId;
  final String? manOfTheMatchName;
  final String? createdBy; // user id who created the match

  Match({
    required this.id,
    required this.tournamentId,
    required this.teamAId,
    required this.teamBId,
    required this.teamA,
    required this.teamB,
    required this.status,
    required this.matchDate,
    required this.venue,
    this.totalOvers = 20,
    this.matchNumber,
    this.tossWinnerId,
    this.tossDecision,
    this.liveScore,
    this.winnerTeamId,
    this.resultText,
    this.isTie = false,
    this.startedAt,
    this.completedAt,
    this.manOfTheMatchId,
    this.manOfTheMatchName,
    this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Compatibility aliases
  String get teamAName => teamA;
  String get teamBName => teamB;
  String get teamAShort => teamA.length > 3 ? teamA.substring(0, 3).toUpperCase() : teamA.toUpperCase();
  String get teamBShort => teamB.length > 3 ? teamB.substring(0, 3).toUpperCase() : teamB.toUpperCase();
  DateTime get scheduledAt => matchDate;
  String? get tossWinnerTeamId => tossWinnerId;

  bool get isLive => status == MatchStatus.live;
  bool get isCompleted => status == MatchStatus.completed;
  bool get isScheduled => status == MatchStatus.scheduled;
  bool get isAbandoned => status == MatchStatus.abandoned;
  bool get hasToss => tossWinnerId != null && tossDecision != null;

  String teamNameById(String? id) {
    if (id == null) return '—';
    if (id == teamAId) return teamA;
    if (id == teamBId) return teamB;
    return '—';
  }

  String? get battingFirstTeamId {
    if (!hasToss) return null;
    if (tossDecision == TossDecision.bat) return tossWinnerId;
    return tossWinnerId == teamAId ? teamBId : teamAId;
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return Match(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      teamAId: json['team_a_id'] as String? ?? 'teamA',
      teamBId: json['team_b_id'] as String? ?? 'teamB',
      teamA: json['team_a'] as String? ?? (json['teamA'] as String? ?? 'Team A'),
      teamB: json['team_b'] as String? ?? (json['teamB'] as String? ?? 'Team B'),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => MatchStatus.scheduled,
      ),
      matchDate: json['match_date'] != null
          ? parseDate(json['match_date'])
          : (json['scheduled_at'] != null ? parseDate(json['scheduled_at']) : DateTime.now()),
      venue: json['venue'] as String? ?? 'Ground',
      totalOvers: json['total_overs'] as int? ?? 20,
      matchNumber: json['match_number'] as int?,
      tossWinnerId: json['toss_winner_id'] as String?,
      tossDecision: json['toss_decision'] != null
          ? TossDecision.values.firstWhere(
              (e) => e.name == (json['toss_decision'] as String?),
              orElse: () => TossDecision.bat,
            )
          : null,
      liveScore: json['live_score'] as Map<String, dynamic>?,
      winnerTeamId: json['winner_team_id'] as String?,
      resultText: json['result_text'] as String?,
      isTie: json['is_tie'] as bool? ?? false,
      startedAt: json['started_at'] != null ? parseDate(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? parseDate(json['completed_at']) : null,
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : null,
      manOfTheMatchId: json['man_of_the_match_id'] as String?,
      manOfTheMatchName: json['man_of_the_match_name'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'team_a': teamA,
      'team_b': teamB,
      'status': status.name,
      'match_date': matchDate.toIso8601String(),
      'venue': venue,
      'total_overs': totalOvers,
      'match_number': matchNumber,
      'toss_winner_id': tossWinnerId,
      'toss_decision': tossDecision?.name,
      'live_score': liveScore,
      'winner_team_id': winnerTeamId,
      'result_text': resultText,
      'is_tie': isTie,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'man_of_the_match_id': manOfTheMatchId,
      'man_of_the_match_name': manOfTheMatchName,
      'created_by': createdBy,
    };
  }

  Match copyWith({
    String? id,
    String? tournamentId,
    String? teamAId,
    String? teamBId,
    String? teamA,
    String? teamB,
    MatchStatus? status,
    DateTime? matchDate,
    String? venue,
    int? totalOvers,
    int? matchNumber,
    String? tossWinnerId,
    TossDecision? tossDecision,
    Map<String, dynamic>? liveScore,
    String? winnerTeamId,
    String? resultText,
    bool? isTie,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    String? manOfTheMatchId,
    String? manOfTheMatchName,
    String? createdBy,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      status: status ?? this.status,
      matchDate: matchDate ?? this.matchDate,
      venue: venue ?? this.venue,
      totalOvers: totalOvers ?? this.totalOvers,
      matchNumber: matchNumber ?? this.matchNumber,
      tossWinnerId: tossWinnerId ?? this.tossWinnerId,
      tossDecision: tossDecision ?? this.tossDecision,
      liveScore: liveScore ?? this.liveScore,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      resultText: resultText ?? this.resultText,
      isTie: isTie ?? this.isTie,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      manOfTheMatchId: manOfTheMatchId ?? this.manOfTheMatchId,
      manOfTheMatchName: manOfTheMatchName ?? this.manOfTheMatchName,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

typedef MatchModel = Match;
