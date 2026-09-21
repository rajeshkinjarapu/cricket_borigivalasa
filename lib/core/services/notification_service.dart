import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to all members when a match is created or goes live
  Future<void> sendMatchNotification({
    required String tournamentId,
    required String matchId,
    required String teamA,
    required String teamB,
    required String venue,
    required DateTime matchDate,
    required bool isLive,
  }) async {
    try {
      final notificationData = {
        'title': isLive ? '🔴 LIVE NOW!' : 'Match Scheduled',
        'body': isLive 
            ? '$teamA vs $teamB has started at $venue!'
            : '$teamA vs $teamB scheduled for ${_formatDate(matchDate)} at $venue',
        'type': 'match_${isLive ? 'live' : 'scheduled'}',
        'tournamentId': tournamentId,
        'matchId': matchId,
        'teamA': teamA,
        'teamB': teamB,
        'venue': venue,
        'matchDate': Timestamp.fromDate(matchDate),
        'isLive': isLive,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add to global notifications collection
      await _firestore.collection('notifications').add(notificationData);

      // Get all members and add to their personal notifications
      final membersSnapshot = await _firestore
          .collection('members')
          .where('role', whereIn: ['member', 'scorer', 'admin'])
          .get();

      final batch = _firestore.batch();
      
      for (var doc in membersSnapshot.docs) {
        final memberNotificationsRef = _firestore
            .collection('members')
            .doc(doc.id)
            .collection('notifications');
        
        batch.set(memberNotificationsRef.doc(), {
          ...notificationData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      
      if (kDebugMode) {
        print('✓ Notification sent for match: $teamA vs $teamB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error sending notification: $e');
      }
    }
  }

  /// Update match status to live and send live notification
  Future<void> markMatchAsLive({
    required String tournamentId,
    required String matchId,
    required String teamA,
    required String teamB,
    required String venue,
  }) async {
    try {
      // Update match status in database
      await _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId)
          .update({
        'status': 'live',
        'startedAt': FieldValue.serverTimestamp(),
      });

      // Send live notification
      await sendMatchNotification(
        tournamentId: tournamentId,
        matchId: matchId,
        teamA: teamA,
        teamB: teamB,
        venue: venue,
        matchDate: DateTime.now(),
        isLive: true,
      );

      if (kDebugMode) {
        print('✓ Match marked as LIVE: $teamA vs $teamB');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Error marking match as live: $e');
      }
    }
  }

  /// Get recent notifications for dashboard hero banner
  Stream<List<Map<String, dynamic>>> getRecentNotifications({int limit = 3}) {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Singleton instance
final notificationService = NotificationService();
