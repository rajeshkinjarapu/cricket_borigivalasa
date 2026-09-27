import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository(this._supabase);

  Stream<List<NotificationModel>> streamNotifications() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) =>
            data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('is_read', false);
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String type = 'info',
    String? matchId,
    String? tournamentId,
  }) async {
    await _supabase.from('notifications').insert({
      'title': title,
      'body': body,
      'type': type,
      'match_id': matchId,
      'tournament_id': tournamentId,
    });
  }
}
