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
        ? Colors.red
        : item.isDuplicate
            ? Colors.blueGrey
            : isIncome
                ? (isDark ? AppColors.incomeLight : AppColors.income)
                : (isDark ? AppColors.expenseLight : AppColors.expense);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isDuplicate
              ? Colors.amber.withValues(alpha: 0.5)
              : isValid && item.isSelected
                  ? primaryColor.withValues(alpha: 0.35)
                  : theme.dividerColor.withValues(alpha: 0.15),
          width: isValid && item.isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Checkbox, Type Badge, and Formatted Amount
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isValid ? () => onToggleSelected(!item.isSelected) : null,
              child: Row(
                children: [
                  Checkbox(
                    value: item.isSelected && isValid && !item.isDuplicate,
                    onChanged: (isValid && !item.isDuplicate)
                        ? onToggleSelected
                        : (val) {
                            // If it is a duplicate, allow user to manually re-select if desired
                            onToggleSelected(val);
                          },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  // Transaction Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          !isValid
                              ? Icons.error_outline_rounded
                              : isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                          size: 13,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isValid
                              ? parsed.transactionType.displayName.toUpperCase()
                              : 'UNRECOGNIZED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.isDuplicate) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DUPLICATE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Body: Counterparty & Reference
              Padding(
                padding: const EdgeInsets.only(left: 44.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Counterparty
                    Text(
                      parsed.counterpartyName ??
                          parsed.description ??
                          (isValid ? 'M-Pesa Transaction' : 'Parse Error'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    parsed.mpesaReference!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: theme.hintColor,
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
                              color: theme.hintColor,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Metadata Chips (Category Selector, Fee, Balance After)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category Pill with Tap to Change
                        InkWell(
                          onTap: onSelectCategory,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.categoryName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Transaction Fee (if any)
                        if (parsed.feeCents > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Fee: KSh ${currencyFormat.format(parsed.feeCents / 100.0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
                              ),
                            ),
                          ),

                        // Balance After (if extracted)
                        if (parsed.balanceAfterCents != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Bal: KSh ${currencyFormat.format(parsed.balanceAfterCents! / 100.0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.hintColor,
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
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                parsed.failureReason!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

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
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Icon(
                              item.isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
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
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: SelectableText(
                          parsed.rawMessage,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color,
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
