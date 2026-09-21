DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class Innings {
  final int inningsNumber;
  final String battingTeamId;
  final String battingTeamName;
  final String battingTeamShort;
  final String bowlingTeamId;
  final String bowlingTeamName;
  final String bowlingTeamShort;
  final String openingStrikerId;
  final String openingStrikerName;
  final String openingNonStrikerId;
  final String openingNonStrikerName;
  final int runs;
  final int wickets;
  final int legalBalls;
  final int wides;
  final int noballs;
  final int byes;
  final int legbyes;
  final String? strikerId;
  final String? strikerName;
  final String? nonStrikerId;
  final String? nonStrikerName;
  final String? currentBowlerId;
  final String? currentBowlerName;
  final int? targetRuns;
  final bool isComplete;
  final String? completionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Innings({
    required this.inningsNumber,
    required this.battingTeamId,
    required this.battingTeamName,
    required this.battingTeamShort,
    required this.bowlingTeamId,
    required this.bowlingTeamName,
    required this.bowlingTeamShort,
    required this.openingStrikerId,
    required this.openingStrikerName,
    required this.openingNonStrikerId,
    required this.openingNonStrikerName,
    this.runs = 0,
    this.wickets = 0,
    this.legalBalls = 0,
    this.wides = 0,
    this.noballs = 0,
    this.byes = 0,
    this.legbyes = 0,
    this.strikerId,
    this.strikerName,
    this.nonStrikerId,
    this.nonStrikerName,
    this.currentBowlerId,
    this.currentBowlerName,
    this.targetRuns,
    this.isComplete = false,
    this.completionReason,
    this.createdAt,
    this.updatedAt,
  });

  factory Innings.fromJson(Map<String, dynamic> json) {
    return Innings(
      inningsNumber: json['innings_number'] as int? ?? 1,
      battingTeamId: json['batting_team_id'] as String? ?? '',
      battingTeamName: json['batting_team_name'] as String? ?? '',
      battingTeamShort: json['batting_team_short'] as String? ?? '',
      bowlingTeamId: json['bowling_team_id'] as String? ?? '',
      bowlingTeamName: json['bowling_team_name'] as String? ?? '',
      bowlingTeamShort: json['bowling_team_short'] as String? ?? '',
      openingStrikerId: json['opening_striker_id'] as String? ?? '',
      openingStrikerName: json['opening_striker_name'] as String? ?? '',
      openingNonStrikerId: json['opening_non_striker_id'] as String? ?? '',
      openingNonStrikerName: json['opening_non_striker_name'] as String? ?? '',
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      legalBalls: json['legal_balls'] as int? ?? 0,
      wides: json['extras_wides'] as int? ?? (json['wides'] as int? ?? 0),
      noballs: json['extras_no_balls'] as int? ?? (json['noballs'] as int? ?? 0),
      byes: json['extras_byes'] as int? ?? (json['byes'] as int? ?? 0),
      legbyes: json['extras_leg_byes'] as int? ?? (json['legbyes'] as int? ?? 0),
      strikerId: json['current_striker_id'] as String? ?? (json['strikerId'] as String?),
      strikerName: json['striker_name'] as String? ?? (json['strikerName'] as String?),
      nonStrikerId: json['current_non_striker_id'] as String? ?? (json['nonStrikerId'] as String?),
      nonStrikerName: json['non_striker_name'] as String? ?? (json['nonStrikerName'] as String?),
      currentBowlerId: json['current_bowler_id'] as String? ?? (json['currentBowlerId'] as String?),
      currentBowlerName: json['current_bowler_name'] as String? ?? (json['currentBowlerName'] as String?),
      targetRuns: json['target_runs'] as int? ?? (json['targetRuns'] as int?),
      isComplete: json['is_complete'] as bool? ?? (json['isComplete'] as bool? ?? false),
      completionReason: json['completion_reason'] as String? ?? (json['completionReason'] as String?),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'innings_number': inningsNumber,
      'batting_team_id': battingTeamId,
      'batting_team_name': battingTeamName,
      'batting_team_short': battingTeamShort,
      'bowling_team_id': bowlingTeamId,
      'bowling_team_name': bowlingTeamName,
      'bowling_team_short': bowlingTeamShort,
      'opening_striker_id': openingStrikerId,
      'opening_striker_name': openingStrikerName,
      'opening_non_striker_id': openingNonStrikerId,
      'opening_non_striker_name': openingNonStrikerName,
      'runs': runs,
      'wickets': wickets,
      'legal_balls': legalBalls,
      'extras_wides': wides,
      'extras_no_balls': noballs,
      'extras_byes': byes,
      'extras_leg_byes': legbyes,
      'current_striker_id': strikerId,
      'striker_name': strikerName,
      'current_non_striker_id': nonStrikerId,
      'non_striker_name': nonStrikerName,
      'current_bowler_id': currentBowlerId,
      'current_bowler_name': currentBowlerName,
      'target_runs': targetRuns,
      'is_complete': isComplete,
      'completion_reason': completionReason,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Innings copyWith({
    int? inningsNumber,
    String? battingTeamId,
    String? battingTeamName,
    String? battingTeamShort,
    String? bowlingTeamId,
    String? bowlingTeamName,
    String? bowlingTeamShort,
    String? openingStrikerId,
    String? openingStrikerName,
    String? openingNonStrikerId,
    String? openingNonStrikerName,
    int? runs,
    int? wickets,
    int? legalBalls,
    int? wides,
    int? noballs,
    int? byes,
    int? legbyes,
    String? strikerId,
    String? strikerName,
    String? nonStrikerId,
    String? nonStrikerName,
    String? currentBowlerId,
    String? currentBowlerName,
    int? targetRuns,
    bool? isComplete,
    String? completionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Innings(
      inningsNumber: inningsNumber ?? this.inningsNumber,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      battingTeamName: battingTeamName ?? this.battingTeamName,
      battingTeamShort: battingTeamShort ?? this.battingTeamShort,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      bowlingTeamName: bowlingTeamName ?? this.bowlingTeamName,
      bowlingTeamShort: bowlingTeamShort ?? this.bowlingTeamShort,
      openingStrikerId: openingStrikerId ?? this.openingStrikerId,
      openingStrikerName: openingStrikerName ?? this.openingStrikerName,
      openingNonStrikerId: openingNonStrikerId ?? this.openingNonStrikerId,
      openingNonStrikerName: openingNonStrikerName ?? this.openingNonStrikerName,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      legalBalls: legalBalls ?? this.legalBalls,
      wides: wides ?? this.wides,
      noballs: noballs ?? this.noballs,
      byes: byes ?? this.byes,
      legbyes: legbyes ?? this.legbyes,
      strikerId: strikerId ?? this.strikerId,
      strikerName: strikerName ?? this.strikerName,
      nonStrikerId: nonStrikerId ?? this.nonStrikerId,
      nonStrikerName: nonStrikerName ?? this.nonStrikerName,
      currentBowlerId: currentBowlerId ?? this.currentBowlerId,
      currentBowlerName: currentBowlerName ?? this.currentBowlerName,
      targetRuns: targetRuns ?? this.targetRuns,
      isComplete: isComplete ?? this.isComplete,
      completionReason: completionReason ?? this.completionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get oversText => '${legalBalls ~/ 6}.${legalBalls % 6}';
  int get extras => wides + noballs + byes + legbyes;
  double get runRate => legalBalls == 0 ? 0 : runs * 6 / legalBalls;
}
