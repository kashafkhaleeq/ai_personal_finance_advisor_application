import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';   // ← ye add karo
import '../models/expense.dart';
import '../models/budget.dart';
import 'package:finance_advisor/models/category.dart';
enum Category {
  food('Food & Dining', Icons.restaurant, Color(0xFFEF6C00)),
  transport('Transport', Icons.directions_car, Color(0xFF1E88E5)),
  shopping('Shopping', Icons.shopping_bag, Color(0xFF8E24AA)),
  bills('Bills & Utilities', Icons.receipt_long, Color(0xFF00897B)),
  entertainment('Entertainment', Icons.movie, Color(0xFFD81B60)),
  health('Health', Icons.favorite, Color(0xFFE53935)),
  education('Education', Icons.school, Color(0xFF3949AB)),
  other('Other', Icons.category, Color(0xFF607D8B));

  const Category(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static Category fromName(String name) {
    return Category.values.firstWhere(
          (c) => c.name == name,
      orElse: () => Category.other,
    );
  }
}