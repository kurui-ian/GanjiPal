import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/profile_edit_dialog.dart';
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
  int _selectedPeriodIndex = 0; // 0: Today, 1: This Week, 2: This Month
  bool _isBalanceHidden = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
        final recentTxs = state.allTransactions.take(6).toList();

        // Primary Monthly Budget
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

        final initial = state.userName.isNotEmpty
            ? state.userName[0].toUpperCase()
            : 'K';

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => state.loadInitialData(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                children: [
                  // 1. Header (Quiet, functional)
                  _buildHeader(context, state, initial, isDark, theme),
                  const SizedBox(height: 16),

                  // 2. Financial Overview Anchor (Available Balance + Cash Flow)
                  _buildFinancialAnchor(
                    context,
                    state,
                    summary,
                    isDark,
                    theme,
                    currencyFormat,
                  ),
                  const SizedBox(height: 16),

                  // 3. Primary Quick Actions
                  _buildQuickActions(context, state, isDark),
                  const SizedBox(height: 22),

                  // 4. Spending Categories Summary (Replaces oversized flow cards)
                  _buildSpendingCategories(
                    context,
                    periodBreakdown,
                    isDark,
                    theme,
                    currencyFormat,
                  ),
                  const SizedBox(height: 22),

                  // 5. Monthly Budget Summary
                  _buildMonthlyBudget(
                    context,
                    state,
                    primaryMonthlyBudget,
                    daysLeft,
                    isDark,
                    theme,
                    currencyFormat,
                  ),
                  const SizedBox(height: 22),

                  // 6. Recent Transactions List
                  _buildRecentTransactions(
                    context,
                    recentTxs,
                    isDark,
                    theme,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- COMPONENT 1: HEADER ---
  Widget _buildHeader(
    BuildContext context,
    AppState state,
    String initial,
    bool isDark,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openProfileModal(context, state),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: isDark ? AppColors.sage : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      state.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.mark_email_unread_outlined,
                size: 21,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              tooltip: 'M-Pesa SMS Ingestion',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SmsImportScreen(appState: state),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                size: 22,
                color: isDark ? AppColors.sage : AppColors.primary,
              ),
              tooltip: 'Add Transaction',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditTransactionScreen(appState: state),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- COMPONENT 2: FINANCIAL OVERVIEW ANCHOR ---
  Widget _buildFinancialAnchor(
    BuildContext context,
    AppState state,
    FinancialSummary summary,
    bool isDark,
    ThemeData theme,
    NumberFormat currencyFormat,
  ) {
    final latestWithBal = state.latestMpesaBalanceTransaction;
    final timeFormat = DateFormat('MMM d, h:mm a');

    final netCents = summary.netCashFlowCents;
    final netColor = netCents >= 0
        ? (isDark ? AppColors.incomeLight : AppColors.income)
        : (isDark ? AppColors.expenseLight : AppColors.expense);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance Row with Privacy Eye Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AVAILABLE BALANCE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      _isBalanceHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 17,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tabular Monetary Available Balance Display
            _isBalanceHidden
                ? Text(
                    'KSh ••••••',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'KSh ${currencyFormat.format(state.currentEstimatedBalance)}',
                      style: TextStyle(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
            const SizedBox(height: 4),

            // Sub-caption: Balance origin & timestamp
            Text(
              latestWithBal != null
                  ? 'From latest M-Pesa • ${timeFormat.format(latestWithBal.timestamp)}'
                  : 'Calculated from recorded transactions',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 14),

            // Period Selector Tabs (Today | This Week | This Month)
            Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildPeriodPill(0, 'Today', isDark),
                  _buildPeriodPill(1, 'This Week', isDark),
                  _buildPeriodPill(2, 'This Month', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Period Cash Flow Breakdown (Inflow / Outflow / Net Flow)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Money In',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isBalanceHidden
                              ? '••••'
                              : '+KSh ${currencyFormat.format(summary.incomeInShillings)}',
                          style: TextStyle(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.incomeLight
                                : AppColors.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Money Out',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isBalanceHidden
                              ? '••••'
                              : '-KSh ${currencyFormat.format(summary.totalOutgoingInShillings)}',
                          style: TextStyle(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.expenseLight
                                : AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Cash Flow',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isBalanceHidden
                              ? '••••'
                              : '${netCents >= 0 ? "+" : "-"}KSh ${currencyFormat.format(summary.netCashFlowInShillings.abs())}',
                          style: TextStyle(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: netColor,
                          ),
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
    );
  }

  Widget _buildPeriodPill(int index, String label, bool isDark) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriodIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurfaceVariant : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.75,
                  )
                : null,
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENT 3: PRIMARY QUICK ACTIONS ---
  Widget _buildQuickActions(BuildContext context, AppState state, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Record'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(appState: state),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Import SMS'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SmsImportScreen(appState: state),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.savings_outlined, size: 16),
            label: const Text('Budgets'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => widget.onNavigateTab(3),
          ),
        ),
      ],
    );
  }

  // --- COMPONENT 4: COMPACT SPENDING CATEGORIES ---
  Widget _buildSpendingCategories(
    BuildContext context,
    List<CategorySpending> periodBreakdown,
    bool isDark,
    ThemeData theme,
    NumberFormat currencyFormat,
  ) {
    final topCategories = periodBreakdown.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending by Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab(2), // Analytics Tab
              child: const Text('View Trends'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: topCategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'No spending recorded $_selectedPeriodLabel',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: topCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cat = entry.value;
                      final percent = (cat.percentageOfTotal * 100).toStringAsFixed(0);
                      final catColor = AppColors.chartPalette[index % AppColors.chartPalette.length];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < topCategories.length - 1 ? 12.0 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'KSh ${currencyFormat.format(cat.amountInShillings)} ($percent%)',
                                  style: TextStyle(
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: cat.percentageOfTotal.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: (isDark
                                        ? Colors.white
                                        : Colors.black)
                                    .withValues(alpha: 0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(catColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  // --- COMPONENT 5: COMPACT MONTHLY BUDGET SUMMARY ---
  Widget _buildMonthlyBudget(
    BuildContext context,
    AppState state,
    BudgetStatus? primaryMonthlyBudget,
    int daysLeft,
    bool isDark,
    ThemeData theme,
    NumberFormat currencyFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Budget',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab(3), // Budgets tab
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openMonthlyBudgetModal(
              context,
              state,
              existing: primaryMonthlyBudget?.budget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: primaryMonthlyBudget != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KSh ${currencyFormat.format(primaryMonthlyBudget.spentInShillings)} of KSh ${currencyFormat.format(primaryMonthlyBudget.limitInShillings)}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(primaryMonthlyBudget.percentageUsed * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryMonthlyBudget.isOverBudget
                                    ? AppColors.expense
                                    : primaryMonthlyBudget.isWarning
                                        ? AppColors.warning
                                        : (isDark ? AppColors.incomeLight : AppColors.income),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: primaryMonthlyBudget.percentageUsed.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: (isDark
                                    ? Colors.white
                                    : Colors.black)
                                .withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryMonthlyBudget.isOverBudget
                                  ? AppColors.expense
                                  : primaryMonthlyBudget.isWarning
                                      ? AppColors.warning
                                      : (isDark ? AppColors.incomeLight : AppColors.income),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              primaryMonthlyBudget.remainingInShillings >= 0
                                  ? 'KSh ${currencyFormat.format(primaryMonthlyBudget.remainingInShillings)} remaining'
                                  : 'Exceeded by KSh ${currencyFormat.format(-primaryMonthlyBudget.remainingInShillings)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: primaryMonthlyBudget.isOverBudget
                                    ? AppColors.expense
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                              ),
                            ),
                            Text(
                              '$daysLeft days left in month',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No spending limit set',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Keep spending on track for the month',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => _openMonthlyBudgetModal(
                            context,
                            state,
                          ),
                          child: const Text('Set Limit'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // --- COMPONENT 6: RECENT TRANSACTIONS LIST ---
  Widget _buildRecentTransactions(
    BuildContext context,
    List<TransactionModel> recentTxs,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigateTab(1), // Transactions Tab
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          child: recentTxs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No recent transactions',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTxs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.75,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
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
                            appState: widget.appState,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
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

    final amountCents = (amount * 100).round();
    final budget = BudgetModel(
      id: widget.existingBudget?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: null, // Overall monthly budget
      period: BudgetPeriod.monthly,
      limitCents: amountCents,
      warningThresholdPercent: _warningThreshold,
      startDate: DateTime.now(),
      createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    widget.appState.saveBudget(budget);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monthly budget updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.existingBudget != null
                ? 'Edit Monthly Budget'
                : 'Set Monthly Spending Limit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your overall personal spending across all categories disciplined.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              prefixText: 'KSh ',
              labelText: 'Monthly Spending Target',
            ),
          ),
          const SizedBox(height: 12),
          // Quick presets
          Wrap(
            spacing: 8,
            children: [15000, 25000, 40000, 60000].map((amt) {
              return ActionChip(
                label: Text('KSh ${NumberFormat('#,##0').format(amt)}'),
                onPressed: () => _applyPreset(amt),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Warning Alert Threshold (${(_warningThreshold * 100).toInt()}%)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Slider(
            value: _warningThreshold,
            min: 0.50,
            max: 0.95,
            divisions: 9,
            activeColor: AppColors.primary,
            label: '${(_warningThreshold * 100).toInt()}%',
            onChanged: (val) => setState(() => _warningThreshold = val),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save Spending Limit'),
            ),
          ),
        ],
      ),
    );
  }
}
