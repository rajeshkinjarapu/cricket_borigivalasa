import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../providers/member_providers.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends ConsumerState<MemberManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'admin', 'scorer', 'member'

  ImageProvider? _getImageProvider(String? photoUrl) {
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

  void _showAddMemberModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddMemberModalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(memberListProvider);
    final playersAsync = ref.watch(allPlayersProvider);
    final repo = ref.read(memberRepositoryProvider);
    final currentUid = repo.currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
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
          'Members & Scorers',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            tooltip: 'Add Member',
            onPressed: () => _showAddMemberModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_member',
        onPressed: () => _showAddMemberModal(context),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Add Member',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // ── Search & Filter Header Section ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Box
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search members, players, or phone...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
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
                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Members & Players', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('👑 Admins', 'admin'),
                      const SizedBox(width: 8),
                      _buildFilterChip('✍️ Scorers', 'scorer'),
                      const SizedBox(width: 8),
                      _buildFilterChip('🏏 Members', 'member'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Members List ──
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading members: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (users) {
                final players = playersAsync.value ?? [];

                // Filter registered users
                final filtered = users.where((u) {
                  // Role Filter
                  if (_selectedFilter == 'admin' && u.role != UserRole.admin) return false;
                  if (_selectedFilter == 'scorer' && u.role != UserRole.scorer) return false;
                  if (_selectedFilter == 'member' && u.role != UserRole.member) return false;

                  // Search Filter
                  if (_searchQuery.isNotEmpty) {
                    final nameMatch = u.displayName.toLowerCase().contains(_searchQuery);
                    final emailMatch = u.email.toLowerCase().contains(_searchQuery);
                    return nameMatch || emailMatch;
                  }
                  return true;
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
                            child: const Icon(Icons.people_outline_rounded,
                                size: 48, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No users found matching "$_searchQuery"'
                                : 'No members registered yet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => _showAddMemberModal(context),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: const Text('Add New Member'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    final isSelf = u.uid == currentUid;
                    final isAdmin = u.role == UserRole.admin;
                    final isScorer = u.role == UserRole.scorer;

                    // Clean phone vs email display
                    String displayContact = u.email;
                    bool isPhone = false;
                    if (u.email.endsWith('@member.cricket.com')) {
                      displayContact = u.email.replaceAll('@member.cricket.com', '');
                      isPhone = true;
                    }

                    // Matching player if any
                    Player? linkedPlayer;
                    for (final p in players) {
                      if (p.phoneNumber == displayContact ||
                          p.name.toLowerCase() == u.displayName.toLowerCase()) {
                        linkedPlayer = p;
                        break;
                      }
                    }

                    final imageProvider = _getImageProvider(u.photoUrl ?? linkedPlayer?.profilePicUrl);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0.8,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isAdmin
                              ? const Color(0xFFFDE68A)
                              : isScorer
                                  ? const Color(0xFFDDD6FE)
                                  : const Color(0xFFE2E8F0),
                          width: isAdmin || isScorer ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Avatar / Squircle
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isAdmin
                                    ? const Color(0xFFFFFBEB)
                                    : isScorer
                                        ? const Color(0xFFF5F3FF)
                                        : const Color(0xFFEFF6FF),
                                border: Border.all(
                                  color: isAdmin
                                      ? const Color(0xFFF59E0B)
                                      : isScorer
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFF3B82F6),
                                  width: 1.5,
                                ),
                                image: imageProvider != null
                                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                                    : null,
                              ),
                              child: imageProvider == null
                                  ? Center(
                                      child: Text(
                                        u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'M',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: isAdmin
                                              ? const Color(0xFFB45309)
                                              : isScorer
                                                  ? const Color(0xFF6D28D9)
                                                  : const Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Member Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          u.displayName.isNotEmpty ? u.displayName : 'Unnamed Member',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelf)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),

                                  // Contact Info
                                  Row(
                                    children: [
                                      Icon(
                                        isPhone ? Icons.phone_android_rounded : Icons.email_outlined,
                                        size: 13,
                                        color: const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          displayContact,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Role Badge + Joined Date
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? const Color(0xFFFEF3C7)
                                              : isScorer
                                                  ? const Color(0xFFEDE9FE)
                                                  : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isAdmin
                                                ? const Color(0xFFFDE68A)
                                                : isScorer
                                                    ? const Color(0xFFDDD6FE)
                                                    : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isAdmin
                                                  ? Icons.workspace_premium_rounded
                                                  : isScorer
                                                      ? Icons.edit_note_rounded
                                                      : Icons.sports_cricket_rounded,
                                              size: 12,
                                              color: isAdmin
                                                  ? const Color(0xFFB45309)
                                                  : isScorer
                                                      ? const Color(0xFF6D28D9)
                                                      : const Color(0xFF475569),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isAdmin
                                                  ? 'ADMIN'
                                                  : isScorer
                                                      ? 'OFFICIAL SCORER'
                                                      : 'MEMBER',
                                              style: TextStyle(
                                                color: isAdmin
                                                    ? const Color(0xFFB45309)
                                                    : isScorer
                                                        ? const Color(0xFF6D28D9)
                                                        : const Color(0xFF475569),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (linkedPlayer != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            linkedPlayer.role.label,
                                            style: const TextStyle(
                                              color: Color(0xFF15803D),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (u.createdAt != null) ...[
                                        const Spacer(),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(u.createdAt!),
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions Popup Menu
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (action) async {
                                if (action == 'make_scorer') {
                                  await repo.updateRole(u.uid, UserRole.scorer);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${u.displayName} is now an Official Scorer. They can create matches & record scores!'),
                                        backgroundColor: const Color(0xFF7C3AED),
                                      ),
                                    );
                                  }
                                } else if (action == 'make_admin') {
                                  await repo.updateRole(u.uid, UserRole.admin);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${u.displayName} promoted to Administrator!'),
                                        backgroundColor: const Color(0xFFD97706),
                                      ),
                                    );
                                  }
                                } else if (action == 'make_member') {
                                  if (isSelf) return;
                                  await repo.updateRole(u.uid, UserRole.member);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${u.displayName} role set to Member.'),
                                        backgroundColor: const Color(0xFF16A34A),
                                      ),
                                    );
                                  }
                                } else if (action == 'remove') {
                                  if (isSelf) return;
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Remove User?', style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: Text('Are you sure you want to remove ${u.displayName}?'),
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
                                          child: const Text('Remove'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await repo.removeUser(u.uid);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${u.displayName} removed successfully.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                if (u.role != UserRole.scorer)
                                  const PopupMenuItem(
                                    value: 'make_scorer',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_note_rounded, color: Color(0xFF7C3AED), size: 18),
                                        SizedBox(width: 8),
                                        Text('Grant Scorer Role (Create & Score)'),
                                      ],
                                    ),
                                  ),
                                if (u.role != UserRole.admin)
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 18),
                                        SizedBox(width: 8),
                                        Text('Make Administrator'),
                                      ],
                                    ),
                                  ),
                                if (u.role != UserRole.member && !isSelf)
                                  const PopupMenuItem(
                                    value: 'make_member',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 18),
                                        SizedBox(width: 8),
                                        Text('Set as Normal Member'),
                                      ],
                                    ),
                                  ),
                                if (!isSelf)
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Remove User', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
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
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Member / Scorer Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddMemberModalSheet extends ConsumerStatefulWidget {
  const _AddMemberModalSheet();

  @override
  ConsumerState<_AddMemberModalSheet> createState() => _AddMemberModalSheetState();
}

class _AddMemberModalSheetState extends ConsumerState<_AddMemberModalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.member;
  bool _alsoCreatePlayer = true;
  PlayerRole _playerRole = PlayerRole.allRounder;
  String? _photoBase64;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
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
      setState(() => _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      // 1. Create member in Auth + Firestore
      final createdUid = await ref.read(memberRepositoryProvider).createMember(
        name: name,
        phoneNumber: phone,
        role: _selectedRole,
        photoUrl: _photoBase64,
      );

      // 2. Optionally create player profile in club pool
      if (_alsoCreatePlayer) {
        final newPlayer = Player(
          id: createdUid ?? '',
          name: name,
          teamId: '',
          role: _playerRole,
          battingStyle: BattingStyle.rightHand,
          bowlingStyle: BowlingStyle.none,
          phoneNumber: phone,
          profilePicUrl: _photoBase64,
        );
        await ref.read(playerControllerProvider.notifier).create(newPlayer);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member $name added successfully!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add member: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? photoPreview;
    if (_photoBase64 != null) {
      try {
        final base64String = _photoBase64!.contains(',')
            ? _photoBase64!.split(',').last
            : _photoBase64!;
        photoPreview = MemoryImage(base64Decode(base64String));
      } catch (_) {}
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Member / Scorer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Register a new app user or official scorer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
          const Divider(height: 16),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                              ? const Icon(Icons.person_outline_rounded, size: 40, color: Color(0xFF94A3B8))
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
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Member Full Name *',
                      hintText: 'e.g. Suresh Kumar',
                      prefixIcon: const Icon(Icons.person_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter member name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Mobile Number
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: 'e.g. 9876543210',
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                      if (v.trim().length < 5) return 'Please enter a valid mobile number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Automatic Login: User ID & Password will both be set to this Mobile Number.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Role Selection
                  const Text(
                    'Select User Role *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleSelectTile(
                          title: '🏏 Member',
                          subtitle: 'View Matches & Stats',
                          role: UserRole.member,
                          selectedColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRoleSelectTile(
                          title: '✍️ Scorer',
                          subtitle: 'Create & Live Score',
                          role: UserRole.scorer,
                          selectedColor: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRoleSelectTile(
                    title: '👑 Administrator',
                    subtitle: 'Full Control (Teams, Matches, Members & Scoring)',
                    role: UserRole.admin,
                    selectedColor: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 18),

                  // Also create as Club Player Checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _alsoCreatePlayer,
                              activeColor: const Color(0xFF1E3A8A),
                              onChanged: (val) => setState(() => _alsoCreatePlayer = val ?? true),
                            ),
                            const Expanded(
                              child: Text(
                                'Also add as Player to Club Roster',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                        if (_alsoCreatePlayer) ...[
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          const Text('Playing Role:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: PlayerRole.values.map((r) {
                              final isSelected = _playerRole == r;
                              return ChoiceChip(
                                label: Text(r.label),
                                selected: isSelected,
                                onSelected: (s) => setState(() => _playerRole = r),
                                selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF475569),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 11.5,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSaving ? 'Creating Member...' : 'Save & Add Member',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectTile({
    required String title,
    required String subtitle,
    required UserRole role,
    required Color selectedColor,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isSelected ? selectedColor : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: selectedColor, size: 16),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? selectedColor.withOpacity(0.8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
