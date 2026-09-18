import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tournament_providers.dart';

class StandingsTab extends ConsumerWidget {
  const StandingsTab({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(tournamentStandingsProvider(tournamentId));
    
    return standingsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No matches completed yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withOpacity(0.05)),
                  columns: const [
                    DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('L', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('NRR', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), numeric: true),
                  ],
                  rows: list.asMap().entries.map((entry) {
                    final index = entry.key;
                    final st = entry.value;
                    final isQualifier = index < 4; // Top 4 qualify

                    return DataRow(
                      color: isQualifier ? WidgetStateProperty.all(Colors.green.withOpacity(0.05)) : null,
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 12)),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(st.teamName[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              Text(st.teamName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        DataCell(Text(st.matchesPlayed.toString())),
                        DataCell(Text(st.won.toString())),
                        DataCell(Text(st.lost.toString())),
                        DataCell(Text(st.netRunRate.toStringAsFixed(3))),
                        DataCell(Text(st.points.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(width: 12, height: 12, color: Colors.green.withOpacity(0.2)),
                const SizedBox(width: 8),
                const Text('Qualifiers Zone', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error computing standings: $e')),
    );
  }
}
