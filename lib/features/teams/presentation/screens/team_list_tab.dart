import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/team_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/cricket_enums.dart';

class TeamListTab extends ConsumerWidget {
  const TeamListTab({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(tournamentTeamsProvider(tournamentId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return Stack(
      children: [
        teamsAsync.when(
          data: (teams) {
            // Filter out County teams based on database flag and name
            final displayTeams = teams.where((t) => !t.isCounty && !t.name.toLowerCase().contains('county')).toList();

            if (displayTeams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No teams added to this tournament.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16).copyWith(bottom: 80),
              itemCount: displayTeams.length,
              itemBuilder: (context, index) {
                final team = displayTeams[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Navigate to Team Detail Screen later (Phase 6b)
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: team.logoUrl != null
                                ? ClipOval(child: Image.network(team.logoUrl!, width: 56, height: 56, fit: BoxFit.cover))
                                : Text(
                                    team.shortName.isNotEmpty ? team.shortName : team.name[0].toUpperCase(),
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  team.captainName != null ? 'Captain: ${team.captainName}' : 'No Captain',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        if (isAdmin)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              heroTag: 'addTeamFab',
              onPressed: () => context.push('/tournaments/$tournamentId/teams/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Team'),
            ),
          ),
      ],
    );
  }
}
