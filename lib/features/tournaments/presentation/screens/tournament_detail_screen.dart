import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/presentation/screens/team_list_tab.dart';
import '../../../matches/presentation/screens/match_list_tab.dart';
import '../providers/tournament_providers.dart';
import 'standings_tab.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.ongoing:
        return const Color(0xFF16A34A); // Emerald Green
      case TournamentStatus.upcoming:
        return const Color(0xFF2563EB); // Royal Blue
      case TournamentStatus.completed:
        return const Color(0xFF64748B); // Slate Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final tAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return tAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: const Text('Tournament Details'),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (t) {
        if (t == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              title: const Text('Tournament Details'),
            ),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        final statusColor = _getStatusColor(t.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A), // Clean Royal Blue Standard Header
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            title: Text(
              t.name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                color: Colors.white,
              ),
            ),
            actions: [
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/tournaments/${t.id}/edit');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Tournament?', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to delete ${t.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(tournamentControllerProvider.notifier).delete(t.id);
                        if (context.mounted) {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/tournaments');
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text('Edit Tournament'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              // ── Tab Bar Switcher on Clean White Background ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    labelColor: const Color(0xFF1E3A8A),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 14),
                            SizedBox(width: 4),
                            Text('Overview'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Teams'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_cricket, size: 14),
                            SizedBox(width: 4),
                            Text('Matches'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.leaderboard_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Standings'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Tab Views ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 1. Overview Tab
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Tournament Header Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFF1E3A8A),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: statusColor.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            t.status.label.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                          ),
                                          child: Text(
                                            t.format.label,
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Details Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tournament Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _InfoRow(
                                icon: Icons.calendar_month_rounded,
                                iconColor: const Color(0xFF2563EB),
                                title: 'Dates',
                                value: '${DateFormat('MMM d').format(t.startDate)} - ${t.endDate != null ? DateFormat('MMM d, yyyy').format(t.endDate!) : 'TBD'}',
                              ),
                              const Divider(height: 20, color: Color(0xFFF1F5F9)),
                              _InfoRow(
                                icon: Icons.place_rounded,
                                iconColor: const Color(0xFFDC2626),
                                title: 'Venue',
                                value: t.venue != null && t.venue!.isNotEmpty ? t.venue! : 'Borigivalasa Ground',
                              ),
                              const Divider(height: 20, color: Color(0xFFF1F5F9)),
                              _InfoRow(
                                icon: Icons.sports_cricket_rounded,
                                iconColor: const Color(0xFF16A34A),
                                title: 'Format',
                                value: '${t.format.label} (${t.format.maxOvers} Overs/Side)',
                              ),
                              const Divider(height: 20, color: Color(0xFFF1F5F9)),
                              _InfoRow(
                                icon: Icons.info_outline_rounded,
                                iconColor: const Color(0xFFD97706),
                                title: 'Status',
                                value: t.status.label,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 2. Teams Tab
                    TeamListTab(tournamentId: t.id),

                    // 3. Matches Tab
                    MatchListTab(tournamentId: t.id),

                    // 4. Standings Tab
                    StandingsTab(tournamentId: t.id),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
