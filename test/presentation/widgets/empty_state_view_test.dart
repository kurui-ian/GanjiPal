import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesatrack/presentation/widgets/empty_state_view.dart';

void main() {
  group('EmptyStateView Widget Tests', () {
    testWidgets('renders icon, title, and message correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'No Transactions Found',
              message: 'Import your M-Pesa SMS to see your expenses.',
            ),
          ),
        ),
      );

      expect(find.text('No Transactions Found'), findsOneWidget);
      expect(
        find.text('Import your M-Pesa SMS to see your expenses.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('triggers onPrimaryAction callback when primary button is tapped', (
      tester,
    ) async {
      bool primaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.savings_outlined,
              title: 'No Active Budgets',
              message: 'Set a monthly spending limit to keep on track.',
              primaryActionTitle: 'Create Budget',
              onPrimaryAction: () {
                primaryTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Create Budget'), findsOneWidget);
      await tester.tap(find.text('Create Budget'));
      await tester.pump();

      expect(primaryTapped, isTrue);
    });

    testWidgets('triggers onSecondaryAction callback when secondary button is tapped', (
      tester,
    ) async {
      bool secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              icon: Icons.sms_outlined,
              title: 'No SMS Messages',
              message: 'Scan your inbox or paste message manually.',
              primaryActionTitle: 'Scan Inbox',
              secondaryActionTitle: 'Paste SMS Manually',
              onSecondaryAction: () {
                secondaryTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Paste SMS Manually'), findsOneWidget);
      await tester.tap(find.text('Paste SMS Manually'));
      await tester.pump();

      expect(secondaryTapped, isTrue);
    });

    testWidgets('renders properly with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: EmptyStateView(
              icon: Icons.search_off,
              title: 'No Search Results',
              message: 'Try adjusting your filters or search keywords.',
            ),
          ),
        ),
      );

      expect(find.text('No Search Results'), findsOneWidget);
      expect(
        find.text('Try adjusting your filters or search keywords.'),
        findsOneWidget,
      );
    });
  });
}
