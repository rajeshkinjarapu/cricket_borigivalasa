import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

class GlobalNotificationListener extends StatefulWidget {
  final Widget child;
  const GlobalNotificationListener({super.key, required this.child});

  @override
  State<GlobalNotificationListener> createState() => _GlobalNotificationListenerState();
}

class _GlobalNotificationListenerState extends State<GlobalNotificationListener> {
  late final RealtimeChannel _channel;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _channel = _supabase.channel('public-inserts');
    
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      callback: (payload) async {
        final table = payload.table;
        final record = payload.newRecord;
        
        if (record.isNotEmpty) {
          if (table == 'matches') {
            final teamA = record['team_a'] ?? 'Team A';
            final teamB = record['team_b'] ?? 'Team B';
            final createdBy = record['created_by'] as String?;
            String creatorName = '';
            if (createdBy != null) {
              try {
                final profile = await _supabase
                    .from('profiles')
                    .select('display_name')
                    .eq('id', createdBy)
                    .maybeSingle();
                creatorName = profile?['display_name'] as String? ?? '';
              } catch (_) {}
            }
            final subtitle = creatorName.isNotEmpty
                ? '$teamA vs $teamB\nScheduled by $creatorName'
                : '$teamA vs $teamB';
            _showHeroBanner(
              title: 'NEW MATCH SCHEDULED!',
              subtitle: subtitle,
              icon: Icons.sports_cricket_rounded,
              colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            );
          } else if (table == 'profiles') {
            final name = record['display_name'] ?? 'A new member';
            final role = record['role'] == 'scorer' ? 'Scorer' : 'Member';
            _showHeroBanner(
              title: 'NEW $role JOINED!',
              subtitle: '$name is now part of the club.',
              icon: Icons.person_add_alt_1_rounded,
              colors: const [Color(0xFF065F46), Color(0xFF10B981)],
            );
          } else if (table == 'teams') {
            final name = record['name'] ?? 'A team';
            _showHeroBanner(
              title: 'NEW TEAM REGISTERED!',
              subtitle: '$name has joined the club.',
              icon: Icons.groups_rounded,
              colors: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
            );
          }
        }
      },
    ).subscribe();
  }

  void _showHeroBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -100.0, end: 0.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: colors.first, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () {
                            overlayEntry.remove();
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
