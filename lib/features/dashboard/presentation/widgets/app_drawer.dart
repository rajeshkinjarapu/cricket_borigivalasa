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

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ── Header Section ──
          _buildDrawerHeader(context, user),

          // ── Navigation Items (Grouped) ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                // Group 1: MAIN
                _buildSectionHeader('MAIN'),
                _buildNavItem(
                  context: context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  route: user?.role == UserRole.admin ? '/admin' : '/member',
                  currentLocation: currentLocation,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(user?.role == UserRole.admin ? '/admin' : '/member');
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

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Group 2: MANAGEMENT
                _buildSectionHeader('MANAGEMENT'),
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
                if (user?.role == UserRole.admin)
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
                  icon: Icons.analytics_rounded,
                  label: 'Stats & Overview',
                  route: '/stats',
                  currentLocation: currentLocation,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/stats');
                  },
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Group 3: ACCOUNT & SETTINGS
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

          // ── Footer Section ──
          _buildDrawerFooter(context, ref),
        ],
      ),
    );
  }

  // ── Header Widget (Simple Clean Minimalist Header) ──
  Widget _buildDrawerHeader(BuildContext context, AppUser? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              color: Color(0xFF1E3A8A),
              size: 26,
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
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Tournament & Scoring App',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8), // slate-400
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // ── Active/Inactive Navigation Item ──
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentLocation,
    required VoidCallback onTap,
  }) {
    final bool isActive = currentLocation == route ||
        (route != '/admin' && route != '/member' && currentLocation.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: isActive
            ? const Color(0xFF1E3A8A).withOpacity(0.09)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isActive
              ? BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.25), width: 1.2)
              : BorderSide.none,
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          dense: true,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF475569),
              size: 19,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: isActive
              ? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF1E3A8A),
                )
              : null,
        ),
      ),
    );
  }

  // ── Footer Section ──
  Widget _buildDrawerFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.sports_cricket_rounded,
                      size: 14,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Borigivalasa Cricket',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
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
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context); // close drawer
              ref.read(authControllerProvider.notifier).signOut();
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
