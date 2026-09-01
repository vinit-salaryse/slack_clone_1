import 'package:flutter/material.dart';

/// Reusable section header for grouping list items (e.g. Channels, Direct messages)
/// Supports expand/collapse with a chevron icon and title with trailing indicator.
class SectionHeader extends StatelessWidget {
  final Widget? leading;
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SectionHeader({
    super.key,
    this.leading,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Text(
              '$title >',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.black87,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
