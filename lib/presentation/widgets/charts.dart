import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/units.dart';
import '../../data/models/tracker_models.dart';

class CalorieBarChart extends StatelessWidget {
  final List<DayTotals> days;
  final int goal;
  final double height;
  const CalorieBarChart(
      {super.key, required this.days, required this.goal, this.height = 220});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = days.fold<double>(
        goal * 1.0, (m, d) => d.calories > m ? d.calories : m);
    final maxY = (maxVal * 1.2 / 500).ceil() * 500.0;
    final dense = days.length > 10;
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${DateFmt.short(days[group.x].date)}\n${rod.toY.round()} kcal',
                TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
                y: goal.toDouble(),
                color: theme.colorScheme.primary,
                strokeWidth: 1.5,
                dashArray: [6, 4]),
          ]),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: maxY / 4,
                getTitlesWidget: (v, _) =>
                    Text('${v.round()}', style: theme.textTheme.labelSmall),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  if (dense && i % 5 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                        dense
                            ? '${days[i].date.day}'
                            : DateFmt.weekdayInitial(days[i].date),
                        style: theme.textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: days[i].calories,
                  width: dense ? 5 : 18,
                  borderRadius: BorderRadius.circular(dense ? 2 : 6),
                  color: days[i].calories > goal * 1.1
                      ? theme.colorScheme.error
                      : (days[i].calories == 0
                          ? theme.colorScheme.outlineVariant
                          : MacroColors.calories),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final bool metric;
  final double height;
  const WeightChart(
      {super.key,
      required this.entries,
      required this.metric,
      this.height = 200});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.length < 2) {
      return SizedBox(
        height: height * 0.5,
        child: Center(
            child: Text('Log at least two weigh-ins to see your trend.',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center)),
      );
    }
    final values =
        entries.map((e) => metric ? e.kg : Units.kgToLb(e.kg)).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) - 1).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                        style: theme.textTheme.labelSmall))),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: entries.length > 5
                    ? (entries.length / 4).ceilToDouble()
                    : 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length || v != i.toDouble())
                    return const SizedBox.shrink();
                  return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFmt.short(entries[i].date),
                          style: theme.textTheme.labelSmall));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i])
              ],
              isCurved: true,
              barWidth: 3,
              color: theme.colorScheme.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

class MacroPie extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double size;
  const MacroPie(
      {super.key,
      required this.protein,
      required this.carbs,
      required this.fat,
      this.size = 130});

  @override
  Widget build(BuildContext context) {
    final p = protein * 4, c = carbs * 4, f = fat * 9;
    final total = p + c + f;
    if (total <= 0) {
      return SizedBox(
          width: size,
          height: size,
          child: Center(
              child: Text('No data',
                  style: Theme.of(context).textTheme.labelMedium)));
    }
    PieChartSectionData section(double v, Color color) => PieChartSectionData(
          value: v,
          color: color,
          radius: size * 0.24,
          title: '${(v / total * 100).round()}%',
          titleStyle: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
        );
    return SizedBox(
      width: size,
      height: size,
      child: PieChart(PieChartData(
        centerSpaceRadius: size * 0.18,
        sectionsSpace: 2,
        sections: [
          section(p, MacroColors.protein),
          section(c, MacroColors.carbs),
          section(f, MacroColors.fat)
        ],
      )),
    );
  }
}

class MacroLegend extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  const MacroLegend(
      {super.key,
      required this.protein,
      required this.carbs,
      required this.fat});

  @override
  Widget build(BuildContext context) {
    Widget item(String label, double g, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('$label  ', style: Theme.of(context).textTheme.bodySmall),
              Text('${g.round()} g',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item('Protein', protein, MacroColors.protein),
        item('Carbs', carbs, MacroColors.carbs),
        item('Fat', fat, MacroColors.fat)
      ],
    );
  }
}
