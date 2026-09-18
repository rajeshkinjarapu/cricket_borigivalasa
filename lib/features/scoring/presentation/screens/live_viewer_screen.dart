import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scoring_providers.dart';
import 'scorecard_screen.dart';

class LiveViewerScreen extends ConsumerWidget {
  const LiveViewerScreen({super.key, required this.tournamentId,
    required this.matchId});
  final String tournamentId, matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i1 = ref.watch(inningsProvider((tournamentId: tournamentId,
      matchId: matchId, innings: 1)));
    final i2 = ref.watch(inningsProvider((tournamentId: tournamentId,
      matchId: matchId, innings: 2)));
    return Scaffold(appBar: AppBar(title: const Text('Live')),
      body: i1.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (a) { if (a == null) return const Center(
          child: Text('Match not started'));
          final b = i2.value;
          return ListView(children: [
            _Panel(i: a, tId: tournamentId, mId: matchId, n: 1),
            if (b != null) _Panel(i: b, tId: tournamentId, mId: matchId, n: 2),
          ]); }));
  }
}
class _Panel extends StatelessWidget {
  const _Panel({required this.i, required this.tId, required this.mId,
    required this.n});
  final dynamic i;
  final String tId, mId;
  final int n;
  @override
  Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.all(12),
      child: Padding(padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i.battingTeamName, style: const TextStyle(
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${i.runs}/${i.wickets}  (${i.oversText} ov)',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('RR ${i.runRate.toStringAsFixed(2)}  •  Extras ${i.extras}',
            style: const TextStyle(fontSize: 12)),
          Align(alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ScorecardScreen(
                tournamentId: tId, matchId: mId, innings: n))),
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('Full scorecard'))),
        ])));
  }
}
