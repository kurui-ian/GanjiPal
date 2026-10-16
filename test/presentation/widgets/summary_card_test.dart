import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesatrack/presentation/widgets/summary_card.dart';

void main() {
  group('SummaryCard Widget Tests', () {
    testWidgets('renders title, amount, and icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Total Spending',
              amountText: 'KSh 15,200',
              icon: Icons.trending_down,
              accentColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('Total Spending'), findsOneWidget);
      expect(find.text('KSh 15,200'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Income',
              amountText: 'KSh 45,000',
              icon: Icons.trending_up,
              accentColor: Colors.green,
              subtitle: '12 transactions this month',
            ),
          ),
        ),
      );

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('KSh 45,000'), findsOneWidget);
      expect(find.text('12 transactions this month'), findsOneWidget);
    });

    testWidgets('does not render subtitle text when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Net Cash Flow',
              amountText: '+KSh 29,800',
              icon: Icons.account_balance_wallet,
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Net Cash Flow'), findsOneWidget);
      expect(find.text('+KSh 29,800'), findsOneWidget);
      // Verify only 2 Text widgets exist (title and amount)
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('renders with Dark Theme correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SummaryCard(
              title: 'Budget Remaining',
              amountText: 'KSh 8,500',
              icon: Icons.savings,
              accentColor: Colors.teal,
              subtitle: '70% remaining',
            ),
          ),
        ),
      );

      expect(find.text('Budget Remaining'), findsOneWidget);
      expect(find.text('KSh 8,500'), findsOneWidget);
      expect(find.text('70% remaining'), findsOneWidget);
      expect(find.byIcon(Icons.savings), findsOneWidget);
    });
  });
}
