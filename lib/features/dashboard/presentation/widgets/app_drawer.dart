import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final bool isAdmin = user?.role == UserRole.admin;

    return Drawer(
      backgroundColor: const Color(0xFF0A192F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A192F), // Deep Navy
              Color(0xFF0F2464), // Royal Navy
              Color(0xFF1E3A8A), // Cricket Blue
            ],
          ),
        ),
        child: Column(
          children: [
            // ── Top Header with App Title & Logged-in User Info ──
            _buildDrawerHeader(context, user, isAdmin),

            // ── Navigation Items List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                children: [
                  // ── Group 1: MAIN ──
                  _buildSectionHeader('MAIN'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    route: isAdmin ? '/admin' : '/member',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(isAdmin ? '/admin' : '/member');
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.sports_cricket_rounded,
                    label: 'Matches',
                    route: '/matches-list',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/matches-list');
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.sensors_rounded,
                    label: 'Live Matches',
                    route: '/live-matches',
                    currentLocation: currentLocation,
                    accentColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/live-matches');
                    },
                  ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 10),

                  // ── Group 2: MANAGEMENT ──
                  _buildSectionHeader('MANAGEMENT'),
                  
                  // ONLY ADMIN sees Tournaments
                  if (isAdmin)
                    _buildNavItem(
                      context: context,
                      icon: Icons.emoji_events_rounded,
                      label: 'Tournaments',
                      route: '/tournaments',
                      currentLocation: currentLocation,
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/tournaments');
                      },
                    ),

                  _buildNavItem(
                    context: context,
                    icon: Icons.groups_rounded,
                    label: 'Teams & Clubs',
                    route: '/teams',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/teams');
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_search_rounded,
                    label: 'Players & Squads',
                    route: '/players',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/players');
                    },
                  ),
                  if (isAdmin)
                    _buildNavItem(
                      context: context,
                      icon: Icons.manage_accounts_rounded,
                      label: 'Manage Members',
                      route: '/members',
                      currentLocation: currentLocation,
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/members');
                      },
                    ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.leaderboard_rounded,
                    label: 'Stats & Standings',
                    route: '/stats',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/stats');
                    },
                  ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 10),

                  // ── Group 3: ACCOUNT ──
                  _buildSectionHeader('ACCOUNT'),
                  _buildNavItem(
                    context: context,
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    route: '/notifications',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.account_circle_rounded,
                    label: 'My Profile',
                    route: '/profile',
                    currentLocation: currentLocation,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                ],
              ),
            ),

            // ── Footer with App Version & Sign Out Button ──
            _buildDrawerFooter(context, ref),
          ],
        ),
      ),
    );
  }

  // ── Header Widget (Rich Cricket Blue Header) ──
  Widget _buildDrawerHeader(BuildContext context, AppUser? user, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Title + Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_cricket_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Borigivalasa Cricket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tournament & Scoring App',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Profile Quick Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF38BDF8),
                  backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                      ? Text(
                          (user?.displayName.isNotEmpty ?? false)
                              ? user!.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isAdmin ? '👑 Administrator' : '🏏 Club Member',
                        style: TextStyle(
                          color: isAdmin ? const Color(0xFFFBBF24) : const Color(0xFF6EE7B7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF60A5FA), // Sky Blue Accent
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Navigation Item (Blue Glassmorphic Active Pill) ──
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentLocation,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final bool isActive = currentLocation == route ||
        (route != '/admin' && route != '/member' && currentLocation.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isActive
            ? Colors.white.withOpacity(0.18)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isActive
              ? BorderSide(color: (accentColor ?? const Color(0xFF38BDF8)).withOpacity(0.6), width: 1.5)
              : BorderSide.none,
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? (accentColor ?? const Color(0xFF2563EB))
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: (accentColor ?? const Color(0xFF2563EB)).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : (accentColor ?? const Color(0xFF93C5FD)),
              size: 20,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFFE2E8F0),
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          trailing: isActive
              ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: accentColor ?? const Color(0xFF38BDF8),
                )
              : null,
        ),
      ),
    );
  }

  // ── Footer Section with Sign Out ──
  Widget _buildDrawerFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
      child: Column(
        children: [
          // App Title & Version Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_cricket_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Borigivalasa Cricket',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFFDC2626).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              Navigator.pop(context); // close drawer
              await ref.read(authControllerProvider.notifier).signOut();
              ref.invalidate(authStateProvider);
              ref.invalidate(currentUserProvider);
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
