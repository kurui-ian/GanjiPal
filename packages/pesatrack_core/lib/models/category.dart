/// Expense and income category model.
class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final bool isDefault;
  final bool isIncome;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.isDefault = false,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
      'is_income': isIncome ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      colorValue: map['color_value'] as int,
      isDefault: (map['is_default'] as int?) == 1,
      isIncome: (map['is_income'] as int?) == 1,
    );
  }

  static const List<CategoryModel> defaults = [
    CategoryModel(
      id: 'food_groceries',
      name: 'Food & Groceries',
      iconName: 'shopping_basket',
      colorValue: 0xFF2E7D32, // Forest Green
      isDefault: true,
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transport',
      iconName: 'directions_bus',
      colorValue: 0xFF0288D1, // Light Blue
      isDefault: true,
    ),
    CategoryModel(
      id: 'rent',
      name: 'Rent & Housing',
      iconName: 'home',
      colorValue: 0xFF6A1B9A, // Purple
      isDefault: true,
    ),
    CategoryModel(
      id: 'utilities',
      name: 'Utilities & Bills',
      iconName: 'flash_on',
      colorValue: 0xFFF57C00, // Orange
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      iconName: 'shopping_bag',
      colorValue: 0xFFC2185B, // Pink
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      iconName: 'movie',
      colorValue: 0xFF0097A7, // Cyan
      isDefault: true,
    ),
    CategoryModel(
      id: 'education',
      name: 'Education',
      iconName: 'school',
      colorValue: 0xFF303F9F, // Indigo
      isDefault: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health & Medical',
      iconName: 'medical_services',
      colorValue: 0xFFD32F2F, // Red
      isDefault: true,
    ),
    CategoryModel(
      id: 'airtime_data',
      name: 'Airtime & Internet',
      iconName: 'wifi',
      colorValue: 0xFF00796B, // Teal
      isDefault: true,
    ),
    CategoryModel(
      id: 'transfers',
      name: 'Transfers & Send Money',
      iconName: 'swap_horiz',
      colorValue: 0xFF455A64, // Blue Grey
      isDefault: true,
    ),
    CategoryModel(
      id: 'cash_withdrawals',
      name: 'Cash Withdrawals',
      iconName: 'local_atm',
      colorValue: 0xFF5D4037, // Brown
      isDefault: true,
    ),
    CategoryModel(
      id: 'fees',
      name: 'Transaction Fees',
      iconName: 'receipt',
      colorValue: 0xFF78909C, // Slate
      isDefault: true,
    ),
    CategoryModel(
      id: 'income',
      name: 'Income & Earnings',
      iconName: 'attach_money',
      colorValue: 0xFF1B5E20, // Deep Green
      isDefault: true,
      isIncome: true,
    ),
    CategoryModel(
      id: 'other',
      name: 'Other / General',
      iconName: 'category',
      colorValue: 0xFF616161, // Grey
      isDefault: true,
    ),
  ];
}
