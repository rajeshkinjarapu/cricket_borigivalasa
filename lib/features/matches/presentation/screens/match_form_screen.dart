import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../tournaments/data/models/tournament.dart';
import '../../../tournaments/presentation/providers/tournament_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({super.key, this.tournamentId, this.matchId});
  final String? tournamentId;
  final String? matchId;

  bool get isEdit => matchId != null;

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTournamentId;
  Team? _teamA;
  Team? _teamB;
  final _oversController = TextEditingController(text: '20');
  final _venueController = TextEditingController(text: 'Borigivalasa Cricket Ground');
  DateTime _matchDate = DateTime.now();

  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = (widget.tournamentId?.isNotEmpty == true) ? widget.tournamentId : null;
  }

  @override
  void dispose() {
    _oversController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _hydrate(MatchModel m, List<Team> teams) {
    if (_isLoaded) return;
    _isLoaded = true;
    _teamA = teams.where((t) => t.id == m.teamAId).firstOrNull;
    _teamB = teams.where((t) => t.id == m.teamBId).firstOrNull;
    _oversController.text = m.totalOvers.toString();
    _venueController.text = m.venue;
    _matchDate = m.matchDate;
    if (_selectedTournamentId == null && m.tournamentId.isNotEmpty) {
      _selectedTournamentId = m.tournamentId;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_matchDate),
      );
      if (time != null && mounted) {
        setState(() {
          _matchDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _save(String effectiveTournamentId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_teamA == null || _teamB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both teams.')));
      return;
    }
    if (_teamA!.id == _teamB!.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team A and Team B cannot be the same.')));
      return;
    }

    setState(() => _isSaving = true);
    final controller = ref.read(matchControllerProvider.notifier);
    final overs = int.tryParse(_oversController.text.trim()) ?? 20;

    if (widget.isEdit) {
      final existing = ref.read(matchDetailProvider((
        tournamentId: effectiveTournamentId,
        matchId: widget.matchId!,
      ))).value;
      if (existing == null) {
        setState(() => _isSaving = false);
        return;
      }
      await controller.update(existing.copyWith(
        teamAId: _teamA!.id,
        teamBId: _teamB!.id,
        teamA: _teamA!.name,
        teamB: _teamB!.name,
        totalOvers: overs,
        venue: _venueController.text.trim(),
        matchDate: _matchDate,
      ));
    } else {
      await controller.create(MatchModel(
        id: '',
        tournamentId: effectiveTournamentId,
        teamAId: _teamA!.id,
        teamBId: _teamB!.id,
        teamA: _teamA!.name,
        teamB: _teamB!.name,
        status: MatchStatus.scheduled,
        totalOvers: overs,
        venue: _venueController.text.trim(),
        matchDate: _matchDate,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isEdit ? 'Match updated!' : 'Match scheduled successfully!'),
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(allTournamentsProvider);
    final allTeamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isEdit ? 'Edit Match' : 'Schedule Match',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: tournamentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
          error: (e, _) => Center(child: Text('Error loading tournaments: $e')),
          data: (tournaments) {
            // Determine effective tournament ID
            if (_selectedTournamentId == null && tournaments.isNotEmpty) {
              _selectedTournamentId = tournaments.first.id;
            }

            final effectiveTournamentId = _selectedTournamentId ?? (tournaments.isNotEmpty ? tournaments.first.id : 'default_tournament');

            return allTeamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
              error: (e, _) => Center(child: Text('Error loading teams: $e')),
              data: (teams) {
                if (teams.length < 2) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.groups_rounded, size: 56, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'At least 2 teams required!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please create at least 2 teams first before scheduling a match.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/teams/new'),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Team Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (widget.isEdit && widget.tournamentId != null) {
                  final m = ref.watch(matchDetailProvider((
                    tournamentId: widget.tournamentId!,
                    matchId: widget.matchId!,
                  ))).value;
                  if (m != null) _hydrate(m, teams);
                }

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Tournament Selector
                      if (tournaments.isNotEmpty) ...[
                        Card(
                          elevation: 0.5,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: DropdownButtonFormField<String>(
                              value: _selectedTournamentId,
                              decoration: InputDecoration(
                                labelText: 'Select Tournament',
                                prefixIcon: const Icon(Icons.emoji_events_rounded, color: Color(0xFF1E3A8A)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: tournaments.map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name, overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedTournamentId = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // VERSUS SECTION
                      Card(
                        elevation: 0.5,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              DropdownButtonFormField<Team>(
                                value: _teamA,
                                decoration: InputDecoration(
                                  labelText: 'Team A (Batting / Home)',
                                  prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1E3A8A)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                                onChanged: (v) => setState(() => _teamA = v),
                                validator: (v) => v == null ? 'Select Team A' : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 6),
                                    ],
                                  ),
                                  child: const Text(
                                    'VS',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                              ),
                              DropdownButtonFormField<Team>(
                                value: _teamB,
                                decoration: InputDecoration(
                                  labelText: 'Team B (Bowling / Away)',
                                  prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1E3A8A)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                                onChanged: (v) => setState(() => _teamB = v),
                                validator: (v) => v == null ? 'Select Team B' : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // MATCH CONFIG SECTION
                      Card(
                        elevation: 0.5,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Match Settings',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _oversController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Total Overs (e.g. 10, 20)',
                                  prefixIcon: const Icon(Icons.timelapse_rounded, color: Color(0xFF1E3A8A)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid overs' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _venueController,
                                decoration: InputDecoration(
                                  labelText: 'Venue / Ground',
                                  prefixIcon: const Icon(Icons.place_rounded, color: Color(0xFF1E3A8A)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: _selectDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A)),
                                          const SizedBox(width: 10),
                                          Text(
                                            DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_matchDate),
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _save(effectiveTournamentId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Text(
                                  widget.isEdit ? 'Update Match' : 'Schedule Match Now',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
