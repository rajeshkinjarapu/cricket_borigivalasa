class AppConstants {
  AppConstants._();
  static const String usersCollection = 'users';
  static const String tournamentsCollection = 'tournaments';
  static const String teamsCollection = 'teams';
  static const String playersCollection = 'players';
  static const String matchesCollection = 'matches';
  static const String inningsCollection = 'innings';
  static const String oversCollection = 'overs';
  static const String battingScorecardCollection = 'batting_scorecard';
  static const String bowlingScorecardCollection = 'bowling_scorecard';
  static const String pointsTableCollection = 'points_table';
}

enum UserRole { superAdmin, admin, scorer, member }

extension UserRoleX on UserRole {
  String get label => this == UserRole.superAdmin
      ? 'Super Admin'
      : this == UserRole.admin
          ? 'Administrator'
          : this == UserRole.scorer
              ? 'Scorer'
              : 'Member';
  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
  bool get isScorer => this == UserRole.scorer;
  bool get isMember => this == UserRole.member;
  bool get canScore => this == UserRole.superAdmin || this == UserRole.admin || this == UserRole.scorer;
  bool get canManageMembers => this == UserRole.superAdmin; // only super admin can assign roles
}
