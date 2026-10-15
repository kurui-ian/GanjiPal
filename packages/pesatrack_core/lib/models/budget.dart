import '../parser/mpesa_transaction_types.dart';

/// Budget configuration model for spending limits.
class BudgetModel {
  final String id;
  final String? categoryId; // Null means overall/global spending limit
  final String? categoryName;
  final BudgetPeriod period;
  final int limitCents;
  final double warningThresholdPercent;
  final DateTime startDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetModel({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.period,
    required this.limitCents,
    this.warningThresholdPercent = 0.80,
    required this.startDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double get limitInShillings => limitCents / 100.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'period': period.name,
      'limit_cents': limitCents,
      'warning_threshold_percent': warningThresholdPercent,
      'start_date': startDate.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      categoryName: map['category_name'] as String?,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      limitCents: map['limit_cents'] as int,
      warningThresholdPercent:
          (map['warning_threshold_percent'] as num?)?.toDouble() ?? 0.80,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    BudgetPeriod? period,
    int? limitCents,
    double? warningThresholdPercent,
    DateTime? startDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      period: period ?? this.period,
      limitCents: limitCents ?? this.limitCents,
      warningThresholdPercent:
          warningThresholdPercent ?? this.warningThresholdPercent,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
