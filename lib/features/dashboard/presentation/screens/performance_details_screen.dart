import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'member_dashboard.dart';

class PerformanceDetailsScreen extends StatelessWidget {
  final String title;
  final String totalCount;
  final Color accentColor;
  final List<PlayerMatchDetail> items;
  final String type;

  const PerformanceDetailsScreen({
    super.key,
    required this.title,
    required this.totalCount,
    required this.accentColor,
    required this.items,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF0F172A), accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              totalCount,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_cricket_outlined, size: 48, color: const Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  const Text(
                    'No records found yet for this metric.',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                final m = item.match;

                String metricValueText = '';
                String metricSubtitleText = '';

                if (type == 'runs') {
                  metricValueText = '${item.runs} Runs';
                  metricSubtitleText = '${item.balls} balls • ${item.fours} 4s • ${item.sixes} 6s';
                } else if (type == 'wickets') {
                  metricValueText = '${item.wickets} Wkts';
                  metricSubtitleText = 'Bowling spell';
                } else if (type == 'fours') {
                  metricValueText = '${item.fours} 4s';
                  metricSubtitleText = '${item.runs} total runs';
                } else if (type == 'sixes') {
                  metricValueText = '${item.sixes} 6s';
                  metricSubtitleText = '${item.runs} total runs';
                } else if (type == 'won') {
                  metricValueText = '🏆 Won';
                  metricSubtitleText = m.resultText ?? 'Match Completed';
                } else if (type == 'mom') {
                  metricValueText = '🏅 Man of the Match';
                  metricSubtitleText = '${item.runs}r & ${item.wickets}w';
                } else if (type == 'fifties') {
                  metricValueText = '🔥 ${item.runs} Runs';
                  metricSubtitleText = '${item.balls} balls • ${item.fours} 4s • ${item.sixes} 6s';
                } else {
                  metricValueText = '${item.runs}r • ${item.wickets}w';
                  metricSubtitleText = m.status.label;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (m.tournamentId.isNotEmpty) {
                        if (m.isCompleted) {
                          context.push('/tournaments/${m.tournamentId}/matches/${m.id}/summary');
                        } else {
                          context.push('/tournaments/${m.tournamentId}/matches/${m.id}');
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.teamA} vs ${m.teamB}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      metricValueText,
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: accentColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• $metricSubtitleText',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
