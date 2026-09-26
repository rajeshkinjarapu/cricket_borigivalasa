import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../matches/data/models/match.dart';
import '../../data/models/innings.dart';
import '../providers/scoring_providers.dart';

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
                return _LiveMatchCard(match: match, isAdmin: isAdmin);
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
}

// ─── Live Match Card — reads innings in real-time ─────────────────────────────
class _LiveMatchCard extends ConsumerWidget {
  const _LiveMatchCard({required this.match, required this.isAdmin});
  final Match match;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tid = match.tournamentId;
    final mid = match.id;
    final i1 = ref.watch(inningsProvider((tournamentId: tid, matchId: mid, innings: 1))).value;
    final i2 = ref.watch(inningsProvider((tournamentId: tid, matchId: mid, innings: 2))).value;

    final bool isCounty = match.liveScore?['matchType'] == 'county' || match.liveScore?['isCounty'] == true;

    // Determine which innings belongs to which team
    Innings? teamAInn, teamBInn;
    if (i1 != null) {
      if (i1.battingTeamId == match.teamAId) {
        teamAInn = i1;
      } else if (i1.battingTeamId == match.teamBId) {
        teamBInn = i1;
      }
    }
    if (i2 != null) {
      if (i2.battingTeamId == match.teamAId) {
        teamAInn = i2;
      } else if (i2.battingTeamId == match.teamBId) {
        teamBInn = i2;
      }
    }

    // Active innings (not complete wins)
    final Innings? activeInn = (i2 != null && !i2.isComplete) ? i2 : (i1 != null && !i1.isComplete ? i1 : (i2 ?? i1));
    final bool isTeamABatting = activeInn?.battingTeamId == match.teamAId;
    final bool isTeamBBatting = activeInn?.battingTeamId == match.teamBId;

    String scoreText(Innings? inn) {
      if (inn == null) return '—';
      final completedOvers = inn.legalBalls ~/ 6;
      final ballsInOver = inn.legalBalls % 6;
      final oversStr = ballsInOver == 0 ? '$completedOvers' : '$completedOvers.$ballsInOver';
      return '${inn.runs}/${inn.wickets} ($oversStr ov)';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: const Color(0xFFEF4444).withOpacity(0.2),
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
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: Color(0xFFEF4444)),
                          SizedBox(width: 5),
                          Text('LIVE', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.6)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCounty ? const Color(0xFFFEF9C3) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isCounty ? const Color(0xFFFDE047) : const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        isCounty ? 'COUNTY' : 'NORMAL',
                        style: TextStyle(
                          color: isCounty ? const Color(0xFF92400E) : const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${match.totalOvers} Ov • ${match.venue}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Team A
            _TeamScoreRow(
              teamName: match.teamA,
              scoreText: scoreText(teamAInn),
              isBatting: isTeamABatting,
              hasStarted: teamAInn != null,
            ),
            const SizedBox(height: 6),
            // Team B
            _TeamScoreRow(
              teamName: match.teamB,
              scoreText: scoreText(teamBInn),
              isBatting: isTeamBBatting,
              hasStarted: teamBInn != null,
            ),

            const Divider(height: 20, color: Color(0xFFF1F5F9)),

            // Buttons
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

class _TeamScoreRow extends StatelessWidget {
  const _TeamScoreRow({
    required this.teamName,
    required this.scoreText,
    required this.isBatting,
    required this.hasStarted,
  });
  final String teamName, scoreText;
  final bool isBatting, hasStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isBatting ? const Color(0xFFF0FDF4) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                teamName,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: isBatting ? FontWeight.w900 : FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (isBatting) ...[
                const SizedBox(width: 6),
                const Icon(Icons.sports_cricket, size: 15, color: Color(0xFF16A34A)),
              ],
            ],
          ),
          Text(
            scoreText,
            style: TextStyle(
              fontSize: hasStarted ? 15.5 : 14,
              fontWeight: FontWeight.w900,
              color: hasStarted ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}
