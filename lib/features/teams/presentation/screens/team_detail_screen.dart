import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../players/presentation/screens/add_players_screen.dart';
import '../providers/team_providers.dart';
import '../../data/models/team.dart';

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

  void _openAddPlayersModal(BuildContext context, Team team, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddPlayersScreen(team: team),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final currentUser = ref.watch(currentUserProvider);
    final canManage = currentUser?.role == UserRole.admin || currentUser?.role == UserRole.scorer;

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
              if (canManage) ...[
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                  tooltip: 'Add Players',
                  onPressed: () => _openAddPlayersModal(context, team, ref),
                ),
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
            ],
          ),
          floatingActionButton: canManage
              ? FloatingActionButton.extended(
                  heroTag: 'fab_team_detail',
                  onPressed: () => _openAddPlayersModal(context, team, ref),
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
                  Row(
                    children: [
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
                      if (canManage) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _openAddPlayersModal(context, team, ref),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: Color(0xFF16A34A)),
                                SizedBox(width: 2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                          if (canManage)
                            ElevatedButton.icon(
                              onPressed: () => _openAddPlayersModal(context, team, ref),
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
                            trailing: canManage
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                                    onSelected: (v) async {
                                      if (v == 'captain') {
                                        await ref.read(teamControllerProvider.notifier).update(
                                              team.copyWith(captainId: p.id, captainName: p.name),
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${p.name} is now the Captain of ${team.name}!'),
                                              backgroundColor: const Color(0xFF16A34A),
                                            ),
                                          );
                                        }
                                      } else if (v == 'edit') {
                                        context.push('/players/edit/${p.id}');
                                      } else if (v == 'remove') {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Remove from Squad?', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text('Remove ${p.name} from ${team.name} squad?'),
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
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await ref.read(playerControllerProvider.notifier).removePlayerFromTeam(p.id, team.id);
                                          if (p.id == team.captainId) {
                                            await ref.read(teamControllerProvider.notifier).update(
                                                  team.copyWith(captainId: '', captainName: ''),
                                                );
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${p.name} removed from squad.')),
                                            );
                                          }
                                        }
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
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                                            SizedBox(width: 8),
                                            Text('Edit Player'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'remove',
                                        child: Row(
                                          children: [
                                            Icon(Icons.person_remove_rounded, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Remove from Squad', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Add Players Modal Sheet (Dual Mode: Select Existing OR Manual Entry)
// ─────────────────────────────────────────────────────────────────────────────
class AddPlayersModalSheet extends ConsumerStatefulWidget {
  const AddPlayersModalSheet({super.key, required this.team, this.initialTab = 0});
  final Team team;
  final int initialTab;

  @override
  ConsumerState<AddPlayersModalSheet> createState() => _AddPlayersModalSheetState();
}

class _AddPlayersModalSheetState extends ConsumerState<AddPlayersModalSheet>
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
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _jerseyCtrl.dispose();
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

    final authEmail = '$cleanPhone@member.cricket.com';
    final password = cleanPhone;

    try {
      final tempApp = await Firebase.initializeApp(
        name: 'temp_squad_create_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      String? createdUid;
      try {
        final cred = await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: authEmail, password: password);
        final u = cred.user!;
        await u.updateDisplayName(name.trim());
        createdUid = u.uid;
      } catch (_) {
      } finally {
        await tempApp.delete();
      }

      final firestore = FirebaseFirestore.instance;
      if (createdUid != null) {
        final appUser = AppUser(
          uid: createdUid,
          email: authEmail,
          displayName: name.trim(),
          role: UserRole.member,
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
        );
        await firestore
            .collection(AppConstants.usersCollection)
            .doc(createdUid)
            .set(appUser.toJson()..remove('uid'), SetOptions(merge: true));
      } else {
        final existing = await firestore
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: authEmail)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await firestore.collection(AppConstants.usersCollection).add({
            'email': authEmail,
            'displayName': name.trim(),
            'role': 'member',
            'createdAt': FieldValue.serverTimestamp(),
            'photoUrl': photoUrl,
          });
        }
      }
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag Handle & Header ──
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Players to Squad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Team: ${widget.team.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 2 Mode Tabs ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    color: const Color(0xFF1E3A8A).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF475569),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
          const SizedBox(height: 10),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── TAB 1: Select from Existing Players List ──
                _buildSelectExistingTab(allPlayersAsync),

                // ── TAB 2: Manual Player Entry Form ──
                _buildManualEntryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectExistingTab(AsyncValue<List<Player>> allPlayersAsync) {
    return allPlayersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      ),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (allPlayers) {
        final filteredPlayers = allPlayers.where((p) {
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
            // Search & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
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
                  fillColor: Colors.white,
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
            ),

            // Role filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            const Divider(height: 12),

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
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _tabController.animateTo(1),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Player Manually'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredPlayers.length,
                      itemBuilder: (ctx, index) {
                        final p = filteredPlayers[index];
                        final isInSquad = p.teamId == widget.team.id || p.teamIds.contains(widget.team.id);
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
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isInSquad ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isInSquad ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                              width: isInSquad ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
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
                                if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '📞 ${p.phoneNumber}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isInSquad
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
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  // ── TAB 2: Manual Player Entry ──
  Widget _buildManualEntryTab() {
    ImageProvider? photoPreview;
    if (_manualPicBase64 != null) {
      try {
        final base64String = _manualPicBase64!.contains(',')
            ? _manualPicBase64!.split(',').last
            : _manualPicBase64!;
        photoPreview = MemoryImage(base64Decode(base64String));
      } catch (_) {}
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Photo Picker
          Center(
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
                    image: photoPreview != null
                        ? DecorationImage(image: photoPreview, fit: BoxFit.cover)
                        : null,
                  ),
                  child: photoPreview == null
                      ? const Icon(Icons.person, size: 40, color: Color(0xFF94A3B8))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Player Name
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Player Name *',
              hintText: 'e.g. Suresh Kumar',
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter player name' : null,
          ),
          const SizedBox(height: 14),

          // Mobile Number
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number (Optional)',
              hintText: 'e.g. 9876543210',
              prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Login credentials will be automatically generated (User ID: Mobile, Password: Mobile).',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Jersey Number
          TextFormField(
            controller: _jerseyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jersey Number (Optional)',
              hintText: 'e.g. 7 or 18',
              prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Player Role
          const Text(
            'Playing Role *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              _buildFormRoleChip('🏏 Batter', PlayerRole.batter),
              _buildFormRoleChip('⚾ Bowler', PlayerRole.bowler),
              _buildFormRoleChip('⚡ All-Rounder', PlayerRole.allRounder),
              _buildFormRoleChip('🧤 Wicket Keeper', PlayerRole.wicketKeeper),
            ],
          ),
          const SizedBox(height: 16),

          // Batting Style
          const Text(
            'Batting Style',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Right-Hand Bat')),
                  selected: _manualBatting == BattingStyle.rightHand,
                  onSelected: (s) => setState(() => _manualBatting = BattingStyle.rightHand),
                  selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Left-Hand Bat')),
                  selected: _manualBatting == BattingStyle.leftHand,
                  onSelected: (s) => setState(() => _manualBatting = BattingStyle.leftHand),
                  selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bowling Style
          const Text(
            'Bowling Style',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<BowlingStyle>(
            value: _manualBowling,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: BowlingStyle.values.map((s) {
              return DropdownMenuItem(value: s, child: Text(s.label));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _manualBowling = val);
            },
          ),
          const SizedBox(height: 24),

          // Create & Add Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isCreatingManual ? null : _submitManualPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isCreatingManual
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isCreatingManual ? 'Creating Player...' : 'Create & Add to ${widget.team.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRoleChip(String label, PlayerRole role) {
    final isSelected = _manualRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (s) {
        if (s) setState(() => _manualRole = role);
      },
      selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Color _getRoleColor(PlayerRole role) {
    switch (role) {
      case PlayerRole.batter:
        return const Color(0xFF2563EB);
      case PlayerRole.bowler:
        return const Color(0xFF16A34A);
      case PlayerRole.allRounder:
        return const Color(0xFF9333EA);
      case PlayerRole.wicketKeeper:
        return const Color(0xFFD97706);
    }
  }
}
