import 'package:cricket_scoring_app/core/utils/cricket_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all out uses full quota', () {
    expect(CricketCalculator.oversForNrr(legalBalls: 47, wickets: 10,
      playersPerSide: 11, maxOvers: 20), 20.0); });
  test('partial uses actual balls', () {
    final o = CricketCalculator.oversForNrr(legalBalls: 73, wickets: 6,
      playersPerSide: 11, maxOvers: 20);
    expect(o, closeTo(73 / 6, 0.001)); });
  test('run rate', () {
    expect(CricketCalculator.runRate(runs: 60, legalBalls: 60), 6.0); });
  test('overs text', () {
    expect(CricketCalculator.oversText(73), '12.1'); });
}
