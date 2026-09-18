import '../data/models/ball_event.dart';

class OverStat {
  final int overNumber, runs, wickets, cumulativeRuns, cumulativeWickets;
  final double runRate;
  const OverStat({required this.overNumber, required this.runs,
    required this.wickets, required this.cumulativeRuns,
    required this.cumulativeWickets, required this.runRate});
}

class InningsOverStats {
  final List<OverStat> overs;
  final int totalRuns, totalWickets;
  const InningsOverStats({required this.overs, required this.totalRuns,
    required this.totalWickets});
}

class StatsEngine {
  StatsEngine._();
  static InningsOverStats build(List<BallEvent> balls) {
    if (balls.isEmpty) return const InningsOverStats(
      overs: [], totalRuns: 0, totalWickets: 0);
    final overs = <OverStat>[];
    int legalCount = 0, currentRuns = 0, currentWkts = 0;
    int cumRuns = 0, cumWkts = 0;
    void flush() {
      cumRuns += currentRuns; cumWkts += currentWkts;
      final rr = legalCount == 0 ? 0.0 : cumRuns * 6 / legalCount;
      overs.add(OverStat(overNumber: overs.length + 1, runs: currentRuns,
        wickets: currentWkts, cumulativeRuns: cumRuns,
        cumulativeWickets: cumWkts, runRate: rr));
      currentRuns = 0; currentWkts = 0;
    }
    for (final b in balls) {
      currentRuns += b.totalDeliveryRuns;
      if (b.isWicket) currentWkts++;
      if (b.isLegalDelivery) {
        legalCount++;
        if (legalCount % 6 == 0) flush();
      }
    }
    if (currentRuns > 0 || currentWkts > 0) flush();
    return InningsOverStats(overs: overs, totalRuns: cumRuns, totalWickets: cumWkts);
  }
}
