import 'package:flutter/material.dart';

class PropertyBadge extends StatelessWidget {
  final String label;
  final bool isEnabled;

  const PropertyBadge({
    super.key,
    required this.label,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
