import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesatrack/presentation/widgets/spending_donut_chart.dart';
import 'package:pesatrack_core/pesatrack_core.dart';

void main() {
  group('SpendingDonutChart Widget Tests', () {
    testWidgets('renders empty state when there are no spending categories', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpendingDonutChart(
              breakdown: [],
              totalSpentInShillings: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('Spending Breakdown'), findsOneWidget);
      expect(find.text('0 Categories'), findsOneWidget);
      expect(find.text('KSh 0'), findsOneWidget);
      expect(
        find.text('No expenses recorded yet in this selected period.'),
        findsOneWidget,
      );
    });

    testWidgets('renders categories and percentages when data is provided', (
      tester,
    ) async {
      final breakdown = [
        const CategorySpending(
          categoryId: 'food',
          categoryName: 'Food & Dining',
          amountCents: 500000,
          transactionCount: 5,
          percentageOfTotal: 0.50,
        ),
        const CategorySpending(
          categoryId: 'utilities',
          categoryName: 'Utilities',
          amountCents: 300000,
          transactionCount: 2,
          percentageOfTotal: 0.30,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpendingDonutChart(
              breakdown: breakdown,
              totalSpentInShillings: 8000.0,
            ),
          ),
        ),
      );

      expect(find.text('Spending Breakdown'), findsOneWidget);
      expect(find.text('2 Categories'), findsOneWidget);
      expect(find.text('KSh 8,000'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
    });
  });
}
