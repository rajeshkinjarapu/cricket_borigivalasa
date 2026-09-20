import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../data/models/team.dart';
import '../providers/team_providers.dart';

class GlobalTeamsScreen extends ConsumerStatefulWidget {
  const GlobalTeamsScreen({super.key});

  @override
  ConsumerState<GlobalTeamsScreen> createState() => _GlobalTeamsScreenState();
}

class _GlobalTeamsScreenState extends ConsumerState<GlobalTeamsScreen> {
  String _searchQuery = '';

  final List<List<Color>> _teamGradients = const [
    [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Royal Blue
    [Color(0xFFB45309), Color(0xFFF59E0B)], // Amber Gold
    [Color(0xFF047857), Color(0xFF10B981)], // Emerald Green
    [Color(0xFF6D28D9), Color(0xFF8B5CF6)], // Purple
    [Color(0xFFBE123C), Color(0xFFF43F5E)], // Rose Crimson
    [Color(0xFF0369A1), Color(0xFF0EA5E9)], // Sky Blue
  ];

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

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final allPlayersAsync = ref.watch(allPlayersProvider);
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Uniform Royal Blue Header
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
        title: const Text(
          'Teams & Clubs',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.group_add_rounded, color: Colors.white),
              tooltip: 'Create Team',
              onPressed: () => context.push('/teams/new'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Summary Section ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search teams or captain...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Teams List ──
          Expanded(
            child: teamsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading teams: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (teams) {
                final filtered = teams.where((t) {
                  if (_searchQuery.isEmpty) return true;
                  final nameMatch = t.name.toLowerCase().contains(_searchQuery);
                  final shortMatch = t.shortName.toLowerCase().contains(_searchQuery);
                  final capMatch = (t.captainName ?? '').toLowerCase().contains(_searchQuery);
                  return nameMatch || shortMatch || capMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.groups_outlined,
                                size: 48, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No teams found matching "$_searchQuery"'
                                : 'No teams created yet.\nTap "+ Create Team" to add one!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final team = filtered[index];
                    final playersList = allPlayersAsync.value ?? [];
                    final teamPlayersCount = playersList.where((p) => p.teamId == team.id).length;
                    final gradient = _teamGradients[index % _teamGradients.length];

                    return _buildTeamListCard(context, team, teamPlayersCount, isAdmin, gradient);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab_global_teams',
              onPressed: () => context.push('/teams/new'),
              backgroundColor: const Color(0xFF16A34A), // Emerald Green
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Team',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          : null,
    );
  }

  Widget _buildTeamListCard(
    BuildContext context,
    Team team,
    int playerCount,
    bool isAdmin,
    List<Color> gradient,
  ) {
    final imageProvider = _getImageProvider(team.logoUrl);
    final primaryColor = gradient.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/teams/${team.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Vibrant Team Logo / Avatar ──
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: imageProvider == null
                        ? LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16), // Modern Squircle
                    border: Border.all(color: primaryColor.withOpacity(0.25), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // ── Team Details ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: primaryColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              team.shortName.isNotEmpty ? team.shortName : 'TEAM',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Captain & Squad Size Info
                      Row(
                        children: [
                          // Captain info
                          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD97706)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              team.captainName?.isNotEmpty == true
                                  ? 'Capt: ${team.captainName!}'
                                  : 'No Captain assigned',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Players Count Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: playerCount > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: playerCount > 0 ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  size: 13,
                                  color: playerCount > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$playerCount Players',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: playerCount > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Admin Menu / Chevron ──
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (action) async {
                      if (action == 'view') {
                        context.push('/teams/${team.id}');
                      } else if (action == 'edit') {
                        context.push('/teams/${team.id}/edit');
                      } else if (action == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete Team?', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text('Are you sure you want to delete ${team.name}? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
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
                        if (confirm == true) {
                          await ref.read(teamControllerProvider.notifier).delete(team.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${team.name} deleted successfully.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 8),
                            Text('View Squad'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text('Edit Team'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Team', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
