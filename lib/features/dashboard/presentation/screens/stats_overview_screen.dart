import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';

class StatsOverviewScreen extends ConsumerWidget {
  const StatsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(loggedInPlayerProvider);
    final user = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text(
            'My Stats',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          elevation: 0,
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'View Profile',
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
        body: playerAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Failed to load stats: $e', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          data: (player) {
            final effectivePlayer = player ??
                Player(
                  id: user?.uid ?? 'guest',
                  name: user?.displayName.isNotEmpty == true
                      ? user!.displayName
                      : 'Player',
                  teamId: '',
                  role: PlayerRole.allRounder,
                  battingStyle: BattingStyle.rightHand,
                  bowlingStyle: BowlingStyle.rightArmMedium,
                  profilePicUrl: user?.photoUrl,
                  stats: PlayerStats(),
                );

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildHeroProfileHeader(effectivePlayer),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    const TabBar(
                      labelColor: Color(0xFF1E3A8A),
                      unselectedLabelColor: Color(0xFF64748B),
                      indicatorColor: Color(0xFF2563EB),
                      indicatorWeight: 3,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      tabs: [
                        Tab(icon: Icon(Icons.sports_cricket, size: 18), text: 'BATTING'),
                        Tab(icon: Icon(Icons.sports_baseball, size: 18), text: 'BOWLING'),
                        Tab(icon: Icon(Icons.military_tech_rounded, size: 18), text: 'CAREER'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _buildBattingTab(effectivePlayer),
                  _buildBowlingTab(effectivePlayer),
                  _buildCareerTab(context, effectivePlayer),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroProfileHeader(Player player) {
    final stats = player.stats;
    final allRounderPoints = stats.runsScored + (stats.wicketsTaken * 20);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF1E3A8A),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        children: [
          // Player Avatar (Squircle) + Name + Badges
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2.2),
                  color: const Color(0xFF0F172A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.5),
                  child: player.profilePicUrl != null &&
                          player.profilePicUrl!.isNotEmpty
                      ? Image.network(
                          player.profilePicUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(player.name),
                        )
                      : _buildAvatarFallback(player.name),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.jerseyNumber != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${player.jerseyNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        player.role.label.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildHeaderStylePill(
                            Icons.sports, player.battingStyle.label),
                        const SizedBox(width: 8),
                        _buildHeaderStylePill(
                            Icons.sports_baseball, player.bowlingStyle.label),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4 Colorful Highlights Pills (Matches, Runs, Wickets, Points)
          Row(
            children: [
              _buildTopStatCard(
                label: 'MATCHES',
                value: '${stats.matchesPlayed}',
                icon: Icons.emoji_events_outlined,
                accentColor: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _buildTopStatCard(
                label: 'RUNS',
                value: '${stats.runsScored}',
                icon: Icons.sports_cricket_rounded,
                accentColor: const Color(0xFF34D399),
              ),
              const SizedBox(width: 8),
              _buildTopStatCard(
                label: 'WICKETS',
                value: '${stats.wicketsTaken}',
                icon: Icons.sports_baseball_rounded,
                accentColor: const Color(0xFFF87171),
              ),
              const SizedBox(width: 8),
              _buildTopStatCard(
                label: 'POINTS',
                value: '$allRounderPoints',
                icon: Icons.stars_rounded,
                accentColor: const Color(0xFFFBBF24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStylePill(IconData icon, String text) {
    if (text == 'None' || text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white60),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildTopStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: accentColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Batting Tab ───
  Widget _buildBattingTab(Player player) {
    final stats = player.stats;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildSectionHeader('BATTING PERFORMANCE', Icons.sports_cricket, const Color(0xFF2563EB)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.68, // Reduced height by ~2 points
          children: [
            _buildStatCard(
              title: 'Total Runs',
              value: '${stats.runsScored}',
              subtitle: 'Career Runs',
              icon: Icons.sports_cricket,
              color: const Color(0xFF2563EB),
            ),
            _buildStatCard(
              title: 'Highest Score',
              value: '${stats.highestScore}',
              subtitle: 'Best Inning',
              icon: Icons.military_tech_rounded,
              color: const Color(0xFFD97706),
            ),
            _buildStatCard(
              title: 'Batting Average',
              value: stats.battingAverage > 0
                  ? stats.battingAverage.toStringAsFixed(2)
                  : (stats.matchesPlayed > 0 && stats.runsScored > 0
                      ? (stats.runsScored / stats.matchesPlayed).toStringAsFixed(2)
                      : '0.00'),
              subtitle: 'Runs per Inning',
              icon: Icons.trending_up,
              color: const Color(0xFF059669),
            ),
            _buildStatCard(
              title: 'Matches Played',
              value: '${stats.matchesPlayed}',
              subtitle: 'Total Fixtures',
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF7C3AED),
            ),
            _buildStatCard(
              title: 'Batting Style',
              value: player.battingStyle.label,
              subtitle: 'Stance',
              icon: Icons.accessibility_new_rounded,
              color: const Color(0xFF0284C7),
              isTextValue: true,
            ),
            _buildStatCard(
              title: 'Role',
              value: player.role.label,
              subtitle: 'Position',
              icon: Icons.badge_outlined,
              color: const Color(0xFF6366F1),
              isTextValue: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          title: 'Batting Summary',
          description: stats.matchesPlayed > 0
              ? 'Has scored ${stats.runsScored} runs in ${stats.matchesPlayed} matches with a personal best of ${stats.highestScore}*.'
              : 'No matches recorded yet. Start participating in tournament matches to build your batting records!',
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  // ─── Bowling Tab ───
  Widget _buildBowlingTab(Player player) {
    final stats = player.stats;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildSectionHeader('BOWLING PERFORMANCE', Icons.sports_baseball, const Color(0xFFDC2626)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.68, // Reduced height by ~2 points
          children: [
            _buildStatCard(
              title: 'Wickets Taken',
              value: '${stats.wicketsTaken}',
              subtitle: 'Career Wickets',
              icon: Icons.sports_baseball,
              color: const Color(0xFFDC2626),
            ),
            _buildStatCard(
              title: 'Best Bowling',
              value: stats.bestBowling.isNotEmpty ? stats.bestBowling : '-',
              subtitle: 'BBI',
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFFD97706),
              isTextValue: true,
            ),
            _buildStatCard(
              title: 'Economy Rate',
              value: stats.economyRate > 0
                  ? stats.economyRate.toStringAsFixed(2)
                  : '-',
              subtitle: 'Runs per Over',
              icon: Icons.speed_rounded,
              color: const Color(0xFF059669),
            ),
            _buildStatCard(
              title: 'Bowling Style',
              value: player.bowlingStyle.label,
              subtitle: 'Action',
              icon: Icons.sports_handball_rounded,
              color: const Color(0xFF0284C7),
              isTextValue: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          title: 'Bowling Summary',
          description: stats.wicketsTaken > 0
              ? 'Has taken ${stats.wicketsTaken} wickets with best match figures of ${stats.bestBowling}.'
              : 'No bowling figures recorded yet. Bowl in tournament fixtures to build your bowling records!',
          icon: Icons.lightbulb_outline_rounded,
          color: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  // ─── Career Tab ───
  Widget _buildCareerTab(BuildContext context, Player player) {
    final stats = player.stats;
    final allRounderPoints = stats.runsScored + (stats.wicketsTaken * 20);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildSectionHeader('CAREER OVERVIEW', Icons.military_tech_rounded, const Color(0xFF7C3AED)),
        const SizedBox(height: 10),

        // Overall Impact Score Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All-Rounder Impact Score',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$allRounderPoints PTS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Calculated as Runs + (Wickets × 20)',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Player Info Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAYER ATTRIBUTES',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                ),
                const Divider(height: 18),
                _buildAttributeRow('Player Name', player.name),
                _buildAttributeRow('Primary Role', player.role.label),
                _buildAttributeRow('Batting Hand', player.battingStyle.label),
                _buildAttributeRow('Bowling Arm', player.bowlingStyle.label),
                if (player.jerseyNumber != null)
                  _buildAttributeRow('Jersey Number', '#${player.jerseyNumber}'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Tournament Standings Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/tournaments'),
            icon: const Icon(Icons.leaderboard_rounded),
            label: const Text('View All Tournaments & Standings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              foregroundColor: const Color(0xFF1E3A8A),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ── Colorful & Slimmer Stat Card ──
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isTextValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.06),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isTextValue ? 14.5 : 19,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
                  color: color.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
