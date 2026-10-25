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
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 17) return Icons.wb_sunny_rounded;
    if (hour >= 17 && hour < 20) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
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
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: avatarConfig.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: avatarConfig.gradient.first
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getGreetingIcon(),
                                      size: 13,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${state.userName} 👋',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.all(3.5),
                                      decoration: BoxDecoration(
                                        color: (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.06),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500],
                                      ),
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
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SmsImportScreen(appState: state),
                                  ),
                                );
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (isDark ? AppColors.darkSurfaceVariant : Colors.white),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.mark_email_unread_rounded,
                                  size: 19,
                                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditTransactionScreen(
                                      appState: state,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF4F46E5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF6366F1),
                          Color(0xFF7C3AED),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.38),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.auto_graph_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  'NET MONEY FLOW',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            // Secondary Account Balance Pill
                            Flexible(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setState(() {
                                      _isBalanceHidden = !_isBalanceHidden;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Colors.white,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 6),
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
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          _isBalanceHidden
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.white.withValues(alpha: 0.8),
                                          size: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Status Tag (Inflow vs Outflow)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: (summary.netCashFlowCents >= 0
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF43F5E))
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (summary.netCashFlowCents >= 0
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFFFB7185))
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    summary.netCashFlowCents >= 0
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 11,
                                    color: summary.netCashFlowCents >= 0
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFFFFCCD5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    summary.netCashFlowCents >= 0
                                        ? 'Net Inflow'
                                        : 'Net Outflow',
                                    style: TextStyle(
                                      color: summary.netCashFlowCents >= 0
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFFFFCCD5),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Activity Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history_rounded,
                                    size: 11,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${summary.transactionCount} transactions $_selectedPeriodLabel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Prominent Net Cash Flow Display
                        _isBalanceHidden
                            ? const Text(
                                '••••••••••',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              )
                            : AnimatedAmountText(
                                amount: summary.netCashFlowInShillings,
                                prefix: summary.netCashFlowCents >= 0 ? '+KSh ' : 'KSh ',
                                style: TextStyle(
                                  color: summary.netCashFlowCents >= 0
                                      ? Colors.white
                                      : const Color(0xFFFFF0F3),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                        const SizedBox(height: 16),

                        // Income vs Outflow Frosted Glass Metric Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF34D399)
                                              .withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward_rounded,
                                        color: Color(0xFF6EE7B7),
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Money In',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          AnimatedAmountText(
                                            amount: summary.incomeInShillings,
                                            prefix: '+KSh ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF43F5E)
                                            .withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFB7185)
                                              .withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        color: Color(0xFFFFCCD5),
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Money Out',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          AnimatedAmountText(
                                            amount: summary.totalOutgoingInShillings,
                                            prefix: '-KSh ',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              letterSpacing: -0.3,
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
                          iconColor: const Color(0xFF64748B),
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
                ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 8,
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.5),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 15),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
