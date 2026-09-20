import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../players/data/models/player.dart';
import '../providers/dashboard_providers.dart';

class LeaderboardSection extends ConsumerStatefulWidget {
  const LeaderboardSection({super.key});

  @override
  ConsumerState<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends ConsumerState<LeaderboardSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  final _tabs = [
    _TabInfo(label: 'Overall', icon: Icons.leaderboard_rounded, color: const Color(0xFF7C3AED)),
    _TabInfo(label: 'Batting', icon: Icons.sports_cricket_rounded, color: const Color(0xFF1E3A8A)),
    _TabInfo(label: 'Bowling', icon: Icons.sports_baseball_rounded, color: const Color(0xFF059669)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overallAsync = ref.watch(overallLeaderboardProvider);
    final battingAsync = ref.watch(battingLeaderboardProvider);
    final bowlingAsync = ref.watch(bowlingLeaderboardProvider);

    final currentAsync = _selectedTab == 0
        ? overallAsync
        : _selectedTab == 1
            ? battingAsync
            : bowlingAsync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Bar
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EEF9)),
          ),
          child: TabBar(
            controller: _tabController,
            padding: const EdgeInsets.all(4),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _tabs[_selectedTab].color,
                  _tabs[_selectedTab].color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            dividerColor: Colors.transparent,
            tabs: _tabs
                .map((t) => Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(t.icon, size: 14),
                          const SizedBox(width: 4),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Leaderboard List
        currentAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
                strokeWidth: 2.5,
              ),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e',
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ),
          data: (players) {
            if (players.isEmpty) {
              return _EmptyLeaderboard(tab: _tabs[_selectedTab]);
            }
            return Column(
              children: List.generate(players.length, (index) {
                return _LeaderboardRow(
                  rank: index + 1,
                  player: players[index],
                  tab: _selectedTab,
                  tabColor: _tabs[_selectedTab].color,
                  onTap: () => context.push('/players/${players[index].id}/stats'),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TabInfo({required this.label, required this.icon, required this.color});
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final Player player;
  final int tab; // 0=overall, 1=batting, 2=bowling
  final Color tabColor;
  final VoidCallback onTap;

  const _LeaderboardRow({
    required this.rank,
    required this.player,
    required this.tab,
    required this.tabColor,
    required this.onTap,
  });

  String get _mainStat {
    if (tab == 1) return '${player.stats.runsScored} runs';
    if (tab == 2) return '${player.stats.wicketsTaken} wkts';
    final score = player.stats.runsScored + (player.stats.wicketsTaken * 20);
    return '$score pts';
  }

  String get _subStat {
    if (tab == 1) {
      return 'Avg: ${player.stats.battingAverage.toStringAsFixed(1)} • HS: ${player.stats.highestScore}';
    }
    if (tab == 2) {
      return 'Best: ${player.stats.bestBowling} • Eco: ${player.stats.economyRate.toStringAsFixed(1)}';
    }
    return '${player.stats.runsScored}R • ${player.stats.wicketsTaken}W';
  }

  Widget _buildRankBadge() {
    if (rank == 1) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text('🥇', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    if (rank == 2) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFF9E9E9E)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Center(
          child: Text('🥈', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    if (rank == 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFFA0522D)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCD7F32).withOpacity(0.35),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Center(
          child: Text('🥉', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: rank <= 3
              ? tabColor.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: rank <= 3
                ? tabColor.withOpacity(0.2)
                : const Color(0xFFE8EEF9),
            width: rank == 1 ? 1.5 : 1,
          ),
          boxShadow: rank == 1
              ? [
                  BoxShadow(
                    color: tabColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildRankBadge(),
            const SizedBox(width: 12),

            // Player avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: tabColor.withOpacity(0.15),
              backgroundImage: (player.profilePicUrl != null &&
                      player.profilePicUrl!.isNotEmpty)
                  ? NetworkImage(player.profilePicUrl!)
                  : null,
              child: (player.profilePicUrl == null ||
                      player.profilePicUrl!.isEmpty)
                  ? Text(
                      player.name.isNotEmpty
                          ? player.name[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: tabColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Name & sub-stat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: rank <= 3
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subStat,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Main stat chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tabColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _mainStat,
                style: TextStyle(
                  color: tabColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  final _TabInfo tab;
  const _EmptyLeaderboard({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF9)),
      ),
      child: Column(
        children: [
          Icon(tab.icon, size: 40, color: tab.color.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'No ${tab.label} data yet',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Stats will appear after matches are played',
            style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}
