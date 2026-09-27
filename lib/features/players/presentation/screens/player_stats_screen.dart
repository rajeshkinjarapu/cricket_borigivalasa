import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/player_providers.dart';

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
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: const Center(
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

        final roleLabel = player.role.label.toUpperCase();
        final roleColor = _roleColor(roleLabel);
        final initial = player.name.trim().isNotEmpty
            ? player.name.trim()[0].toUpperCase()
            : '?';

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: CustomScrollView(
            slivers: [
              // ─── Premium SliverAppBar Hero ───────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          context.push(
                              '/tournaments/$tournamentId/teams/$teamId/players/$playerId/edit');
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('Delete Player?',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w900)),
                              content: Text(
                                  'Are you sure you want to remove ${player.name} from the squad?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(c, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await ref
                                .read(playerControllerProvider.notifier)
                                .delete(player.id);
                            if (context.mounted) context.pop();
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_rounded,
                                size: 16, color: roleColor),
                            const SizedBox(width: 10),
                            const Text('Edit Player',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 16, color: Color(0xFFDC2626)),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0F172A),
                          roleColor.withOpacity(0.85),
                          const Color(0xFF0F172A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background circles
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: roleColor.withOpacity(0.12),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: -30,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.04),
                            ),
                          ),
                        ),
                        // Main content
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Avatar with glow ring
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Glow ring
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: roleColor.withOpacity(0.5),
                                            blurRadius: 30,
                                            spreadRadius: 8,
                                          ),
                                        ],
                                        border: Border.all(
                                            color: roleColor, width: 3),
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    // Avatar
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.15),
                                      backgroundImage: getAppAvatarProvider(
                                          player.profilePicUrl),
                                      child:
                                          getAppAvatarProvider(
                                                      player.profilePicUrl) ==
                                                  null
                                              ? Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    fontSize: 42,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                    ),
                                    // Jersey number badge
                                    if (player.jerseyNumber != null)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: roleColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                          child: Text(
                                            '#${player.jerseyNumber}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Name
                                Text(
                                  player.name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Role badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: roleColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: roleColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    roleLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Style chips
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (player.battingStyle.label.isNotEmpty &&
                                        player.battingStyle.label != 'None')
                                      _StyleChip(
                                        icon: Icons.sports_cricket_rounded,
                                        label: player.battingStyle.label,
                                      ),
                                    if (player.battingStyle.label.isNotEmpty &&
                                        player.bowlingStyle.label.isNotEmpty &&
                                        player.battingStyle.label != 'None' &&
                                        player.bowlingStyle.label != 'None')
                                      const SizedBox(width: 8),
                                    if (player.bowlingStyle.label.isNotEmpty &&
                                        player.bowlingStyle.label != 'None')
                                      _StyleChip(
                                        icon: Icons.sports_baseball_rounded,
                                        label: player.bowlingStyle.label,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Stats Content ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'CAREER STATISTICS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stats Grid — 2 columns, 3 rows
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.55,
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
                            value: player.stats.battingAverage
                                .toStringAsFixed(1),
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
                            value: player.stats.bestBowling.isEmpty
                                ? '-'
                                : player.stats.bestBowling,
                            icon: Icons.emoji_events_rounded,
                            accentColor: const Color(0xFFEA580C),
                            bgColor: const Color(0xFFFFEDD5),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Extra info card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: roleColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'PLAYER INFO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.sports_cricket_rounded,
                              label: 'Batting Style',
                              value: player.battingStyle.label.isEmpty
                                  ? 'Not set'
                                  : player.battingStyle.label,
                              color: const Color(0xFF2563EB),
                            ),
                            const _InfoDivider(),
                            _InfoRow(
                              icon: Icons.sports_baseball_rounded,
                              label: 'Bowling Style',
                              value: player.bowlingStyle.label.isEmpty
                                  ? 'Not set'
                                  : player.bowlingStyle.label,
                              color: const Color(0xFF059669),
                            ),
                            const _InfoDivider(),
                            _InfoRow(
                              icon: Icons.shield_rounded,
                              label: 'Playing Role',
                              value: player.role.label,
                              color: roleColor,
                            ),
                            if (player.jerseyNumber != null) ...[
                              const _InfoDivider(),
                              _InfoRow(
                                icon: Icons.tag_rounded,
                                label: 'Jersey Number',
                                value: '#${player.jerseyNumber}',
                                color: const Color(0xFFD97706),
                              ),
                            ],
                            if (player.phoneNumber != null &&
                                player.phoneNumber!.isNotEmpty) ...[
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
              ),
            ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon + label row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: accentColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accentColor.withOpacity(0.75),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Big bold value
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: -1,
                  height: 1.0,
                ),
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
