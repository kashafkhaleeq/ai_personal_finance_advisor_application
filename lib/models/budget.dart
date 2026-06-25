import 'category.dart';

/// A monthly spending limit for one category.
class Budget {
  final int? id;
  final Category category;
  final double monthlyLimit;

  Budget({
    this.id,
    required this.category,
    required this.monthlyLimit,
  });

  Map<String, dynamic> toMap() => {
    'category': category.name,
    'limit': monthlyLimit,
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    category: Category.fromName(map['category'] as String),
    monthlyLimit: (map['limit'] as num).toDouble(),
  );

  Budget copyWith({int? id, Category? category, double? monthlyLimit}) =>
      Budget(
        id: id ?? this.id,
        category: category ?? this.category,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      );
}