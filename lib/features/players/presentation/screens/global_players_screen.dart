import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/player.dart';
import '../providers/player_providers.dart';

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
    final teamsAsync = ref.watch(allTeamsProvider);

    final teamsMap = <String, String>{};
    teamsAsync.whenData((teams) {
      for (final t in teams) {
        teamsMap[t.id] = t.name;
      }
    });

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
              onPressed: () => _showAddEditPlayerDialog(context, null, teamsAsync.value ?? []),
            ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab_global_players',
              onPressed: () => _showAddEditPlayerDialog(context, null, teamsAsync.value ?? []),
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
                      _buildRoleFilterChip('Batters', PlayerRole.batter),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Bowlers', PlayerRole.bowler),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('All-Rounders', PlayerRole.allRounder),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Wicket Keepers', PlayerRole.wicketKeeper),
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
                  final teamName = (teamsMap[p.teamId] ?? '').toLowerCase();
                  final teamMatch = teamName.contains(_searchQuery);
                  final roleMatch = _selectedRole == null || p.role == _selectedRole;

                  return (nameMatch || jerseyMatch || teamMatch) && roleMatch;
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
                                ? 'Click "+ Add Player" to register players'
                                : 'Registered players will appear here',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final teamName = teamsMap[p.teamId];
                    return _PlayerCard(
                      player: p,
                      teamName: teamName,
                      isAdmin: isAdmin,
                      onEdit: () => _showAddEditPlayerDialog(context, p, teamsAsync.value ?? []),
                      onDelete: () => _confirmDeletePlayer(context, p),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading players: $e', style: const TextStyle(color: Colors.red)),
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
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePlayer(BuildContext context, Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Player?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${player.name}? This action cannot be undone.'),
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

  void _showAddEditPlayerDialog(BuildContext context, Player? player, List<Team> teams) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditPlayerSheet(player: player, teams: teams),
    );
  }
}

// ── Player Card Widget ──
class _PlayerCard extends StatelessWidget {
  final Player player;
  final String? teamName;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlayerCard({
    required this.player,
    required this.teamName,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  ImageProvider? _getPlayerImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image') || photoUrl.length > 500) {
        final base64String = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(photoUrl);
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
    final roleColor = _getRoleColor(player.role);
    final imageProvider = _getPlayerImage(player.profilePicUrl);

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Player Photo / Avatar ──
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
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

                  // Role & Team Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          player.role.label,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Team Badge
                      if (teamName != null && teamName!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            teamName!,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Batting & Bowling Info & Phone
                  Text(
                    '${player.battingStyle.label}${player.bowlingStyle != BowlingStyle.none ? ' • ${player.bowlingStyle.label}' : ''}${player.phoneNumber != null && player.phoneNumber!.isNotEmpty ? ' • 📞 ${player.phoneNumber}' : ''}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
    );
  }
}

// ── Add/Edit Player Modal BottomSheet ──
class _AddEditPlayerSheet extends ConsumerStatefulWidget {
  final Player? player;
  final List<Team> teams;

  const _AddEditPlayerSheet({this.player, required this.teams});

  @override
  ConsumerState<_AddEditPlayerSheet> createState() => _AddEditPlayerSheetState();
}

class _AddEditPlayerSheetState extends ConsumerState<_AddEditPlayerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _jerseyController;
  late TextEditingController _phoneController;
  
  String? _teamId;
  PlayerRole _role = PlayerRole.batter;
  BattingStyle _battingStyle = BattingStyle.rightHand;
  BowlingStyle _bowlingStyle = BowlingStyle.none;
  String? _profilePicUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameController = TextEditingController(text: p?.name ?? '');
    _jerseyController = TextEditingController(text: p?.jerseyNumber?.toString() ?? '');
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _teamId = p?.teamId.isNotEmpty == true ? p!.teamId : (widget.teams.isNotEmpty ? widget.teams.first.id : null);
    _role = p?.role ?? PlayerRole.batter;
    _battingStyle = p?.battingStyle ?? BattingStyle.rightHand;
    _bowlingStyle = p?.bowlingStyle ?? BowlingStyle.none;
    _profilePicUrl = p?.profilePicUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() => _profilePicUrl = base64String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final controller = ref.read(playerControllerProvider.notifier);
      final jersey = int.tryParse(_jerseyController.text.trim());
      final phone = _phoneController.text.trim();
      final teamIdToSave = _teamId ?? (widget.teams.isNotEmpty ? widget.teams.first.id : '');

      if (widget.player != null) {
        // Edit Player
        await controller.update(widget.player!.copyWith(
          name: _nameController.text.trim(),
          teamId: teamIdToSave,
          role: _role,
          battingStyle: _battingStyle,
          bowlingStyle: _bowlingStyle,
          jerseyNumber: jersey,
          phoneNumber: phone.isNotEmpty ? phone : null,
          profilePicUrl: _profilePicUrl,
        ));
      } else {
        // Create Player
        await controller.create(Player(
          id: '',
          name: _nameController.text.trim(),
          teamId: teamIdToSave,
          role: _role,
          battingStyle: _battingStyle,
          bowlingStyle: _bowlingStyle,
          jerseyNumber: jersey,
          phoneNumber: phone.isNotEmpty ? phone : null,
          profilePicUrl: _profilePicUrl,
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.player != null ? 'Player updated successfully!' : 'Player registered successfully!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider? _previewImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image') || photoUrl.length > 500) {
        final base64String = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(photoUrl);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.player != null;
    final imageProvider = _previewImage(_profilePicUrl);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Player' : 'Add New Player',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Photo Picker Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
                          image: imageProvider != null
                              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageProvider == null
                            ? const Icon(Icons.person, size: 44, color: Color(0xFF94A3B8))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('Tap to choose photo', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Player Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
              ),
              const SizedBox(height: 14),

              // Team Dropdown
              if (widget.teams.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _teamId,
                  decoration: InputDecoration(
                    labelText: 'Team',
                    prefixIcon: const Icon(Icons.groups_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.teams
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _teamId = v),
                ),
              if (widget.teams.isNotEmpty) const SizedBox(height: 14),

              // Role Dropdown
              DropdownButtonFormField<PlayerRole>(
                value: _role,
                decoration: InputDecoration(
                  labelText: 'Role',
                  prefixIcon: const Icon(Icons.sports_cricket_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: PlayerRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 14),

              // Batting Style Dropdown
              DropdownButtonFormField<BattingStyle>(
                value: _battingStyle,
                decoration: InputDecoration(
                  labelText: 'Batting Style',
                  prefixIcon: const Icon(Icons.sports),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: BattingStyle.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setState(() => _battingStyle = v!),
              ),
              const SizedBox(height: 14),

              // Bowling Style Dropdown
              DropdownButtonFormField<BowlingStyle>(
                value: _bowlingStyle,
                decoration: InputDecoration(
                  labelText: 'Bowling Style',
                  prefixIcon: const Icon(Icons.sports_baseball_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: BowlingStyle.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setState(() => _bowlingStyle = v!),
              ),
              const SizedBox(height: 14),

              // Jersey Number Field
              TextFormField(
                controller: _jerseyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jersey Number (Optional)',
                  prefixIcon: const Icon(Icons.tag_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              // Mobile Number Field (Optional)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number (Optional)',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: const Icon(Icons.phone_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A), // Emerald Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEdit ? 'SAVE CHANGES' : 'REGISTER PLAYER',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
