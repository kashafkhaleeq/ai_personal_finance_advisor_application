import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String userName = 'User';
  String currencySymbol = 'Rs';
  double totalSpentThisMonth = 0;
  double remaining = 0;
  double changePercent = 0;
  List<Map<String, dynamic>> categoryBreakdown = [];
  List<Map<String, dynamic>> weeklyBarData = [];
  List recentExpenses = [];

  Future<void> loadAll() async {
    notifyListeners();
  }

  Future<void> initMemberSince() async {
    notifyListeners();
  }
}