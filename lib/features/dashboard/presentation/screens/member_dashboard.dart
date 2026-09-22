import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/live_match_card.dart';
import '../widgets/upcoming_match_card.dart';
import '../widgets/leaderboard_section.dart';
import '../widgets/app_drawer.dart';

class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider);
    final isScorer = u?.role == UserRole.scorer;

    final liveMatchesAsync = ref.watch(liveMatchesProvider);
    final upcomingMatchesAsync = ref.watch(upcomingMatchesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Member Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Profile Info Card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Square avatar with rounded corners
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                        image: getAppAvatarProvider(u?.photoUrl) != null
                            ? DecorationImage(image: getAppAvatarProvider(u?.photoUrl)!, fit: BoxFit.cover)
                            : null,
                      ),
                      child: getAppAvatarProvider(u?.photoUrl) == null
                          ? Center(
                              child: Text(
                                (u?.displayName.isNotEmpty ?? false) ? u!.displayName[0].toUpperCase() : 'M',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
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
                        const Text('Welcome back,', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                        Text(
                          u?.displayName ?? 'Member',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isScorer)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                                SizedBox(width: 4),
                                Text('Scorer', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _QuickActionBtn(
                    icon: Icons.sports_cricket,
                    label: 'View Matches',
                    color: const Color(0xFF2563EB),
                    onTap: () => context.push('/matches-list'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionBtn(
                    icon: Icons.leaderboard_rounded,
                    label: 'My Stats',
                    color: const Color(0xFF7C3AED),
                    onTap: () => context.push('/stats'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Upcoming Matches
            const _SectionTitle(title: '📅 UPCOMING MATCHES'),
            upcomingMatchesAsync.when(
              data: (matches) {
                if (matches.isEmpty) return const Padding(padding: EdgeInsets.only(bottom: 24), child: Text('No upcoming matches'));
                return Column(children: matches.map((m) => UpcomingMatchCard(match: m)).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Leaderboard
            const _SectionTitle(title: '🏅 LEADERBOARD'),
            const LeaderboardSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.black87),
      ),
    );
  }
}
