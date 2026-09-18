import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/live_match_card.dart';
import '../widgets/upcoming_match_card.dart';
import '../widgets/tournament_summary_card.dart';

class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider);
    final isScorer = true; // In the future, check user permissions

    final liveMatchesAsync = ref.watch(liveMatchesProvider);
    final upcomingMatchesAsync = ref.watch(upcomingMatchesProvider);
    final tournamentsAsync = ref.watch(activeTournamentsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                (u?.displayName.isNotEmpty ?? false) ? u!.displayName[0].toUpperCase() : 'M',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${u?.displayName ?? 'Member'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const Row(
                  children: [
                    Text('Role: Scorer ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Icon(Icons.verified, color: Colors.green, size: 14),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined, color: Colors.black87),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              ref.invalidate(authStateProvider);
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Quick Actions
            if (isScorer) ...[
              Row(
                children: [
                  Expanded(child: _QuickActionBtn(icon: Icons.add, label: 'Create Match', color: Theme.of(context).primaryColor, onTap: () => context.push('/tournaments'))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickActionBtn(icon: Icons.play_arrow, label: 'Start Scoring', color: Colors.orange, onTap: () => context.push('/matches-list'))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickActionBtn(icon: Icons.emoji_events, label: '+ Tourn.', color: Colors.purple, onTap: () => context.push('/tournaments/new'))),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Live Now
            const _SectionTitle(title: '🔴 LIVE NOW'),
            liveMatchesAsync.when(
              data: (matches) {
                if (matches.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 24), child: Text('No live matches'));
                return Column(children: matches.map((m) => LiveMatchCard(match: m)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            // Upcoming Matches
            const _SectionTitle(title: '📅 UPCOMING MATCHES'),
            upcomingMatchesAsync.when(
              data: (matches) {
                if (matches.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 24), child: Text('No upcoming matches'));
                return Column(children: matches.map((m) => UpcomingMatchCard(match: m)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            // My Tournaments
            const _SectionTitle(title: '🏆 MY TOURNAMENTS'),
            tournamentsAsync.when(
              data: (tournaments) {
                if (tournaments.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 24), child: Text('No active tournaments'));
                return Column(children: tournaments.map((t) => TournamentSummaryCard(tournament: t)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black87),
      ),
    );
  }
}
