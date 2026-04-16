import 'package:clockify/features/modules/localstorage_module.dart';
import 'package:clockify/features/repositories/time_entries_gain_manager.dart';
import 'package:clockify/ui/providers/date_range_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CumulativeHoursChart extends ConsumerWidget {
  const CumulativeHoursChart({super.key, required this.gainManager});

  final TimeEntriesGainManager gainManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeProvider);
    final minHours = LocalStorageModule.minHoursPerDay;
    final targetHours = LocalStorageModule.targetHoursPerDay;

    final data = _buildData(dateRange, minHours, targetHours);
    if (data.businessDays.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final actualColor = colorScheme.primary;
    const minColor = Colors.orange;
    const targetColor = Colors.teal;

    // Order: target, min, actual — matches the tooltip label switch (Alvo, Mínimo, Trabalhado)
    final lines = <LineChartBarData>[
      if (targetHours != null)
        _line(data.targetSpots, targetColor, dashed: true),
      if (minHours != null) _line(data.minSpots, minColor, dashed: true),
      _line(data.actualSpots, actualColor, dashed: false),
    ];
    final tooltipLabels = <String>[
      if (targetHours != null) 'Alvo',
      if (minHours != null) 'Mínimo',
      'Trabalhado',
    ];
    // Gain list for each line, in the same order as tooltipLabels/lines
    final gainLists = <List<double>>[
      if (targetHours != null) data.cumulativeTargetGainByIndex,
      if (minHours != null) data.cumulativeMinGainByIndex,
      data.cumulativeGainByIndex,
    ];

    final allValues = [
      ...data.actualSpots.map((s) => s.y),
      if (minHours != null) ...data.minSpots.map((s) => s.y),
      if (targetHours != null) ...data.targetSpots.map((s) => s.y),
    ];
    final maxY = allValues.isEmpty
        ? 1.0
        : allValues.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legend(
            actualColor,
            minHours != null ? minColor : null,
            targetHours != null ? targetColor : null,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.businessDays.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.05,
                lineBarsData: lines,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${value.toStringAsFixed(0)}h',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _labelInterval(data.businessDays.length),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= data.businessDays.length) {
                          return const SizedBox.shrink();
                        }
                        final day = data.businessDays[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.shade700,
                    maxContentWidth: 200,
                    fitInsideHorizontally: true,
                    getTooltipItems: (spots) {
                      return [
                        for (int i = 0; i < spots.length; i++)
                          () {
                            final spot = spots[i];
                            final label = tooltipLabels[i];
                            final hours = spot.y.toStringAsFixed(1);
                            final dayIndex = spot.x.toInt();
                            final gains = gainLists[i];
                            final gainSuffix = dayIndex < gains.length
                                ? ' (\$${gains[dayIndex].toStringAsFixed(0)})'
                                : '';
                            return LineTooltipItem(
                              '$label: ${hours}h$gainSuffix',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.5,
                              ),
                              textAlign: .start,
                            );
                          }(),
                      ];
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(
    List<FlSpot> spots,
    Color color, {
    required bool dashed,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: dashed ? 1.5 : 2.5,
      dotData: FlDotData(show: false),
      dashArray: dashed ? [6, 4] : null,
    );
  }

  Widget _legend(Color actualColor, Color? minColor, Color? targetColor) {
    return Wrap(
      spacing: 12,
      children: [
        _legendItem(actualColor, 'Trabalhadas'),
        if (minColor != null) _legendItem(minColor, 'Mínimo'),
        if (targetColor != null) _legendItem(targetColor, 'Alvo'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  double _labelInterval(int count) {
    return 1;
    // if (count <= 10) return 1;
    // if (count <= 25) return 5;
    // return 10;
  }

  _ChartData _buildData(
    DateRange dateRange,
    double? minHours,
    double? targetHours,
  ) {
    // Collect all business days in the filtered period
    final businessDays = <DateTime>[];
    var current = dateRange.startDate;
    while (!current.isAfter(dateRange.endDate)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        businessDays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    final totalActualHours = gainManager.totalDuration.inMinutes / 60.0;
    final averageHourlyRate = totalActualHours > 0
        ? gainManager.totalGain / totalActualHours
        : 0.0;

    final actualSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    final cumulativeGainByIndex = <double>[];
    final cumulativeMinGainByIndex = <double>[];
    final cumulativeTargetGainByIndex = <double>[];

    double cumulativeActual = 0;
    double cumulativeGain = 0;
    double cumulativeMin = 0;
    double cumulativeTarget = 0;

    for (int i = 0; i < businessDays.length; i++) {
      final day = businessDays[i];

      // Actual: sum hours + gain for this business day + following weekend days
      Duration dayDuration = gainManager.getDurationOnDate(
        day.year,
        day.month,
        day.day,
      );
      double dayGain = gainManager
          .getTotalOnDate(day.year, day.month, day.day)
          .values
          .fold(0.0, (a, b) => a + b);

      // Check if the next day(s) are weekend — if so, fold them into this business day
      DateTime next = day.add(const Duration(days: 1));
      while (next.weekday == DateTime.saturday ||
          next.weekday == DateTime.sunday) {
        if (!next.isAfter(dateRange.endDate)) {
          dayDuration += gainManager.getDurationOnDate(
            next.year,
            next.month,
            next.day,
          );
          dayGain += gainManager
              .getTotalOnDate(next.year, next.month, next.day)
              .values
              .fold(0.0, (a, b) => a + b);
        }
        next = next.add(const Duration(days: 1));
      }

      cumulativeActual += dayDuration.inMinutes / 60.0;
      cumulativeGain += dayGain;
      cumulativeGainByIndex.add(cumulativeGain);
      actualSpots.add(FlSpot(i.toDouble(), cumulativeActual));

      if (minHours != null) {
        cumulativeMin += minHours;
        minSpots.add(FlSpot(i.toDouble(), cumulativeMin));
        cumulativeMinGainByIndex.add(cumulativeMin * averageHourlyRate);
      }
      if (targetHours != null) {
        cumulativeTarget += targetHours;
        targetSpots.add(FlSpot(i.toDouble(), cumulativeTarget));
        cumulativeTargetGainByIndex.add(cumulativeTarget * averageHourlyRate);
      }
    }

    return _ChartData(
      businessDays: businessDays,
      actualSpots: actualSpots,
      minSpots: minSpots,
      targetSpots: targetSpots,
      cumulativeGainByIndex: cumulativeGainByIndex,
      cumulativeMinGainByIndex: cumulativeMinGainByIndex,
      cumulativeTargetGainByIndex: cumulativeTargetGainByIndex,
    );
  }
}

class _ChartData {
  final List<DateTime> businessDays;
  final List<FlSpot> actualSpots;
  final List<FlSpot> minSpots;
  final List<FlSpot> targetSpots;
  final List<double> cumulativeGainByIndex;
  final List<double> cumulativeMinGainByIndex;
  final List<double> cumulativeTargetGainByIndex;

  _ChartData({
    required this.businessDays,
    required this.actualSpots,
    required this.minSpots,
    required this.targetSpots,
    required this.cumulativeGainByIndex,
    required this.cumulativeMinGainByIndex,
    required this.cumulativeTargetGainByIndex,
  });
}
