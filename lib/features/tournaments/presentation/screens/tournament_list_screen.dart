import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/models/tournament.dart';

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    final tournamentsAsync = ref.watch(allTournamentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Royal Blue Header
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tournaments',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Segmented Tab Bar (White/Light Background with Pill Tabs) ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF1E3A8A),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Ongoing'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF2563EB)),
                        SizedBox(width: 5),
                        Text('Upcoming'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 15, color: Color(0xFFD97706)),
                        SizedBox(width: 5),
                        Text('Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: tournamentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading tournaments: $e',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (tournaments) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _TournamentList(
                      tournaments: tournaments
                          .where((t) => t.status == TournamentStatus.ongoing)
                          .toList(),
                      emptyMessage: 'No ongoing tournaments in progress.',
                      emptyIcon: Icons.emoji_events_outlined,
                    ),
                    _TournamentList(
                      tournaments: tournaments
                          .where((t) => t.status == TournamentStatus.upcoming)
                          .toList(),
                      emptyMessage: 'No upcoming tournaments scheduled.',
                      emptyIcon: Icons.calendar_month_outlined,
                    ),
                    _TournamentList(
                      tournaments: tournaments
                          .where((t) => t.status == TournamentStatus.completed)
                          .toList(),
                      emptyMessage: 'No completed tournaments yet.',
                      emptyIcon: Icons.workspace_premium_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab_tournaments',
              onPressed: () => context.push('/tournaments/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Tournament',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
    );
  }
}

class _TournamentList extends StatelessWidget {
  final List<Tournament> tournaments;
  final String emptyMessage;
  final IconData emptyIcon;

  const _TournamentList({
    required this.tournaments,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
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
                child: Icon(emptyIcon, size: 48, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
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
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final t = tournaments[index];
        final isOngoing = t.status == TournamentStatus.ongoing;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isOngoing ? 2 : 0.8,
          shadowColor: isOngoing ? const Color(0xFF16A34A).withOpacity(0.2) : Colors.black12,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isOngoing ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
              width: isOngoing ? 1.4 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/tournaments/${t.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOngoing
                              ? const Color(0xFFF0FDF4)
                              : (t.status == TournamentStatus.upcoming
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOngoing
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFDBEAFE),
                          ),
                        ),
                        child: Text(
                          t.status.label.toUpperCase(),
                          style: TextStyle(
                            color: isOngoing
                                ? const Color(0xFF16A34A)
                                : (t.status == TournamentStatus.upcoming
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B)),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${DateFormat('MMM d').format(t.startDate)} - ${t.endDate != null ? DateFormat('MMM d, yyyy').format(t.endDate!) : 'Ongoing'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          t.venue ?? 'Chintathota Cricket Ground',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.format.label,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
