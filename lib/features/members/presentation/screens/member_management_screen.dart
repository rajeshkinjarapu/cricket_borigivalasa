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

class UnifiedMember {
  final String id;
  final String? uid;
  final String name;
  final String? contact;
  final bool isPhone;
  final UserRole role;
  final String? photoUrl;
  final Player? linkedPlayer;
  final DateTime? createdAt;
  final bool isSelf;

  UnifiedMember({
    required this.id,
    this.uid,
    required this.name,
    this.contact,
    this.isPhone = false,
    required this.role,
    this.photoUrl,
    this.linkedPlayer,
    this.createdAt,
    this.isSelf = false,
  });
}

class MemberManagementScreen extends ConsumerStatefulWidget {
  final String initialFilter;

  const MemberManagementScreen({
    super.key,
    this.initialFilter = 'all',
  });

  @override
  ConsumerState<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends ConsumerState<MemberManagementScreen> {
  String _searchQuery = '';
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

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

  void _showAddModal(BuildContext context, {bool defaultToScorer = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberOrScorerModalSheet(
        initialRole: defaultToScorer ? UserRole.scorer : UserRole.member,
        initialTab: defaultToScorer ? 0 : 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(memberListProvider);
    final playersAsync = ref.watch(allPlayersProvider);
    final repo = ref.read(memberRepositoryProvider);
    final currentUid = repo.currentUid;
    final isScorerView = _selectedFilter == 'scorer';

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
        title: Text(
          isScorerView ? 'Official Scorers' : 'Members & Scorers',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isScorerView ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: Colors.white),
            tooltip: isScorerView ? 'Add Scorer' : 'Add Member',
            onPressed: () => _showAddModal(context, defaultToScorer: isScorerView),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_add_member_or_scorer',
        onPressed: () => _showAddModal(context, defaultToScorer: isScorerView),
        backgroundColor: isScorerView ? const Color(0xFF7C3AED) : const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(isScorerView ? Icons.edit_note_rounded : Icons.person_add_rounded),
        label: Text(
          isScorerView ? 'Add Scorer' : 'Add Member',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    hintText: isScorerView ? 'Search scorers by name or phone...' : 'Search members, players, or phone...',
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
                      _buildFilterChip('🏏 Members & Players', 'member'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Members & Players Unified List ──
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

                // Combine registered users + all players
                final List<UnifiedMember> unifiedList = [];
                final Set<String> processedPlayerIds = {};
                final Set<String> processedPhones = {};
                final Set<String> processedNames = {};

                // 1. Process users
                for (final u in users) {
                  String displayContact = u.email;
                  bool isPhone = false;
                  if (u.email.endsWith('@member.cricket.com')) {
                    displayContact = u.email.replaceAll('@member.cricket.com', '');
                    isPhone = true;
                  }

                  Player? linkedPlayer;
                  for (final p in players) {
                    if ((p.phoneNumber != null && p.phoneNumber == displayContact) ||
                        p.id == u.uid ||
                        p.name.toLowerCase().trim() == u.displayName.toLowerCase().trim()) {
                      linkedPlayer = p;
                      processedPlayerIds.add(p.id);
                      break;
                    }
                  }

                  if (isPhone && displayContact.isNotEmpty) processedPhones.add(displayContact);
                  if (u.displayName.isNotEmpty) processedNames.add(u.displayName.toLowerCase().trim());

                  unifiedList.add(UnifiedMember(
                    id: u.uid,
                    uid: u.uid,
                    name: u.displayName.isNotEmpty ? u.displayName : 'Member',
                    contact: displayContact,
                    isPhone: isPhone,
                    role: u.role,
                    photoUrl: u.photoUrl ?? linkedPlayer?.profilePicUrl,
                    linkedPlayer: linkedPlayer,
                    createdAt: u.createdAt,
                    isSelf: u.uid == currentUid,
                  ));
                }

                // 2. Add players not in users collection yet
                for (final p in players) {
                  if (processedPlayerIds.contains(p.id)) continue;
                  if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty && processedPhones.contains(p.phoneNumber)) continue;
                  if (processedNames.contains(p.name.toLowerCase().trim())) continue;

                  unifiedList.add(UnifiedMember(
                    id: p.id,
                    uid: null, // Standalone player
                    name: p.name,
                    contact: p.phoneNumber ?? '',
                    isPhone: p.phoneNumber != null && p.phoneNumber!.isNotEmpty,
                    role: UserRole.member,
                    photoUrl: p.profilePicUrl,
                    linkedPlayer: p,
                    createdAt: p.createdAt,
                    isSelf: false,
                  ));
                }

                // Filter unified list
                final filtered = unifiedList.where((u) {
                  // Role Filter
                  if (_selectedFilter == 'admin' && u.role != UserRole.admin) return false;
                  if (_selectedFilter == 'scorer' && u.role != UserRole.scorer) return false;
                  if (_selectedFilter == 'member' && u.role != UserRole.member) return false;

                  // Search Filter
                  if (_searchQuery.isNotEmpty) {
                    final nameMatch = u.name.toLowerCase().contains(_searchQuery);
                    final contactMatch = (u.contact ?? '').toLowerCase().contains(_searchQuery);
                    return nameMatch || contactMatch;
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
                            child: Icon(
                              isScorerView ? Icons.edit_note_rounded : Icons.people_outline_rounded,
                              size: 48,
                              color: isScorerView ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isScorerView
                                ? 'No Official Scorers appointed yet.'
                                : (_searchQuery.isNotEmpty
                                    ? 'No members found matching "$_searchQuery"'
                                    : 'No members or players found.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isScorerView)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Appoint scorers from players, members, or register new ones. Scorers can create matches and score live.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddModal(context, defaultToScorer: isScorerView),
                            icon: Icon(isScorerView ? Icons.edit_note_rounded : Icons.person_add_rounded, size: 18),
                            label: Text(isScorerView ? 'Appoint / Add Scorer' : 'Add New Member'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isScorerView ? const Color(0xFF7C3AED) : const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    final isSelf = u.isSelf;
                    final isAdmin = u.role == UserRole.admin;
                    final isScorer = u.role == UserRole.scorer;
                    final isPlayer = u.linkedPlayer != null;

                    final imageProvider = _getImageProvider(u.photoUrl);

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
                                        u.name.isNotEmpty ? u.name[0].toUpperCase() : 'M',
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
                                          u.name,
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
                                  if (u.contact != null && u.contact!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          u.isPhone ? Icons.phone_android_rounded : Icons.email_outlined,
                                          size: 13,
                                          color: const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            u.contact!,
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
                                                      : Icons.person_rounded,
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
                                                      : (u.uid != null ? 'MEMBER' : 'PLAYER'),
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
                                      if (isPlayer) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            '🏏 ${u.linkedPlayer!.role.label}',
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
                                  if (u.uid != null) {
                                    await repo.updateRole(u.uid!, UserRole.scorer);
                                  } else {
                                    await repo.createMember(
                                      name: u.name,
                                      phoneNumber: u.contact ?? u.name,
                                      role: UserRole.scorer,
                                      photoUrl: u.photoUrl,
                                    );
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${u.name} is now an Official Scorer. They can create matches & record scores!'),
                                        backgroundColor: const Color(0xFF7C3AED),
                                      ),
                                    );
                                  }
                                } else if (action == 'make_admin') {
                                  if (u.uid != null) {
                                    await repo.updateRole(u.uid!, UserRole.admin);
                                  } else {
                                    await repo.createMember(
                                      name: u.name,
                                      phoneNumber: u.contact ?? u.name,
                                      role: UserRole.admin,
                                      photoUrl: u.photoUrl,
                                    );
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${u.name} promoted to Administrator!'),
                                        backgroundColor: const Color(0xFFD97706),
                                      ),
                                    );
                                  }
                                } else if (action == 'make_member') {
                                  if (isSelf) return;
                                  if (u.uid != null) {
                                    await repo.updateRole(u.uid!, UserRole.member);
                                  } else {
                                    await repo.createMember(
                                      name: u.name,
                                      phoneNumber: u.contact ?? u.name,
                                      role: UserRole.member,
                                      photoUrl: u.photoUrl,
                                    );
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${u.name} role set to Member.'),
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
                                      content: Text('Are you sure you want to remove ${u.name}?'),
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
                                    if (u.uid != null) await repo.removeUser(u.uid!);
                                    if (u.linkedPlayer != null) {
                                      await ref.read(playerControllerProvider.notifier).delete(u.linkedPlayer!.id);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${u.name} removed successfully.'),
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
// Add / Appoint Member or Scorer Modal Sheet (3 Tabs: Players, Members, Register New)
// ─────────────────────────────────────────────────────────────────────────────
class _AddMemberOrScorerModalSheet extends ConsumerStatefulWidget {
  const _AddMemberOrScorerModalSheet({
    this.initialRole = UserRole.scorer,
    this.initialTab = 0,
  });

  final UserRole initialRole;
  final int initialTab;

  @override
  ConsumerState<_AddMemberOrScorerModalSheet> createState() => _AddMemberOrScorerModalSheetState();
}

class _AddMemberOrScorerModalSheetState extends ConsumerState<_AddMemberOrScorerModalSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 & 2 search queries
  String _playerSearch = '';
  String _memberSearch = '';

  // Tab 3 form state
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late UserRole _selectedRole;
  bool _alsoCreatePlayer = true;
  PlayerRole _playerRole = PlayerRole.allRounder;
  String? _photoBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _submitNewRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      final createdUid = await ref.read(memberRepositoryProvider).createMember(
        name: name,
        phoneNumber: phone,
        role: _selectedRole,
        photoUrl: _photoBase64,
      );

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
            content: Text('${_selectedRole == UserRole.scorer ? "Scorer" : "Member"} $name registered successfully!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final allPlayersAsync = ref.watch(allPlayersProvider);
    final allMembersAsync = ref.watch(memberListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appoint / Add Scorer & Member',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Select from existing players, members, or register a new one',
                        style: TextStyle(
                          fontSize: 12.5,
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
          const SizedBox(height: 10),

          // ── 3 Tabs ──
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
                    color: const Color(0xFF1E3A8A).withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF475569),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'From Players'),
                Tab(text: 'From Members'),
                Tab(text: 'Register New'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab Bar Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── TAB 1: From Existing Players ──
                _buildPlayersTab(allPlayersAsync),

                // ── TAB 2: From Existing Members ──
                _buildMembersTab(allMembersAsync),

                // ── TAB 3: Register New Scorer / Member Form ──
                _buildRegisterNewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Select Player to make Scorer ──
  Widget _buildPlayersTab(AsyncValue<List<Player>> playersAsync) {
    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (players) {
        final filtered = players.where((p) {
          if (_playerSearch.isEmpty) return true;
          return p.name.toLowerCase().contains(_playerSearch.toLowerCase()) ||
              (p.phoneNumber ?? '').contains(_playerSearch);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                onChanged: (val) => setState(() => _playerSearch = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search club players by name or phone...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No players found.', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                                style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              '${p.role.label} • 📞 ${p.phoneNumber ?? "No phone"}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            trailing: ElevatedButton.icon(
                              onPressed: () async {
                                await ref.read(memberRepositoryProvider).createMember(
                                  name: p.name,
                                  phoneNumber: p.phoneNumber ?? p.name,
                                  role: UserRole.scorer,
                                  photoUrl: p.profilePicUrl,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${p.name} is now an Official Scorer!'),
                                      backgroundColor: const Color(0xFF7C3AED),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.edit_note_rounded, size: 16),
                              label: const Text('Make Scorer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
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

  // ── Tab 2: Select Member to make Scorer ──
  Widget _buildMembersTab(AsyncValue<List<AppUser>> membersAsync) {
    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        final filtered = members.where((m) {
          if (_memberSearch.isEmpty) return true;
          return m.displayName.toLowerCase().contains(_memberSearch.toLowerCase()) ||
              m.email.toLowerCase().contains(_memberSearch.toLowerCase());
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                onChanged: (val) => setState(() => _memberSearch = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search registered members...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No members found.', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final m = filtered[i];
                        final isAlreadyScorer = m.role == UserRole.scorer;

                        String displayContact = m.email;
                        if (m.email.endsWith('@member.cricket.com')) {
                          displayContact = m.email.replaceAll('@member.cricket.com', '');
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF3E8FF),
                              child: Text(
                                m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : 'M',
                                style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(m.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              'Role: ${m.role.name.toUpperCase()} • $displayContact',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            trailing: isAlreadyScorer
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Already Scorer', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 11)),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref.read(memberRepositoryProvider).updateRole(m.uid, UserRole.scorer);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${m.displayName} is now an Official Scorer!'),
                                            backgroundColor: const Color(0xFF7C3AED),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                                    label: const Text('Make Scorer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED),
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

  // ── Tab 3: Register New User / Scorer Form ──
  Widget _buildRegisterNewTab() {
    ImageProvider? photoPreview;
    if (_photoBase64 != null) {
      try {
        final base64String = _photoBase64!.contains(',')
            ? _photoBase64!.split(',').last
            : _photoBase64!;
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
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
                    image: photoPreview != null
                        ? DecorationImage(image: photoPreview, fit: BoxFit.cover)
                        : null,
                  ),
                  child: photoPreview == null
                      ? const Icon(Icons.person_outline_rounded, size: 36, color: Color(0xFF94A3B8))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Name
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g. Suresh Kumar',
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
          ),
          const SizedBox(height: 12),

          // Phone Number
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
                    'Auto-Login: User ID & Password will both be set to this Mobile Number.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Role selection
          const Text('Assign Role *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('✍️ Official Scorer')),
                  selected: _selectedRole == UserRole.scorer,
                  onSelected: (s) => setState(() => _selectedRole = UserRole.scorer),
                  selectedColor: const Color(0xFF7C3AED).withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('🏏 Member')),
                  selected: _selectedRole == UserRole.member,
                  onSelected: (s) => setState(() => _selectedRole = UserRole.member),
                  selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Also create as Player
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _alsoCreatePlayer,
                  activeColor: const Color(0xFF1E3A8A),
                  onChanged: (val) => setState(() => _alsoCreatePlayer = val ?? true),
                ),
                const Expanded(
                  child: Text(
                    'Also add to Club Players roster',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _submitNewRegistration,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isSaving ? 'Registering...' : 'Register & Assign Role',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedRole == UserRole.scorer ? const Color(0xFF7C3AED) : const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
