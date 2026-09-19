import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../players/presentation/screens/global_players_screen.dart';
import '../providers/team_providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({
    super.key,
    required this.teamId,
    this.tournamentId = 'global',
  });

  final String teamId;
  final String tournamentId;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return teamAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
        body: Center(child: Text('Error: $e')),
      ),
      data: (team) {
        if (team == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            body: const Center(child: Text('Team not found')),
          );
        }

        final imageProvider = _getImageProvider(team.logoUrl);

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            ),
            actions: [
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/teams/new?teamId=$teamId');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Team?', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to delete ${team.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(teamControllerProvider.notifier).delete(team.id);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Team')),
                    PopupMenuItem(value: 'delete', child: Text('Delete Team', style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  heroTag: 'fab_team_detail',
                  onPressed: () => context.push('/players'),
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Manage Players', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Team Hero Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Team Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 2.5),
                        image: imageProvider != null
                            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageProvider == null
                          ? Center(
                              child: Text(
                                team.shortName.isNotEmpty
                                    ? team.shortName
                                    : (team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Team Name & Captain
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  team.shortName.isNotEmpty ? team.shortName : 'TEAM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (team.captainName?.isNotEmpty == true) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    team.captainName!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Squad Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Team Squad / Players',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  playersAsync.maybeWhen(
                    data: (p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${p.length} Players',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Players List (With Photos) ──
              playersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                data: (players) {
                  if (players.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person_search_rounded, size: 54, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text(
                            'No players added to this squad yet.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isAdmin)
                            ElevatedButton.icon(
                              onPressed: () => context.push('/players'),
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text('Add Players to Team'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: players.map((p) {
                      final roleColor = _getRoleColor(p.role);
                      final playerImg = _getImageProvider(p.profilePicUrl);
                      final isCaptain = p.id == team.captainId || (team.captainName?.toLowerCase() == p.name.toLowerCase());

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: roleColor.withOpacity(0.2)),
                              image: playerImg != null
                                  ? DecorationImage(image: playerImg, fit: BoxFit.cover)
                                  : null,
                            ),
                            child: playerImg == null
                                ? Center(
                                    child: Text(
                                      p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCaptain) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Text(
                                    'CAPTAIN',
                                    style: TextStyle(
                                      color: Color(0xFFB45309),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              if (p.jerseyNumber != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '#${p.jerseyNumber}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.role.label,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${p.battingStyle.label}${p.phoneNumber != null && p.phoneNumber!.isNotEmpty ? " • 📞 ${p.phoneNumber}" : ""}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
