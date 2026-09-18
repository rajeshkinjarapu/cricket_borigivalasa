import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../widgets/dashboard_tile.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(currentUserProvider);
    return Scaffold(appBar: AppBar(title: const Text('Admin Dashboard'),
      actions: [IconButton(icon: const Icon(Icons.logout),
        onPressed: () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go('/login');
        })]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            CircleAvatar(radius: 26,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text((u?.displayName.isNotEmpty ?? false)
                ? u!.displayName[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('Hello, ${u?.displayName ?? 'Admin'}',
                style: Theme.of(context).textTheme.titleMedium),
              const Text('Administrator')])),
          ])),
        const SizedBox(height: 16),
        Text('Manage', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.15, children: [
          DashboardTile(icon: Icons.emoji_events_outlined, label: 'Tournaments',
            subtitle: 'Create & manage', onTap: () => context.push('/tournaments')),
          DashboardTile(icon: Icons.groups_outlined, label: 'Teams',
            subtitle: 'Within tournaments', onTap: () => context.push('/tournaments')),
          DashboardTile(icon: Icons.person_outline, label: 'Players',
            subtitle: 'Manage squads', onTap: () => context.push('/tournaments')),
          DashboardTile(icon: Icons.sports_cricket_outlined, label: 'Matches',
            subtitle: 'Inside tournaments', onTap: () => context.push('/tournaments')),
          DashboardTile(icon: Icons.play_circle_outline, label: 'Live Scoring',
            subtitle: 'Open a match', highlight: true,
            onTap: () => context.push('/tournaments')),
          DashboardTile(icon: Icons.manage_accounts_outlined, label: 'Members',
            subtitle: 'Manage roles', onTap: () => context.push('/members')),
        ]),
      ])));
  }
}
