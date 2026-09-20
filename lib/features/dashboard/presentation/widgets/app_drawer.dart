import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const Color drawerBlue = Color(0xFF1E3A8A); // Clean, solid Royal Blue theme

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final bool isAdmin = user?.role == UserRole.admin;

    return Drawer(
      backgroundColor: drawerBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Clean App Header (No Administrator Box) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.sports_cricket_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Borigivalasa Cricket',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tournament & Scoring App',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation Items List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  // ── MAIN ──
                  _buildSectionLabel('MAIN'),
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
                    icon: Icons.sports_score_rounded,
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
                    badgeText: 'LIVE',
                    badgeColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/live-matches');
                    },
                  ),

                  const SizedBox(height: 8),
                  Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 8),

                  // ── MANAGEMENT ──
                  _buildSectionLabel('MANAGEMENT'),
                  if (isAdmin)
                    _buildNavItem(
                      context: context,
                      icon: Icons.emoji_events_rounded,
                      label: 'Tournaments',
                      route: '/tournaments',
                      currentLocation: currentLocation,
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
                      label: 'Members',
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

                  const SizedBox(height: 8),
                  Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                  const SizedBox(height: 8),

                  // ── ACCOUNT ──
                  _buildSectionLabel('ACCOUNT'),
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

            // ── Clean Footer with Sign Out ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
                ),
              ),
              child: SizedBox(
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
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentLocation,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
  }) {
    final bool isActive = currentLocation == route ||
        (route != '/admin' && route != '/member' && currentLocation.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isActive
              ? BorderSide(color: Colors.white.withOpacity(0.4), width: 1.2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.85),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (isActive)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
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
          'Are you sure you want to sign out?',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
