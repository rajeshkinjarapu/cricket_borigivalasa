import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/match_providers.dart';
import '../../data/models/match.dart';

class MatchListTab extends ConsumerWidget {
  const MatchListTab({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournamentId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (matches) {
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_cricket, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No matches scheduled yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 24),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => context.push('/tournaments/$tournamentId/matches/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Schedule Match'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length + (isAdmin ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == matches.length && isAdmin) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/tournaments/$tournamentId/matches/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Match'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            }

            final match = matches[index];
            return _MatchCard(tournamentId: tournamentId, match: match);
          },
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.tournamentId, required this.match});
  final String tournamentId;
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == MatchStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isCompleted) {
            context.push('/tournaments/$tournamentId/matches/${match.id}/summary');
          } else {
            context.push('/tournaments/$tournamentId/matches/${match.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.status.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, hh:mm a').format(match.matchDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.teamA,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('VS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                      match.teamB,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${match.venue} • ${match.totalOvers} Overs', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
