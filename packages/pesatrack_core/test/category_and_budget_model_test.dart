import 'package:pesatrack_core/pesatrack_core.dart';
import 'package:test/test.dart';

void main() {
  group('CategoryModel Unit Tests', () {
    test('default categories list contains standard expense types', () {
      expect(CategoryModel.defaults, isNotEmpty);
      final food = CategoryModel.defaults.firstWhere((c) => c.id == 'food_groceries');
      expect(food.name, equals('Food & Groceries'));
      expect(food.isDefault, isTrue);
      expect(food.isIncome, isFalse);
    });

    test('serializes to map and deserializes accurately', () {
      const customCategory = CategoryModel(
        id: 'cat_custom_1',
        name: 'Freelance Design',
        iconName: 'palette',
        colorValue: 0xFFFF5722,
        isDefault: false,
        isIncome: true,
      );

      final map = customCategory.toMap();
      expect(map['id'], equals('cat_custom_1'));
      expect(map['is_income'], equals(1));
      expect(map['is_default'], equals(0));

      final restored = CategoryModel.fromMap(map);
      expect(restored.id, equals(customCategory.id));
      expect(restored.name, equals(customCategory.name));
      expect(restored.iconName, equals(customCategory.iconName));
      expect(restored.colorValue, equals(customCategory.colorValue));
      expect(restored.isIncome, isTrue);
      expect(restored.isDefault, isFalse);
    });
  });

  group('BudgetModel Unit Tests', () {
    final now = DateTime(2026, 10, 20);

    test('calculates limitInShillings correctly from minor units', () {
      final budget = BudgetModel(
        id: 'b_01',
        period: BudgetPeriod.monthly,
        limitCents: 5000000, // 50,000 KES
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(budget.limitInShillings, equals(50000.0));
    });

    test('serializes and deserializes cleanly with null categoryId', () {
      final overallBudget = BudgetModel(
        id: 'b_overall',
        categoryId: null,
        categoryName: null,
        period: BudgetPeriod.monthly,
        limitCents: 8000000,
        warningThresholdPercent: 0.85,
        startDate: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = overallBudget.toMap();
      expect(map['category_id'], isNull);
      expect(map['period'], equals('monthly'));
      expect(map['warning_threshold_percent'], equals(0.85));

      final restored = BudgetModel.fromMap(map);
      expect(restored.id, equals(overallBudget.id));
      expect(restored.categoryId, isNull);
      expect(restored.period, equals(BudgetPeriod.monthly));
      expect(restored.limitInShillings, equals(80000.0));
      expect(restored.warningThresholdPercent, equals(0.85));
      expect(restored.isActive, isTrue);
    });
  });
}
