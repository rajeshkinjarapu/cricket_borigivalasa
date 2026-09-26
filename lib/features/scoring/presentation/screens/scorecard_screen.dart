import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scoring_providers.dart';

class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
    this.innings = 1,
    this.isEmbedded = false,
  });

  final String tournamentId, matchId;
  final int innings;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = (tournamentId: tournamentId, matchId: matchId, innings: innings);
    final inn = ref.watch(inningsProvider(k));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: isEmbedded ? null : AppBar(
          title: Text('Innings $innings Scorecard'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Batting'), Tab(text: 'Bowling')],
          ),
        ),
        body: inn.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (i) {
            if (i == null) return const Center(child: Text('No scorecard available yet'));

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.battingTeamName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${i.runs}/${i.wickets}  (${i.oversText} ov)',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Extras ${i.extras}  •  RR ${i.runRate.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [_BatTab(k: k), _BowlTab(k: k)],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BatTab extends ConsumerWidget {
  const _BatTab({required this.k});
  final InningsKey k;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(battingScorecardProvider(k)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rows) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (c, i) {
          final r = rows[i];
          return ListTile(
            dense: true,
            title: Text(
              r.playerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: r.isOut && r.dismissalText != null
                ? Text(r.dismissalText!, style: const TextStyle(fontSize: 11))
                : const Text('not out', style: TextStyle(fontSize: 11, color: Colors.green)),
            trailing: Text(
              '${r.runs} (${r.balls})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
}

class _BowlTab extends ConsumerWidget {
  const _BowlTab({required this.k});
  final InningsKey k;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(bowlingScorecardProvider(k)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (rows) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (c, i) {
          final r = rows[i];
          final ov = '${r.balls ~/ 6}.${r.balls % 6}';
          final econ = r.balls == 0 ? '—' : (r.runs * 6 / r.balls).toStringAsFixed(1);
          return ListTile(
            dense: true,
            title: Text(
              r.playerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('$ov ov • M ${r.maidens} • Econ $econ'),
            trailing: Text(
              '${r.wickets}/${r.runs}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
}
