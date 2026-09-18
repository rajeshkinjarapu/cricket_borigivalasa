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

enum UserRole { admin, member }

extension UserRoleX on UserRole {
  String get label => name;
  bool get isAdmin => this == UserRole.admin;
  bool get isMember => this == UserRole.member;
}
