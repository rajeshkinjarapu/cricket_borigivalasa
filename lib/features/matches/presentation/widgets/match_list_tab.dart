import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/match_providers.dart';

class MatchListTab extends ConsumerWidget {
  const MatchListTab({super.key, required this.tournamentId});
  final String tournamentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(matchListProvider(tournamentId));
    final isAdmin = ref.watch(currentUserProvider)?.role == UserRole.admin;
    return Scaffold(backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin ? FloatingActionButton.small(
        onPressed: () => context.push(
          '/tournaments/$tournamentId/matches/new'),
        child: const Icon(Icons.add)) : null,
      body: a.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (matches) {
          if (matches.isEmpty) return EmptyState(
            icon: Icons.sports_cricket_outlined, title: 'No matches yet',
            subtitle: isAdmin ? 'Schedule the first match' : 'Fixtures soon',
            actionLabel: isAdmin ? 'Schedule' : null,
            onAction: isAdmin ? () => context.push(
              '/tournaments/$tournamentId/matches/new') : null);
          return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            children: [for (final m in matches) Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Row(children: [
                  Expanded(child: Text(m.teamAName, maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('vs', style: TextStyle(fontSize: 11))),
                  Expanded(child: Text(m.teamBName, textAlign: TextAlign.end,
                    maxLines: 1, overflow: TextOverflow.ellipsis))]),
                subtitle: Text(m.status.label +
                  (m.resultText?.isNotEmpty == true
                    ? ' • ${m.resultText}' : '')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/tournaments/$tournamentId/matches/${m.id}')))]); }));
  }
}
