import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/stats_engine.dart';
import '../providers/scoring_providers.dart';

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key, required this.tournamentId,
    required this.matchId});
  final String tournamentId, matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title: const Text('Charts'),
        bottom: const TabBar(tabs: [Tab(text: 'Manhattan'),
          Tab(text: 'Run rate'), Tab(text: 'Worm')])),
      body: TabBarView(children: [
        _Chart(t: tournamentId, m: matchId, mode: 0),
        _Chart(t: tournamentId, m: matchId, mode: 1),
        _Chart(t: tournamentId, m: matchId, mode: 2),
      ])));
  }
}

class _Chart extends ConsumerWidget {
  const _Chart({required this.t, required this.m, required this.mode});
  final String t, m;
  final int mode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(future: Future.wait([
      ref.watch(allBallsProvider((tournamentId: t, matchId: m, innings: 1)).future),
      ref.watch(allBallsProvider((tournamentId: t, matchId: m, innings: 2)).future),
    ]), builder: (c, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final b1 = s.data![0]; final b2 = s.data![1];
      final i1 = b1.isEmpty ? null : StatsEngine.build(b1);
      final i2 = b2.isEmpty ? null : StatsEngine.build(b2);
      if (i1 == null && i2 == null) return const Center(child: Text('No data'));
      return Padding(padding: const EdgeInsets.all(16),
        child: mode == 0 ? _manhattan(i1, i2)
          : mode == 1 ? _rate(i1, i2) : _worm(i1, i2));
    });
  }

  Widget _manhattan(InningsOverStats? a, InningsOverStats? b) {
    final maxOver = [a?.overs.length ?? 0, b?.overs.length ?? 0]
      .reduce((x, y) => x > y ? x : y);
    final maxR = [...(a?.overs.map((e) => e.runs) ?? []),
      ...(b?.overs.map((e) => e.runs) ?? []), 6]
      .reduce((x, y) => x > y ? x : y);
    return BarChart(BarChartData(maxY: (maxR + 2).toDouble(),
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28, interval: 6)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          reservedSize: 22, getTitlesWidget: (v, _) => Text('${v.toInt() + 1}',
            style: const TextStyle(fontSize: 10))))),
      barGroups: List.generate(maxOver, (i) => BarChartGroupData(x: i,
        barsSpace: 2,
        barRods: [
          BarChartRodData(toY: (i < (a?.overs.length ?? 0) ? a!.overs[i].runs : 0)
            .toDouble(), color: Colors.blue.shade400, width: 8,
            borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: (i < (b?.overs.length ?? 0) ? b!.overs[i].runs : 0)
            .toDouble(), color: Colors.orange.shade400, width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
       ),
      ),
     ),
    );
  }

  Widget _rate(InningsOverStats? a, InningsOverStats? b) {
    List<FlSpot> sp(InningsOverStats? s) => s?.overs.map((o) => FlSpot(
      o.overNumber.toDouble(), o.runRate)).toList() ?? [];
    final all = [...sp(a), ...sp(b)];
    final maxY = all.isEmpty ? 12.0 : all.map((s) => s.y)
      .reduce((x, y) => x > y ? x : y) + 2;
    return LineChart(LineChartData(minY: 0, maxY: maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28, interval: 2)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          reservedSize: 22, interval: 5,
          getTitlesWidget: (v, _) => Text('Ov ${v.toInt()}',
            style: const TextStyle(fontSize: 10))))),
      lineBarsData: [
        LineChartBarData(spots: sp(a), isCurved: true,
          color: Colors.blue.shade400, barWidth: 2,
          dotData: const FlDotData(show: false)),
        LineChartBarData(spots: sp(b), isCurved: true,
          color: Colors.orange.shade400, barWidth: 2,
          dotData: const FlDotData(show: false)),
      ]));
  }

  Widget _worm(InningsOverStats? a, InningsOverStats? b) {
    List<FlSpot> w(InningsOverStats? s) => s?.overs.map((o) => FlSpot(
      (o.overNumber - 1) * 6 + 6, o.cumulativeRuns.toDouble())).toList() ?? [];
    final all = [...w(a), ...w(b)];
    final maxY = all.isEmpty ? 100.0 : all.map((s) => s.y)
      .reduce((x, y) => x > y ? x : y) + 10;
    final maxX = all.isEmpty ? 120.0 : all.map((s) => s.x)
      .reduce((x, y) => x > y ? x : y) + 6;
    return LineChart(LineChartData(minY: 0, maxY: maxY, minX: 0, maxX: maxX,
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 30, interval: 20)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          reservedSize: 22, interval: 30,
          getTitlesWidget: (v, _) => Text('Ov ${v ~/ 6}',
            style: const TextStyle(fontSize: 10))))),
      lineBarsData: [
        LineChartBarData(spots: w(a), isCurved: false,
          color: Colors.blue.shade400, barWidth: 2,
          dotData: const FlDotData(show: false)),
        LineChartBarData(spots: w(b), isCurved: false,
          color: Colors.orange.shade400, barWidth: 2,
          dotData: const FlDotData(show: false)),
      ]));
  }
}
