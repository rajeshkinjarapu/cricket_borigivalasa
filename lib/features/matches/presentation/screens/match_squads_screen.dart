import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../../players/presentation/screens/add_players_screen.dart';
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

  void _openAddPlayersPage(
    BuildContext context,
    Team? team,
    String teamId,
    String teamName,
    String oppositeTeamName,
    Set<String> oppositeTeamPlayerIds, {
    int initialTab = 0,
  }) {
    final effectiveTeam = team ?? Team(id: teamId, name: teamName, shortName: teamName.isNotEmpty ? teamName[0] : 'T');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddPlayersScreen(
          team: effectiveTeam,
          oppositeTeamName: oppositeTeamName,
          oppositeTeamPlayerIds: oppositeTeamPlayerIds,
          initialTab: initialTab,
        ),
      ),
    );
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

        final activeTeamName = _selectedSquadTabIndex == 0 ? match.teamA : match.teamB;
        final activeTeamId = _selectedSquadTabIndex == 0 ? match.teamAId : match.teamBId;
        final activeTeam = _selectedSquadTabIndex == 0 ? teamA : teamB;
        final activePlayers = _selectedSquadTabIndex == 0 ? teamAPlayers : teamBPlayers;

        final oppositeTeamName = _selectedSquadTabIndex == 0 ? match.teamB : match.teamA;
        final oppositeTeamPlayerIds = _selectedSquadTabIndex == 0
            ? teamBPlayers.map((p) => p.id).toSet()
            : teamAPlayers.map((p) => p.id).toSet();

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
                  'Match Squads Selection',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                ),
                Text(
                  '${match.teamA} vs ${match.teamB}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // ── Clean Top Team Selector Tabs ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Tab 1: Team A
                    Expanded(
                      child: _buildTeamTab(
                        title: match.teamA,
                        count: teamAPlayers.length,
                        isSelected: _selectedSquadTabIndex == 0,
                        onTap: () => setState(() => _selectedSquadTabIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tab 2: Team B
                    Expanded(
                      child: _buildTeamTab(
                        title: match.teamB,
                        count: teamBPlayers.length,
                        isSelected: _selectedSquadTabIndex == 1,
                        onTap: () => setState(() => _selectedSquadTabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Active Team Squad Content ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // Squad Header with Dual Action Buttons (Database & Manual)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '$activeTeamName (${activePlayers.length} Players)',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. From Database
                              ElevatedButton.icon(
                                onPressed: () => _openAddPlayersPage(
                                  context,
                                  activeTeam,
                                  activeTeamId,
                                  activeTeamName,
                                  oppositeTeamName,
                                  oppositeTeamPlayerIds,
                                  initialTab: 0,
                                ),
                                icon: const Icon(Icons.storage_rounded, size: 13),
                                label: const Text('From DB'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 2. Manual Player
                              ElevatedButton.icon(
                                onPressed: () => _openAddPlayersPage(
                                  context,
                                  activeTeam,
                                  activeTeamId,
                                  activeTeamName,
                                  oppositeTeamName,
                                  oppositeTeamPlayerIds,
                                  initialTab: 1,
                                ),
                                icon: const Icon(Icons.person_add_rounded, size: 13),
                                label: const Text('Manual'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Players List or Empty View
                    if (activePlayers.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            Text(
                              'No players added to $activeTeamName yet.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (canManage)
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _openAddPlayersPage(
                                      context,
                                      activeTeam,
                                      activeTeamId,
                                      activeTeamName,
                                      oppositeTeamName,
                                      oppositeTeamPlayerIds,
                                      initialTab: 0,
                                    ),
                                    icon: const Icon(Icons.storage_rounded, size: 16),
                                    label: const Text('Select from Database'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _openAddPlayersPage(
                                      context,
                                      activeTeam,
                                      activeTeamId,
                                      activeTeamName,
                                      oppositeTeamName,
                                      oppositeTeamPlayerIds,
                                      initialTab: 1,
                                    ),
                                    icon: const Icon(Icons.person_add_rounded, size: 16),
                                    label: const Text('Add Manually'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Row(
                                children: [
                                  // Player Number
                                  Container(
                                    width: 24,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Avatar
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: roleColor.withOpacity(0.12),
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
                                              fontSize: 15,
                                              color: roleColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),

                                  // Name & Role
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
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                                ),
                                                child: const Text(
                                                  'CAPTAIN',
                                                  style: TextStyle(
                                                    color: Color(0xFFB45309),
                                                    fontSize: 9.5,
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
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: roleColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                player.role.label,
                                                style: TextStyle(
                                                  color: roleColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (player.phoneNumber != null && player.phoneNumber!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '📞 ${player.phoneNumber}',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quick Options Menu
                                  if (canManage)
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF94A3B8)),
                                      onSelected: (v) async {
                                        if (v == 'captain' && activeTeam != null) {
                                          await ref.read(teamControllerProvider.notifier).update(
                                                activeTeam.copyWith(captainId: player.id, captainName: player.name),
                                              );
                                        } else if (v == 'remove') {
                                          await ref
                                              .read(playerControllerProvider.notifier)
                                              .removePlayerFromTeam(player.id, activeTeamId);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'captain',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                                              const SizedBox(width: 8),
                                              Text(isCaptain ? 'Captain (Active)' : 'Make Captain'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_remove_rounded, color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text('Remove from Squad', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bottom Fixed Action Bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (match.hasToss) {
                          context.pushReplacement(
                            '/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring',
                          );
                        } else {
                          context.pushReplacement(
                            '/tournaments/${widget.tournamentId}/matches/${widget.matchId}',
                          );
                        }
                      },
                      icon: Icon(
                        match.hasToss ? Icons.play_circle_fill_rounded : Icons.how_to_vote_rounded,
                        size: 20,
                      ),
                      label: Text(
                        match.hasToss ? 'CONFIRM SQUADS & START SCORING' : 'CONFIRM SQUADS & GO TO TOSS',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}');
                        }
                      },
                      child: const Text(
                        'Back to Match Center',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamTab({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.22)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count Players',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
