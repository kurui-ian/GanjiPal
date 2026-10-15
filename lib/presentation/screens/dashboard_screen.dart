import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/summary_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final state = widget.appState;
        final theme = Theme.of(context);
        final currencyFormat = NumberFormat('#,##0.00', 'en_US');

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.allTransactions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('PesaTrack')),
            body: EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Welcome to PesaTrack',
              message: 'Keep track of your daily M-Pesa spending, income, and cash flow automatically or manually.',
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

        final recentTxs = state.allTransactions.take(5).toList();
        final budgetStatuses = state.budgetStatuses;

        return Scaffold(
          appBar: AppBar(
            title: const Text('PesaTrack'),
            actions: [
              IconButton(
                icon: const Icon(Icons.sms_outlined),
                tooltip: 'SMS Ingestion',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SmsImportScreen(appState: state),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
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
          body: RefreshIndicator(
            onRefresh: () => state.loadInitialData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              children: [
                // Period Toggle Chips
                Row(
                  children: [
                    _buildPeriodChip(0, 'Today'),
                    const SizedBox(width: 8),
                    _buildPeriodChip(1, 'This Week'),
                    const SizedBox(width: 8),
                    _buildPeriodChip(2, 'This Month'),
                  ],
                ),
                const SizedBox(height: 16),

                // Net Cash Flow Banner
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Cash Flow',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${summary.transactionCount} transactions',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${summary.netCashFlowCents >= 0 ? "+" : ""}KSh ${currencyFormat.format(summary.netCashFlowInShillings)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                const SizedBox(height: 2),
                                Text(
                                  '+KSh ${currencyFormat.format(summary.incomeInShillings)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Gross Spending',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '-KSh ${currencyFormat.format(summary.grossSpendingInShillings)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid of Details
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    SummaryCard(
                      title: 'Expenses',
                      amountText:
                          'KSh ${currencyFormat.format(summary.netSpendingInShillings)}',
                      icon: Icons.trending_down,
                      accentColor: AppColors.expense,
                      subtitle: '${summary.expenseTransactionCount} purchases',
                    ),
                    SummaryCard(
                      title: 'Fees Paid',
                      amountText:
                          'KSh ${currencyFormat.format(summary.feesInShillings)}',
                      icon: Icons.receipt_long,
                      accentColor: Colors.blueGrey,
                      subtitle: 'M-Pesa tariffs',
                    ),
                    SummaryCard(
                      title: 'Cash Out',
                      amountText:
                          'KSh ${currencyFormat.format(summary.cashWithdrawnInShillings)}',
                      icon: Icons.local_atm,
                      accentColor: AppColors.withdrawal,
                      subtitle: 'Agent & ATM',
                    ),
                    SummaryCard(
                      title: 'Transfers Sent',
                      amountText:
                          'KSh ${currencyFormat.format(summary.totalTransfersSentCents / 100.0)}',
                      icon: Icons.swap_horiz,
                      accentColor: AppColors.transfer,
                      subtitle: 'To mobile numbers',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Active Budgets Quick Glance
                if (budgetStatuses.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget Health',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateTab(3), // Budgets tab
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
                          padding: const EdgeInsets.all(12.0),
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
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
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
                              LinearProgressIndicator(
                                value: bs.percentageUsed.clamp(0.0, 1.0),
                                color: bs.isOverBudget
                                    ? AppColors.expense
                                    : bs.isWarning
                                    ? Colors.amber[800]
                                    : AppColors.income,
                                backgroundColor: Colors.grey.withValues(
                                  alpha: 0.2,
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

                // Recent Transactions
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodChip(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriodIndex = index;
          });
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
