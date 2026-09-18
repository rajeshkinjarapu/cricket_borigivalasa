import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../providers/scoring_providers.dart';

class InningsSetupScreen extends ConsumerStatefulWidget {
  const InningsSetupScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.inningsNumber,
    this.targetRuns,
  });

  final String tournamentId;
  final String matchId;
  final int inningsNumber;
  final int? targetRuns;

  @override
  ConsumerState<InningsSetupScreen> createState() => _InningsSetupScreenState();
}

class _InningsSetupScreenState extends ConsumerState<InningsSetupScreen> {
  String? _strikerId;
  String? _nonStrikerId;
  String? _bowlerId;
  bool _isSaving = false;

  Future<void> _startInnings() async {
    if (_strikerId == null || _nonStrikerId == null || _bowlerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all players')));
      return;
    }
    if (_strikerId == _nonStrikerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Striker and Non-Striker cannot be the same')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final match = ref.read(matchDetailProvider((
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      ))).value;
      if (match == null) return;

      final battingFirstTeamId = match.tossDecision == TossDecision.bat
          ? match.tossWinnerId!
          : (match.tossWinnerId == match.teamAId ? match.teamBId : match.teamAId);

      String batId, bowlId;
      if (widget.inningsNumber == 1) {
        batId = battingFirstTeamId;
        bowlId = batId == match.teamAId ? match.teamBId : match.teamAId;
      } else {
        batId = battingFirstTeamId == match.teamAId ? match.teamBId : match.teamAId;
        bowlId = battingFirstTeamId;
      }

      final teams = ref.read(tournamentTeamsProvider(widget.tournamentId)).value ?? [];
      final batTeam = teams.firstWhere((t) => t.id == batId);
      final bowlTeam = teams.firstWhere((t) => t.id == bowlId);

      final batPlayers = ref.read(teamPlayersProvider(batId)).value ?? [];
      final bowlPlayers = ref.read(teamPlayersProvider(bowlId)).value ?? [];

      await ref.read(scoringRepositoryProvider).initInnings(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: widget.inningsNumber,
        battingTeam: batTeam,
        bowlingTeam: bowlTeam,
        openingStriker: batPlayers.firstWhere((p) => p.id == _strikerId),
        openingNonStriker: batPlayers.firstWhere((p) => p.id == _nonStrikerId),
        openingBowler: bowlPlayers.firstWhere((p) => p.id == _bowlerId),
        targetRuns: widget.targetRuns,
      );

      if (mounted) {
        context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    ))).value;
    if (match == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final battingFirstTeamId = match.tossDecision == TossDecision.bat
        ? match.tossWinnerId!
        : (match.tossWinnerId == match.teamAId ? match.teamBId : match.teamAId);

    String batId, bowlId;
    if (widget.inningsNumber == 1) {
      batId = battingFirstTeamId;
      bowlId = batId == match.teamAId ? match.teamBId : match.teamAId;
    } else {
      batId = battingFirstTeamId == match.teamAId ? match.teamBId : match.teamAId;
      bowlId = battingFirstTeamId;
    }

    final batTeamName = batId == match.teamAId ? match.teamA : match.teamB;
    final bowlTeamName = bowlId == match.teamAId ? match.teamA : match.teamB;

    final batPlayersAsync = ref.watch(teamPlayersProvider(batId));
    final bowlPlayersAsync = ref.watch(teamPlayersProvider(bowlId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Innings ${widget.inningsNumber} Setup', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.targetRuns != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Target: ${widget.targetRuns} runs',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),

            // Batting Team Selection
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sports_cricket, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text('Batting: $batTeamName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPlayerDropdown(
                      label: 'Striker',
                      asyncPlayers: batPlayersAsync,
                      selectedId: _strikerId,
                      excludeId: _nonStrikerId,
                      onChanged: (v) => setState(() => _strikerId = v),
                    ),
                    const SizedBox(height: 16),
                    _buildPlayerDropdown(
                      label: 'Non-Striker',
                      asyncPlayers: batPlayersAsync,
                      selectedId: _nonStrikerId,
                      excludeId: _strikerId,
                      onChanged: (v) => setState(() => _nonStrikerId = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bowling Team Selection
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_baseball, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Bowling: $bowlTeamName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPlayerDropdown(
                      label: 'Opening Bowler',
                      asyncPlayers: bowlPlayersAsync,
                      selectedId: _bowlerId,
                      onChanged: (v) => setState(() => _bowlerId = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _startInnings,
                icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.play_arrow),
                label: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('LET\'S PLAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown({
    required String label,
    required AsyncValue<List<dynamic>> asyncPlayers,
    required String? selectedId,
    String? excludeId,
    required ValueChanged<String?> onChanged,
  }) {
    return asyncPlayers.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (players) {
        final items = players.where((p) => p.id != excludeId).toList();
        return DropdownButtonFormField<String>(
          value: selectedId,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: items.map((p) => DropdownMenuItem<String>(value: p.id as String, child: Text(p.name as String))).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
