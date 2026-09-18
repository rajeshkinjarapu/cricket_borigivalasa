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

  @override
  Widget build(BuildContext context) {
    final tAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return tAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (t) {
        if (t == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Tournament not found')));
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).primaryColor, const Color(0xFF1A237E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.emoji_events, size: 80, color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                  ),
                  actions: [
                    if (isAdmin)
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') context.push('/tournaments/${t.id}/edit');
                          else if (v == 'delete') {
                            // Show confirm dialog
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Delete Tournament?'),
                                content: Text('Are you sure you want to delete ${t.name}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ref.read(tournamentControllerProvider.notifier).delete(t.id);
                              if (context.mounted) context.pop();
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                  ],
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Teams'),
                        Tab(text: 'Matches'),
                        Tab(text: 'Standings'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Overview Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InfoRow(icon: Icons.calendar_month, title: 'Dates', value: '${DateFormat('MMM d').format(t.startDate)} - ${t.endDate != null ? DateFormat('MMM d, yyyy').format(t.endDate!) : 'TBD'}'),
                            const Divider(height: 24),
                            _InfoRow(icon: Icons.place, title: 'Venue', value: t.venue ?? 'Not specified'),
                            const Divider(height: 24),
                            _InfoRow(icon: Icons.sports_cricket, title: 'Format', value: t.format.label),
                            const Divider(height: 24),
                            _InfoRow(icon: Icons.info_outline, title: 'Status', value: t.status.label),
                          ],
                        ),
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
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
