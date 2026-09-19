class TeamStanding {
  final String teamId;
  final String teamName;
  final int matchesPlayed;
  final int won;
  final int lost;
  final int tied;
  final int noResult;
  final int points;
  final double netRunRate;

  const TeamStanding({
    required this.teamId,
    required this.teamName,
    this.matchesPlayed = 0,
    this.won = 0,
    this.lost = 0,
    this.tied = 0,
    this.noResult = 0,
    this.points = 0,
    this.netRunRate = 0.0,
  });

  TeamStanding copyWith({
    String? teamId,
    String? teamName,
    int? matchesPlayed,
    int? won,
    int? lost,
    int? tied,
    int? noResult,
    int? points,
    double? netRunRate,
  }) {
    return TeamStanding(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      won: won ?? this.won,
      lost: lost ?? this.lost,
      tied: tied ?? this.tied,
      noResult: noResult ?? this.noResult,
      points: points ?? this.points,
      netRunRate: netRunRate ?? this.netRunRate,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'teamName': teamName,
    'matchesPlayed': matchesPlayed,
    'won': won,
    'lost': lost,
    'tied': tied,
    'noResult': noResult,
    'points': points,
    'netRunRate': netRunRate,
  };

  factory TeamStanding.fromJson(Map<String, dynamic> json) => TeamStanding(
    teamId: json['teamId'] as String? ?? '',
    teamName: json['teamName'] as String? ?? '',
    matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
    won: (json['won'] as num?)?.toInt() ?? 0,
    lost: (json['lost'] as num?)?.toInt() ?? 0,
    tied: (json['tied'] as num?)?.toInt() ?? 0,
    noResult: (json['noResult'] as num?)?.toInt() ?? 0,
    points: (json['points'] as num?)?.toInt() ?? 0,
    netRunRate: (json['netRunRate'] as num?)?.toDouble() ?? 0.0,
  );
}
