import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final timeFormat = DateFormat('MMM d, h:mm a');

    final isIncome =
        transaction.classification == FinancialClassification.income ||
        transaction.classification == FinancialClassification.adjustment;

    final amountColor = isIncome
        ? (isDark ? AppColors.incomeLight : AppColors.income)
        : (isDark ? AppColors.expenseLight : AppColors.expense);

    final sign = isIncome ? '+' : '-';
    final amountString =
        '$sign KSh ${currencyFormat.format(transaction.amountInShillings)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon Badge
            _buildLeadingBadge(context),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.counterpartyName ??
                              transaction.description ??
                              transaction.categoryName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.reviewStatus ==
                          ReviewStatus.needsReview) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.amber[300]
                                  : Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.transactionType.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeFormat.format(transaction.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount Column
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountString,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ),
                  if (transaction.feeCents > 0) ...[
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Fee: KSh ${currencyFormat.format(transaction.feeInShillings)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                if (transaction.balanceAfterCents != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bal: KSh ${currencyFormat.format(transaction.balanceAfterCents! / 100.0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLeadingBadge(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (transaction.classification) {
      case FinancialClassification.income:
        iconData = Icons.arrow_downward_rounded;
        iconColor = AppColors.income;
        break;
      case FinancialClassification.expense:
        iconData = Icons.arrow_upward_rounded;
        iconColor = AppColors.expense;
        break;
      case FinancialClassification.transfer:
        iconData = Icons.swap_horiz_rounded;
        iconColor = AppColors.transfer;
        break;
      case FinancialClassification.withdrawal:
        iconData = Icons.local_atm_rounded;
        iconColor = AppColors.withdrawal;
        break;
      case FinancialClassification.deposit:
        iconData = Icons.account_balance_wallet_rounded;
        iconColor = AppColors.income;
        break;
      case FinancialClassification.adjustment:
        iconData = Icons.replay_rounded;
        iconColor = AppColors.adjustment;
        break;
      case FinancialClassification.unclassified:
        iconData = Icons.help_outline_rounded;
        iconColor = AppColors.unclassified;
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }
}
