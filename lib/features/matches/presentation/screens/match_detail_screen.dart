import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({super.key, required this.tournamentId, required this.matchId});
  final String tournamentId;
  final String matchId;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  String? _selectedTossWinner;
  TossDecision? _selectedDecision;
  bool _isSavingToss = false;

  Future<void> _saveToss(Match match) async {
    if (_selectedTossWinner == null || _selectedDecision == null) return;
    setState(() => _isSavingToss = true);
    final ok = await ref.read(matchControllerProvider.notifier).setToss(
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
      tossWinnerTeamId: _selectedTossWinner!,
      tossDecision: _selectedDecision!,
    );
    if (mounted) {
      setState(() => _isSavingToss = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toss recorded successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    )));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return matchAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (match) {
        if (match == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Match not found')));

        final isTossDone = match.hasToss;
        final tossWinnerName = match.tossWinnerId == match.teamAId ? match.teamA : match.teamB;
        final battingFirstTeam = match.tossDecision == TossDecision.bat
            ? (match.tossWinnerId == match.teamAId ? match.teamA : match.teamB)
            : (match.tossWinnerId == match.teamAId ? match.teamB : match.teamA);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('Match Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (isAdmin && match.status == MatchStatus.scheduled)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/edit'),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Scoreboard Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          match.status.label.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(match.teamA, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('VS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Expanded(
                            child: Text(match.teamB, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${match.venue} • ${match.totalOvers} Overs',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(match.matchDate),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // SCHEDULED MATCH STATE
                if (match.status == MatchStatus.scheduled) ...[
                  if (!isTossDone && isAdmin)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.monetization_on, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Toss Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('Who won the toss?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildChoiceChip(match.teamA, _selectedTossWinner == match.teamAId, () => setState(() => _selectedTossWinner = match.teamAId))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildChoiceChip(match.teamB, _selectedTossWinner == match.teamBId, () => setState(() => _selectedTossWinner = match.teamBId))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('What did they choose?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildChoiceChip('Batting', _selectedDecision == TossDecision.bat, () => setState(() => _selectedDecision = TossDecision.bat))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildChoiceChip('Bowling', _selectedDecision == TossDecision.bowl, () => setState(() => _selectedDecision = TossDecision.bowl))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: (_selectedTossWinner != null && _selectedDecision != null && !_isSavingToss) ? () => _saveToss(match) : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: _isSavingToss
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save Toss Result', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (isTossDone)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            '$tossWinnerName won the toss and elected to ${match.tossDecision!.label.toLowerCase()}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('$battingFirstTeam will bat first.', style: TextStyle(color: Colors.green.shade700)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (isTossDone && isAdmin)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring');
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('START SCORING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                ],

                // LIVE MATCH STATE
                if (match.status == MatchStatus.live) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE MATCH IN PROGRESS',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring'),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('OPEN LIVE SCORER CONSOLE'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/live'),
                    icon: const Icon(Icons.visibility),
                    label: const Text('WATCH LIVE STREAM & BALLS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scorecard'),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Scorecard'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/charts'),
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Charts'),
                        ),
                      ),
                    ],
                  ),
                ],

                // COMPLETED MATCH STATE
                if (match.status == MatchStatus.completed) ...[
                  Card(
                    color: Colors.amber.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.amber.shade300)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            match.resultText ?? 'Match Completed',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/summary'),
                    icon: const Icon(Icons.sports_score),
                    label: const Text('VIEW MATCH SUMMARY'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scorecard'),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Scorecard'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/charts'),
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Charts'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
