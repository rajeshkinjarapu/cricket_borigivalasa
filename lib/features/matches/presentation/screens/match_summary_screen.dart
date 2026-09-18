import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/match_providers.dart';
import '../../data/models/match.dart';

class MatchSummaryScreen extends ConsumerWidget {
  const MatchSummaryScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  final String tournamentId, matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider((tournamentId: tournamentId, matchId: matchId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Match Summary')),
      body: matchAsync.when(
        data: (m) {
          if (m == null) return const Center(child: Text('Match not found'));
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('${m.teamAName} vs ${m.teamBName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(m.venue.isEmpty ? 'Venue TBD' : m.venue, style: const TextStyle(color: Colors.grey)),
                      const Divider(),
                      if (m.isCompleted) ...[
                        Text(
                          m.resultText ?? 'Match Completed',
                          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text('Status: ${m.status.name.toUpperCase()}', style: const TextStyle(fontSize: 16)),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Innings Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Detailed scorecards will appear here.')),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Top Performers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Player of the Match'),
                  subtitle: const Text('TBD'),
                  trailing: const Text('TBD'),
                  onTap: () {},
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
