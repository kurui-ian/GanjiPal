import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/spending_donut_chart.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';
import 'sms_import_screen.dart';
import 'transaction_detail_modal.dart';

class DashboardScreen extends StatefulWidget {
  final AppState appState;
  final Function(int) onNavigateTab;

  const DashboardScreen({
    super.key,
    required this.appState,
    required this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedPeriodIndex = 2; // Default: This Month (0: Today, 1: Week, 2: Month)
  bool _isBalanceHidden = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final state = widget.appState;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final currencyFormat = NumberFormat('#,##0.00', 'en_US');

        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.allTransactions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('GanjiPal')),
            body: EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Welcome to GanjiPal',
              message:
                  'Keep track of your daily M-Pesa spending, income, and cash flow automatically or manually.',
              primaryActionTitle: 'Import M-Pesa SMS',
              onPrimaryAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SmsImportScreen(appState: state),
                  ),
                );
              },
              secondaryActionTitle: 'Add Manual Transaction',
              onSecondaryAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditTransactionScreen(appState: state),
                  ),
                );
              },
            ),
          );
        }

        // Active period summary
        final summary = _selectedPeriodIndex == 0
            ? state.todaySummary
            : _selectedPeriodIndex == 1
            ? state.weekSummary
            : state.monthSummary;

        final periodBreakdown =
            state.categoryBreakdownForPeriod(_selectedPeriodIndex);
        final recentTxs = state.allTransactions.take(5).toList();
        final budgetStatuses = state.budgetStatuses;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => state.loadInitialData(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                children: [
                  // Minimal Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.heroGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                'GP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              const Text(
                                'GanjiPal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sms_outlined,
                                size: 20,
                              ),
                            ),
                            tooltip: 'Import SMS',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SmsImportScreen(appState: state),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 20,
                              ),
                            ),
                            tooltip: 'Add Transaction',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEditTransactionScreen(
                                    appState: state,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Hero Balance Card (Minimal Modern Fintech Gradient)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.heroGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isBalanceHidden = !_isBalanceHidden;
                                    });
                                  },
                                  child: Icon(
                                    _isBalanceHidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'M-Pesa Ledger',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isBalanceHidden
                              ? '••••••••••'
                              : 'KSh ${currencyFormat.format(state.currentEstimatedBalance)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Money In',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '+KSh ${currencyFormat.format(summary.incomeInShillings)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Gross Out',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '-KSh ${currencyFormat.format(summary.grossSpendingInShillings)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Flow Breakdown Cards (Horizontal Cards)
                  Row(
                    children: [
                      Expanded(
                        child: _buildFlowCard(
                          context,
                          title: 'Net Flow',
                          amount:
                              '${summary.netCashFlowCents >= 0 ? "+" : ""}KSh ${currencyFormat.format(summary.netCashFlowInShillings)}',
                          subtitle: '${summary.transactionCount} transactions',
                          icon: Icons.trending_up,
                          iconColor: summary.netCashFlowCents >= 0
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFlowCard(
                          context,
                          title: 'Cash Out',
                          amount:
                              'KSh ${currencyFormat.format(summary.cashWithdrawnInShillings)}',
                          subtitle: 'ATM & Agents',
                          icon: Icons.local_atm_rounded,
                          iconColor: AppColors.withdrawal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFlowCard(
                          context,
                          title: 'Transfers',
                          amount:
                              'KSh ${currencyFormat.format(summary.totalTransfersSentCents / 100.0)}',
                          subtitle: 'To numbers',
                          icon: Icons.swap_horiz_rounded,
                          iconColor: AppColors.transfer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Period Selector Segmented Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildSegmentTab(0, 'Today'),
                        _buildSegmentTab(1, 'This Week'),
                        _buildSegmentTab(2, 'This Month'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Spending Overview Donut Chart
                  SpendingDonutChart(
                    breakdown: periodBreakdown,
                    totalSpentInShillings: summary.netSpendingInShillings,
                  ),
                  const SizedBox(height: 20),

                  // Active Budgets Quick Glance (if any)
                  if (budgetStatuses.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Budgets & Limits',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              widget.onNavigateTab(3), // Budgets tab
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...budgetStatuses.take(2).map((bs) {
                      final percent = (bs.percentageUsed * 100).toInt();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      bs.budget.categoryName ??
                                          '${bs.budget.period.displayName} Spending',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '$percent%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: bs.isOverBudget
                                            ? AppColors.expense
                                            : bs.isWarning
                                            ? Colors.amber[800]
                                            : AppColors.income,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: bs.percentageUsed.clamp(0.0, 1.0),
                                    minHeight: 6,
                                    color: bs.isOverBudget
                                        ? AppColors.expense
                                        : bs.isWarning
                                        ? Colors.amber[800]
                                        : AppColors.income,
                                    backgroundColor: (isDark
                                            ? Colors.white
                                            : Colors.black)
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            widget.onNavigateTab(1), // Transactions tab
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTxs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 70),
                      itemBuilder: (context, index) {
                        final tx = recentTxs[index];
                        return TransactionTile(
                          transaction: tx,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => TransactionDetailModal(
                                transaction: tx,
                                appState: state,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriodIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlowCard(
    BuildContext context, {
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
