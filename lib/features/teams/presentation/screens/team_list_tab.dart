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
            if (teams.isEmpty) {
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
            return GridView.builder(
              padding: const EdgeInsets.all(16).copyWith(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return InkWell(
                  onTap: () {
                    // Navigate to Team Detail Screen later (Phase 6b)
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: team.logoUrl != null
                                ? ClipOval(child: Image.network(team.logoUrl!, width: 72, height: 72, fit: BoxFit.cover))
                                : Text(
                                    team.shortName.isNotEmpty ? team.shortName : team.name[0].toUpperCase(),
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            team.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team.captainName != null ? 'C: ${team.captainName}' : 'No Captain',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
