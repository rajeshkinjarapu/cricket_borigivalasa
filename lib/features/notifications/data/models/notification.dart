class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? matchId;
  final String? tournamentId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'info',
    this.matchId,
    this.tournamentId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'info',
      matchId: json['match_id'] as String?,
      tournamentId: json['tournament_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'match_id': matchId,
      'tournament_id': tournamentId,
      'is_read': isRead,
    };
  }
}
