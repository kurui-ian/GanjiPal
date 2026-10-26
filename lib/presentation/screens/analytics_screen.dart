import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/empty_state_view.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppState appState;

  const AnalyticsScreen({super.key, required this.appState});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _rangeDays = 30; // 7, 30, 90

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final state = widget.appState;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final currencyFormat = NumberFormat('#,##0', 'en_US');

        if (state.allTransactions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Analytics')),
            body: const EmptyStateView(
              icon: Icons.bar_chart_rounded,
              title: 'No Analytics Available',
              message:
                  'Analytics and spending trends will appear once transactions are recorded.',
            ),
          );
        }

        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: _rangeDays));
        final txsInRange = state.allTransactions
            .where((tx) => !tx.timestamp.isBefore(startDate))
            .toList();

        final summary = FinancialCalculator.calculateSummary(txsInRange);
        final categoryBreakdown =
            FinancialCalculator.calculateCategoryBreakdown(txsInRange);
        final topMerchants = FinancialCalculator.findTopMerchants(
          txsInRange,
          limit: 5,
        );
        final dailySpending = FinancialCalculator.calculateDailySpending(
          txsInRange,
          startDate: startDate,
          endDate: now,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            children: [
              // Period Selector Segmented Tabs
              Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightBorder,
                    width: 0.75,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildRangeSegment(7, '7 Days', isDark),
                    _buildRangeSegment(30, '30 Days', isDark),
                    _buildRangeSegment(90, '90 Days', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Metrics Card
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightBorder,
                    width: 0.75,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERIOD CASH FLOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildMetric(
                          context,
                          'Money Out',
                          'KSh ${currencyFormat.format(summary.totalOutgoingInShillings)}',
                          AppColors.expense,
                          isDark,
                        ),
                        Container(
                          width: 0.75,
                          height: 36,
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                        _buildMetric(
                          context,
                          'Money In',
                          'KSh ${currencyFormat.format(summary.incomeInShillings)}',
                          isDark ? AppColors.sage : AppColors.primary,
                          isDark,
                        ),
                        Container(
                          width: 0.75,
                          height: 36,
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                        _buildMetric(
                          context,
                          'M-Pesa Fees',
                          'KSh ${currencyFormat.format(summary.feesInShillings)}',
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Daily Spending Trend Chart
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightBorder,
                    width: 0.75,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Outflows',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'KSh / Day',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: RepaintBoundary(
                        child: _DailySpendingBarChart(dailyData: dailySpending),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Breakdown Card
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightBorder,
                    width: 0.75,
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (categoryBreakdown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'No expenses recorded in this period',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...categoryBreakdown.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cat = entry.value;
                        final percent = (cat.percentageOfTotal * 100)
                            .toStringAsFixed(0);
                        final catColor =
                            _getCategoryColor(cat.categoryId, index);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: catColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        cat.categoryName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'KSh ${currencyFormat.format(cat.amountInShillings)}   $percent%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: cat.percentageOfTotal,
                                  minHeight: 4,
                                  backgroundColor: (isDark
                                          ? Colors.white
                                          : Colors.black)
                                      .withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    catColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Top Counterparties Card
              if (topMerchants.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceBorder
                          : AppColors.lightBorder,
                      width: 0.75,
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Recipients & Merchants',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...topMerchants.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final m = entry.value;
                        final isLast = idx == topMerchants.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          .withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        m.merchantName.isNotEmpty
                                            ? m.merchantName[0].toUpperCase()
                                            : 'M',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      m.merchantName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13.5,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'KSh ${currencyFormat.format(m.totalInShillings)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 0.75,
                                color: isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider,
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRangeSegment(int days, String label, bool isDark) {
    final isSelected = _rangeDays == days;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _rangeDays = days;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.darkSurfaceHighlight
                    : AppColors.lightSurface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? AppColors.darkSurfaceBorder
                        : AppColors.lightBorder,
                    width: 0.75,
                  )
                : Border.all(color: Colors.transparent, width: 0.75),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context,
    String title,
    String amount,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String catId, int index) {
    if (index >= 0 && index < AppColors.chartPalette.length) {
      return AppColors.chartPalette[index];
    }
    final cat = CategoryModel.defaults.firstWhere(
      (c) => c.id == catId,
      orElse: () => const CategoryModel(
        id: 'other',
        name: 'Other',
        iconName: 'category',
        colorValue: 0xFF52B788,
      ),
    );
    return Color(cat.colorValue);
  }
}

class _DailySpendingBarChart extends StatelessWidget {
  final Map<DateTime, int> dailyData;

  const _DailySpendingBarChart({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final entries = dailyData.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));

    // Find max spending
    int maxAmount = 1;
    for (final e in entries) {
      if (e.value > maxAmount) maxAmount = e.value;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((e) {
              final ratio = (e.value / maxAmount).clamp(0.04, 1.0);
              final hasSpend = e.value > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Tooltip(
                    message:
                        '${DateFormat('MMM d').format(e.key)}: KSh ${(e.value / 100.0).toStringAsFixed(0)}',
                    child: FractionallySizedBox(
                      heightFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasSpend
                              ? (isDark ? AppColors.sage : AppColors.primary)
                              : (isDark
                                  ? AppColors.darkSurfaceBorder
                                  : const Color(0xFFE2E8F0)),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 0.75,
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ],
    );
  }
}
