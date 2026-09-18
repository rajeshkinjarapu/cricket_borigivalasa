import 'package:cloud_firestore/cloud_firestore.dart';
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
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return Match(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      teamAId: json['teamAId'] as String? ?? 'teamA',
      teamBId: json['teamBId'] as String? ?? 'teamB',
      teamA: json['teamA'] as String? ?? (json['teamAName'] as String? ?? 'Team A'),
      teamB: json['teamB'] as String? ?? (json['teamBName'] as String? ?? 'Team B'),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => MatchStatus.scheduled,
      ),
      matchDate: json['matchDate'] != null
          ? parseDate(json['matchDate'])
          : (json['scheduledAt'] != null ? parseDate(json['scheduledAt']) : DateTime.now()),
      venue: json['venue'] as String? ?? 'Ground',
      totalOvers: json['totalOvers'] as int? ?? 20,
      matchNumber: json['matchNumber'] as int?,
      tossWinnerId: json['tossWinnerId'] as String? ?? (json['tossWinnerTeamId'] as String?),
      tossDecision: json['tossDecision'] != null
          ? TossDecision.values.firstWhere(
              (e) => e.name == (json['tossDecision'] as String?),
              orElse: () => TossDecision.bat,
            )
          : null,
      liveScore: json['liveScore'] as Map<String, dynamic>?,
      winnerTeamId: json['winnerTeamId'] as String?,
      resultText: json['resultText'] as String?,
      isTie: json['isTie'] as bool? ?? false,
      startedAt: json['startedAt'] != null ? parseDate(json['startedAt']) : null,
      completedAt: json['completedAt'] != null ? parseDate(json['completedAt']) : null,
      createdAt: json['createdAt'] != null ? parseDate(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'teamA': teamA,
      'teamB': teamB,
      'teamAName': teamA,
      'teamBName': teamB,
      'teamAShort': teamAShort,
      'teamBShort': teamBShort,
      'status': status.name,
      'matchDate': Timestamp.fromDate(matchDate),
      'scheduledAt': Timestamp.fromDate(matchDate),
      'venue': venue,
      'totalOvers': totalOvers,
      'matchNumber': matchNumber,
      'tossWinnerId': tossWinnerId,
      'tossWinnerTeamId': tossWinnerId,
      'tossDecision': tossDecision?.name,
      'liveScore': liveScore,
      'winnerTeamId': winnerTeamId,
      'resultText': resultText,
      'isTie': isTie,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
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
    );
  }
}

typedef MatchModel = Match;
