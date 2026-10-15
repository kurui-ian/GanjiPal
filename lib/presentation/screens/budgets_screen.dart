import 'package:flutter/material.dart';
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

        return Scaffold(
          appBar: AppBar(title: const Text('Budgets & Limits')),
          body: statuses.isEmpty
              ? EmptyStateView(
                  icon: Icons.savings_outlined,
                  title: 'No Spending Limits Set',
                  message: 'Set daily, weekly, or monthly budgets to stay in control of your M-Pesa spending.',
                  primaryActionTitle: 'Set a Budget',
                  onPrimaryAction: () => _showAddBudgetDialog(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  itemCount: statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final status = statuses[index];
                    return Dismissible(
                      key: Key(status.budget.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
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
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New Budget'),
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
            value: _selectedPeriod,
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
            value: _selectedCategoryId,
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
