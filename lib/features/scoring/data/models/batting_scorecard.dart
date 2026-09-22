typedef BattingScorecardRow = BattingScorecard;

class BattingScorecard {
  final String playerId;
  final String playerName;
  final int battingOrder;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final String? dismissalText;
  final bool isStriker;
  final bool isNonStriker;

  BattingScorecard({
    required this.playerId,
    required this.playerName,
    required this.battingOrder,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.dismissalText,
    this.isStriker = false,
    this.isNonStriker = false,
  });

  factory BattingScorecard.fromJson(Map<String, dynamic> json) {
    return BattingScorecard(
      playerId: json['playerId'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      battingOrder: json['battingOrder'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      balls: json['balls'] as int? ?? 0,
      fours: json['fours'] as int? ?? 0,
      sixes: json['sixes'] as int? ?? 0,
      isOut: json['isOut'] as bool? ?? false,
      dismissalText: json['dismissalText'] as String?,
      isStriker: json['isStriker'] as bool? ?? false,
      isNonStriker: json['isNonStriker'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'battingOrder': battingOrder,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'isOut': isOut,
      'dismissalText': dismissalText,
      'isStriker': isStriker,
      'isNonStriker': isNonStriker,
    };
  }

  BattingScorecard copyWith({
    String? playerId,
    String? playerName,
    int? battingOrder,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOut,
    String? dismissalText,
    bool? isStriker,
    bool? isNonStriker,
  }) {
    return BattingScorecard(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      battingOrder: battingOrder ?? this.battingOrder,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      dismissalText: dismissalText ?? this.dismissalText,
      isStriker: isStriker ?? this.isStriker,
      isNonStriker: isNonStriker ?? this.isNonStriker,
    );
  }
}
