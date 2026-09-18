import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/models/match.dart';

class GlobalMatchesScreen extends ConsumerStatefulWidget {
  const GlobalMatchesScreen({super.key});

  @override
  ConsumerState<GlobalMatchesScreen> createState() => _GlobalMatchesScreenState();
}

class _GlobalMatchesScreenState extends ConsumerState<GlobalMatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveMatchesAsync = ref.watch(liveMatchesProvider);
    final upcomingMatchesAsync = ref.watch(upcomingMatchesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: '🔴 Live'),
            Tab(text: '📅 Upcoming'),
            Tab(text: '🏆 All Matches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Live Tab
          liveMatchesAsync.when(
            data: (matches) => _buildMatchList(
              context,
              matches,
              emptyMsg: 'No live matches in progress right now.',
              emptyIcon: Icons.sports_cricket,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // 2. Upcoming Tab
          upcomingMatchesAsync.when(
            data: (matches) => _buildMatchList(
              context,
              matches,
              emptyMsg: 'No upcoming fixtures scheduled yet.',
              emptyIcon: Icons.calendar_month_outlined,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // 3. All Matches Tab
          liveMatchesAsync.when(
            data: (live) => upcomingMatchesAsync.when(
              data: (upcoming) {
                final all = [...live, ...upcoming];
                return _buildMatchList(
                  context,
                  all,
                  emptyMsg: 'No matches found.',
                  emptyIcon: Icons.sports_score,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    List<Match> matches, {
    required String emptyMsg,
    required IconData emptyIcon,
  }) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final m = matches[index];
        final isLive = m.status == MatchStatus.live;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isLive ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isLive ? Colors.red.shade300 : Colors.grey.shade200,
              width: isLive ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (m.tournamentId.isNotEmpty) {
                context.push('/tournaments/${m.tournamentId}/matches/${m.id}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLive ? '🔴 LIVE' : m.status.label.toUpperCase(),
                          style: TextStyle(
                            color: isLive ? Colors.red : Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(m.matchDate),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.teamA,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m.teamB,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${m.venue} • ${m.totalOvers} Overs',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
