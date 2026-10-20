import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Ultra-smooth animated numeric currency text.
/// Uses [TweenAnimationBuilder] to smoothly count up/down between monetary values
/// when periods switch or balances update, with zero frame drop.
class AnimatedAmountText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String prefix;
  final bool showDecimals;
  final Duration duration;
  final Curve curve;
  final TextAlign textAlign;
  final bool scaleDownToFit;
  final Alignment alignment;

  const AnimatedAmountText({
    super.key,
    required this.amount,
    this.style,
    this.prefix = 'KSh ',
    this.showDecimals = true,
    this.duration = const Duration(milliseconds: 550),
    this.curve = Curves.easeOutCubic,
    this.textAlign = TextAlign.left,
    this.scaleDownToFit = true,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat(
      showDecimals ? '#,##0.00' : '#,##0',
      'en_US',
    );

    Widget child = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        final formatted = currencyFormatter.format(value.abs());
        final sign = amount < 0 ? '-' : (prefix.startsWith('+') ? '+' : '');
        final cleanPrefix = prefix.replaceFirst(RegExp(r'^[+-]'), '');

        return Text(
          '$sign$cleanPrefix$formatted',
          style: style,
          textAlign: textAlign,
          maxLines: 1,
        );
      },
    );

    if (scaleDownToFit) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: child,
      );
    }

    return child;
  }
}
