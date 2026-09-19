import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/cricket_enums.dart';

class PlayerStats {
  final int matchesPlayed;
  final int runsScored;
  final int highestScore;
  final int wicketsTaken;
  final String bestBowling; // e.g. "4/20"
  final double battingAverage;
  final double economyRate;

  PlayerStats({
    this.matchesPlayed = 0,
    this.runsScored = 0,
    this.highestScore = 0,
    this.wicketsTaken = 0,
    this.bestBowling = '-',
    this.battingAverage = 0.0,
    this.economyRate = 0.0,
  });

  factory PlayerStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PlayerStats();
    return PlayerStats(
      matchesPlayed: json['matchesPlayed'] as int? ?? 0,
      runsScored: json['runsScored'] as int? ?? 0,
      highestScore: json['highestScore'] as int? ?? 0,
      wicketsTaken: json['wicketsTaken'] as int? ?? 0,
      bestBowling: json['bestBowling'] as String? ?? '-',
      battingAverage: (json['battingAverage'] as num?)?.toDouble() ?? 0.0,
      economyRate: (json['economyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchesPlayed': matchesPlayed,
      'runsScored': runsScored,
      'highestScore': highestScore,
      'wicketsTaken': wicketsTaken,
      'bestBowling': bestBowling,
      'battingAverage': battingAverage,
      'economyRate': economyRate,
    };
  }
}

class Player {
  final String id;
  final String name;
  final String teamId;
  final PlayerRole role;
  final BattingStyle battingStyle;
  final BowlingStyle bowlingStyle;
  final int? jerseyNumber;
  final String? phoneNumber;
  final String? profilePicUrl;
  final PlayerStats stats;
  final DateTime createdAt;

  Player({
    required this.id,
    required this.name,
    required this.teamId,
    required this.role,
    this.battingStyle = BattingStyle.rightHand,
    this.bowlingStyle = BowlingStyle.none,
    this.jerseyNumber,
    this.phoneNumber,
    this.profilePicUrl,
    PlayerStats? stats,
    DateTime? createdAt,
  })  : stats = stats ?? PlayerStats(),
        createdAt = createdAt ?? DateTime.now();

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      teamId: json['teamId'] as String? ?? '',
      role: PlayerRole.values.firstWhere(
        (e) => e.name == (json['role'] as String?),
        orElse: () => PlayerRole.batter,
      ),
      battingStyle: BattingStyle.values.firstWhere(
        (e) => e.name == (json['battingStyle'] as String?),
        orElse: () => BattingStyle.rightHand,
      ),
      bowlingStyle: BowlingStyle.values.firstWhere(
        (e) => e.name == (json['bowlingStyle'] as String?),
        orElse: () => BowlingStyle.none,
      ),
      jerseyNumber: json['jerseyNumber'] as int?,
      phoneNumber: json['phoneNumber'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      stats: PlayerStats.fromJson(json['stats'] as Map<String, dynamic>?),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
      'role': role.name,
      'battingStyle': battingStyle.name,
      'bowlingStyle': bowlingStyle.name,
      'jerseyNumber': jerseyNumber,
      'phoneNumber': phoneNumber,
      'profilePicUrl': profilePicUrl,
      'stats': stats.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? teamId,
    PlayerRole? role,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    int? jerseyNumber,
    String? phoneNumber,
    String? profilePicUrl,
    PlayerStats? stats,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
