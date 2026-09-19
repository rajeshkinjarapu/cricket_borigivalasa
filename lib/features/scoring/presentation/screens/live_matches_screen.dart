import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../matches/data/models/match.dart';

class LiveMatchesScreen extends ConsumerStatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  ConsumerState<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends ConsumerState<LiveMatchesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveMatchesAsync = ref.watch(liveMatchesProvider);
    final user = ref.watch(currentUserProvider);
    final bool isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(_pulseAnim.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.8),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'Live Matches',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1E3A8A),
        onRefresh: () async {
          ref.invalidate(liveMatchesProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: liveMatchesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading live matches: $e',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (matches) {
            if (matches.isEmpty) {
              return _buildNoLiveMatchesView(context, isAdmin);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return _buildLiveMatchCard(context, match, isAdmin);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoLiveMatchesView(BuildContext context, bool isAdmin) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
            ),
            child: const Icon(
              Icons.sensors_off_rounded,
              size: 46,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No Live Matches Right Now',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'When a match begins and live scoring starts, live ball-by-ball updates and scores will appear here in real-time!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        if (isAdmin)
          Center(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/matches/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Schedule New Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          Center(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/matches-list'),
              icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A)),
              label: const Text(
                'View Upcoming Fixtures',
                style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveMatchCard(BuildContext context, Match match, bool isAdmin) {
    final live = match.liveScore;
    final inn1 = live?['inn1'] as Map<String, dynamic>?;
    final inn2 = live?['inn2'] as Map<String, dynamic>?;

    final String runsA = inn1?['runs']?.toString() ?? '0';
    final String wktsA = inn1?['wickets']?.toString() ?? '0';
    final String oversA = inn1?['overs']?.toString() ?? '0.0';

    final String runsB = inn2?['runs']?.toString() ?? '-';
    final String wktsB = inn2?['wickets']?.toString() ?? '-';
    final String oversB = inn2?['overs']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: const Color(0xFFEF4444).withOpacity(0.25),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Live Badge + Venue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE MATCH',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${match.totalOvers} Overs • ${match.venue}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Team A Score Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.teamA,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$runsA/$wktsA ($oversA ov)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Team B Score Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.teamB,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  runsB != '-' ? '$runsB/$wktsB ($oversB ov)' : 'Yet to bat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: runsB != '-' ? const Color(0xFF1E3A8A) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (match.tournamentId.isNotEmpty) {
                        context.push('/tournaments/${match.tournamentId}/matches/${match.id}/live');
                      }
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Watch Live'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (match.tournamentId.isNotEmpty) {
                          context.push('/tournaments/${match.tournamentId}/matches/${match.id}/scoring');
                        }
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Live Scorer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
