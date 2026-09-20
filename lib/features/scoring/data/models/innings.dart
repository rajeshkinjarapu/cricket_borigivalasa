import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
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
      inningsNumber: json['inningsNumber'] as int? ?? 1,
      battingTeamId: json['battingTeamId'] as String? ?? '',
      battingTeamName: json['battingTeamName'] as String? ?? '',
      battingTeamShort: json['battingTeamShort'] as String? ?? '',
      bowlingTeamId: json['bowlingTeamId'] as String? ?? '',
      bowlingTeamName: json['bowlingTeamName'] as String? ?? '',
      bowlingTeamShort: json['bowlingTeamShort'] as String? ?? '',
      openingStrikerId: json['openingStrikerId'] as String? ?? '',
      openingStrikerName: json['openingStrikerName'] as String? ?? '',
      openingNonStrikerId: json['openingNonStrikerId'] as String? ?? '',
      openingNonStrikerName: json['openingNonStrikerName'] as String? ?? '',
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      legalBalls: json['legalBalls'] as int? ?? 0,
      wides: json['wides'] as int? ?? 0,
      noballs: json['noballs'] as int? ?? 0,
      byes: json['byes'] as int? ?? 0,
      legbyes: json['legbyes'] as int? ?? 0,
      strikerId: json['strikerId'] as String?,
      strikerName: json['strikerName'] as String?,
      nonStrikerId: json['nonStrikerId'] as String?,
      nonStrikerName: json['nonStrikerName'] as String?,
      currentBowlerId: json['currentBowlerId'] as String?,
      currentBowlerName: json['currentBowlerName'] as String?,
      targetRuns: json['targetRuns'] as int?,
      isComplete: json['isComplete'] as bool? ?? false,
      completionReason: json['completionReason'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inningsNumber': inningsNumber,
      'battingTeamId': battingTeamId,
      'battingTeamName': battingTeamName,
      'battingTeamShort': battingTeamShort,
      'bowlingTeamId': bowlingTeamId,
      'bowlingTeamName': bowlingTeamName,
      'bowlingTeamShort': bowlingTeamShort,
      'openingStrikerId': openingStrikerId,
      'openingStrikerName': openingStrikerName,
      'openingNonStrikerId': openingNonStrikerId,
      'openingNonStrikerName': openingNonStrikerName,
      'runs': runs,
      'wickets': wickets,
      'legalBalls': legalBalls,
      'wides': wides,
      'noballs': noballs,
      'byes': byes,
      'legbyes': legbyes,
      'strikerId': strikerId,
      'strikerName': strikerName,
      'nonStrikerId': nonStrikerId,
      'nonStrikerName': nonStrikerName,
      'currentBowlerId': currentBowlerId,
      'currentBowlerName': currentBowlerName,
      'targetRuns': targetRuns,
      'isComplete': isComplete,
      'completionReason': completionReason,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
