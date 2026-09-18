import 'package:flutter/material.dart';
class DashboardTile extends StatelessWidget {
  const DashboardTile({super.key, required this.icon, required this.label,
    this.subtitle, this.highlight = false, this.onTap});
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool highlight;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Material(color: highlight ? s.primaryContainer : s.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label'))),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 32, color: s.primary), const Spacer(),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(fontSize: 11, color: s.onSurfaceVariant))],
        ]))));
  }
}
