import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../matches/data/models/match.dart';
import '../../data/models/innings.dart';
import '../../data/models/batting_scorecard.dart';
import '../../data/models/bowling_scorecard.dart';
import '../providers/scoring_providers.dart';

class CombinedScorecardTab extends ConsumerStatefulWidget {
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
  ConsumerState<CombinedScorecardTab> createState() => _CombinedScorecardTabState();
}

class _CombinedScorecardTabState extends ConsumerState<CombinedScorecardTab> {
  final GlobalKey _shareKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareScorecard() async {
    setState(() => _isSharing = true);
    try {
      // Capture widget as image
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isSharing = false);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() => _isSharing = false);
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/scorecard_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.match.teamA} vs ${widget.match.teamB} - Match Scorecard\n${widget.match.resultText ?? ''}',
        subject: 'Cricket Match Scorecard',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k1 = (tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 1);
    final k2 = (tournamentId: widget.tournamentId, matchId: widget.matchId, innings: 2);
    final bat1Async = ref.watch(battingScorecardProvider(k1));
    final bowl1Async = ref.watch(bowlingScorecardProvider(k1));
    final bat2Async = ref.watch(battingScorecardProvider(k2));
    final bowl2Async = ref.watch(bowlingScorecardProvider(k2));

    final bat1 = bat1Async.value ?? [];
    final bowl1 = bowl1Async.value ?? [];
    final bat2 = bat2Async.value ?? [];
    final bowl2 = bowl2Async.value ?? [];

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          child: Column(
            children: [
              // Share card preview (9:16 ratio)
              RepaintBoundary(
                key: _shareKey,
                child: _buildShareCard(bat1, bowl1, bat2, bowl2),
              ),
              const SizedBox(height: 16),
              // Info note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1D4ED8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Share button press చేయండి - ఇది 9:16 ratio లో beautiful scorecard image గా share అవుతుంది!',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Share Button
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _shareScorecard,
              icon: _isSharing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share_rounded, size: 22),
              label: Text(
                _isSharing ? 'Preparing...' : '📤  Share Scorecard',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareCard(
    List<BattingScorecardRow> bat1,
    List<BowlingScorecardRow> bowl1,
    List<BattingScorecardRow> bat2,
    List<BowlingScorecardRow> bowl2,
  ) {
    final match = widget.match;
    final i1 = widget.i1;
    final i2 = widget.i2;
    final momName = match.manOfTheMatchName ?? '';
    final resultText = match.resultText ?? _computeResult(match, i1, i2);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Column(
              children: [
                // App branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text('BORIGIVALASA CRICKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Match title
                Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEE, MMM dd yyyy').format(match.matchDate)} • ${match.venue.isNotEmpty ? match.venue : 'Cricket Ground'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Result pill
                if (resultText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 10, spreadRadius: 1)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Text(resultText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ─── Innings Cards ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                if (i1 != null)
                  _buildInningsCard(
                    label: '1st Innings',
                    teamName: i1.battingTeamId == match.teamAId ? match.teamA : match.teamB,
                    innings: i1,
                    batRows: bat1,
                    bowlRows: bowl1,
                  ),
                if (i1 != null && i2 != null) const SizedBox(height: 8),
                if (i2 != null)
                  _buildInningsCard(
                    label: '2nd Innings',
                    teamName: i2.battingTeamId == match.teamAId ? match.teamA : match.teamB,
                    innings: i2,
                    batRows: bat2,
                    bowlRows: bowl2,
                  ),
              ],
            ),
          ),

          // ─── Man of the Match ───
          if (momName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFEAB308).withOpacity(0.2), const Color(0xFFF59E0B).withOpacity(0.1)],
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
                        color: const Color(0xFFEAB308).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.5)),
                      ),
                      child: const Text('🏅', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYER OF THE MATCH', style: TextStyle(color: const Color(0xFFEAB308).withOpacity(0.8), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(momName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ─── Footer ───
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  'Borigivalasa Cricket Club',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsCard({
    required String label,
    required String teamName,
    required Innings innings,
    required List<BattingScorecardRow> batRows,
    required List<BowlingScorecardRow> bowlRows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
                    Text(teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: Text(
                    '${innings.runs}/${innings.wickets} (${innings.oversText})',
                    style: const TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Batting rows (top batters by runs)
          if (batRows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text('BATTING', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 9.5, letterSpacing: 0.8)),
                ],
              ),
            ),
            // Table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Batter', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w800))),
                  _headerCell('R'),
                  _headerCell('B'),
                  _headerCell('4s'),
                  _headerCell('6s'),
                  _headerCell('SR'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Top batters
            ...batRows.take(5).map((b) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      b.playerName.split(' ').first,
                      style: TextStyle(
                        color: b.runs >= 30 ? Colors.white : Colors.white.withOpacity(0.8),
                        fontWeight: b.runs >= 30 ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _dataCell('${b.runs}', highlight: b.runs >= 30),
                  _dataCell('${b.balls}'),
                  _dataCell('${b.fours}'),
                  _dataCell('${b.sixes}'),
                  _dataCell(b.balls > 0 ? ((b.runs / b.balls) * 100).toStringAsFixed(0) : '0'),
                ],
              ),
            )),
          ],

          // Bowling rows (top bowlers)
          if (bowlRows.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(height: 1, color: Colors.white.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text('BOWLING', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w900, fontSize: 9.5, letterSpacing: 0.8)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Bowler', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w800))),
                  _headerCell('O'),
                  _headerCell('M'),
                  _headerCell('R'),
                  _headerCell('W'),
                  _headerCell('ER'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            ...bowlRows.take(4).map((b) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      b.playerName.split(' ').first,
                      style: TextStyle(
                        color: b.wickets >= 2 ? Colors.white : Colors.white.withOpacity(0.8),
                        fontWeight: b.wickets >= 2 ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _dataCell(b.oversText),
                  _dataCell('${b.maidens}'),
                  _dataCell('${b.runs}'),
                  _dataCell('${b.wickets}', highlight: b.wickets >= 2),
                  _dataCell(b.economy.toStringAsFixed(1)),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(String label) {
    return Expanded(
      child: Center(
        child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _dataCell(String value, {bool highlight = false}) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF6EE7B7) : Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _computeResult(MatchModel match, Innings? i1, Innings? i2) {
    if (i1 != null && i2 != null) {
      if (i2.runs > i1.runs) {
        final rem = 10 - i2.wickets;
        final battingTeam = i2.battingTeamId == match.teamAId ? match.teamA : match.teamB;
        return '$battingTeam won by $rem wickets';
      } else if (i1.runs > i2.runs) {
        final rem = i1.runs - i2.runs;
        final battingTeam = i1.battingTeamId == match.teamAId ? match.teamA : match.teamB;
        return '$battingTeam won by $rem runs';
      } else {
        return 'Match Tied';
      }
    }
    return match.resultText ?? '';
  }
}
