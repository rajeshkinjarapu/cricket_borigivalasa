import '../../../../core/constants/cricket_enums.dart';

class BallEvent {
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
      batRuns: json['batRuns'] as int? ?? 0,
      extraRuns: json['extraRuns'] as int? ?? 0,
      extraType: ExtraType.values.firstWhere(
        (e) => e.name == (json['extraType'] as String?),
        orElse: () => ExtraType.none,
      ),
      isWicket: json['isWicket'] as bool? ?? false,
      wicketType: json['wicketType'] != null
          ? WicketType.values.firstWhere(
              (e) => e.name == (json['wicketType'] as String?),
              orElse: () => WicketType.bowled,
            )
          : null,
      dismissedPlayerId: json['dismissedPlayerId'] as String?,
      dismissedPlayerName: json['dismissedPlayerName'] as String?,
      fielderId: json['fielderId'] as String?,
      fielderName: json['fielderName'] as String?,
      batsmanId: json['batsmanId'] as String? ?? '',
      batsmanName: json['batsmanName'] as String? ?? '',
      bowlerId: json['bowlerId'] as String? ?? '',
      bowlerName: json['bowlerName'] as String? ?? '',
      newBatsmanId: json['newBatsmanId'] as String?,
      newBatsmanName: json['newBatsmanName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batRuns': batRuns,
      'extraRuns': extraRuns,
      'extraType': extraType.name,
      'isWicket': isWicket,
      'wicketType': wicketType?.name,
      'dismissedPlayerId': dismissedPlayerId,
      'dismissedPlayerName': dismissedPlayerName,
      'fielderId': fielderId,
      'fielderName': fielderName,
      'batsmanId': batsmanId,
      'batsmanName': batsmanName,
      'bowlerId': bowlerId,
      'bowlerName': bowlerName,
      'newBatsmanId': newBatsmanId,
      'newBatsmanName': newBatsmanName,
      'timestamp': timestamp.toIso8601String(),
    };
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
