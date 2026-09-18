import 'package:flutter/material.dart';
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title,
    this.subtitle, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Center(child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 72, color: s.outline),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[const SizedBox(height: 8),
          Text(subtitle!, textAlign: TextAlign.center,
            style: TextStyle(color: s.onSurfaceVariant))],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onAction,
            icon: const Icon(Icons.add), label: Text(actionLabel!))],
      ])));
  }
}
