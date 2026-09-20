import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';

class MatchSquadsScreen extends ConsumerStatefulWidget {
  const MatchSquadsScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  final String tournamentId;
  final String matchId;

  @override
  ConsumerState<MatchSquadsScreen> createState() => _MatchSquadsScreenState();
}

class _MatchSquadsScreenState extends ConsumerState<MatchSquadsScreen> {
  int _selectedSquadTabIndex = 0; // 0 for Team A, 1 for Team B

  ImageProvider? _getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('data:image') || url.length > 500) {
        final base64String = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(url);
    } catch (_) {
      return null;
    }
  }

  Color _getRoleColor(PlayerRole role) {
    switch (role) {
      case PlayerRole.batter:
        return const Color(0xFF2563EB); // Blue
      case PlayerRole.bowler:
        return const Color(0xFF16A34A); // Green
      case PlayerRole.allRounder:
        return const Color(0xFF9333EA); // Purple
      case PlayerRole.wicketKeeper:
        return const Color(0xFFD97706); // Amber
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider((
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    )));
    final currentUser = ref.watch(currentUserProvider);
    final canManage = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.scorer;

    return matchAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: const Text('Match Error'),
        ),
        body: Center(child: Text('Error loading match: $e')),
      ),
      data: (match) {
        if (match == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              title: const Text('Match Not Found'),
            ),
            body: const Center(child: Text('Match not found or has been deleted.')),
          );
        }

        final teamAAsync = ref.watch(teamDetailProvider(match.teamAId));
        final teamBAsync = ref.watch(teamDetailProvider(match.teamBId));
        final teamA = teamAAsync.value;
        final teamB = teamBAsync.value;

        final teamAPlayersAsync = ref.watch(teamPlayersProvider(match.teamAId));
        final teamBPlayersAsync = ref.watch(teamPlayersProvider(match.teamBId));
        final teamAPlayers = teamAPlayersAsync.value ?? [];
        final teamBPlayers = teamBPlayersAsync.value ?? [];

        final bothReady = teamAPlayers.length >= 11 && teamBPlayers.length >= 11;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}');
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Match Squads & Playing XI',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                ),
                Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Progress indicator ──
                _buildXIProgressBanner(
                  teamAName: match.teamA,
                  teamBName: match.teamB,
                  countA: teamAPlayers.length,
                  countB: teamBPlayers.length,
                  bothReady: bothReady,
                ),
                const SizedBox(height: 12),

                // ── 2 TABS PLAYING XI SECTION ──
                _buildPlaying11TabsSection(
                  context: context,
                  match: match,
                  teamA: teamA,
                  teamB: teamB,
                  teamAPlayers: teamAPlayers,
                  teamBPlayers: teamBPlayers,
                  isAdmin: canManage,
                ),
                const SizedBox(height: 24),

                // ── PROCEED TO TOSS BUTTON ──
                ElevatedButton.icon(
                  onPressed: bothReady
                      ? () {
                          context.pushReplacement(
                            '/tournaments/${widget.tournamentId}/matches/${widget.matchId}',
                          );
                        }
                      : null,
                  icon: Icon(
                    bothReady ? Icons.how_to_vote_rounded : Icons.lock_outline_rounded,
                    size: 22,
                  ),
                  label: Text(
                    bothReady
                        ? 'CONFIRM PLAYING 11 & PROCEED TO TOSS'
                        : 'Need 11 Players Each (${teamAPlayers.length}/11 & ${teamBPlayers.length}/11)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: bothReady ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: bothReady ? 3 : 0,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.pushReplacement(
                        '/tournaments/${widget.tournamentId}/matches/${widget.matchId}',
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'BACK TO MATCH CENTER',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.2),
                    foregroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildXIProgressBanner({
    required String teamAName,
    required String teamBName,
    required int countA,
    required int countB,
    required bool bothReady,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bothReady ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bothReady ? const Color(0xFF86EFAC) : const Color(0xFFBFD9FE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            bothReady ? Icons.check_circle_rounded : Icons.group_add_rounded,
            color: bothReady ? const Color(0xFF16A34A) : const Color(0xFF1E3A8A),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bothReady ? 'Both XIs are ready! Proceeding to toss...' : 'Select Playing XI for each team',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: bothReady ? const Color(0xFF15803D) : const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTeamProgress(teamAName, countA),
                    const SizedBox(width: 12),
                    _buildTeamProgress(teamBName, countB),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamProgress(String teamName, int count) {
    final done = count >= 11;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: done ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Text(
          '${teamName.split(' ').first}: $count/11',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: done ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying11TabsSection({
    required BuildContext context,
    required Match match,
    required Team? teamA,
    required Team? teamB,
    required List<Player> teamAPlayers,
    required List<Player> teamBPlayers,
    required bool isAdmin,
  }) {
    final activeTeamName = _selectedSquadTabIndex == 0 ? match.teamA : match.teamB;
    final activeTeamId = _selectedSquadTabIndex == 0 ? match.teamAId : match.teamBId;
    final activeTeam = _selectedSquadTabIndex == 0 ? teamA : teamB;
    final activePlayers = _selectedSquadTabIndex == 0 ? teamAPlayers : teamBPlayers;

    final logoA = _getImageProvider(teamA?.logoUrl);
    final logoB = _getImageProvider(teamB?.logoUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups_rounded, color: Color(0xFF1E3A8A), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Match Squads',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (isAdmin)
                  TextButton.icon(
                    onPressed: () => context.push('/teams/$activeTeamId'),
                    icon: const Icon(Icons.manage_accounts_rounded, size: 17, color: Color(0xFF1E3A8A)),
                    label: const Text(
                      'Manage',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E3A8A)),
                    ),
                  ),
              ],
            ),
          ),

          // ── 2 Tabs Switcher ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Tab 1: Team A
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedSquadTabIndex = 0),
                    borderRadius: BorderRadius.circular(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _selectedSquadTabIndex == 0 ? const Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedSquadTabIndex == 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: _selectedSquadTabIndex == 0 ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                            backgroundImage: logoA,
                            child: logoA == null
                                ? Text(
                                    match.teamA.isNotEmpty ? match.teamA[0].toUpperCase() : 'A',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedSquadTabIndex == 0 ? Colors.white : const Color(0xFF334155),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              match.teamA,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedSquadTabIndex == 0 ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _selectedSquadTabIndex == 0
                                  ? Colors.white.withOpacity(0.25)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${teamAPlayers.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _selectedSquadTabIndex == 0 ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Tab 2: Team B
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedSquadTabIndex = 1),
                    borderRadius: BorderRadius.circular(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _selectedSquadTabIndex == 1 ? const Color(0xFF1E3A8A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedSquadTabIndex == 1
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: _selectedSquadTabIndex == 1 ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                            backgroundImage: logoB,
                            child: logoB == null
                                ? Text(
                                    match.teamB.isNotEmpty ? match.teamB[0].toUpperCase() : 'B',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedSquadTabIndex == 1 ? Colors.white : const Color(0xFF334155),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              match.teamB,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedSquadTabIndex == 1 ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _selectedSquadTabIndex == 1
                                  ? Colors.white.withOpacity(0.25)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${teamBPlayers.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _selectedSquadTabIndex == 1 ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Selected Squad Player List ──
          if (activePlayers.isEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_search_rounded, size: 44, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'No players registered in $activeTeamName yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => context.push('/teams/$activeTeamId'),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text('Add Players to $activeTeamName'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              itemCount: activePlayers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final player = activePlayers[idx];
                final roleColor = _getRoleColor(player.role);
                final playerImage = _getImageProvider(player.profilePicUrl);
                final isCaptain = activeTeam != null &&
                    (activeTeam.captainId == player.id ||
                        (activeTeam.captainName != null &&
                            activeTeam.captainName!.toLowerCase() == player.name.toLowerCase()));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      // Player Number / Index
                      Container(
                        width: 24,
                        alignment: Alignment.center,
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Player Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: roleColor.withOpacity(0.1),
                          border: Border.all(color: roleColor.withOpacity(0.3), width: 1.5),
                          image: playerImage != null
                              ? DecorationImage(image: playerImage, fit: BoxFit.cover)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: playerImage == null
                            ? Text(
                                player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: roleColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Player Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    player.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (isCaptain) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Text(
                                      'C',
                                      style: TextStyle(
                                        color: Color(0xFFB45309),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                                if (player.jerseyNumber != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '#${player.jerseyNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    player.role.label,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${player.battingStyle.label}${player.phoneNumber != null && player.phoneNumber!.isNotEmpty ? " • 📞 ${player.phoneNumber}" : ""}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
