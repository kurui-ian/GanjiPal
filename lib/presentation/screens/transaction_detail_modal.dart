import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';
import '../providers/app_state.dart';

class TransactionDetailModal extends StatefulWidget {
  final TransactionModel transaction;
  final AppState appState;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.appState,
  });

  @override
  State<TransactionDetailModal> createState() => _TransactionDetailModalState();
}

class _TransactionDetailModalState extends State<TransactionDetailModal> {
  late TransactionModel _currentTx;
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _currentTx = widget.transaction;
    _selectedCategoryId = widget.transaction.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');

    final isIncome =
        _currentTx.classification == FinancialClassification.income ||
        _currentTx.classification == FinancialClassification.adjustment;

    final amountColor = isIncome
        ? (isDark ? AppColors.incomeLight : AppColors.income)
        : (isDark ? AppColors.expenseLight : AppColors.expense);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Header with Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTx.counterpartyName ??
                            _currentTx.description ??
                            _currentTx.transactionType.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(_currentTx.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topRight,
                  child: Text(
                    '${isIncome ? "+" : "-"}KSh ${currencyFormat.format(_currentTx.amountInShillings)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Transaction Attributes Table
          _buildRow('Transaction Type', _currentTx.transactionType.displayName),
          _buildRow('Classification', _currentTx.classification.displayName),
          if (_currentTx.mpesaReference != null)
            _buildRow(
              'M-Pesa Reference',
              _currentTx.mpesaReference!,
              isMonospace: true,
              isCopyable: true,
            ),
          if (_currentTx.feeCents > 0)
            _buildRow(
              'Transaction Fee',
              'KSh ${currencyFormat.format(_currentTx.feeInShillings)}',
            ),
          if (_currentTx.counterpartyPhone != null)
            _buildRow('Phone Number', _currentTx.counterpartyPhone!),
          if (_currentTx.accountReference != null)
            _buildRow('Account Number', _currentTx.accountReference!),
          if (_currentTx.balanceAfterCents != null)
            _buildRow(
              'Balance After',
              'KSh ${currencyFormat.format(_currentTx.balanceAfterCents! / 100.0)}',
            ),
          if (_currentTx.reversalReference != null)
            _buildRow('Reversed Ref', _currentTx.reversalReference!),
          _buildRow('Source', _currentTx.source.displayName),

          const SizedBox(height: 16),

          // Category Picker
          Text(
            'Category',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: widget.appState.categories.map((c) {
              return DropdownMenuItem(value: c.id, child: Text(c.name));
            }).toList(),
            onChanged: (newCatId) {
              if (newCatId != null && newCatId != _selectedCategoryId) {
                final cat = widget.appState.categories.firstWhere(
                  (c) => c.id == newCatId,
                );
                final updated = _currentTx.copyWith(
                  categoryId: cat.id,
                  categoryName: cat.name,
                  updatedAt: DateTime.now(),
                );
                widget.appState.updateTransaction(updated);
                setState(() {
                  _selectedCategoryId = newCatId;
                  _currentTx = updated;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              if (_currentTx.source == TransactionSource.manual)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.expense,
                      size: 18,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: AppColors.expense),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.expense),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (_currentTx.source == TransactionSource.manual)
                const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRow(
    String label,
    String value, {
    bool isMonospace = false,
    bool isCopyable = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget valueWidget = Text(
      value,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontFamily: isMonospace ? 'monospace' : null,
      ),
    );

    if (isCopyable) {
      valueWidget = InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $value to clipboard'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              valueWidget,
              const SizedBox(width: 4),
              Icon(Icons.copy_rounded, size: 12, color: theme.hintColor),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text(
            'This will permanently delete this manual transaction record.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.appState.deleteTransaction(_currentTx.id);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
