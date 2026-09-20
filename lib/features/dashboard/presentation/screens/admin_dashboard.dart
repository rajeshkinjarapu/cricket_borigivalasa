import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../members/presentation/providers/member_providers.dart';
import '../../widgets/dashboard_tile.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/live_match_card.dart';
import '../widgets/app_drawer.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  ImageProvider? _getAvatarImage(String? photoUrl) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider);
    final totalTeams = ref.watch(totalTeamsCountProvider);
    final totalMembers = ref.watch(totalUnifiedMembersCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: const Color(0xFF1E3A8A),
        onRefresh: () async {
          ref.invalidate(liveMatchesProvider);
          ref.invalidate(totalTeamsCountProvider);
          ref.invalidate(totalPlayersCountProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Hero Header Card ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withOpacity(0.25),
                        image: _getAvatarImage(u?.photoUrl) != null
                            ? DecorationImage(
                                image: _getAvatarImage(u?.photoUrl)!,
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: _getAvatarImage(u?.photoUrl) == null
                          ? Center(
                              child: Text(
                                (u?.displayName.isNotEmpty ?? false)
                                    ? u!.displayName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 34),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${(u?.displayName.isNotEmpty == true) ? u!.displayName : 'Rajesh Kinjarapu'} 👋',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Administrator',
                              style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats Mini Cards Row ──
            Row(
              children: [
                _statCard(
                  label: 'Tournaments',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFD97706),
                  value: ref.watch(totalTournamentsCountProvider).when(
                      data: (v) => '$v',
                      loading: () => '...',
                      error: (_, __) => '-'),
                ),
                const SizedBox(width: 12),
                _statCard(
                  label: 'Teams',
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF2563EB),
                  value: totalTeams.when(
                      data: (v) => '$v',
                      loading: () => '...',
                      error: (_, __) => '-'),
                ),
                const SizedBox(width: 12),
                _statCard(
                  label: 'Members',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF16A34A),
                  value: totalMembers.when(
                      data: (count) => '$count',
                      loading: () => '...',
                      error: (_, __) => '-'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Manage Operations Grid ──
            Text('Manage Operations',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 14),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                _AnimatedTile(
                  child: DashboardTile(
                    icon: Icons.emoji_events_rounded,
                    label: 'Tournaments',
                    subtitle: 'Create & manage',
                    color: Colors.orange.shade100,
                    iconColor: Colors.orange.shade800,
                    onTap: () => context.push('/tournaments'),
                  ),
                ),
                _AnimatedTile(
                  child: DashboardTile(
                    icon: Icons.groups_rounded,
                    label: 'Teams',
                    subtitle: 'Manage all teams',
                    color: Colors.blue.shade100,
                    iconColor: Colors.blue.shade800,
                    onTap: () => context.push('/teams'),
                  ),
                ),
                _AnimatedTile(
                  child: DashboardTile(
                    icon: Icons.person_search_rounded,
                    label: 'Players',
                    subtitle: 'Squads & stats',
                    color: Colors.green.shade100,
                    iconColor: Colors.green.shade800,
                    onTap: () => context.push('/players'),
                  ),
                ),
                _AnimatedTile(
                  child: DashboardTile(
                    icon: Icons.sports_cricket_rounded,
                    label: 'Matches',
                    subtitle: 'Schedule & view',
                    color: Colors.purple.shade100,
                    iconColor: Colors.purple.shade800,
                    onTap: () => context.push('/matches-list'),
                  ),
                ),
                _AnimatedTile(
                  child: DashboardTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Scorer',
                    subtitle: 'Live ball-by-ball',
                    color: const Color(0xFFFCE7F3),
                    iconColor: const Color(0xFFBE185D),
                    onTap: () => context.push('/matches-list'),
                  ),
                ),
                _AnimatedTile(
                  child: DashboardTile(
                    icon: Icons.manage_accounts_rounded,
                    label: 'Members',
                    subtitle: 'Manage users & roles',
                    color: Colors.teal.shade100,
                    iconColor: Colors.teal.shade800,
                    onTap: () => context.push('/members'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Stat mini card ──
  Widget _statCard(
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration:
                  BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Tap animation wrapper ──
class _AnimatedTile extends StatefulWidget {
  final Widget child;
  const _AnimatedTile({required this.child});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

