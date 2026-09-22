import '../../../../core/constants/cricket_enums.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

class BallEvent {
  final String? id;
  final int ballNumber;
  final int overNumber;
  final int batRuns;
  final int extraRuns;
  final ExtraType extraType;
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? dismissedPlayerName;
  final String? fielderId;
  final String? fielderName;
  final String batsmanId;
  final String batsmanName;
  final String bowlerId;
  final String bowlerName;
  final String? newBatsmanId;
  final String? newBatsmanName;
  final DateTime timestamp;

  BallEvent({
    this.id,
    this.ballNumber = 0,
    this.overNumber = 0,
    this.batRuns = 0,
    this.extraRuns = 0,
    this.extraType = ExtraType.none,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.dismissedPlayerName,
    this.fielderId,
    this.fielderName,
    required this.batsmanId,
    required this.batsmanName,
    required this.bowlerId,
    required this.bowlerName,
    this.newBatsmanId,
    this.newBatsmanName,
    required this.timestamp,
  });

  factory BallEvent.fromJson(Map<String, dynamic> json) {
    return BallEvent(
      id: json['id'] as String?,
      ballNumber: json['ball_number'] as int? ?? (json['ballNumber'] as int? ?? 0),
      overNumber: json['over_number'] as int? ?? (json['overNumber'] as int? ?? 0),
      batRuns: json['runs_scored'] as int? ?? (json['batRuns'] as int? ?? 0),
      extraRuns: json['extras_runs'] as int? ?? (json['extraRuns'] as int? ?? 0),
      extraType: ExtraType.values.firstWhere(
        (e) => e.name == (json['extras_type'] as String? ?? json['extraType'] as String?),
        orElse: () => ExtraType.none,
      ),
      isWicket: json['is_wicket'] as bool? ?? (json['isWicket'] as bool? ?? false),
      wicketType: (json['wicket_type'] ?? json['wicketType']) != null
          ? WicketType.values.firstWhere(
              (e) => e.name == (json['wicket_type'] as String? ?? json['wicketType'] as String?),
              orElse: () => WicketType.bowled,
            )
          : null,
      dismissedPlayerId: json['player_out_id'] as String? ?? json['dismissedPlayerId'] as String?,
      dismissedPlayerName: json['dismissedPlayerName'] as String?,
      fielderId: json['fielder_id'] as String? ?? json['fielderId'] as String?,
      fielderName: json['fielderName'] as String?,
      batsmanId: json['batter_id'] as String? ?? json['batsmanId'] as String? ?? '',
      batsmanName: json['batsmanName'] as String? ?? '',
      bowlerId: json['bowler_id'] as String? ?? json['bowlerId'] as String? ?? '',
      bowlerName: json['bowlerName'] as String? ?? '',
      newBatsmanId: json['newBatsmanId'] as String?,
      newBatsmanName: json['newBatsmanName'] as String?,
      timestamp: _parseDateTime(json['ball_time'] ?? json['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ball_number': ballNumber,
      'over_number': overNumber,
      'runs_scored': batRuns,
      'extras_runs': extraRuns,
      'extras_type': extraType.name,
      'is_wicket': isWicket,
      'wicket_type': wicketType?.name,
      'player_out_id': dismissedPlayerId,
      'dismissed_player_name': dismissedPlayerName,
      'fielder_id': fielderId,
      'fielder_name': fielderName,
      'batter_id': batsmanId,
      'batsman_name': batsmanName,
      'bowler_id': bowlerId,
      'bowler_name': bowlerName,
      'new_batsman_id': newBatsmanId,
      'new_batsman_name': newBatsmanName,
      'ball_time': timestamp.toIso8601String(),
    };
  }

  BallEvent copyWith({
    String? id,
    int? ballNumber,
    int? overNumber,
    int? batRuns,
    int? extraRuns,
    ExtraType? extraType,
    bool? isWicket,
    WicketType? wicketType,
    String? dismissedPlayerId,
    String? dismissedPlayerName,
    String? fielderId,
    String? fielderName,
    String? batsmanId,
    String? batsmanName,
    String? bowlerId,
    String? bowlerName,
    String? newBatsmanId,
    String? newBatsmanName,
    DateTime? timestamp,
  }) {
    return BallEvent(
      id: id ?? this.id,
      ballNumber: ballNumber ?? this.ballNumber,
      overNumber: overNumber ?? this.overNumber,
      batRuns: batRuns ?? this.batRuns,
      extraRuns: extraRuns ?? this.extraRuns,
      extraType: extraType ?? this.extraType,
      isWicket: isWicket ?? this.isWicket,
      wicketType: wicketType ?? this.wicketType,
      dismissedPlayerId: dismissedPlayerId ?? this.dismissedPlayerId,
      dismissedPlayerName: dismissedPlayerName ?? this.dismissedPlayerName,
      fielderId: fielderId ?? this.fielderId,
      fielderName: fielderName ?? this.fielderName,
      batsmanId: batsmanId ?? this.batsmanId,
      batsmanName: batsmanName ?? this.batsmanName,
      bowlerId: bowlerId ?? this.bowlerId,
      bowlerName: bowlerName ?? this.bowlerName,
      newBatsmanId: newBatsmanId ?? this.newBatsmanId,
      newBatsmanName: newBatsmanName ?? this.newBatsmanName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isLegalDelivery => extraType != ExtraType.wide && extraType != ExtraType.noball;
  bool get countsAsBallFaced => isLegalDelivery;
  bool get creditsBatsmanRuns => extraType == ExtraType.none || extraType == ExtraType.noball;

  int get totalDeliveryRuns {
    switch (extraType) {
      case ExtraType.none: return batRuns;
      case ExtraType.wide: return 1 + extraRuns;
      case ExtraType.noball: return 1 + batRuns;
      case ExtraType.bye:
      case ExtraType.legbye: return extraRuns;
    }
  }

  int get bowlerRunsConceded {
    switch (extraType) {
      case ExtraType.none: return batRuns;
      case ExtraType.wide: return 1 + extraRuns;
      case ExtraType.noball: return 1 + batRuns;
      case ExtraType.bye:
      case ExtraType.legbye: return 0;
    }
  }

  bool get rotatesStrike {
    switch (extraType) {
      case ExtraType.none:
      case ExtraType.noball: return batRuns.isOdd;
      case ExtraType.wide:
      case ExtraType.bye:
      case ExtraType.legbye: return extraRuns.isOdd;
    }
  }

  String get shortLabel {
    if (isWicket) return 'W';
    switch (extraType) {
      case ExtraType.wide: return extraRuns > 0 ? 'Wd+$extraRuns' : 'Wd';
      case ExtraType.noball: return batRuns > 0 ? 'Nb+$batRuns' : 'Nb';
      case ExtraType.bye: return '${extraRuns}b';
      case ExtraType.legbye: return '${extraRuns}lb';
      case ExtraType.none: return '$batRuns';
    }
  }
}
