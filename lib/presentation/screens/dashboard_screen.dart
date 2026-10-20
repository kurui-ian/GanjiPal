import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/animated_amount_text.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/profile_edit_dialog.dart';
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
  int _selectedPeriodIndex = 0; // Default: Today (0: Today, 1: This Week, 2: This Month)
  bool _isBalanceHidden = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _selectedPeriodLabel {
    if (_selectedPeriodIndex == 0) return 'today';
    if (_selectedPeriodIndex == 1) return 'this week';
    return 'this month';
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

        if (state.isLoading && state.allTransactions.isEmpty) {
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
        BudgetStatus? primaryMonthlyBudget;
        for (final bs in budgetStatuses) {
          if (bs.budget.period == BudgetPeriod.monthly &&
              bs.budget.categoryId == null) {
            primaryMonthlyBudget = bs;
            break;
          }
        }
        if (primaryMonthlyBudget == null) {
          for (final bs in budgetStatuses) {
            if (bs.budget.period == BudgetPeriod.monthly) {
              primaryMonthlyBudget = bs;
              break;
            }
          }
        }

        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final daysLeft = (daysInMonth - now.day).clamp(0, 31);

        final avatarConfig =
            ProfileAvatarHelper.getConfig(state.avatarIndex);
        final initial = state.userName.isNotEmpty
            ? state.userName[0].toUpperCase()
            : 'K';

        final otherBudgets = budgetStatuses
            .where((bs) => bs.budget.id != primaryMonthlyBudget?.budget.id)
            .toList();

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
                  // Minimal Top Header with User Profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _openProfileModal(context, state),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: avatarConfig.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: avatarConfig.gradient.first
                                        .withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
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
                                Row(
                                  children: [
                                    Text(
                                      '${state.userName} 👋',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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

                  // Hero Money Tracing Card (Net Cash Flow is the Hero, Balance is secondary)
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
                        // Top Row: Net Flow Label + Subtle Balance Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.query_stats_rounded,
                                  color: Colors.white70,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Net Money Flow',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // Secondary Account Balance Pill
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _isBalanceHidden
                                              ? 'Bal: ••••'
                                              : 'Bal: KSh ${currencyFormat.format(state.currentEstimatedBalance)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
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
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Prominent Net Cash Flow Display
                        _isBalanceHidden
                            ? const Text(
                                '••••••••••',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              )
                            : AnimatedAmountText(
                                amount: summary.netCashFlowInShillings,
                                prefix: summary.netCashFlowCents >= 0 ? '+KSh ' : 'KSh ',
                                style: TextStyle(
                                  color: summary.netCashFlowCents >= 0
                                      ? Colors.white
                                      : const Color(0xFFFFD1D9),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                        const SizedBox(height: 6),

                        // Activity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${summary.transactionCount} transactions tracked $_selectedPeriodLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 14),

                        // Income vs Outflow Sub-Metrics (Fully Responsive & Overflow-Proof)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Money In',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        AnimatedAmountText(
                                          amount: summary.incomeInShillings,
                                          prefix: '+KSh ',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Money Out',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        AnimatedAmountText(
                                          amount: summary.totalOutgoingInShillings,
                                          prefix: '-KSh ',
                                          alignment: Alignment.centerRight,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Flow Breakdown Cards: Tariffs Paid, Cash Out, Transfers
                  Row(
                    children: [
                      Expanded(
                        child: _buildFlowCard(
                          context,
                          title: 'M-Pesa Tariffs',
                          amount:
                              'KSh ${currencyFormat.format(summary.feesInShillings)}',
                          subtitle: 'Safaricom fees',
                          icon: Icons.receipt_long_rounded,
                          iconColor: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 18),

                  // Primary Monthly Budget Card (Tracks monthly spending limit)
                  Card(
                    child: InkWell(
                      onTap: () => _openMonthlyBudgetModal(
                        context,
                        state,
                        existing: primaryMonthlyBudget?.budget,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: primaryMonthlyBudget != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (primaryMonthlyBudget.isOverBudget
                                                  ? AppColors.expense
                                                  : primaryMonthlyBudget.isWarning
                                                      ? Colors.amber[800]!
                                                      : AppColors.primary)
                                              .withValues(
                                            alpha: isDark ? 0.25 : 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: primaryMonthlyBudget.isOverBudget
                                              ? AppColors.expense
                                              : primaryMonthlyBudget.isWarning
                                                  ? Colors.amber[800]
                                                  : AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              primaryMonthlyBudget
                                                      .budget.categoryName ??
                                                  'Monthly Budget',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'KSh ${currencyFormat.format(primaryMonthlyBudget.spentInShillings)} of KSh ${currencyFormat.format(primaryMonthlyBudget.limitInShillings)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (primaryMonthlyBudget.isOverBudget
                                                  ? AppColors.expense
                                                  : primaryMonthlyBudget.isWarning
                                                      ? Colors.amber[800]!
                                                      : AppColors.income)
                                              .withValues(
                                            alpha: isDark ? 0.2 : 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              primaryMonthlyBudget.isOverBudget
                                                  ? 'Exceeded'
                                                  : '${(primaryMonthlyBudget.percentageUsed * 100).toInt()}% used',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: primaryMonthlyBudget
                                                        .isOverBudget
                                                    ? AppColors.expense
                                                    : primaryMonthlyBudget.isWarning
                                                        ? Colors.amber[800]
                                                        : AppColors.income,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 11,
                                              color: primaryMonthlyBudget
                                                      .isOverBudget
                                                  ? AppColors.expense
                                                  : primaryMonthlyBudget.isWarning
                                                      ? Colors.amber[800]
                                                      : AppColors.income,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: primaryMonthlyBudget
                                          .percentageUsed
                                          .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: (isDark
                                              ? Colors.white
                                              : Colors.black)
                                          .withValues(alpha: 0.08),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        primaryMonthlyBudget.isOverBudget
                                            ? AppColors.expense
                                            : primaryMonthlyBudget.isWarning
                                                ? Colors.amber[800]!
                                                : AppColors.income,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        primaryMonthlyBudget.remainingInShillings >=
                                                0
                                            ? 'KSh ${currencyFormat.format(primaryMonthlyBudget.remainingInShillings)} remaining'
                                            : 'Over by KSh ${currencyFormat.format(-primaryMonthlyBudget.remainingInShillings)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: primaryMonthlyBudget
                                                  .isOverBudget
                                              ? AppColors.expense
                                              : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                        ),
                                      ),
                                      Text(
                                        '$daysLeft days left in month',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: isDark ? 0.25 : 0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.savings_outlined,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Monthly Budget',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Set spending limit for this month',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Set Limit',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
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
                  RepaintBoundary(
                    child: SpendingDonutChart(
                      breakdown: periodBreakdown,
                      totalSpentInShillings: periodBreakdown.fold<double>(0, (sum, item) => sum + item.amountInShillings),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Other Category Budgets (if any)
                  if (otherBudgets.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category Limits',
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
                    ...otherBudgets.take(2).map((bs) {
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

  void _openProfileModal(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileEditBottomSheet(appState: state),
    );
  }

  void _openMonthlyBudgetModal(
    BuildContext context,
    AppState state, {
    BudgetModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthlyBudgetBottomSheet(
        appState: state,
        existingBudget: existing,
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBudgetBottomSheet extends StatefulWidget {
  final AppState appState;
  final BudgetModel? existingBudget;

  const _MonthlyBudgetBottomSheet({
    required this.appState,
    this.existingBudget,
  });

  @override
  State<_MonthlyBudgetBottomSheet> createState() =>
      _MonthlyBudgetBottomSheetState();
}

class _MonthlyBudgetBottomSheetState extends State<_MonthlyBudgetBottomSheet> {
  late final TextEditingController _controller;
  double _warningThreshold = 0.80;

  @override
  void initState() {
    super.initState();
    final existingLimit = widget.existingBudget?.limitInShillings;
    _controller = TextEditingController(
      text: existingLimit != null
          ? existingLimit.toStringAsFixed(0)
          : '25000',
    );
    _warningThreshold = widget.existingBudget?.warningThresholdPercent ?? 0.80;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(int amount) {
    _controller.text = amount.toString();
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    setState(() {});
  }

  void _save() {
    final clean = _controller.text.replaceAll(',', '').trim();
    final amount = double.tryParse(clean.isEmpty ? '25000' : clean);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly budget amount')),
      );
      return;
    }

    final budget = BudgetModel(
      id: widget.existingBudget?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: null, // Global monthly budget
      categoryName: null,
      period: BudgetPeriod.monthly,
      limitCents: (amount * 100).round(),
      warningThresholdPercent: _warningThreshold,
      startDate: widget.existingBudget?.startDate ?? DateTime.now(),
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.appState.saveBudget(budget);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Monthly budget set to KSh ${NumberFormat('#,##0').format(amount)}',
        ),
      ),
    );
  }

  void _delete() {
    if (widget.existingBudget != null) {
      widget.appState.deleteBudget(widget.existingBudget!.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monthly budget removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingBudget != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Monthly Budget' : 'Set Monthly Budget',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Set a target spending limit for this month across your M-Pesa account.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: false,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'KSh ',
                hintText: '25,000',
                labelText: 'Monthly Spending Limit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [10000, 20000, 30000, 50000].map((amt) {
                return ActionChip(
                  label: Text('KSh ${NumberFormat('#,##0').format(amt)}'),
                  onPressed: () => _applyPreset(amt),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alert Warning Threshold',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(_warningThreshold * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: _warningThreshold,
              min: 0.50,
              max: 0.95,
              divisions: 9,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _warningThreshold = val),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Set Monthly Budget',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _delete,
                  child: const Text(
                    'Remove Monthly Budget',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
