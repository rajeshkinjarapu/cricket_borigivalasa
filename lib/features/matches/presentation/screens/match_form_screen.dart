import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({super.key, required this.tournamentId, this.matchId});
  final String tournamentId;
  final String? matchId;

  bool get isEdit => matchId != null;

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Team? _teamA;
  Team? _teamB;
  final _oversController = TextEditingController(text: '20');
  final _venueController = TextEditingController();
  DateTime _matchDate = DateTime.now();
  
  bool _isSaving = false;
  bool _isLoaded = false;

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

  Future<void> _save() async {
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
        tournamentId: widget.tournamentId,
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
        tournamentId: widget.tournamentId,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEdit ? 'Match updated!' : 'Match scheduled successfully!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Match' : 'Schedule Match', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (teams) {
            if (teams.length < 2) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_cricket, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Not enough teams!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('You need at least 2 teams in the tournament to schedule a match.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (widget.isEdit) {
              final m = ref.watch(matchDetailProvider((
                tournamentId: widget.tournamentId,
                matchId: widget.matchId!,
              ))).value;
              if (m != null) _hydrate(m, teams);
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // VERSUS SECTION
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          DropdownButtonFormField<Team>(
                            value: _teamA,
                            decoration: InputDecoration(
                              labelText: 'Team A (Home)',
                              prefixIcon: const Icon(Icons.shield),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                            onChanged: (v) => setState(() => _teamA = v),
                            validator: (v) => v == null ? 'Select Team A' : null,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.black87,
                              child: Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          DropdownButtonFormField<Team>(
                            value: _teamB,
                            decoration: InputDecoration(
                              labelText: 'Team B (Away)',
                              prefixIcon: const Icon(Icons.shield_outlined),
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
                  const SizedBox(height: 16),

                  // MATCH CONFIG SECTION
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Match Config', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _oversController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Total Overs (per innings)',
                              prefixIcon: const Icon(Icons.timeline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid overs' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _venueController,
                            decoration: InputDecoration(
                              labelText: 'Venue / Ground Name',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter venue' : null,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date & Time',
                                prefixIcon: const Icon(Icons.calendar_month),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(_matchDate)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isEdit ? 'Update Match' : 'Schedule Match', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
