import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

import '../../core/constants/app_colors.dart';

/// Item representing a parsed SMS in the batch review pipeline.
class SmsBatchReviewItem {
  final String id;
  final ParsedSmsResult parsed;
  bool isSelected;
  String categoryId;
  String categoryName;
  bool isDuplicate;
  bool isExpanded;

  SmsBatchReviewItem({
    required this.id,
    required this.parsed,
    this.isSelected = true,
    required this.categoryId,
    required this.categoryName,
    this.isDuplicate = false,
    this.isExpanded = false,
  });

  bool get isValid => parsed.isMpesa && parsed.amountCents > 0;
}

/// Rich review card for an extracted M-Pesa transaction before committing to SQLite.
class SmsBatchReviewCard extends StatelessWidget {
  final SmsBatchReviewItem item;
  final ValueChanged<bool?> onToggleSelected;
  final VoidCallback onSelectCategory;
  final VoidCallback onToggleExpand;
  final VoidCallback? onDelete;

  const SmsBatchReviewCard({
    super.key,
    required this.item,
    required this.onToggleSelected,
    required this.onSelectCategory,
    required this.onToggleExpand,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    final parsed = item.parsed;
    final isValid = item.isValid;
    final isIncome = parsed.classification == FinancialClassification.income;

    final primaryColor = !isValid
        ? AppColors.expense
        : item.isDuplicate
            ? Colors.blueGrey
            : isIncome
                ? (isDark ? AppColors.sage : AppColors.primary)
                : AppColors.expense;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isDuplicate
              ? Colors.amber.withValues(alpha: 0.5)
              : isDark
                  ? AppColors.darkSurfaceBorder
                  : AppColors.lightBorder,
          width: 0.75,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Checkbox, Type Badge, and Formatted Amount
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: isValid ? () => onToggleSelected(!item.isSelected) : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: item.isSelected && isValid && !item.isDuplicate,
                      onChanged: (isValid && !item.isDuplicate)
                          ? onToggleSelected
                          : (val) {
                              onToggleSelected(val);
                            },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Transaction Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isValid
                          ? parsed.transactionType.displayName.toUpperCase()
                          : 'UNRECOGNIZED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  if (item.isDuplicate) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DUPLICATE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Amount
                  Text(
                    isValid
                        ? '${isIncome ? "+" : "-"} KSh ${currencyFormat.format(parsed.amountCents / 100.0)}'
                        : 'Invalid Amount',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Body: Counterparty & Reference
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Counterparty
                  Text(
                    parsed.counterpartyName ??
                        parsed.description ??
                        (isValid ? 'M-Pesa Transaction' : 'Parse Error'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Timestamp and Reference Row
                  Row(
                    children: [
                      if (parsed.mpesaReference != null) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: parsed.mpesaReference!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Copied ${parsed.mpesaReference} to clipboard',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  parsed.mpesaReference!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 10,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (parsed.timestamp != null)
                        Text(
                          dateFormat.format(parsed.timestamp!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Metadata Chips (Category Selector, Fee, Balance After)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Category Pill with Tap to Change
                      InkWell(
                        onTap: onSelectCategory,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkSurfaceBorder
                                  : AppColors.lightBorder,
                              width: 0.75,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.categoryName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 14,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Transaction Fee (if any)
                      if (parsed.feeCents > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Fee KSh ${currencyFormat.format(parsed.feeCents / 100.0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),

                      // Balance After (if extracted)
                      if (parsed.balanceAfterCents != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bal KSh ${currencyFormat.format(parsed.balanceAfterCents! / 100.0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (!isValid && parsed.failureReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.expense.withValues(alpha: 0.25),
                          width: 0.75,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.expense,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              parsed.failureReason!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Expand / Collapse Raw SMS
                  InkWell(
                    onTap: onToggleExpand,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.isExpanded ? 'Hide Raw SMS' : 'View Raw SMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.sage
                                  : AppColors.primary,
                            ),
                          ),
                          Icon(
                            item.isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: isDark
                                ? AppColors.sage
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expanded Raw SMS Drawer
                  if (item.isExpanded) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.grey[100])
                            ?.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSurfaceBorder
                              : AppColors.lightBorder,
                          width: 0.75,
                        ),
                      ),
                      child: SelectableText(
                        parsed.rawMessage,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
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
}
