import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../tournaments/data/models/tournament.dart';
import '../../../tournaments/presentation/providers/tournament_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';

enum MatchTypeOption {
  normal,
  county,
}

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

  // ── MATCH TYPE (Normal vs County) ──
  MatchTypeOption _matchType = MatchTypeOption.normal;

  // ── NORMAL MATCH CONTROLLERS & STATE ──
  bool _manualTeamA = false;
  bool _manualTeamB = false;
  Team? _teamA;
  Team? _teamB;
  final _teamANameController = TextEditingController();
  final _teamBNameController = TextEditingController();
  final _oversController = TextEditingController(text: '20');
  final _venueController = TextEditingController(text: 'Chintathota Cricket Ground');

  // ── COUNTY MATCH CONTROLLERS & STATE ──
  int _countyPlayerCount = 2; // 2 for 1v1 (Single duel), 4 for 2v2 (Pairs duel)
  final _countyBatsman1Controller = TextEditingController();
  final _countyBowler1Controller = TextEditingController();
  final _countyBatsman2Controller = TextEditingController();
  final _countyBowler2Controller = TextEditingController();
  Player? _countyBatsman1Player;
  Player? _countyBowler1Player;
  Player? _countyBatsman2Player;
  Player? _countyBowler2Player;

  final _countyTargetController = TextEditingController(text: '30');
  final _countyBallsController = TextEditingController(text: '12');
  final _countyWicketsController = TextEditingController(text: '1');
  final _countyVenueController = TextEditingController(text: 'Chintathota Cricket Ground');

  // ── COMMON STATE ──
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

    _countyBatsman1Controller.dispose();
    _countyBowler1Controller.dispose();
    _countyBatsman2Controller.dispose();
    _countyBowler2Controller.dispose();
    _countyTargetController.dispose();
    _countyBallsController.dispose();
    _countyWicketsController.dispose();
    _countyVenueController.dispose();
    super.dispose();
  }

  void _hydrate(MatchModel m, List<Team> teams) {
    if (_isLoaded) return;
    _isLoaded = true;

    final isCounty = m.liveScore?['matchType'] == 'county' || m.liveScore?['isCounty'] == true;
    if (isCounty) {
      _matchType = MatchTypeOption.county;
      _countyPlayerCount = m.liveScore?['countyMode'] == '2v2' ? 4 : 2;
      _countyTargetController.text = (m.liveScore?['targetRuns'] ?? 30).toString();
      _countyBallsController.text = (m.liveScore?['totalBalls'] ?? 12).toString();
      _countyWicketsController.text = (m.liveScore?['wickets'] ?? 1).toString();
      _countyBatsman1Controller.text = m.liveScore?['batsman1'] ?? m.teamA;
      _countyBowler1Controller.text = m.liveScore?['bowler1'] ?? m.teamB;
      if (m.liveScore?['batsman2'] != null) {
        _countyBatsman2Controller.text = m.liveScore!['batsman2'];
      }
      if (m.liveScore?['bowler2'] != null) {
        _countyBowler2Controller.text = m.liveScore!['bowler2'];
      }
      _countyVenueController.text = m.venue;
    } else {
      _matchType = MatchTypeOption.normal;
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
    }

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
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
    bool isCountyTeam = false,
  }) async {
    if (!isManual && selectedTeam != null) {
      return (id: selectedTeam.id, name: selectedTeam.name);
    }

    final trimmed = manualName.trim();
    final existingMatch = existingTeams.where((t) => t.name.trim().toLowerCase() == trimmed.toLowerCase()).firstOrNull;
    if (existingMatch != null) {
      return (id: existingMatch.id, name: existingMatch.name);
    }

    final teamController = ref.read(teamControllerProvider.notifier);
    final short = trimmed.length <= 4
        ? trimmed.toUpperCase()
        : trimmed.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(3).join();

    final newTeamId = await teamController.create(Team(
      id: '',
      name: trimmed,
      shortName: short.isNotEmpty ? short : 'TM',
      isCounty: isCountyTeam,
    ));

    return (id: newTeamId ?? 'team_${DateTime.now().millisecondsSinceEpoch}', name: trimmed);
  }

  /// Opens a modern bottom sheet to pick any registered club player
  void _openPlayerPicker({
    required String title,
    required Function(Player) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final allPlayers = ref.watch(allPlayersProvider).value ?? [];
            String searchQuery = '';

            return StatefulBuilder(
              builder: (context, setModalState) {
                final filtered = allPlayers.where((p) {
                  return p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      (p.phoneNumber != null && p.phoneNumber!.contains(searchQuery));
                }).toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.sports_cricket_rounded, color: Color(0xFFD97706), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),

                      // Search Input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search player name or phone...',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A8A)),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setModalState(() => searchQuery = val),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      allPlayers.isEmpty ? 'No registered players found' : 'No matching players found',
                                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (context, index) {
                                  final p = filtered[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.12),
                                      child: Text(
                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                                      ),
                                    ),
                                    title: Text(
                                      p.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                    ),
                                    subtitle: Text(
                                      '${p.role.label}${p.phoneNumber != null ? ' • ${p.phoneNumber}' : ''}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                                    onTap: () {
                                      onSelect(p);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _save({
    required String effectiveTournamentId,
    required List<Team> existingTeams,
    required bool startImmediately,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    // ─────────────────────────────────────────────────────────────
    // 1. COUNTY MATCH LOGIC
    // ─────────────────────────────────────────────────────────────
    if (_matchType == MatchTypeOption.county) {
      final bat1 = _countyBatsman1Controller.text.trim();
      final bowl1 = _countyBowler1Controller.text.trim();

      if (bat1.isEmpty || bowl1.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter or select both Batsman and Bowler names.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      String nameA = bat1;
      String nameB = bowl1;
      String? bat2;
      String? bowl2;

      if (_countyPlayerCount == 4) {
        bat2 = _countyBatsman2Controller.text.trim();
        bowl2 = _countyBowler2Controller.text.trim();
        if (bat2.isEmpty || bowl2.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter all 4 player names for 2 vs 2 County.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
        nameA = '$bat1 & $bat2';
        nameB = '$bowl1 & $bowl2';
      }

      if (nameA.toLowerCase() == nameB.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batsman and Bowler cannot have the exact same name.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final targetRuns = int.tryParse(_countyTargetController.text.trim()) ?? 30;
      final totalBalls = int.tryParse(_countyBallsController.text.trim()) ?? 12;
      final wickets = int.tryParse(_countyWicketsController.text.trim()) ?? 1;
      final overs = (totalBalls / 6.0).ceil();
      final venue = _countyVenueController.text.trim().isNotEmpty
          ? _countyVenueController.text.trim()
          : 'Chintathota Cricket Ground';

      setState(() => _isSaving = true);
      final controller = ref.read(matchControllerProvider.notifier);

      try {
        final teamAResolved = await _resolveTeam(
          isManual: true,
          selectedTeam: null,
          manualName: nameA,
          existingTeams: existingTeams,
          isCountyTeam: true,
        );

        final teamBResolved = await _resolveTeam(
          isManual: true,
          selectedTeam: null,
          manualName: nameB,
          existingTeams: existingTeams,
          isCountyTeam: true,
        );

        // Auto-associate batsman & bowler in player records
        try {
          final playerRepo = ref.read(playerRepositoryProvider);
          if (_countyBatsman1Player != null) {
            await playerRepo.addPlayerToTeam(_countyBatsman1Player!.id, teamAResolved.id);
          } else {
            final pid = await playerRepo.create(Player(
              id: '',
              name: bat1,
              teamId: teamAResolved.id,
              role: PlayerRole.batter,
              battingStyle: BattingStyle.rightHand,
              bowlingStyle: BowlingStyle.rightArmMedium,
              stats: PlayerStats(),
            ));
            _countyBatsman1Player = Player(id: pid, name: bat1, teamId: teamAResolved.id, role: PlayerRole.batter, stats: PlayerStats());
          }

          if (_countyBowler1Player != null) {
            await playerRepo.addPlayerToTeam(_countyBowler1Player!.id, teamBResolved.id);
          } else {
            final pid = await playerRepo.create(Player(
              id: '',
              name: bowl1,
              teamId: teamBResolved.id,
              role: PlayerRole.bowler,
              battingStyle: BattingStyle.rightHand,
              bowlingStyle: BowlingStyle.rightArmMedium,
              stats: PlayerStats(),
            ));
            _countyBowler1Player = Player(id: pid, name: bowl1, teamId: teamBResolved.id, role: PlayerRole.bowler, stats: PlayerStats());
          }

          if (_countyPlayerCount == 4 && bat2 != null && bowl2 != null) {
            if (_countyBatsman2Player != null) {
              await playerRepo.addPlayerToTeam(_countyBatsman2Player!.id, teamAResolved.id);
            } else {
              final pid = await playerRepo.create(Player(
                id: '',
                name: bat2,
                teamId: teamAResolved.id,
                role: PlayerRole.batter,
                battingStyle: BattingStyle.rightHand,
                bowlingStyle: BowlingStyle.rightArmMedium,
                stats: PlayerStats(),
              ));
              _countyBatsman2Player = Player(id: pid, name: bat2, teamId: teamAResolved.id, role: PlayerRole.batter, stats: PlayerStats());
            }

            if (_countyBowler2Player != null) {
              await playerRepo.addPlayerToTeam(_countyBowler2Player!.id, teamBResolved.id);
            } else {
              final pid = await playerRepo.create(Player(
                id: '',
                name: bowl2,
                teamId: teamBResolved.id,
                role: PlayerRole.bowler,
                battingStyle: BattingStyle.rightHand,
                bowlingStyle: BowlingStyle.rightArmMedium,
                stats: PlayerStats(),
              ));
              _countyBowler2Player = Player(id: pid, name: bowl2, teamId: teamBResolved.id, role: PlayerRole.bowler, stats: PlayerStats());
            }
          }
        } catch (_) {}

        final countyLiveScore = {
          'matchType': 'county',
          'isCounty': true,
          'countyMode': _countyPlayerCount == 2 ? '1v1' : '2v2',
          'targetRuns': targetRuns,
          'totalBalls': totalBalls,
          'wickets': wickets,
          'batsman1': bat1,
          'bowler1': bowl1,
          'batsman2': bat2,
          'bowler2': bowl2,
          'statusMessage': 'County Duel: $nameA chasing $targetRuns in $totalBalls balls',
        };

        String? targetMatchId = widget.matchId;

        if (widget.isEdit) {
          var existing = ref.read(matchDetailProvider((
            tournamentId: effectiveTournamentId,
            matchId: widget.matchId!,
          ))).value;

          if (existing != null) {
            await controller.update(existing.copyWith(
              teamAId: teamAResolved.id,
              teamBId: teamBResolved.id,
              teamA: teamAResolved.name,
              teamB: teamBResolved.name,
              totalOvers: overs,
              venue: venue,
              matchDate: _matchDate,
              tossWinnerId: teamAResolved.id,
              tossDecision: TossDecision.bat,
              liveScore: countyLiveScore,
            ));
          } else {
            await ref.read(matchRepositoryProvider).updatePartial(
              tournamentId: effectiveTournamentId,
              matchId: widget.matchId!,
              data: {
                'teamAId': teamAResolved.id,
                'teamBId': teamBResolved.id,
                'teamA': teamAResolved.name,
                'teamB': teamBResolved.name,
                'totalOvers': overs,
                'venue': venue,
                'liveScore': countyLiveScore,
              },
            );
          }
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
            venue: venue,
            matchDate: _matchDate,
            tossWinnerId: teamAResolved.id,
            tossDecision: TossDecision.bat,
            liveScore: countyLiveScore,
          ));
        }

        if (mounted) {
          setState(() => _isSaving = false);
          if (startImmediately && targetMatchId != null && targetMatchId.isNotEmpty) {
            final scoringRepo = ref.read(scoringRepositoryProvider);
            if (_countyBatsman1Player != null && _countyBowler1Player != null) {
              await scoringRepo.initInnings(
                tournamentId: effectiveTournamentId,
                matchId: targetMatchId,
                inningsNumber: 1,
                battingTeam: Team(id: teamAResolved.id, name: teamAResolved.name, shortName: teamAResolved.name.substring(0, 1), logoUrl: ''),
                bowlingTeam: Team(id: teamBResolved.id, name: teamBResolved.name, shortName: teamBResolved.name.substring(0, 1), logoUrl: ''),
                openingStriker: _countyBatsman1Player!,
                openingNonStriker: null,
                openingBowler: _countyBowler1Player!,
                targetRuns: targetRuns,
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚡ County Duel: $nameA vs $nameB started! Target: $targetRuns in $totalBalls balls'),
                backgroundColor: const Color(0xFFD97706),
              ),
            );
            context.pushReplacement('/tournaments/$effectiveTournamentId/matches/$targetMatchId/scoring');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEdit ? 'County Match updated successfully!' : 'County Match scheduled successfully!'),
                backgroundColor: const Color(0xFF16A34A),
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tournaments/$effectiveTournamentId/matches/${widget.matchId ?? targetMatchId}');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving county match: $e'), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    // ─────────────────────────────────────────────────────────────
    // 2. NORMAL MATCH LOGIC
    // ─────────────────────────────────────────────────────────────
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
        isCountyTeam: false,
      );

      final teamBResolved = await _resolveTeam(
        isManual: _manualTeamB,
        selectedTeam: _teamB,
        manualName: _teamBNameController.text,
        existingTeams: existingTeams,
        isCountyTeam: false,
      );

      String? targetMatchId = widget.matchId;

      if (widget.isEdit) {
        var existing = ref.read(matchDetailProvider((
          tournamentId: effectiveTournamentId,
          matchId: widget.matchId!,
        ))).value;

        if (existing == null) {
          try {
            existing = await ref.read(matchRepositoryProvider).watchById(effectiveTournamentId, widget.matchId!).first;
          } catch (_) {}
        }

        if (existing != null) {
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
          await ref.read(matchRepositoryProvider).updatePartial(
            tournamentId: effectiveTournamentId,
            matchId: widget.matchId!,
            data: {
              'teamAId': teamAResolved.id,
              'teamBId': teamBResolved.id,
              'teamA': teamAResolved.name,
              'teamB': teamBResolved.name,
              'totalOvers': overs,
              'venue': _venueController.text.trim(),
            },
          );
        }
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

        if (!widget.isEdit && startImmediately && targetMatchId != null && targetMatchId.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${teamAResolved.name} vs ${teamBResolved.name} match created! Select Playing XI...'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          context.pushReplacement('/tournaments/$effectiveTournamentId/matches/$targetMatchId/squads');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEdit ? 'Match settings updated successfully!' : 'Match scheduled successfully!'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/tournaments/$effectiveTournamentId/matches/${widget.matchId ?? targetMatchId}');
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit ? 'Edit Match' : 'Create Match',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
            ),
            const Text(
              'Select match type & configure contest',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF93C5FD)),
            ),
          ],
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
              data: (allTeams) {
                final teams = allTeams.where((t) => !t.isCounty).toList();
                
                if (widget.isEdit && widget.tournamentId != null) {
                  final m = ref.watch(matchDetailProvider((
                    tournamentId: widget.tournamentId!,
                    matchId: widget.matchId!,
                  ))).value;
                  if (m != null) _hydrate(m, teams);
                }

                if (teams.isEmpty) {
                  _manualTeamA = true;
                  _manualTeamB = true;
                }

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // ─────────────────────────────────────────────────────────────
                      // 1. MATCH TYPE SELECTOR (NORMAL vs COUNTY)
                      // ─────────────────────────────────────────────────────────────
                      _buildMatchTypeSelector(),
                      const SizedBox(height: 16),

                      // Tournament Selector
                      if (tournaments.isNotEmpty && _matchType == MatchTypeOption.normal) ...[
                        _buildTournamentSelector(tournaments),
                        const SizedBox(height: 16),
                      ],

                      // ─────────────────────────────────────────────────────────────
                      // 2. DYNAMIC CONTENT: NORMAL MATCH vs COUNTY MATCH
                      // ─────────────────────────────────────────────────────────────
                      if (_matchType == MatchTypeOption.normal) ...[
                        // NORMAL MATCH: TEAMS CARD
                        _buildNormalTeamsCard(teams),
                        const SizedBox(height: 16),

                        // NORMAL MATCH: SETTINGS CARD
                        _buildNormalSettingsCard(),
                        const SizedBox(height: 22),

                        // NORMAL MATCH: ACTION BUTTONS
                        _buildNormalActionButtons(effectiveTournamentId, teams),
                      ] else ...[
                        // COUNTY MATCH: PERSON vs PERSON DUEL CARD
                        _buildCountyDuelCard(),
                        const SizedBox(height: 16),

                        // COUNTY MATCH: TARGET & BALLS QUOTA CARD
                        _buildCountyRulesCard(),
                        const SizedBox(height: 16),

                        // COUNTY MATCH: VENUE & DATE
                        _buildCountyVenueAndDateCard(),
                        const SizedBox(height: 22),

                        // COUNTY MATCH: ACTION BUTTONS
                        _buildCountyActionButtons(effectiveTournamentId, teams),
                      ],

                      const SizedBox(height: 28),
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

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: MATCH TYPE SELECTOR CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMatchTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 8),
              const Text(
                'SELECT MATCH TYPE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // OPTION 1: NORMAL MATCH
              Expanded(
                child: _buildTypeOptionTile(
                  title: 'Normal Match',
                  icon: Icons.sports_cricket_rounded,
                  isSelected: _matchType == MatchTypeOption.normal,
                  activeColor: const Color(0xFF16A34A),
                  onTap: () {
                    setState(() => _matchType = MatchTypeOption.normal);
                  },
                ),
              ),
              const SizedBox(width: 10),

              // OPTION 2: COUNTY MATCH
              Expanded(
                child: _buildTypeOptionTile(
                  title: 'County Match',
                  icon: Icons.bolt_rounded,
                  isSelected: _matchType == MatchTypeOption.county,
                  activeColor: const Color(0xFFD97706),
                  onTap: () {
                    setState(() => _matchType = MatchTypeOption.county);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOptionTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon Badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 3),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 9),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: TOURNAMENT SELECTOR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTournamentSelector(List<Tournament> tournaments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTournamentId,
        decoration: InputDecoration(
          labelText: 'Select Tournament',
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: NORMAL MATCH - TEAMS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNormalTeamsCard(List<Team> teams) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select or Enter Teams',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '11 vs 11',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TEAM A SECTION
          _buildNormalTeamField(
            teamLabel: 'Team A (Batting / Home)',
            isManual: _manualTeamA,
            selectedTeam: _teamA,
            nameController: _teamANameController,
            teams: teams,
            containerColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            icon: Icons.sports_cricket_rounded,
            iconColor: const Color(0xFF2563EB),
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

          // VS BADGE
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                ),
              ),
            ),
          ),

          // TEAM B SECTION
          _buildNormalTeamField(
            teamLabel: 'Team B (Bowling / Away)',
            isManual: _manualTeamB,
            selectedTeam: _teamB,
            nameController: _teamBNameController,
            teams: teams,
            containerColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            icon: Icons.sports_baseball_rounded,
            iconColor: const Color(0xFF16A34A),
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
    );
  }

  Widget _buildNormalTeamField({
    required String teamLabel,
    required bool isManual,
    required Team? selectedTeam,
    required TextEditingController nameController,
    required List<Team> teams,
    required Color containerColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onToggleManual,
    required ValueChanged<Team?> onSelectTeam,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    teamLabel,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: iconColor),
                  ),
                ],
              ),
              if (teams.isNotEmpty)
                TextButton.icon(
                  onPressed: onToggleManual,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 26)),
                  icon: Icon(isManual ? Icons.list_rounded : Icons.edit_note_rounded, size: 15, color: const Color(0xFF2563EB)),
                  label: Text(
                    isManual ? 'Select from list' : 'Type name',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (isManual || teams.isEmpty)
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter team name (e.g. Tigers)',
                prefixIcon: Icon(Icons.shield_outlined, color: iconColor),
                filled: true,
                fillColor: Colors.white,
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
                prefixIcon: Icon(Icons.shield_rounded, color: iconColor),
                filled: true,
                fillColor: Colors.white,
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: NORMAL MATCH - SETTINGS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNormalSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              labelText: 'Total Overs',
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

          // Venue
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: NORMAL MATCH - ACTION BUTTONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNormalActionButtons(String effectiveTournamentId, List<Team> teams) {
    return Column(
      children: [
        if (widget.isEdit) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _save(
                effectiveTournamentId: effectiveTournamentId,
                existingTeams: teams,
                startImmediately: false,
              ),
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
              label: Text(
                _isSaving ? 'SAVING CHANGES...' : 'SAVE & UPDATE MATCH',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF16A34A).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
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
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF16A34A).withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: COUNTY MATCH - PERSON vs PERSON DUEL CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCountyDuelCard() {
    final is2v2 = _countyPlayerCount == 4;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFEF4444)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sports_kabaddi_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Person vs Person Challenge',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  is2v2 ? '2 vs 2' : '1 vs 1',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Single batsman plays • Single bowler defends target',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // ── BATSMAN SECTION (CHASING TARGET) ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_cricket_rounded, size: 18, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'BATSMAN (CHASING TARGET)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _openPlayerPicker(
                          title: 'Select Batsman',
                          onSelect: (p) {
                            setState(() {
                              _countyBatsman1Player = p;
                              _countyBatsman1Controller.text = p.name;
                            });
                          },
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                      icon: const Icon(Icons.person_search_rounded, size: 15, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Pick Player',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Batsman 1 input
                TextFormField(
                  controller: _countyBatsman1Controller,
                  decoration: InputDecoration(
                    hintText: 'Enter Batsman name',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter batsman name' : null,
                ),

                // If 2 vs 2: Batsman 2 input
                if (is2v2) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Batsman 2:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                      ),
                      TextButton(
                        onPressed: () {
                          _openPlayerPicker(
                            title: 'Select 2nd Batsman',
                            onSelect: (p) {
                              setState(() {
                                _countyBatsman2Player = p;
                                _countyBatsman2Controller.text = p.name;
                              });
                            },
                          );
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
                        child: const Text('Pick Player', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _countyBatsman2Controller,
                    decoration: InputDecoration(
                      hintText: 'Enter 2nd Batsman name',
                      prefixIcon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    validator: (v) => is2v2 && (v == null || v.trim().isEmpty) ? 'Enter 2nd batsman name' : null,
                  ),
                ],
              ],
            ),
          ),

          // ── GLOWING DUEL BADGE ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFD97706).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFDE68A), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      is2v2 ? '2 ON 2 COUNTY DUEL' : '1 ON 1 COUNTY DUEL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.bolt_rounded, color: Color(0xFFFDE68A), size: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── BOWLER SECTION (DEFENDING TARGET) ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sports_baseball_rounded, size: 18, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Text(
                          'BOWLER (DEFENDING TARGET)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _openPlayerPicker(
                          title: 'Select Bowler',
                          onSelect: (p) {
                            setState(() {
                              _countyBowler1Player = p;
                              _countyBowler1Controller.text = p.name;
                            });
                          },
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                      icon: const Icon(Icons.person_search_rounded, size: 15, color: Color(0xFFD97706)),
                      label: const Text(
                        'Pick Player',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bowler 1 input
                TextFormField(
                  controller: _countyBowler1Controller,
                  decoration: InputDecoration(
                    hintText: 'Enter Bowler name',
                    prefixIcon: const Icon(Icons.sports_baseball_rounded, color: Color(0xFFD97706)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter bowler name' : null,
                ),

                // If 2 vs 2: Bowler 2 input
                if (is2v2) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bowler 2:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF78350F)),
                      ),
                      TextButton(
                        onPressed: () {
                          _openPlayerPicker(
                            title: 'Select 2nd Bowler',
                            onSelect: (p) {
                              setState(() {
                                _countyBowler2Player = p;
                                _countyBowler2Controller.text = p.name;
                              });
                            },
                          );
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
                        child: const Text('Pick Player', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _countyBowler2Controller,
                    decoration: InputDecoration(
                      hintText: 'Enter 2nd Bowler name',
                      prefixIcon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFD97706)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    validator: (v) => is2v2 && (v == null || v.trim().isEmpty) ? 'Enter 2nd bowler name' : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: COUNTY MATCH - TARGET SCORE & BALLS QUOTA CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCountyRulesCard() {
    final targetRuns = int.tryParse(_countyTargetController.text.trim()) ?? 30;
    final totalBalls = int.tryParse(_countyBallsController.text.trim()) ?? 12;
    final oversEquivalent = (totalBalls / 6.0).toStringAsFixed(1);
    final rrr = totalBalls > 0 ? (targetRuns / totalBalls * 6.0).toStringAsFixed(2) : '0.00';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.track_changes_rounded, size: 18, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 10),
              const Text(
                'TARGET SCORE & BALLS',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. TARGET RUNS INPUT
          TextFormField(
            controller: _countyTargetController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Target Score',
              helperText: 'Runs required by batsman to win',
              helperStyle: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600, fontSize: 11),
              prefixIcon: const Icon(Icons.flag_rounded, color: Color(0xFFD97706)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid target score' : null,
          ),
          const SizedBox(height: 16),

          // 2. TOTAL BALLS QUOTA INPUT
          TextFormField(
            controller: _countyBallsController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Total Balls',
              helperText: 'Balls quota for the bowler',
              helperStyle: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 11),
              prefixIcon: const Icon(Icons.timelapse_rounded, color: Color(0xFF2563EB)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid balls count' : null,
          ),
          const SizedBox(height: 16),

          // 3. TOTAL WICKETS INPUT
          TextFormField(
            controller: _countyWicketsController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Total Wickets',
              helperText: 'How many wickets to play?',
              helperStyle: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 11),
              prefixIcon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid wickets count' : null,
          ),
          const SizedBox(height: 16),

          // ── LIVE CHALLENGE BANNER PREVIEW ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target: $targetRuns Runs in $totalBalls Balls ($oversEquivalent Overs)',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Required Run Rate: $rrr RPO • 1 Batsman vs 1 Bowler',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: COUNTY MATCH - VENUE & DATE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCountyVenueAndDateCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ground & Schedule',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          // Ground
          TextFormField(
            controller: _countyVenueController,
            decoration: InputDecoration(
              labelText: 'Venue / Ground',
              prefixIcon: const Icon(Icons.place_rounded, color: Color(0xFFD97706)),
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
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706)),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COMPONENT: COUNTY MATCH - ACTION BUTTONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCountyActionButtons(String effectiveTournamentId, List<Team> teams) {
    return Column(
      children: [
        // 1. START COUNTY MATCH NOW (Primary Action)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _save(
              effectiveTournamentId: effectiveTournamentId,
              existingTeams: teams,
              startImmediately: true,
            ),
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
            label: Text(
              _isSaving ? 'CREATING DUEL...' : 'START COUNTY MATCH NOW',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFD97706).withOpacity(0.45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. SCHEDULE COUNTY MATCH (For Later)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : () => _save(
              effectiveTournamentId: effectiveTournamentId,
              existingTeams: teams,
              startImmediately: false,
            ),
            icon: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
            label: const Text(
              'Schedule County Match For Later',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
