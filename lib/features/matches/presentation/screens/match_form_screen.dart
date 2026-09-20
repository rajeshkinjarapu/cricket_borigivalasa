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

  // Manual or Dropdown selection modes
  bool _manualTeamA = false;
  bool _manualTeamB = false;

  Team? _teamA;
  Team? _teamB;
  final _teamANameController = TextEditingController();
  final _teamBNameController = TextEditingController();

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
    _teamANameController.dispose();
    _teamBNameController.dispose();
    _oversController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _hydrate(MatchModel m, List<Team> teams) {
    if (_isLoaded) return;
    _isLoaded = true;
    _teamA = teams.where((t) => t.id == m.teamAId).firstOrNull;
    _teamB = teams.where((t) => t.id == m.teamBId).firstOrNull;
    if (_teamA == null) {
      _manualTeamA = true;
      _teamANameController.text = m.teamA;
    }
    if (_teamB == null) {
      _manualTeamB = true;
      _teamBNameController.text = m.teamB;
    }
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

  /// Resolve or auto-create a team if entered manually
  Future<({String id, String name})> _resolveTeam({
    required bool isManual,
    required Team? selectedTeam,
    required String manualName,
    required List<Team> existingTeams,
  }) async {
    if (!isManual && selectedTeam != null) {
      return (id: selectedTeam.id, name: selectedTeam.name);
    }

    final trimmed = manualName.trim();
    final existingMatch = existingTeams.where((t) => t.name.trim().toLowerCase() == trimmed.toLowerCase()).firstOrNull;
    if (existingMatch != null) {
      return (id: existingMatch.id, name: existingMatch.name);
    }

    // Auto-create in teams collection if it doesn't exist
    final teamController = ref.read(teamControllerProvider.notifier);
    final short = trimmed.length <= 4
        ? trimmed.toUpperCase()
        : trimmed.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(3).join();

    final newTeamId = await teamController.create(Team(
      id: '',
      name: trimmed,
      shortName: short.isNotEmpty ? short : 'TM',
    ));

    return (id: newTeamId ?? 'team_${DateTime.now().millisecondsSinceEpoch}', name: trimmed);
  }

  Future<void> _save({
    required String effectiveTournamentId,
    required List<Team> existingTeams,
    required bool startImmediately,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final nameA = _manualTeamA ? _teamANameController.text.trim() : _teamA?.name ?? '';
    final nameB = _manualTeamB ? _teamBNameController.text.trim() : _teamB?.name ?? '';

    if (nameA.isEmpty || nameB.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter both Team names.')),
      );
      return;
    }

    if (nameA.toLowerCase() == nameB.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team A and Team B cannot be the same.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final controller = ref.read(matchControllerProvider.notifier);
    final overs = int.tryParse(_oversController.text.trim()) ?? 20;

    try {
      final teamAResolved = await _resolveTeam(
        isManual: _manualTeamA,
        selectedTeam: _teamA,
        manualName: _teamANameController.text,
        existingTeams: existingTeams,
      );

      final teamBResolved = await _resolveTeam(
        isManual: _manualTeamB,
        selectedTeam: _teamB,
        manualName: _teamBNameController.text,
        existingTeams: existingTeams,
      );

      String? targetMatchId = widget.matchId;

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
          teamAId: teamAResolved.id,
          teamBId: teamBResolved.id,
          teamA: teamAResolved.name,
          teamB: teamBResolved.name,
          totalOvers: overs,
          venue: _venueController.text.trim(),
          matchDate: _matchDate,
        ));
      } else {
        targetMatchId = await controller.create(MatchModel(
          id: '',
          tournamentId: effectiveTournamentId,
          teamAId: teamAResolved.id,
          teamBId: teamBResolved.id,
          teamA: teamAResolved.name,
          teamB: teamBResolved.name,
          status: MatchStatus.scheduled,
          totalOvers: overs,
          venue: _venueController.text.trim(),
          matchDate: _matchDate,
        ));
      }

      if (mounted) {
        setState(() => _isSaving = false);

        if (startImmediately && targetMatchId != null && targetMatchId.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${teamAResolved.name} vs ${teamBResolved.name} match created! Select Playing XI...'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          // Navigate directly to match squads / Playing XI selection page
          context.pushReplacement('/tournaments/$effectiveTournamentId/matches/$targetMatchId/squads');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit ? 'Match updated successfully!' : 'Match scheduled successfully!'),
              backgroundColor: const Color(0xFF1E3A8A),
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/matches-list');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving match: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentsAsync = ref.watch(allTournamentsProvider);
    final allTeamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          widget.isEdit ? 'Edit Match' : 'Create Match',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: tournamentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
          error: (e, _) => Center(child: Text('Error loading tournaments: $e')),
          data: (tournaments) {
            if (_selectedTournamentId == null && tournaments.isNotEmpty) {
              _selectedTournamentId = tournaments.first.id;
            }

            final effectiveTournamentId = _selectedTournamentId ?? (tournaments.isNotEmpty ? tournaments.first.id : 'default_tournament');

            return allTeamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
              error: (e, _) => Center(child: Text('Error loading teams: $e')),
              data: (teams) {
                if (widget.isEdit && widget.tournamentId != null) {
                  final m = ref.watch(matchDetailProvider((
                    tournamentId: widget.tournamentId!,
                    matchId: widget.matchId!,
                  ))).value;
                  if (m != null) _hydrate(m, teams);
                }

                // If no registered teams exist, default to manual entry
                if (teams.isEmpty) {
                  _manualTeamA = true;
                  _manualTeamB = true;
                }

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // Tournament Selector
                      if (tournaments.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedTournamentId,
                            decoration: InputDecoration(
                              labelText: 'Tournament',
                              prefixIcon: const Icon(Icons.emoji_events_rounded, color: Color(0xFF1E3A8A)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            items: tournaments.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedTournamentId = val),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── VERSUS CARD (DROPDOWN + MANUAL ENTRY) ──
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select or Enter Teams',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 14),

                            // ── TEAM A SECTION ──
                            _buildTeamField(
                              teamLabel: 'Team A (Batting / Home)',
                              isManual: _manualTeamA,
                              selectedTeam: _teamA,
                              nameController: _teamANameController,
                              teams: teams,
                              onToggleManual: () {
                                setState(() {
                                  _manualTeamA = !_manualTeamA;
                                  if (_manualTeamA && _teamA != null) {
                                    _teamANameController.text = _teamA!.name;
                                  }
                                });
                              },
                              onSelectTeam: (t) => setState(() => _teamA = t),
                            ),

                            // VS Badge
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 6),
                                    ],
                                  ),
                                  child: const Text(
                                    'VS',
                                    style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),

                            // ── TEAM B SECTION ──
                            _buildTeamField(
                              teamLabel: 'Team B (Bowling / Away)',
                              isManual: _manualTeamB,
                              selectedTeam: _teamB,
                              nameController: _teamBNameController,
                              teams: teams,
                              onToggleManual: () {
                                setState(() {
                                  _manualTeamB = !_manualTeamB;
                                  if (_manualTeamB && _teamB != null) {
                                    _teamBNameController.text = _teamB!.name;
                                  }
                                });
                              },
                              onSelectTeam: (t) => setState(() => _teamB = t),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── MATCH SETTINGS CARD ──
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Match Settings',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 14),

                            // Total Overs
                            TextFormField(
                              controller: _oversController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Total Overs (e.g. 10, 20)',
                                prefixIcon: const Icon(Icons.timelapse_rounded, color: Color(0xFF1E3A8A)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid overs' : null,
                            ),
                            const SizedBox(height: 14),

                            // Venue / Ground
                            TextFormField(
                              controller: _venueController,
                              decoration: InputDecoration(
                                labelText: 'Venue / Ground',
                                prefixIcon: const Icon(Icons.place_rounded, color: Color(0xFF1E3A8A)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Date & Time Picker Tile
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
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
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
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
                      const SizedBox(height: 22),

                      // ── 2 ACTION BUTTONS: SCHEDULE & START MATCH NOW ──
                      Column(
                        children: [
                          // 1. START MATCH NOW (Primary Action)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : () => _save(
                                effectiveTournamentId: effectiveTournamentId,
                                existingTeams: teams,
                                startImmediately: true,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                              label: const Text(
                                'START MATCH NOW',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A), // Emerald Green
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: const Color(0xFF16A34A).withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. SCHEDULE MATCH (For Later)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isSaving ? null : () => _save(
                                effectiveTournamentId: effectiveTournamentId,
                                existingTeams: teams,
                                startImmediately: false,
                              ),
                              icon: const Icon(Icons.schedule_rounded, color: Color(0xFF1E3A8A), size: 20),
                              label: const Text(
                                'Schedule Match For Later',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildTeamField({
    required String teamLabel,
    required bool isManual,
    required Team? selectedTeam,
    required TextEditingController nameController,
    required List<Team> teams,
    required VoidCallback onToggleManual,
    required ValueChanged<Team?> onSelectTeam,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              teamLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
            if (teams.isNotEmpty)
              TextButton.icon(
                onPressed: onToggleManual,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                icon: Icon(isManual ? Icons.list_rounded : Icons.edit_note_rounded, size: 16, color: const Color(0xFF2563EB)),
                label: Text(
                  isManual ? 'Select from list' : 'Type manual name',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (isManual || teams.isEmpty)
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Enter team name (e.g. Tigers)',
              prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF1E3A8A)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter team name' : null,
          )
        else
          DropdownButtonFormField<Team>(
            value: selectedTeam,
            decoration: InputDecoration(
              hintText: 'Choose team',
              prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF1E3A8A)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
            onChanged: onSelectTeam,
            validator: (v) => v == null ? 'Select a team' : null,
          ),
      ],
    );
  }
}
