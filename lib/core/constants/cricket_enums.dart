export 'app_constants.dart' show UserRole;

enum TournamentFormat { t10, t20, odi }
extension TournamentFormatX on TournamentFormat {
  String get label => this == TournamentFormat.t10 ? 'T10'
    : this == TournamentFormat.t20 ? 'T20' : 'ODI';
  int get maxOvers => this == TournamentFormat.t10 ? 10
    : this == TournamentFormat.t20 ? 20 : 50;
}

enum TournamentStatus { upcoming, ongoing, completed }
extension TournamentStatusX on TournamentStatus {
  String get label => this == TournamentStatus.upcoming ? 'Upcoming'
    : this == TournamentStatus.ongoing ? 'Ongoing' : 'Completed';
}

enum PlayerRole { batter, bowler, allRounder, wicketKeeper }
extension PlayerRoleX on PlayerRole {
  String get label => this == PlayerRole.batter ? 'Batter'
    : this == PlayerRole.bowler ? 'Bowler'
    : this == PlayerRole.allRounder ? 'All-rounder' : 'Wicket-keeper';
}

enum BattingStyle { rightHand, leftHand }
extension BattingStyleX on BattingStyle {
  String get label => this == BattingStyle.rightHand ? 'Right hand' : 'Left hand';
}

enum BowlingStyle { none, rightArmFast, rightArmMedium, rightArmOffSpin,
  rightArmLegSpin, leftArmFast, leftArmMedium, leftArmOrthodox, leftArmChinaman }
extension BowlingStyleX on BowlingStyle {
  String get label {
    switch (this) {
      case BowlingStyle.none: return 'Does not bowl';
      case BowlingStyle.rightArmFast: return 'Right-arm fast';
      case BowlingStyle.rightArmMedium: return 'Right-arm medium';
      case BowlingStyle.rightArmOffSpin: return 'Right-arm off-spin';
      case BowlingStyle.rightArmLegSpin: return 'Right-arm leg-spin';
      case BowlingStyle.leftArmFast: return 'Left-arm fast';
      case BowlingStyle.leftArmMedium: return 'Left-arm medium';
      case BowlingStyle.leftArmOrthodox: return 'Left-arm orthodox';
      case BowlingStyle.leftArmChinaman: return 'Left-arm chinaman';
    }
  }
}

enum MatchStatus { scheduled, live, completed, abandoned }
extension MatchStatusX on MatchStatus {
  String get label => this == MatchStatus.scheduled ? 'Scheduled'
    : this == MatchStatus.live ? 'Live'
    : this == MatchStatus.completed ? 'Completed' : 'Abandoned';
}

enum TossDecision { bat, bowl }
extension TossDecisionX on TossDecision {
  String get label => this == TossDecision.bat ? 'Bat first' : 'Bowl first';
}

enum ExtraType { none, wide, noball, bye, legbye }

enum WicketType { bowled, caught, lbw, runOut, stumped, hitWicket,
  retiredHurt, obstructingField }
extension WicketTypeX on WicketType {
  String get label {
    switch (this) {
      case WicketType.bowled: return 'Bowled';
      case WicketType.caught: return 'Caught';
      case WicketType.lbw: return 'LBW';
      case WicketType.runOut: return 'Run out';
      case WicketType.stumped: return 'Stumped';
      case WicketType.hitWicket: return 'Hit wicket';
      case WicketType.retiredHurt: return 'Retired hurt';
      case WicketType.obstructingField: return 'Obstructing';
    }
  }
  bool get creditedToBowler => this != WicketType.runOut &&
    this != WicketType.retiredHurt && this != WicketType.obstructingField;
  bool get needsFielder => this == WicketType.caught ||
    this == WicketType.runOut || this == WicketType.stumped;
}
