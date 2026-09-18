class BowlingScorecard {
  final String playerId;
  final String playerName;
  final int balls;
  final int runs;
  final int wickets;
  final int maidens;
  final int wides;
  final int noballs;

  BowlingScorecard({
    required this.playerId,
    required this.playerName,
    this.balls = 0,
    this.runs = 0,
    this.wickets = 0,
    this.maidens = 0,
    this.wides = 0,
    this.noballs = 0,
  });

  factory BowlingScorecard.fromJson(Map<String, dynamic> json) {
    return BowlingScorecard(
      playerId: json['playerId'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      balls: json['balls'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      wickets: json['wickets'] as int? ?? 0,
      maidens: json['maidens'] as int? ?? 0,
      wides: json['wides'] as int? ?? 0,
      noballs: json['noballs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'balls': balls,
      'runs': runs,
      'wickets': wickets,
      'maidens': maidens,
      'wides': wides,
      'noballs': noballs,
    };
  }

  BowlingScorecard copyWith({
    String? playerId,
    String? playerName,
    int? balls,
    int? runs,
    int? wickets,
    int? maidens,
    int? wides,
    int? noballs,
  }) {
    return BowlingScorecard(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      balls: balls ?? this.balls,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      maidens: maidens ?? this.maidens,
      wides: wides ?? this.wides,
      noballs: noballs ?? this.noballs,
    );
  }

  String get oversText => '${balls ~/ 6}.${balls % 6}';
  double get economy => balls == 0 ? 0 : runs * 6 / balls;
}
