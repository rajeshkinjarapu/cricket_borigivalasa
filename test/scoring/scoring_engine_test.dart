import 'package:cricket_scoring_app/core/constants/cricket_enums.dart';
import 'package:cricket_scoring_app/features/scoring/data/models/ball_event.dart';
import 'package:cricket_scoring_app/features/scoring/domain/scoring_engine.dart';
import 'package:flutter_test/flutter_test.dart';

BallEvent _b({int bat = 0, int extra = 0,
    ExtraType type = ExtraType.none, bool w = false, WicketType? wt,
    String? out, String? nb}) => BallEvent(batRuns: bat, extraRuns: extra,
  extraType: type, isWicket: w, wicketType: wt, dismissedPlayerId: out,
  dismissedPlayerName: out, newBatsmanId: nb, newBatsmanName: nb,
  batsmanId: 'b1', batsmanName: 'B1', bowlerId: 'p1', bowlerName: 'P1',
  timestamp: DateTime(2024));

InningsSnapshot _r(List<BallEvent> balls) => ScoringEngine.reduce(
  openingStrikerId: 'b1', openingStrikerName: 'B1',
  openingNonStrikerId: 'b2', openingNonStrikerName: 'B2', balls: balls);

void main() {
  test('empty list', () { final s = _r([]);
    expect(s.runs, 0); expect(s.legalBalls, 0); expect(s.strikerId, 'b1'); });
  test('single rotates strike', () { final s = _r([_b(bat: 1)]);
    expect(s.runs, 1); expect(s.strikerId, 'b2'); });
  test('4 keeps strike', () { final s = _r([_b(bat: 4)]);
    expect(s.strikerId, 'b1'); expect(s.batting['b1']!.fours, 1); });
  test('end of over rotates', () {
    final s = _r(List.generate(6, (_) => _b()));
    expect(s.legalBalls, 6); expect(s.strikerId, 'b2'); });
  test('wide adds 1 run no ball count', () {
    final s = _r([_b(extra: 0, type: ExtraType.wide)]);
    expect(s.runs, 1); expect(s.wides, 1); expect(s.legalBalls, 0); });
  test('no ball + 6 = 7 runs', () {
    final s = _r([_b(bat: 6, type: ExtraType.noball)]);
    expect(s.runs, 7); expect(s.noballs, 1);
    expect(s.batting['b1']!.runs, 6); expect(s.batting['b1']!.balls, 0); });
  test('bye does not credit batsman', () {
    final s = _r([_b(extra: 2, type: ExtraType.bye)]);
    expect(s.runs, 2); expect(s.byes, 2); expect(s.batting['b1']!.runs, 0); });
  test('bowled wicket', () {
    final s = _r([_b(w: true, wt: WicketType.bowled, out: 'b1', nb: 'b3')]);
    expect(s.wickets, 1); expect(s.bowling['p1']!.wickets, 1);
    expect(s.batting['b1']!.isOut, true);
    expect(s.fallOfWickets.length, 1); });
  test('run out does not credit bowler', () {
    final s = _r([_b(w: true, wt: WicketType.runOut, out: 'b1', nb: 'b3')]);
    expect(s.wickets, 1); expect(s.bowling['p1']!.wickets, 0); });
  test('maiden over', () {
    final s = _r(List.generate(6, (_) => _b()));
    expect(s.bowling['p1']!.runs, 0); expect(s.bowling['p1']!.balls, 6); });
  test('all out check', () {
    final balls = List.generate(10, (i) => _b(w: true,
      wt: WicketType.bowled, out: i == 0 ? 'b1' : 'b\${i + 2}',
      nb: 'b\${i + 3}', ));
    final s = _r(balls);
    final r = ScoringEngine.checkInningsComplete(
      snap: s, maxOvers: 20, playersPerSide: 11);
    expect(r, 'All out'); });
}
