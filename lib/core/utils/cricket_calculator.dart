class CricketCalculator {
  CricketCalculator._();
  static double oversForNrr({required int legalBalls, required int wickets,
      required int playersPerSide, required int maxOvers}) {
    if (wickets >= playersPerSide - 1) return maxOvers.toDouble();
    if (legalBalls == 0) return 0;
    return legalBalls / 6.0;
  }
  static double runRate({required int runs, required int legalBalls}) =>
    legalBalls == 0 ? 0 : runs * 6 / legalBalls;
  static String oversText(int b) => '${b ~/ 6}.${b % 6}';
}
