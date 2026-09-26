import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../members/presentation/providers/member_providers.dart';

import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../teams/data/models/team.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../../data/models/player.dart';
import '../providers/player_providers.dart';

class AddPlayersScreen extends ConsumerStatefulWidget {
  const AddPlayersScreen({
    super.key,
    required this.team,
    this.oppositeTeamName,
    this.oppositeTeamPlayerIds,
    this.initialTab = 0,
  });

  final Team team;
  final String? oppositeTeamName;
  final Set<String>? oppositeTeamPlayerIds;
  final int initialTab;

  @override
  ConsumerState<AddPlayersScreen> createState() => _AddPlayersScreenState();
}

class _AddPlayersScreenState extends ConsumerState<AddPlayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Selection Search & Filter
  String _searchQuery = '';
  PlayerRole? _selectedRoleFilter;

  // Tab 2: Manual Entry Form State
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();
  PlayerRole _manualRole = PlayerRole.batter;
  BattingStyle _manualBatting = BattingStyle.rightHand;
  BowlingStyle _manualBowling = BowlingStyle.none;
  String? _manualPicBase64;
  bool _isCreatingManual = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _jerseyCtrl.dispose();
    super.dispose();
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
      setState(() => _manualPicBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _provisionAccount({required String name, required String phone, String? photoUrl}) async {
    final cleanPhone = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (cleanPhone.length < 5) return;

    try {
      await ref.read(memberRepositoryProvider).createMember(
        name: name.trim(),
        phoneNumber: cleanPhone,
        role: UserRole.member,
        photoUrl: photoUrl,
      );
    } catch (_) {}
  }

  Future<void> _submitManualPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreatingManual = true);

    try {
      final phone = _phoneCtrl.text.trim();
      final name = _nameCtrl.text.trim();
      final jersey = int.tryParse(_jerseyCtrl.text.trim());

      final newPlayer = Player(
        id: '',
        name: name,
        teamId: widget.team.id,
        teamIds: [widget.team.id],
        role: _manualRole,
        battingStyle: _manualBatting,
        bowlingStyle: _manualBowling,
        jerseyNumber: jersey,
        phoneNumber: phone.isNotEmpty ? phone : null,
        profilePicUrl: _manualPicBase64,
      );

      final createdId = await ref.read(playerControllerProvider.notifier).create(newPlayer);

      if (createdId != null && phone.isNotEmpty) {
        await _provisionAccount(name: name, phone: phone, photoUrl: _manualPicBase64);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $name to ${widget.team.name} squad!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add player: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingManual = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPlayersAsync = ref.watch(allPlayersProvider);
    final allTeamsAsync = ref.watch(allTeamsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Players to Squad',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Team: ${widget.team.name}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Mode Switcher Tab Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF475569),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.format_list_bulleted_rounded, size: 18),
                    text: 'Select Existing Player',
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.person_add_alt_1_rounded, size: 18),
                    text: 'Manual Entry / New',
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSelectExistingTab(allPlayersAsync, allTeamsAsync),
                _buildManualEntryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectExistingTab(AsyncValue<List<Player>> allPlayersAsync, AsyncValue<List<Team>> allTeamsAsync) {
    return allPlayersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (allPlayers) {
        final teams = allTeamsAsync.value ?? [];
        final countyTeamIds = teams.where((t) => t.isCounty).map((t) => t.id).toSet();
        
        final filteredPlayers = allPlayers.where((p) {
          if (countyTeamIds.contains(p.teamId)) return false;
          
          if (_selectedRoleFilter != null && p.role != _selectedRoleFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesName = p.name.toLowerCase().contains(query);
            final matchesPhone = p.phoneNumber?.contains(query) == true;
            return matchesName || matchesPhone;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search & Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by player name or mobile number...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
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
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleFilterChip('All', null),
                        _buildRoleFilterChip('🏏 Batters', PlayerRole.batter),
                        _buildRoleFilterChip('⚾ Bowlers', PlayerRole.bowler),
                        _buildRoleFilterChip('⚡ All-Rounders', PlayerRole.allRounder),
                        _buildRoleFilterChip('🧤 Keepers', PlayerRole.wicketKeeper),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Players List
            Expanded(
              child: filteredPlayers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No players found matching "$_searchQuery"'
                                  : 'No players registered yet.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _tabController.animateTo(1),
                              icon: const Icon(Icons.person_add_rounded, size: 16),
                              label: const Text('Add Player Manually'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filteredPlayers.length,
                      itemBuilder: (ctx, index) {
                        final p = filteredPlayers[index];
                        final isInCurrentSquad = p.teamId == widget.team.id || p.teamIds.contains(widget.team.id);
                        final isInOppositeSquad = widget.oppositeTeamPlayerIds?.contains(p.id) == true;
                        final roleColor = _getRoleColor(p.role);

                        ImageProvider? playerImg;
                        if (p.profilePicUrl?.isNotEmpty == true) {
                          try {
                            if (p.profilePicUrl!.startsWith('data:image') || p.profilePicUrl!.length > 500) {
                              final base64String = p.profilePicUrl!.contains(',')
                                  ? p.profilePicUrl!.split(',').last
                                  : p.profilePicUrl!;
                              playerImg = MemoryImage(base64Decode(base64String));
                            } else {
                              playerImg = NetworkImage(p.profilePicUrl!);
                            }
                          } catch (_) {}
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isInCurrentSquad
                                ? const Color(0xFFF0FDF4)
                                : isInOppositeSquad
                                    ? const Color(0xFFF8FAFC)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isInCurrentSquad
                                  ? const Color(0xFF86EFAC)
                                  : isInOppositeSquad
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFFE2E8F0),
                              width: isInCurrentSquad ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: roleColor.withOpacity(0.25)),
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
                                          fontSize: 16,
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: isInOppositeSquad ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.jerseyNumber != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '#${p.jerseyNumber}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.role.label,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${p.battingStyle.label}${p.bowlingStyle != BowlingStyle.none ? " • ${p.bowlingStyle.label}" : ""}',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: isInCurrentSquad
                                ? ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(playerControllerProvider.notifier)
                                          .removePlayerFromTeam(p.id, widget.team.id);
                                    },
                                    icon: const Icon(Icons.check_rounded, size: 14),
                                    label: const Text('In Squad'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : isInOppositeSquad
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                        ),
                                        child: Text(
                                          'In ${widget.oppositeTeamName ?? "Other Team"}',
                                          style: const TextStyle(
                                            color: Color(0xFFB45309),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: () async {
                                          await ref
                                              .read(playerControllerProvider.notifier)
                                              .addPlayerToTeam(p.id, widget.team.id);
                                        },
                                        icon: const Icon(Icons.add_rounded, size: 14),
                                        label: const Text('Add to Squad'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E3A8A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleFilterChip(String label, PlayerRole? role) {
    final isSelected = _selectedRoleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedRoleFilter = role),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
        checkmarkColor: const Color(0xFF1E3A8A),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [


              // Player Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Player Name *',
                  hintText: 'e.g. Rohit Sharma',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter player name' : null,
              ),
              const SizedBox(height: 14),

              // Mobile Number
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF1E3A8A)),
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


              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isCreatingManual ? null : _submitManualPlayer,
                icon: _isCreatingManual
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_rounded, size: 20),
                label: Text(
                  _isCreatingManual ? 'Creating Player...' : 'Add Player to Squad',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
