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
          backgroundColor: const Color(0xFFF4F7FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}');
                }
              },
            ),
            title: const Text(
              'Match Squads',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white, letterSpacing: -0.5),
            ),
          ),
          body: Column(
            children: [
              // ── Modern Segmented Team Selector ──
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTeamTab(
                          title: match.teamA,
                          count: teamAPlayers.length,
                          isSelected: _selectedSquadTabIndex == 0,
                          onTap: () => setState(() => _selectedSquadTabIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 4),
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
              ),

              // ── Active Team Squad Content ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    // Squad Header with Dual Action Buttons (Database & Manual)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeTeamName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${activePlayers.length} / 11 Players Selected',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canManage && activePlayers.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IconActionBtn(
                                icon: Icons.storage_rounded,
                                color: const Color(0xFF3B82F6),
                                onTap: () => _openAddPlayersPage(
                                  context, activeTeam, activeTeamId, activeTeamName, oppositeTeamName, oppositeTeamPlayerIds, initialTab: 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _IconActionBtn(
                                icon: Icons.person_add_rounded,
                                color: const Color(0xFF10B981),
                                onTap: () => _openAddPlayersPage(
                                  context, activeTeam, activeTeamId, activeTeamName, oppositeTeamName, oppositeTeamPlayerIds, initialTab: 1,
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
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.group_add_rounded, size: 48, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Squad is Empty',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add players to $activeTeamName to get ready for the match.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            if (canManage)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _openAddPlayersPage(
                                      context, activeTeam, activeTeamId, activeTeamName, oppositeTeamName, oppositeTeamPlayerIds, initialTab: 0,
                                    ),
                                    icon: const Icon(Icons.search_rounded, size: 18),
                                    label: const Text('Choose Existing Player', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _openAddPlayersPage(
                                      context, activeTeam, activeTeamId, activeTeamName, oppositeTeamName, oppositeTeamPlayerIds, initialTab: 1,
                                    ),
                                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                    label: const Text('Create New Player', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F172A),
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 4)),
                          ],
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
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                              child: Row(
                                children: [
                                  // Player Number
                                  SizedBox(
                                    width: 20,
                                    child: Text(
                                      '${idx + 1}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Avatar
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: roleColor.withOpacity(0.1),
                                      border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
                                      image: playerImage != null ? DecorationImage(image: playerImage, fit: BoxFit.cover) : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: playerImage == null
                                        ? Text(
                                            player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: roleColor),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),

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
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                              ),
                                            ),
                                            if (isCaptain) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'CAPT',
                                                  style: TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.w900),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              player.role.label,
                                              style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            if (player.jerseyNumber != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '•   #${player.jerseyNumber}',
                                                style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 12),
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
                                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF94A3B8)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      onSelected: (v) async {
                                        if (v == 'captain' && activeTeam != null) {
                                          await ref.read(teamControllerProvider.notifier).update(
                                                activeTeam.copyWith(captainId: player.id, captainName: player.name),
                                              );
                                        } else if (v == 'remove') {
                                          await ref.read(playerControllerProvider.notifier).removePlayerFromTeam(player.id, activeTeamId);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'captain',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                                              const SizedBox(width: 8),
                                              Text(isCaptain ? 'Captain (Active)' : 'Make Captain', style: const TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_remove_rounded, color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text('Remove from Squad', style: TextStyle(color: Colors.red, fontSize: 14)),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (match.hasToss) {
                          context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}/scoring');
                        } else {
                          context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(match.hasToss ? Icons.play_circle_fill_rounded : Icons.sports_cricket_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            match.hasToss ? 'CONFIRM & START SCORING' : 'CONFIRM SQUADS & GO TO TOSS',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.pushReplacement('/tournaments/${widget.tournamentId}/matches/${widget.matchId}');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Back to Match Center',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.white70,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
