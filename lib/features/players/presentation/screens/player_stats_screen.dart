import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/player_providers.dart';
import '../../../matches/data/models/match.dart' as app_match;

import '../../data/models/player.dart';

class PlayerMatchDetail {
  final app_match.Match match;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int wickets;
  final bool isWin;
  final bool isMoM;
  PlayerMatchDetail({
    required this.match,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.wickets,
    required this.isWin,
    required this.isMoM,
  });
}

final playerDetailedStatsProvider = FutureProvider.family<List<PlayerMatchDetail>, Player>((ref, player) async {
  final sb = Supabase.instance.client;
  final playerId = player.id;
  final playerName = player.name;
  final playerTeamId = player.teamId;
  final playerTeamIds = player.teamIds;

  List<app_match.Match> allMatches = [];
  try {
    final matchesRes = await sb.from('matches').select();
    allMatches = (matchesRes as List).map((m) => app_match.Match.fromJson(m as Map<String, dynamic>)).toList();
  } catch (_) {}

  List<Map<String, dynamic>> balls = [];
  try {
    final res = await sb.from('ball_events').select('match_id, batter_id, bowler_id, runs_scored, is_boundary, wicket_type');
    balls = List<Map<String, dynamic>>.from(res);
  } catch (_) {}

  final Map<String, int> matchRuns = {};
  final Map<String, int> matchBalls = {};
  final Map<String, int> matchFours = {};
  final Map<String, int> matchSixes = {};
  final Map<String, int> matchWickets = {};
  final Set<String> playedMatchIds = {};

  for (final b in balls) {
    final mid = b['match_id']?.toString();
    if (mid == null) continue;
    final batterId = b['batter_id']?.toString();
    final bowlerId = b['bowler_id']?.toString();
    final runs = b['runs_scored'] as int? ?? 0;
    final isBoundary = b['is_boundary'] as bool? ?? false;
    final wicketType = b['wicket_type'] as String?;

    if (batterId == playerId) {
      playedMatchIds.add(mid);
      matchRuns[mid] = (matchRuns[mid] ?? 0) + runs;
      matchBalls[mid] = (matchBalls[mid] ?? 0) + 1;
      if (isBoundary && runs == 4) matchFours[mid] = (matchFours[mid] ?? 0) + 1;
      if (isBoundary && runs == 6) matchSixes[mid] = (matchSixes[mid] ?? 0) + 1;
    }
    if (bowlerId == playerId) {
      playedMatchIds.add(mid);
      if (wicketType != null && ['bowled', 'lbw', 'caught', 'stumped', 'hitWicket'].contains(wicketType)) {
        matchWickets[mid] = (matchWickets[mid] ?? 0) + 1;
      }
    }
  }

  final List<PlayerMatchDetail> list = [];
  for (final m in allMatches) {
    if (!playedMatchIds.contains(m.id)) continue;
    
    final bool isWin = m.winnerTeamId != null &&
        (m.winnerTeamId == playerTeamId || playerTeamIds.contains(m.winnerTeamId));
        
    final bool isMoM = (m.manOfTheMatchId == playerId) ||
        (m.manOfTheMatchName != null && m.manOfTheMatchName!.trim().toLowerCase() == playerName.trim().toLowerCase());
    
    list.add(PlayerMatchDetail(
      match: m,
      runs: matchRuns[m.id] ?? 0,
      balls: matchBalls[m.id] ?? 0,
      fours: matchFours[m.id] ?? 0,
      sixes: matchSixes[m.id] ?? 0,
      wickets: matchWickets[m.id] ?? 0,
      isWin: isWin,
      isMoM: isMoM,
    ));
  }
  return list;
});

class PlayerStatsScreen extends ConsumerWidget {
  const PlayerStatsScreen({
    super.key,
    required this.tournamentId,
    required this.teamId,
    required this.playerId,
  });

  final String tournamentId;
  final String teamId;
  final String playerId;

  // Role → color/icon config
  static const _roleColors = {
    'BATSMAN': Color(0xFF1D4ED8),
    'BATTER': Color(0xFF1D4ED8),
    'BOWLER': Color(0xFF059669),
    'ALL-ROUNDER': Color(0xFF7C3AED),
    'WICKET KEEPER': Color(0xFFD97706),
    'WICKET-KEEPER': Color(0xFFD97706),
  };

  Color _roleColor(String role) =>
      _roleColors[role.toUpperCase()] ?? const Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerDetailProvider(playerId));
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.role == UserRole.admin ||
        currentUser?.role == UserRole.superAdmin;

    return playerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (player) {
        if (player == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Player Profile')),
            body: const Center(child: Text('Player not found')),
          );
        }

        final detailedStatsAsync = ref.watch(playerDetailedStatsProvider(player));
        final detailedList = detailedStatsAsync.value ?? [];
        
        final int totalFours = detailedList.fold(0, (sum, m) => sum + m.fours);
        final int totalSixes = detailedList.fold(0, (sum, m) => sum + m.sixes);
        final int noOf25s = detailedList.where((m) => m.runs >= 25 && m.runs < 50).length;
        final int noOf50s = detailedList.where((m) => m.runs >= 50).length;
        final int momCount = detailedList.where((m) => m.isMoM).length;
        
        // Approximate win percentage
        final totalMatches = detailedList.length;
        final wonMatches = detailedList.where((m) => m.isWin).length; // using the approximated isWin
        final winPercentage = totalMatches > 0 ? ((wonMatches / totalMatches) * 100).toStringAsFixed(0) : '0';

        final roleLabel = player.role.label.toUpperCase();
        final roleColor = _roleColor(roleLabel);
        final initial = player.name.trim().isNotEmpty
            ? player.name.trim()[0].toUpperCase()
            : '?';        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            title: const Text('Player Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/tournaments/$tournamentId/teams/$teamId/players/$playerId/edit');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Delete Player?', style: TextStyle(fontWeight: FontWeight.w900)),
                          content: Text('Are you sure you want to remove ${player.name} from the squad?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(playerControllerProvider.notifier).delete(player.id);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 16, color: roleColor),
                        const SizedBox(width: 10),
                        const Text('Edit Player', style: TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ─── Header Info Card ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: roleColor.withOpacity(0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.1),
                          backgroundImage: getAppAvatarProvider(player.profilePicUrl),
                          child: getAppAvatarProvider(player.profilePicUrl) == null
                              ? Text(initial, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: roleColor))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: roleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    roleLabel,
                                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                                  ),
                                ),
                                if (player.jerseyNumber != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                                    child: Text(
                                      '#${player.jerseyNumber}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Stats Grid ─────────────────────────────────────────
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text('CAREER STATISTICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3.0,
                  children: [
                    _StatCard(
                      label: 'Matches',
                      value: '${player.stats.matchesPlayed}',
                      icon: Icons.calendar_month_rounded,
                      accentColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    _StatCard(
                      label: 'Total Runs',
                      value: '${player.stats.runsScored}',
                      icon: Icons.sports_cricket_rounded,
                      accentColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                    _StatCard(
                      label: 'High Score',
                      value: '${player.stats.highestScore}',
                      icon: Icons.star_rounded,
                      accentColor: const Color(0xFFEAB308),
                      bgColor: const Color(0xFFFEF9C3),
                    ),
                    _StatCard(
                      label: 'Batting Avg',
                      value: player.stats.battingAverage.toStringAsFixed(1),
                      icon: Icons.bar_chart_rounded,
                      accentColor: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                    ),
                    _StatCard(
                      label: 'Wickets',
                      value: '${player.stats.wicketsTaken}',
                      icon: Icons.sports_baseball_rounded,
                      accentColor: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF5F3FF),
                    ),
                    _StatCard(
                      label: 'Best Bowling',
                      value: player.stats.bestBowling.isEmpty ? '-' : player.stats.bestBowling,
                      icon: Icons.emoji_events_rounded,
                      accentColor: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFEDD5),
                    ),
                    _StatCard(
                      label: 'Total Fours',
                      value: '$totalFours',
                      icon: Icons.sports_baseball,
                      accentColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                    _StatCard(
                      label: 'Total Sixes',
                      value: '$totalSixes',
                      icon: Icons.rocket_launch_rounded,
                      accentColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                    ),
                    _StatCard(
                      label: 'No of 25s',
                      value: '$noOf25s',
                      icon: Icons.exposure_plus_2,
                      accentColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                    _StatCard(
                      label: 'No of 50s',
                      value: '$noOf50s',
                      icon: Icons.fireplace_rounded,
                      accentColor: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFEDD5),
                    ),
                    _StatCard(
                      label: 'MoM Awards',
                      value: '$momCount',
                      icon: Icons.workspace_premium_rounded,
                      accentColor: const Color(0xFFEAB308),
                      bgColor: const Color(0xFFFEF9C3),
                    ),
                    _StatCard(
                      label: 'Win %',
                      value: '$winPercentage%',
                      icon: Icons.percent_rounded,
                      accentColor: const Color(0xFF0F766E),
                      bgColor: const Color(0xFFCCFBF1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Player Info Card ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 16, decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          const Text('PLAYER DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 1.0)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.sports_cricket_rounded,
                        label: 'Batting Style',
                        value: player.battingStyle.label.isEmpty ? 'Not set' : player.battingStyle.label,
                        color: const Color(0xFF2563EB),
                      ),
                      const _InfoDivider(),
                      _InfoRow(
                        icon: Icons.sports_baseball_rounded,
                        label: 'Bowling Style',
                        value: player.bowlingStyle.label.isEmpty ? 'Not set' : player.bowlingStyle.label,
                        color: const Color(0xFF059669),
                      ),
                      if (player.phoneNumber != null && player.phoneNumber!.isNotEmpty) ...[
                        const _InfoDivider(),
                        _InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: player.phoneNumber!,
                          color: const Color(0xFF0F766E),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Style Chip ───────────────────────────────────────────────────────────────
class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: accentColor.withOpacity(0.75), letterSpacing: 0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor, height: 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
            alignment: Alignment.center,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color.withOpacity(0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 46);
  }
}
