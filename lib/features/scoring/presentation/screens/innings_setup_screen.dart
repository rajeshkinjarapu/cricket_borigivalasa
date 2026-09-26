import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/data/models/team.dart';
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

  Future<void> _startInnings(List<Player> batPlayers, List<Player> bowlPlayers, String batId, String bowlId, String batTeamName, String bowlTeamName, {bool isCounty = false}) async {
    if (_strikerId == null || _bowlerId == null || (!isCounty && _nonStrikerId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all players')));
      return;
    }
    if (!isCounty && _strikerId == _nonStrikerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Striker and Non-Striker cannot be the same')));
      return;
    }

    final openingStriker = batPlayers.where((p) => p.id == _strikerId).firstOrNull;
    final openingNonStriker = isCounty ? null : batPlayers.where((p) => p.id == _nonStrikerId).firstOrNull;
    final openingBowler = bowlPlayers.where((p) => p.id == _bowlerId).firstOrNull;

    if (openingStriker == null || (!isCounty && openingNonStriker == null) || openingBowler == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected players could not be found.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final teams = ref.read(teamsProvider).value ?? [];
      final batTeam = teams.where((t) => t.id == batId).firstOrNull ?? Team(id: batId, name: batTeamName, shortName: '', tournamentIds: [widget.tournamentId]);
      final bowlTeam = teams.where((t) => t.id == bowlId).firstOrNull ?? Team(id: bowlId, name: bowlTeamName, shortName: '', tournamentIds: [widget.tournamentId]);

      await ref.read(scoringRepositoryProvider).initInnings(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        inningsNumber: widget.inningsNumber,
        battingTeam: batTeam,
        bowlingTeam: bowlTeam,
        openingStriker: openingStriker,
        openingNonStriker: openingNonStriker,
        openingBowler: openingBowler,
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

    final batPlayers = batPlayersAsync.value ?? [];
    final bowlPlayers = bowlPlayersAsync.value ?? [];

    final isCounty = match.liveScore?['isCounty'] == true;

    if (isCounty && !_isSaving) {
      if (batPlayers.isNotEmpty && bowlPlayers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _strikerId = batPlayers.first.id;
          _nonStrikerId = null;
          _bowlerId = bowlPlayers.first.id;
          _startInnings(batPlayers, bowlPlayers, batId, bowlId, batTeamName, bowlTeamName, isCounty: true);
        });
      }
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              SizedBox(height: 16),
              Text('Starting County Duel...', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final hasEnoughPlayers = batPlayers.length >= 2 && bowlPlayers.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Innings ${widget.inningsNumber} Setup',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.targetRuns != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_rounded, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Text(
                      'Target: ${widget.targetRuns} runs',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),

            // Incomplete squad warning banner if players are missing
            if (!hasEnoughPlayers)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Players Missing for Innings',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Batting team ($batTeamName) needs at least 2 players (has ${batPlayers.length}). Bowling team ($bowlTeamName) needs at least 1 player (has ${bowlPlayers.length}).',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (batPlayers.length < 2)
                          ElevatedButton.icon(
                            onPressed: () => context.push('/teams/$batId'),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text('Add to $batTeamName'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        if (bowlPlayers.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => context.push('/teams/$bowlId'),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text('Add to $bowlTeamName'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            // Batting Team Selection
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_cricket, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Text(
                          'Batting: $batTeamName',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPlayerDropdown(
                      label: 'Opening Striker *',
                      asyncPlayers: batPlayersAsync,
                      selectedId: _strikerId,
                      excludeId: _nonStrikerId,
                      onChanged: (v) => setState(() => _strikerId = v),
                    ),
                    const SizedBox(height: 12),
                    _buildPlayerDropdown(
                      label: 'Opening Non-Striker *',
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
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_baseball, color: Color(0xFFEA580C)),
                        const SizedBox(width: 8),
                        Text(
                          'Bowling: $bowlTeamName',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPlayerDropdown(
                      label: 'Opening Bowler *',
                      asyncPlayers: bowlPlayersAsync,
                      selectedId: _bowlerId,
                      onChanged: (v) => setState(() => _bowlerId = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (_isSaving || !hasEnoughPlayers)
                    ? null
                    : () => _startInnings(batPlayers, bowlPlayers, batId, bowlId, batTeamName, bowlTeamName),
                icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.play_arrow_rounded),
                label: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('START INNINGS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEnoughPlayers ? const Color(0xFF16A34A) : const Color(0xFF94A34A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
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
    required AsyncValue<List<Player>> asyncPlayers,
    required String? selectedId,
    String? excludeId,
    required ValueChanged<String?> onChanged,
  }) {
    return asyncPlayers.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (players) {
        final items = players.where((p) => p.id != excludeId).toList();
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Text(
              'No players available. Please add players first.',
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          );
        }
        return DropdownButtonFormField<String>(
          value: items.any((p) => p.id == selectedId) ? selectedId : null,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.8),
            ),
          ),
          items: items.map((p) => DropdownMenuItem<String>(
            value: p.id,
            child: Text(
              p.name,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          )).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
