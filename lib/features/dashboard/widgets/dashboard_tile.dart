import 'package:flutter/material.dart';

class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.highlight = false,
    this.onTap,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool highlight;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final bgColor = color ?? (highlight ? s.primaryContainer : s.surfaceContainerHighest);
    final iColor = iconColor ?? s.primary;
    final txtColor = color != null && color!.computeLuminance() < 0.5 ? Colors.white : const Color(0xFF0F172A);
    final subColor = color != null && color!.computeLuminance() < 0.5 ? Colors.white70 : const Color(0xFF64748B);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: txtColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 10.5, color: subColor, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
