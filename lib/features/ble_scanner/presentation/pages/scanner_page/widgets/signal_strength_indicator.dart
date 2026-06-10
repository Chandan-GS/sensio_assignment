import 'package:flutter/material.dart';

class SignalStrengthIndicator extends StatelessWidget {
  final int rssi;
  final double barWidth;
  final double spacing;

  const SignalStrengthIndicator({
    super.key,
    required this.rssi,
    this.barWidth = 4.0,
    this.spacing = 3.0,
  });

  int get _level {
    if (rssi >= -65) {
      return 3;
    } else if (rssi >= -85) {
      return 2;
    } else {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.secondary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    final level = _level;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(
          active: level >= 1,
          height: 6.0,
          color: activeColor,
          inactiveColor: inactiveColor,
        ),
        SizedBox(width: spacing),
        _buildBar(
          active: level >= 2,
          height: 12.0,
          color: activeColor,
          inactiveColor: inactiveColor,
        ),
        SizedBox(width: spacing),
        _buildBar(
          active: level >= 3,
          height: 18.0,
          color: activeColor,
          inactiveColor: inactiveColor,
        ),
      ],
    );
  }

  Widget _buildBar({
    required bool active,
    required double height,
    required Color color,
    required Color inactiveColor,
  }) {
    return Container(
      width: barWidth,
      height: height,
      decoration: BoxDecoration(
        color: active ? color : inactiveColor,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
