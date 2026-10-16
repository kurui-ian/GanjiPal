import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/empty_state_view.dart';

class BudgetsScreen extends StatelessWidget {
  final AppState appState;

  const BudgetsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final statuses = appState.budgetStatuses;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final currencyFormat = NumberFormat('#,##0', 'en_US');

        // Calculate aggregated metrics across active budgets
        int totalLimitCents = 0;
        int totalSpentCents = 0;
        for (final s in statuses) {
          totalLimitCents += s.budget.limitCents;
          totalSpentCents += s.spentCents;
        }

        final overallPercent = totalLimitCents > 0
            ? (totalSpentCents / totalLimitCents).clamp(0.0, 1.0)
            : 0.0;
        final overallRemainingInShillings =
            (totalLimitCents - totalSpentCents) / 100.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Budgets & Limits'),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
                tooltip: 'Create Budget',
                onPressed: () => _showAddBudgetDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: statuses.isEmpty
              ? EmptyStateView(
                  icon: Icons.savings_outlined,
                  title: 'No Spending Limits Set',
                  message:
                      'Set daily, weekly, or monthly budgets to stay in control of your M-Pesa spending.',
                  primaryActionTitle: 'Set a Budget',
                  onPrimaryAction: () => _showAddBudgetDialog(context),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  children: [
                    // Hero Budget Progress Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
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
                              const Text(
                                'Total Monthly Budget',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                child: Text(
                                  '${(overallPercent * 100).toInt()}% Used',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'KSh ${currencyFormat.format(totalSpentCents / 100.0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '/ KSh ${currencyFormat.format(totalLimitCents / 100.0)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: overallPercent,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            overallRemainingInShillings >= 0
                                ? 'KSh ${currencyFormat.format(overallRemainingInShillings)} remaining this month'
                                : 'Exceeded by KSh ${currencyFormat.format(-overallRemainingInShillings)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Budgets Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Category Limits (${statuses.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Swipe to delete',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Individual Budget Cards
                    ...statuses.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Dismissible(
                          key: Key(status.budget.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.expense,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) {
                            appState.deleteBudget(status.budget.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Budget deleted')),
                            );
                          },
                          child: BudgetProgressCard(
                            status: status,
                            onTap: () => _showBudgetOptions(context, status),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add),
            label: const Text(
              'New Limit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => _showAddBudgetDialog(context),
          ),
        );
      },
    );
  }

  void _showAddBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetBottomSheet(appState: appState),
    );
  }

  void _showBudgetOptions(BuildContext context, BudgetStatus status) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.expense),
                title: const Text(
                  'Delete Budget',
                  style: TextStyle(color: AppColors.expense),
                ),
                onTap: () {
                  appState.deleteBudget(status.budget.id);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddBudgetBottomSheet extends StatefulWidget {
  final AppState appState;

  const _AddBudgetBottomSheet({required this.appState});

  @override
  State<_AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<_AddBudgetBottomSheet> {
  final _amountController = TextEditingController();
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  String? _selectedCategoryId; // null = overall
  double _warningThreshold = 0.80;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Spending Limit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Amount Limit
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Limit Amount (KSh)',
              prefixText: 'KSh ',
              hintText: '10,000',
            ),
          ),
          const SizedBox(height: 16),

          // Period Selector
          DropdownButtonFormField<BudgetPeriod>(
            initialValue: _selectedPeriod,
            decoration: const InputDecoration(labelText: 'Budget Period'),
            items: BudgetPeriod.values.map((p) {
              return DropdownMenuItem(value: p, child: Text(p.displayName));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPeriod = val);
            },
          ),
          const SizedBox(height: 16),

          // Scope: Overall or Specific Category
          DropdownButtonFormField<String?>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Category Scope'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Overall Spending (All Categories)'),
              ),
              ...widget.appState.categories.map((c) {
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }),
            ],
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 16),

          // Warning Threshold Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alert Threshold',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('${(_warningThreshold * 100).toInt()}% of budget'),
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
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveBudget,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Set Budget',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveBudget() {
    final clean = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(clean);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget limit')),
      );
      return;
    }

    String? catName;
    if (_selectedCategoryId != null) {
      catName = widget.appState.categories
          .firstWhere((c) => c.id == _selectedCategoryId)
          .name;
    }

    final budget = BudgetModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: _selectedCategoryId,
      categoryName: catName,
      period: _selectedPeriod,
      limitCents: (amount * 100).round(),
      warningThresholdPercent: _warningThreshold,
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.appState.saveBudget(budget);
    Navigator.of(context).pop();
  }
}
