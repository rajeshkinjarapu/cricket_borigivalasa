import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/player.dart';
import '../providers/player_providers.dart';
import 'player_form_screen.dart';

class GlobalPlayersScreen extends ConsumerStatefulWidget {
  const GlobalPlayersScreen({super.key});

  @override
  ConsumerState<GlobalPlayersScreen> createState() => _GlobalPlayersScreenState();
}

class _GlobalPlayersScreenState extends ConsumerState<GlobalPlayersScreen> {
  String _searchQuery = '';
  PlayerRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    final playersAsync = ref.watch(allPlayersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Players',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
              tooltip: 'Add Player',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerFormScreen()),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab_global_players',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerFormScreen()),
                );
              },
              backgroundColor: const Color(0xFF16A34A), // Emerald Green
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Player', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          // ── Search Bar & Filter Section ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search player by name, jersey, or role...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const SizedBox(height: 10),
                // Role Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('🏏 Batters', PlayerRole.batter),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('🎳 Bowlers', PlayerRole.bowler),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('⭐ All-Rounders', PlayerRole.allRounder),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('🧤 Wicket Keepers', PlayerRole.wicketKeeper),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Players List ──
          Expanded(
            child: playersAsync.when(
              data: (players) {
                var filtered = players.where((p) {
                  final nameMatch = p.name.toLowerCase().contains(_searchQuery);
                  final jerseyMatch = p.jerseyNumber?.toString().contains(_searchQuery) ?? false;
                  final phoneMatch = p.phoneNumber?.contains(_searchQuery) ?? false;
                  final roleMatch = _selectedRole == null || p.role == _selectedRole;

                  return (nameMatch || jerseyMatch || phoneMatch) && roleMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No players match "$_searchQuery"'
                                : 'No players registered yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAdmin
                                ? 'Tap "Add Player" to register players to the club.'
                                : 'Players will appear here once registered.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          if (isAdmin && _searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PlayerFormScreen()),
                                );
                              },
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Add First Player'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final player = filtered[index];
                    return _PlayerCard(
                      player: player,
                      isAdmin: isAdmin,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PlayerFormScreen(player: player)),
                        );
                      },
                      onDelete: () => _confirmDeletePlayer(player),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, PlayerRole? role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Player?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${player.name}? This will remove the player record.'),
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

    if (confirmed == true) {
      await ref.read(playerControllerProvider.notifier).delete(player.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.name} deleted successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ── Player Card Widget ──
class _PlayerCard extends StatelessWidget {
  final Player player;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlayerCard({
    required this.player,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

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

  String _getRoleLabel(PlayerRole role) {
    switch (role) {
      case PlayerRole.batter:
        return '🏏 Batter';
      case PlayerRole.bowler:
        return '🎳 Bowler';
      case PlayerRole.allRounder:
        return '⭐ All-Rounder';
      case PlayerRole.wicketKeeper:
        return '🧤 Wicket Keeper';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(player.role);
    final imageProvider = getAppAvatarProvider(player.profilePicUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isAdmin ? onEdit : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Player Photo / Squircle Avatar ──
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), // Modern Squircle
                  color: roleColor.withOpacity(0.12),
                  border: Border.all(color: roleColor.withOpacity(0.25), width: 1.5),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: imageProvider == null
                    ? Center(
                        child: Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: roleColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // ── Player Details ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.jerseyNumber != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${player.jerseyNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Role Badge Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getRoleLabel(player.role),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Batting & Bowling Info & Phone
                    Text(
                      '${player.battingStyle.label}${player.bowlingStyle != BowlingStyle.none ? ' • ${player.bowlingStyle.label}' : ''}${player.phoneNumber != null && player.phoneNumber!.isNotEmpty ? ' • 📞 ${player.phoneNumber}' : ''}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // ── Admin Edit/Delete Menu ──
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text('Edit Player'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
