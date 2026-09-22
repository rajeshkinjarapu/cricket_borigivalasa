
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
      matchesPlayed: json['matches_played'] as int? ?? 0,
      runsScored: json['runs_scored'] as int? ?? 0,
      highestScore: json['highest_score'] as int? ?? 0,
      wicketsTaken: json['wickets'] as int? ?? 0,
      bestBowling: json['best_bowling'] as String? ?? '-',
      battingAverage: (json['batting_average'] as num?)?.toDouble() ?? 0.0,
      economyRate: (json['economy_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matches_played': matchesPlayed,
      'runs_scored': runsScored,
      'highest_score': highestScore,
      'wickets': wicketsTaken,
      'best_bowling': bestBowling,
      'batting_average': battingAverage,
      'economy_rate': economyRate,
    };
  }
}

class Player {
  final String id;
  final String name;
  final String teamId;
  final List<String> teamIds;
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
    this.teamIds = const [],
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
    final tId = json['team_id'] as String? ?? '';
    final tIds = (json['team_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        (tId.isNotEmpty ? [tId] : <String>[]);

    final roleRaw = (json['role'] as String?)?.toLowerCase();
    PlayerRole parsedRole = PlayerRole.batter;
    if (roleRaw == 'bowler') {
      parsedRole = PlayerRole.bowler;
    } else if (roleRaw == 'allrounder' || roleRaw == 'all_rounder') {
      parsedRole = PlayerRole.allRounder;
    } else if (roleRaw == 'wicketkeeper' || roleRaw == 'wicket_keeper') {
      parsedRole = PlayerRole.wicketKeeper;
    } else if (roleRaw == 'batsman' || roleRaw == 'batter') {
      parsedRole = PlayerRole.batter;
    }

    final batRaw = (json['batting_style'] as String?)?.toLowerCase();
    final parsedBatting = (batRaw == 'lefthanded' || batRaw == 'lefthand')
        ? BattingStyle.leftHand
        : BattingStyle.rightHand;

    final bowlRaw = json['bowling_style'] as String?;
    BowlingStyle parsedBowling = BowlingStyle.none;
    if (bowlRaw != null && bowlRaw.isNotEmpty && bowlRaw != 'none') {
      parsedBowling = BowlingStyle.values.firstWhere(
        (e) => e.name == bowlRaw,
        orElse: () {
          if (bowlRaw == 'rightArmSpin') return BowlingStyle.rightArmOffSpin;
          if (bowlRaw == 'leftArmSpin') return BowlingStyle.leftArmOrthodox;
          if (bowlRaw == 'rightArmFast') return BowlingStyle.rightArmFast;
          if (bowlRaw == 'rightArmMedium') return BowlingStyle.rightArmMedium;
          if (bowlRaw == 'leftArmFast') return BowlingStyle.leftArmFast;
          if (bowlRaw == 'leftArmMedium') return BowlingStyle.leftArmMedium;
          return BowlingStyle.none;
        },
      );
    }

    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      teamId: tId,
      teamIds: tIds,
      role: parsedRole,
      battingStyle: parsedBatting,
      bowlingStyle: parsedBowling,
      jerseyNumber: json['jersey_number'] as int?,
      phoneNumber: json['phone_number'] as String?,
      profilePicUrl: json['profile_pic_url'] as String?,
      stats: PlayerStats.fromJson(json), // Flattened in Supabase
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'team_id': teamId,
      'team_ids': teamIds.isNotEmpty ? teamIds : (teamId.isNotEmpty ? [teamId] : []),
      'role': role.name,
      'batting_style': battingStyle.name,
      'bowling_style': bowlingStyle.name,
      'jersey_number': jerseyNumber,
      'phone_number': phoneNumber,
      'profile_pic_url': profilePicUrl,
      ...stats.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? teamId,
    List<String>? teamIds,
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
      teamIds: teamIds ?? this.teamIds,
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
