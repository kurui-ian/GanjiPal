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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
        child: Row(
          children: [
            // Compact Leading Circular Badge
            _buildLeadingBadge(context),
            const SizedBox(width: 12),

            // Counterparty & Transaction Meta
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
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
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.transactionType.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeFormat.format(transaction.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Tabular Monetary Amount Column
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountString,
                      style: TextStyle(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
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
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                  ],
                  if (transaction.balanceAfterCents != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Bal: KSh ${currencyFormat.format(transaction.balanceAfterCents! / 100.0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 18),
    );
  }
}
