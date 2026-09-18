import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tournaments', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/tournaments/new'),
              icon: const Icon(Icons.add),
              label: const Text('New'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tournaments) {
          return TabBarView(
            controller: _tabController,
            children: [
              _TournamentList(
                tournaments: tournaments.where((t) => t.status == TournamentStatus.ongoing).toList(),
                emptyMessage: 'No ongoing tournaments',
              ),
              _TournamentList(
                tournaments: tournaments.where((t) => t.status == TournamentStatus.upcoming).toList(),
                emptyMessage: 'No upcoming tournaments',
              ),
              _TournamentList(
                tournaments: tournaments.where((t) => t.status == TournamentStatus.completed).toList(),
                emptyMessage: 'No completed tournaments',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TournamentList extends StatelessWidget {
  final List<dynamic> tournaments;
  final String emptyMessage;

  const _TournamentList({required this.tournaments, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final t = tournaments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Icons.emoji_events, color: Theme.of(context).primaryColor),
            ),
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
              'Starts: ${DateFormat('MMM d, yyyy').format(t.startDate)}\n${t.teamsCount} Teams',
              style: const TextStyle(height: 1.5),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tournaments/${t.id}'),
          ),
        );
      },
    );
  }
}
