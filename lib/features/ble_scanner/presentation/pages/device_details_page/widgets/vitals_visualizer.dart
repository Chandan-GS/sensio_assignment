import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum VitalType { heartRate, spo2, temperature, unknown }

class VitalsVisualizer extends StatelessWidget {
  final List<int> values;
  final String title;
  final VitalType type;

  const VitalsVisualizer({
    super.key,
    required this.values,
    required this.title,
    this.type = VitalType.unknown,
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
    bool isAlert = false;
    double defaultMinY = (minValue - 1).toDouble();
    double defaultMaxY = (maxValue + 1).toDouble();

    if (type == VitalType.heartRate) {
      if (values.last > 100 || values.last < 60) isAlert = true;
      defaultMinY = (minValue - 5).toDouble();
      defaultMaxY = (maxValue + 5).toDouble();
    } else if (type == VitalType.spo2) {
      if (values.last < 95) isAlert = true;
      defaultMinY = 85;
      defaultMaxY = 100;
    } else if (type == VitalType.temperature) {
      if (values.last >= 37.5) isAlert = true;
      defaultMinY = 35;
      defaultMaxY = 42;
    }

    final chartMinY = minValue < defaultMinY
        ? minValue.toDouble() - 1
        : defaultMinY;
    final chartMaxY = maxValue > defaultMaxY
        ? maxValue.toDouble() + 1
        : defaultMaxY;

    final mainColor = isAlert ? Colors.red : theme.colorScheme.secondary;

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
                    color: mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Latest: ${values.last}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: mainColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              width: double.infinity,
              child: type == VitalType.heartRate
                  ? _buildBarChart(
                      spots,
                      chartMinY,
                      chartMaxY,
                      mainColor,
                      theme,
                    )
                  : _buildLineChart(spots, chartMinY, chartMaxY, mainColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<FlSpot> spots,
    double minY,
    double maxY,
    Color mainColor,
  ) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length > 1 ? values.length - 1 : 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: mainColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: mainColor.withValues(alpha: 0.2),
            ),
          ),
        ],
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),

        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(handleBuiltInTouches: true),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildBarChart(
    List<FlSpot> spots,
    double minY,
    double maxY,
    Color mainColor,
    ThemeData theme,
  ) {
    return BarChart(
      BarChartData(
        minY: minY.clamp(0, double.infinity),
        maxY: maxY,
        barGroups: spots
            .map(
              (spot) => BarChartGroupData(
                x: spot.x.toInt(),
                barRods: [
                  BarChartRodData(
                    toY: spot.y,
                    color: mainColor,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
