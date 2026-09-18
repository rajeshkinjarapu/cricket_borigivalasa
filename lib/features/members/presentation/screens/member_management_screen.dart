import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../providers/member_providers.dart';

class MemberManagementScreen extends ConsumerWidget {
  const MemberManagementScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(memberListProvider);
    final repo = ref.read(memberRepositoryProvider);
    final self = repo.currentUid;
    return Scaffold(appBar: AppBar(title: const Text('Members')),
      body: a.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) => ListView.separated(padding: const EdgeInsets.all(12),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (c, i) { final u = users[i];
            final isSelf = u.uid == self;
            return Card(child: ListTile(
              leading: CircleAvatar(
                backgroundColor: u.role == UserRole.admin
                  ? Theme.of(c).colorScheme.primaryContainer
                  : Theme.of(c).colorScheme.surfaceContainerHighest,
                child: Text(u.displayName.isNotEmpty
                  ? u.displayName[0].toUpperCase() : '?')),
              title: Text(u.displayName + (isSelf ? '  (you)' : ''),
                style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(u.email),
              trailing: PopupMenuButton<String>(onSelected: (v) async {
                if (v == 'promote') await repo.updateRole(u.uid, UserRole.admin);
                else if (v == 'demote') {
                  if (isSelf) return;
                  await repo.updateRole(u.uid, UserRole.member);
                } else if (v == 'remove') {
                  if (isSelf) return;
                  final ok = await showConfirmDialog(context,
                    title: 'Remove?', message: 'Remove ${u.displayName}?');
                  if (ok) await repo.removeUser(u.uid);
                }
              }, itemBuilder: (_) => [
                if (u.role == UserRole.member) const PopupMenuItem(
                  value: 'promote', child: Text('Promote to admin'))
                else const PopupMenuItem(
                  value: 'demote', child: Text('Demote to member')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ]))); })));
  }
}
