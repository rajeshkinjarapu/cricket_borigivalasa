import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../providers/team_providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({super.key, required this.tournamentId, required this.teamId});
  final String tournamentId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final playersAsync = ref.watch(teamPlayersProvider(teamId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return teamAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (team) {
        if (team == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Team not found')));

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(team.name),
            actions: [
              if (isAdmin)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      context.push('/tournaments/$tournamentId/teams/$teamId/edit');
                    } else if (v == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Team?'),
                          content: Text('Are you sure you want to delete ${team.name}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(teamControllerProvider.notifier).delete(team.id);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
                      child: team.logoUrl == null
                          ? Text(
                              team.shortName.isNotEmpty ? team.shortName : team.name[0].toUpperCase(),
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(team.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (team.captainName != null && team.captainName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Chip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text('Captain: ${team.captainName}'),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                        tabs: const [
                          Tab(text: 'Squad'),
                          Tab(text: 'Matches'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Squad Tab
                            playersAsync.when(
                              data: (players) {
                                if (players.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.groups, size: 64, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        const Text('No players added yet.', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                                  itemCount: players.length,
                                  itemBuilder: (context, index) {
                                    final p = players[index];
                                    return Card(
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      child: ListTile(
                                        onTap: () => context.push('/tournaments/$tournamentId/teams/$teamId/players/${p.id}/stats'),
                                        leading: CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                          backgroundImage: p.profilePicUrl != null ? NetworkImage(p.profilePicUrl!) : null,
                                          child: p.profilePicUrl == null
                                              ? Text(p.name[0].toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold))
                                              : null,
                                        ),
                                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(p.role.label),
                                        trailing: isAdmin
                                            ? IconButton(
                                                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                                                onPressed: () => context.push('/tournaments/$tournamentId/teams/$teamId/players/${p.id}/edit'),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, _) => Center(child: Text('Error: $e')),
                            ),
                            // Matches Tab (Placeholder)
                            const Center(child: Text('Recent matches will appear here', style: TextStyle(color: Colors.grey))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/tournaments/$tournamentId/teams/$teamId/players/new'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Player'),
                )
              : null,
        );
      },
    );
  }
}
