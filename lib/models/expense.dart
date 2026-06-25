import 'category.dart';

/// A single spending transaction.
class Expense {
  final int? id;
  final double amount;
  final Category category;
  final String note;
  final DateTime date;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  /// Convert to SQLite row
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'category': category.name,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  /// Create Expense from SQLite row
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: Category.fromName(
        map['category'] as String,
      ),
      note: (map['note'] ?? '') as String,
      date: DateTime.parse(
        map['date'] as String,
      ),
    );
  }

  /// Update copy
  Expense copyWith({
    int? id,
    double? amount,
    Category? category,
    String? note,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}