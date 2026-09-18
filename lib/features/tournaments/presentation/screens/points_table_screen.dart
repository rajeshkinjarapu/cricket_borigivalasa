import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tournament_providers.dart';

class PointsTableScreen extends ConsumerWidget {
  const PointsTableScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(tournamentStandingsProvider(tournamentId));
    final t = ref.watch(tournamentDetailProvider(tournamentId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.value?.name != null ? '${t.value!.name} - Points Table' : 'Points Table'),
      ),
      body: standings.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No matches played yet.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Team')),
                  DataColumn(label: Text('M')),
                  DataColumn(label: Text('W')),
                  DataColumn(label: Text('L')),
                  DataColumn(label: Text('T')),
                  DataColumn(label: Text('Pts')),
                ],
                rows: list.map((st) => DataRow(cells: [
                  DataCell(Text(st.teamName)),
                  DataCell(Text(st.matchesPlayed.toString())),
                  DataCell(Text(st.won.toString())),
                  DataCell(Text(st.lost.toString())),
                  DataCell(Text(st.tied.toString())),
                  DataCell(Text(st.points.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                ])).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
