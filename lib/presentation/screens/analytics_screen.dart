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
              message: 'Analytics and spending trends will appear once transactions are recorded.',
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
          appBar: AppBar(title: const Text('Analytics & Trends')),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            children: [
              // Period Selector Segmented Tabs (Zero Overflow)
              Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildRangeSegment(7, 'Last 7 Days', isDark),
                    _buildRangeSegment(30, 'Last 30 Days', isDark),
                    _buildRangeSegment(90, 'Last 90 Days', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spending Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMetric(
                            context,
                            'Total Outflows',
                            'KSh ${currencyFormat.format(summary.totalOutgoingInShillings)}',
                            AppColors.expense,
                          ),
                          const SizedBox(width: 8),
                          _buildMetric(
                            context,
                            'Income Received',
                            'KSh ${currencyFormat.format(summary.incomeInShillings)}',
                            AppColors.income,
                          ),
                          const SizedBox(width: 8),
                          _buildMetric(
                            context,
                            'Tariff Fees',
                            'KSh ${currencyFormat.format(summary.feesInShillings)}',
                            isDark ? AppColors.darkTextSecondary : AppColors.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Daily Spending Trend Chart (Custom Canvas Bar Visualization)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Spending Trend',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'KSh / Day',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: RepaintBoundary(
                          child: _DailySpendingBarChart(dailyData: dailySpending),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (categoryBreakdown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text('No expenses recorded in this period'),
                          ),
                        )
                      else
                        ...categoryBreakdown.asMap().entries.map((entry) {
                          final index = entry.key;
                          final cat = entry.value;
                          final percent = (cat.percentageOfTotal * 100)
                              .toStringAsFixed(1);
                          final catColor = _getCategoryColor(cat.categoryId, index);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
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
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: catColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat.categoryName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'KSh ${currencyFormat.format(cat.amountInShillings)} ($percent%)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: cat.percentageOfTotal,
                                    minHeight: 7,
                                    backgroundColor: (isDark
                                            ? Colors.white
                                            : Colors.black)
                                        .withValues(alpha: 0.06),
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
              ),
              const SizedBox(height: 16),

              // Top Merchants
              if (topMerchants.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Spending Counterparties',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...topMerchants.map((m) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: (isDark
                                            ? AppColors.sage
                                            : AppColors.primary)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      m.merchantName.isNotEmpty
                                          ? m.merchantName[0].toUpperCase()
                                          : 'M',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.sage
                                            : AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    m.merchantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'KSh ${currencyFormat.format(m.totalInShillings)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightBorder,
                    width: 1,
                  )
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.primary)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
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
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
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
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
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
                            top: Radius.circular(3),
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
          height: 1,
          color: isDark ? AppColors.darkSurfaceBorder : AppColors.lightBorder,
        ),
      ],
    );
  }
}
