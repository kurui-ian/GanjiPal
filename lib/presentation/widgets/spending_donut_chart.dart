import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';

/// Minimalist, modern Donut Chart representing category spending breakdown.
/// Inspired by modern fintech mobile dashboards.
class SpendingDonutChart extends StatefulWidget {
  final List<CategorySpending> breakdown;
  final double totalSpentInShillings;

  const SpendingDonutChart({
    super.key,
    required this.breakdown,
    required this.totalSpentInShillings,
  });

  @override
  State<SpendingDonutChart> createState() => _SpendingDonutChartState();
}

class _SpendingDonutChartState extends State<SpendingDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    final totalFromBreakdown = widget.breakdown.fold<double>(
      0,
      (sum, item) => sum + item.amountInShillings,
    );
    final displayTotal = widget.totalSpentInShillings > 0
        ? widget.totalSpentInShillings
        : totalFromBreakdown;

    final hasSpending = (displayTotal > 0 || totalFromBreakdown > 0) &&
        widget.breakdown.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.2 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.breakdown.length} Categories',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Donut & Legend Container with Adaptive Sizing
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 320;
                final donutSize = isCompact ? 116.0 : 136.0;
                final centerRadius = isCompact ? 36.0 : 42.0;
                final spacing = isCompact ? 12.0 : 18.0;

                return Row(
                  children: [
                    // Donut Chart with Centered Total
                    SizedBox(
                      width: donutSize,
                      height: donutSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!
                                          .touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 3,
                                centerSpaceRadius: centerRadius,
                                sections: hasSpending
                                    ? _buildSections(isDark)
                                    : [
                                        PieChartSectionData(
                                          color: (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withValues(alpha: 0.07),
                                          value: 1,
                                          title: '',
                                          radius: 14,
                                        ),
                                      ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'KSh ${currencyFormat.format(displayTotal)}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: isCompact ? 11.5 : 13,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SPENT',
                                  style: TextStyle(
                                    fontSize: isCompact ? 8.5 : 9.5,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: spacing),

                    // Category Legends List
                    Expanded(
                      child: hasSpending
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.breakdown.take(4).map((cat) {
                            final index = widget.breakdown.indexOf(cat);
                            final color = AppColors.chartPalette[
                                index % AppColors.chartPalette.length];
                            final percent = (cat.percentageOfTotal * 100).toInt();

                            final isSelected = _touchedIndex == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat.categoryName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? color
                                          : (isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          'No expenses recorded yet in this selected period.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

  List<PieChartSectionData> _buildSections(bool isDark) {
    return widget.breakdown.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? 22.0 : 16.0;

      final color =
          AppColors.chartPalette[index % AppColors.chartPalette.length];

      return PieChartSectionData(
        color: color,
        value: cat.amountInShillings,
        title: '',
        radius: radius,
      );
    }).toList();
  }
}
