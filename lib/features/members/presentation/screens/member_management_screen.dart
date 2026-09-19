import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/data/models/app_user.dart';
import '../providers/member_providers.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends ConsumerState<MemberManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'admin', 'member'

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(memberListProvider);
    final repo = ref.read(memberRepositoryProvider);
    final currentUid = repo.currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Registered Members',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: Colors.white,
          ),
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
                    hintText: 'Search by name or email/phone...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
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
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Admins', 'admin'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Members', 'member'),
                  ],
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
                final filtered = users.where((u) {
                  // Role Filter
                  if (_selectedFilter == 'admin' && u.role != UserRole.admin) return false;
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
                                ? 'No members found matching "$_searchQuery"'
                                : 'No registered members found.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    final isSelf = u.uid == currentUid;
                    final isAdmin = u.role == UserRole.admin;

                    // Clean phone vs email display
                    String displayContact = u.email;
                    bool isPhone = false;
                    if (u.email.endsWith('@member.cricket.com')) {
                      displayContact = u.email.replaceAll('@member.cricket.com', '');
                      isPhone = true;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0.6,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFE2E8F0),
                          width: isAdmin ? 1.2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAdmin
                                    ? const Color(0xFFFFFBEB)
                                    : const Color(0xFFEFF6FF),
                                border: Border.all(
                                  color: isAdmin
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF3B82F6),
                                  width: 1.5,
                                ),
                              ),
                              child: (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        u.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarInitial(u),
                                      ),
                                    )
                                  : _buildAvatarInitial(u),
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
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
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

                                  // Email / Phone
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
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isAdmin
                                                ? const Color(0xFFFDE68A)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isAdmin
                                                  ? Icons.workspace_premium_rounded
                                                  : Icons.sports_cricket_rounded,
                                              size: 12,
                                              color: isAdmin
                                                  ? const Color(0xFFB45309)
                                                  : const Color(0xFF475569),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isAdmin ? 'ADMIN' : 'MEMBER',
                                              style: TextStyle(
                                                color: isAdmin
                                                    ? const Color(0xFFB45309)
                                                    : const Color(0xFF475569),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (u.createdAt != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(u.createdAt!),
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
                                if (action == 'promote') {
                                  await repo.updateRole(u.uid, UserRole.admin);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${u.displayName} promoted to Admin')),
                                    );
                                  }
                                } else if (action == 'demote') {
                                  if (isSelf) return;
                                  await repo.updateRole(u.uid, UserRole.member);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${u.displayName} changed to Member')),
                                    );
                                  }
                                } else if (action == 'remove') {
                                  if (isSelf) return;
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Remove Member?',
                                    message: 'Are you sure you want to remove ${u.displayName}?',
                                  );
                                  if (ok) {
                                    await repo.removeUser(u.uid);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${u.displayName} removed')),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                if (u.role == UserRole.member)
                                  const PopupMenuItem(
                                    value: 'promote',
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 18),
                                        SizedBox(width: 8),
                                        Text('Make Admin'),
                                      ],
                                    ),
                                  )
                                else if (!isSelf)
                                  const PopupMenuItem(
                                    value: 'demote',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 18),
                                        SizedBox(width: 8),
                                        Text('Demote to Member'),
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

  Widget _buildAvatarInitial(AppUser u) {
    final initial = u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'M';
    final isAdmin = u.role == UserRole.admin;
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: isAdmin ? const Color(0xFFB45309) : const Color(0xFF1E3A8A),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
