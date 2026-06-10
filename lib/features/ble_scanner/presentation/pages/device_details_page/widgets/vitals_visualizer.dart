import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VitalsVisualizer extends StatelessWidget {
  final List<int> values;
  final String title;

  const VitalsVisualizer({
    super.key,
    required this.values,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    int maxValue = values.reduce((a, b) => a > b ? a : b);
    int minValue = values.reduce((a, b) => a < b ? a : b);

    if (maxValue == minValue) {
      maxValue += 1;
      minValue -= 1;
    }

    final yRange = (maxValue - minValue).toDouble();
    final yPadding = yRange == 0 ? 1.0 : yRange * 0.2;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Latest: ${values.last}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (values.length > 1 ? values.length - 1 : 1).toDouble(),
                  minY: minValue.toDouble() - yPadding,
                  maxY: maxValue.toDouble() + yPadding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(
                    handleBuiltInTouches: true,
                  ),
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
