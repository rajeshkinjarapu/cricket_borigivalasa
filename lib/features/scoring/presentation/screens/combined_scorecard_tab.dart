import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../matches/data/models/match.dart';
import '../../data/models/innings.dart';
import '../../data/models/batting_scorecard.dart';
import '../../data/models/bowling_scorecard.dart';
import '../providers/scoring_providers.dart';

class CombinedScorecardTab extends ConsumerWidget {
  const CombinedScorecardTab({
    super.key,
    required this.match,
    required this.i1,
    required this.i2,
    required this.tournamentId,
    required this.matchId,
  });

  final MatchModel match;
  final Innings? i1;
  final Innings? i2;
  final String tournamentId;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k1 = (tournamentId: tournamentId, matchId: matchId, innings: 1);
    final k2 = (tournamentId: tournamentId, matchId: matchId, innings: 2);
    final bat1 = ref.watch(battingScorecardProvider(k1)).value ?? [];
    final bowl1 = ref.watch(bowlingScorecardProvider(k1)).value ?? [];
    final bat2 = ref.watch(battingScorecardProvider(k2)).value ?? [];
    final bowl2 = ref.watch(bowlingScorecardProvider(k2)).value ?? [];

    final momName = match.manOfTheMatchName ?? '';
    final resultText = match.resultText ?? _computeResult(match, i1, i2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // ─── Result Banner ───
        if (resultText.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    resultText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // ─── Man of the Match ───
        if (momName.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFEAB308).withOpacity(0.15), const Color(0xFFFEF9C3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🏅', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PLAYER OF THE MATCH',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      momName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ─── 1st Innings Scorecard ───
        if (i1 != null) ...[
          _buildInningsCard(
            context: context,
            label: '1ST INNINGS',
            teamName: i1!.battingTeamId == match.teamAId ? match.teamA : match.teamB,
            innings: i1!,
            batRows: bat1,
            bowlRows: bowl1,
            accentColor: const Color(0xFF1E3A8A),
            bgColor: const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 10),
        ],

        // ─── 2nd Innings Scorecard ───
        if (i2 != null) ...[
          _buildInningsCard(
            context: context,
            label: '2ND INNINGS',
            teamName: i2!.battingTeamId == match.teamAId ? match.teamA : match.teamB,
            innings: i2!,
            batRows: bat2,
            bowlRows: bowl2,
            accentColor: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
          ),
          const SizedBox(height: 10),
        ],

        // ─── Share Info ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.share_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${match.teamA} vs ${match.teamB} • ${resultText.isNotEmpty ? resultText : "Match details"}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showShareText(context, match, i1, i2, bat1, bowl1, bat2, bowl2, momName, resultText),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInningsCard({
    required BuildContext context,
    required String label,
    required String teamName,
    required Innings innings,
    required List<BattingScorecardRow> batRows,
    required List<BowlingScorecardRow> bowlRows,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: accentColor.withOpacity(0.7), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
                    const SizedBox(height: 1),
                    Text(teamName, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${innings.runs}/${innings.wickets} (${innings.oversText})',
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Batting
          if (batRows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Icon(Icons.sports_cricket_rounded, size: 12, color: accentColor.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text('BATTING', style: TextStyle(color: accentColor.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
                ],
              ),
            ),
            // Table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Batter', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800))),
                  _th('R'), _th('B'), _th('4s'), _th('6s'), _th('SR'),
                ],
              ),
            ),
            const Divider(height: 8, indent: 14, endIndent: 14, color: Color(0xFFF1F5F9)),
            ...batRows.map((b) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      b.playerName,
                      style: TextStyle(
                        color: b.runs >= 30 ? const Color(0xFF0F172A) : const Color(0xFF334155),
                        fontWeight: b.runs >= 30 ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _td('${b.runs}', bold: b.runs >= 30, color: b.runs >= 50 ? const Color(0xFF059669) : null),
                  _td('${b.balls}'),
                  _td('${b.fours}'),
                  _td('${b.sixes}', bold: b.sixes > 0, color: b.sixes > 0 ? const Color(0xFF7C3AED) : null),
                  _td(b.balls > 0 ? ((b.runs / b.balls) * 100).toStringAsFixed(0) : '-'),
                ],
              ),
            )),
          ],

          // Bowling
          if (bowlRows.isNotEmpty) ...[
            Container(height: 1, color: const Color(0xFFF1F5F9), margin: const EdgeInsets.symmetric(vertical: 6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Row(
                children: [
                  Icon(Icons.sports_baseball_rounded, size: 12, color: const Color(0xFF059669).withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text('BOWLING', style: TextStyle(color: const Color(0xFF059669).withOpacity(0.8), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Bowler', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800))),
                  _th('O'), _th('M'), _th('R'), _th('W'), _th('ER'),
                ],
              ),
            ),
            const Divider(height: 8, indent: 14, endIndent: 14, color: Color(0xFFF1F5F9)),
            ...bowlRows.map((b) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      b.playerName,
                      style: TextStyle(
                        color: b.wickets >= 2 ? const Color(0xFF0F172A) : const Color(0xFF334155),
                        fontWeight: b.wickets >= 2 ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _td(b.oversText),
                  _td('${b.maidens}'),
                  _td('${b.runs}'),
                  _td('${b.wickets}', bold: b.wickets >= 2, color: b.wickets >= 3 ? const Color(0xFFDC2626) : null),
                  _td(b.economy.toStringAsFixed(1)),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _th(String label) {
    return Expanded(
      child: Center(
        child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _td(String value, {bool bold = false, Color? color}) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: color ?? (bold ? const Color(0xFF0F172A) : const Color(0xFF475569)),
            fontSize: 12,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showShareText(
    BuildContext context,
    MatchModel match,
    Innings? i1,
    Innings? i2,
    List<BattingScorecardRow> bat1,
    List<BowlingScorecardRow> bowl1,
    List<BattingScorecardRow> bat2,
    List<BowlingScorecardRow> bowl2,
    String momName,
    String resultText,
  ) {
    final sb = StringBuffer();
    sb.writeln('🏏 ${match.teamA} vs ${match.teamB}');
    sb.writeln('📅 ${DateFormat('MMM dd, yyyy').format(match.matchDate)}');
    if (match.venue.isNotEmpty) sb.writeln('📍 ${match.venue}');
    sb.writeln();

    if (i1 != null) {
      final t1 = i1.battingTeamId == match.teamAId ? match.teamA : match.teamB;
      sb.writeln('1ST INN: $t1 — ${i1.runs}/${i1.wickets} (${i1.oversText})');
      for (final b in bat1) {
        if (b.runs > 0 || b.balls > 0) {
          sb.writeln('  ${b.playerName}: ${b.runs}(${b.balls}) ${b.fours > 0 ? "${b.fours}x4" : ""} ${b.sixes > 0 ? "${b.sixes}x6" : ""}');
        }
      }
      sb.writeln('Bowling:');
      for (final b in bowl1) {
        sb.writeln('  ${b.playerName}: ${b.oversText}-${b.maidens}-${b.runs}-${b.wickets}');
      }
      sb.writeln();
    }

    if (i2 != null) {
      final t2 = i2.battingTeamId == match.teamAId ? match.teamA : match.teamB;
      sb.writeln('2ND INN: $t2 — ${i2.runs}/${i2.wickets} (${i2.oversText})');
      for (final b in bat2) {
        if (b.runs > 0 || b.balls > 0) {
          sb.writeln('  ${b.playerName}: ${b.runs}(${b.balls}) ${b.fours > 0 ? "${b.fours}x4" : ""} ${b.sixes > 0 ? "${b.sixes}x6" : ""}');
        }
      }
      sb.writeln('Bowling:');
      for (final b in bowl2) {
        sb.writeln('  ${b.playerName}: ${b.oversText}-${b.maidens}-${b.runs}-${b.wickets}');
      }
      sb.writeln();
    }

    if (resultText.isNotEmpty) sb.writeln('🏆 $resultText');
    if (momName.isNotEmpty) sb.writeln('🏅 Player of the Match: $momName');
    sb.writeln('\n#BorigivalasaCricket');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareTextSheet(shareText: sb.toString()),
    );
  }

  String _computeResult(MatchModel match, Innings? i1, Innings? i2) {
    if (i1 != null && i2 != null) {
      if (i2.runs > i1.runs) {
        final rem = 10 - i2.wickets;
        final t = i2.battingTeamId == match.teamAId ? match.teamA : match.teamB;
        return '$t won by $rem ${rem == 1 ? "wicket" : "wickets"}';
      } else if (i1.runs > i2.runs) {
        final rem = i1.runs - i2.runs;
        final t = i1.battingTeamId == match.teamAId ? match.teamA : match.teamB;
        return '$t won by $rem ${rem == 1 ? "run" : "runs"}';
      } else {
        return 'Match Tied';
      }
    }
    return match.resultText ?? '';
  }
}

// ─── Share Text Bottom Sheet ──────────────────────────────────────────────────
class _ShareTextSheet extends StatelessWidget {
  const _ShareTextSheet({required this.shareText});
  final String shareText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Share Scorecard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A))),
                ElevatedButton.icon(
                  onPressed: () {
                    // Copy to clipboard
                    final data = ClipboardData(text: shareText);
                    Clipboard.setData(data);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Scorecard copied to clipboard!'),
                        backgroundColor: Color(0xFF059669),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE2E8F0)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(shareText, style: const TextStyle(color: Color(0xFFE2E8F0), fontFamily: 'monospace', fontSize: 12.5, height: 1.6)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
