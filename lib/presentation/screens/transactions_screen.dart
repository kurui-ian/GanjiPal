import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';
import 'transaction_detail_modal.dart';

class TransactionsScreen extends StatelessWidget {
  final AppState appState;

  const TransactionsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final filtered = appState.filteredTransactions;
        final hasActiveFilters =
            appState.filterClassification != null ||
            appState.filterCategoryId != null ||
            appState.filterStartDate != null ||
            appState.searchQuery.isNotEmpty;

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final currencyFormat = NumberFormat('#,##0.00', 'en_US');

        // Most recent transaction with an explicit balance
        final latestWithBalance = appState.latestMpesaBalanceTransaction;

        // Group filtered transactions by date
        final groupedTxs = _groupTransactionsByDate(filtered);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transactions'),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded, size: 20),
                  ),
                ),
                tooltip: 'Filter Transactions',
                onPressed: () => _showFilterBottomSheet(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search Input Field
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search merchant, phone, reference...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    suffixIcon: appState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => appState.setSearchQuery(''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) => appState.setSearchQuery(val),
                ),
              ),

              // Segmented Filter Pills: All | Expense | Income | Transfers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildQuickPill(
                        context,
                        label: 'All',
                        isSelected: appState.filterClassification == null,
                        onTap: () => appState.setFilterClassification(null),
                      ),
                      _buildQuickPill(
                        context,
                        label: 'Expense',
                        isSelected: appState.filterClassification ==
                            FinancialClassification.expense,
                        onTap: () => appState.setFilterClassification(
                          FinancialClassification.expense,
                        ),
                      ),
                      _buildQuickPill(
                        context,
                        label: 'Income',
                        isSelected: appState.filterClassification ==
                            FinancialClassification.income,
                        onTap: () => appState.setFilterClassification(
                          FinancialClassification.income,
                        ),
                      ),
                      _buildQuickPill(
                        context,
                        label: 'Transfers',
                        isSelected: appState.filterClassification ==
                            FinancialClassification.transfer,
                        onTap: () => appState.setFilterClassification(
                          FinancialClassification.transfer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Current Balance Ledger Banner
              if (latestWithBalance != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latest M-Pesa Balance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'KSh ${currencyFormat.format(latestWithBalance.balanceAfterCents! / 100.0)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, h:mm a').format(
                            latestWithBalance.timestamp,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Active Filters Notification Chip
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reset Filters'),
                        onPressed: () => appState.clearFilters(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${filtered.length} matching transactions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              // Date-Grouped Transaction List
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: hasActiveFilters
                            ? 'No Matching Transactions'
                            : 'No Transactions Recorded',
                        message: hasActiveFilters
                            ? 'Try clearing your filters or search keywords.'
                            : 'Transactions will appear here once imported from M-Pesa or entered manually.',
                        primaryActionTitle: hasActiveFilters
                            ? 'Clear Filters'
                            : 'Add Manual Transaction',
                        onPrimaryAction: hasActiveFilters
                            ? () => appState.clearFilters()
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditTransactionScreen(
                                      appState: appState,
                                    ),
                                  ),
                                );
                              },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                        itemCount: groupedTxs.length,
                        itemBuilder: (context, groupIndex) {
                          final dateHeader =
                              groupedTxs.keys.elementAt(groupIndex);
                          final txList = groupedTxs[dateHeader]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateHeader,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                          ),
                                    ),
                                    Text(
                                      '${txList.length} txs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Card(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: txList.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    indent: 70,
                                  ),
                                  itemBuilder: (context, index) {
                                    final tx = txList[index];
                                    return TransactionTile(
                                      transaction: tx,
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) =>
                                              TransactionDetailModal(
                                                transaction: tx,
                                                appState: appState,
                                              ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_transactions',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(appState: appState),
                ),
              );
            },
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildQuickPill(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate(
    List<TransactionModel> txs,
  ) {
    final Map<String, List<TransactionModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in txs) {
      final txDate = DateTime(
        tx.timestamp.year,
        tx.timestamp.month,
        tx.timestamp.day,
      );
      String header;
      if (txDate == today) {
        header = 'Today';
      } else if (txDate == yesterday) {
        header = 'Yesterday';
      } else if (txDate.year == now.year) {
        header = DateFormat('MMMM d').format(txDate);
      } else {
        header = DateFormat('MMMM d, yyyy').format(txDate);
      }
      groups.putIfAbsent(header, () => []).add(tx);
    }
    return groups;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterBottomSheet(appState: appState),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final AppState appState;

  const _FilterBottomSheet({required this.appState});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  FinancialClassification? _selectedClassification;
  String? _selectedCategory;
  String _selectedSort = 'newest';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedClassification = widget.appState.filterClassification;
    _selectedCategory = widget.appState.filterCategoryId;
    _selectedSort = widget.appState.sortOrder;
    _startDate = widget.appState.filterStartDate;
    _endDate = widget.appState.filterEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.appState.clearFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Classification
          Text(
            'Classification',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Expenses'),
                selected:
                    _selectedClassification == FinancialClassification.expense,
                onSelected: (val) => setState(
                  () => _selectedClassification = val
                      ? FinancialClassification.expense
                      : null,
                ),
              ),
              FilterChip(
                label: const Text('Income'),
                selected:
                    _selectedClassification == FinancialClassification.income,
                onSelected: (val) => setState(
                  () => _selectedClassification = val
                      ? FinancialClassification.income
                      : null,
                ),
              ),
              FilterChip(
                label: const Text('Transfers'),
                selected:
                    _selectedClassification == FinancialClassification.transfer,
                onSelected: (val) => setState(
                  () => _selectedClassification = val
                      ? FinancialClassification.transfer
                      : null,
                ),
              ),
              FilterChip(
                label: const Text('Withdrawals'),
                selected:
                    _selectedClassification ==
                    FinancialClassification.withdrawal,
                onSelected: (val) => setState(
                  () => _selectedClassification = val
                      ? FinancialClassification.withdrawal
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range
          Text(
            'Date Range',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              _startDate != null && _endDate != null
                  ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                  : 'Select Date Range',
            ),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (range != null) {
                setState(() {
                  _startDate = range.start;
                  _endDate = DateTime(
                    range.end.year,
                    range.end.month,
                    range.end.day,
                    23,
                    59,
                    59,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Sort Order
          Text(
            'Sort By',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSort,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
              DropdownMenuItem(value: 'highest', child: Text('Highest Amount')),
              DropdownMenuItem(value: 'lowest', child: Text('Lowest Amount')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedSort = val);
            },
          ),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.appState.setFilterClassification(
                  _selectedClassification,
                );
                widget.appState.setFilterCategory(_selectedCategory);
                widget.appState.setDateRange(_startDate, _endDate);
                widget.appState.setSortOrder(_selectedSort);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
