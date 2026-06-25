import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import 'package:finance_advisor/models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'finance.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        amount      REAL    NOT NULL,
        category    TEXT    NOT NULL,
        date        TEXT    NOT NULL,
        note        TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        category TEXT PRIMARY KEY,
        "limit"  REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE prefs (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute(
          'CREATE TABLE IF NOT EXISTS prefs (key TEXT PRIMARY KEY, value TEXT)');
    }
    if (oldV < 3) {
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('''
        CREATE TABLE expenses (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          amount      REAL    NOT NULL,
          category    TEXT    NOT NULL,
          date        TEXT    NOT NULL,
          note        TEXT
        )
      ''');
    }
  }

  // ── EXPENSES ──────────────────────────────────────────────
  Future<int> insertExpense(Expense e) async {
    final db = await database;
    try {
      final id = await db.insert('expenses', e.toMap());
      debugPrint('Expense inserted with id: $id');
      return id;
    } catch (err) {
      debugPrint('insertExpense ERROR: $err');
      return -1;
    }
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final db = await database;
    final from = DateTime(month.year, month.month, 1).toIso8601String();
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59)
        .toIso8601String();
    final rows = await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [from, to],
      orderBy: 'date DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ── BUDGETS ───────────────────────────────────────────────
  Future<void> upsertBudget(Budget b) async {
    final db = await database;
    try {
      await db.insert(
        'budgets',
        b.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Budget upserted: ${b.category.name} = ${b.monthlyLimit}');
    } catch (err) {
      debugPrint('upsertBudget ERROR: $err');
    }
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> deleteBudget(Category cat) async {
    final db = await database;
    await db.delete('budgets',
        where: 'category = ?', whereArgs: [cat.name]);
  }

  // ── PREFS ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPrefs() async {
    final db = await database;
    final rows = await db.query('prefs');
    final map = <String, dynamic>{};
    for (final r in rows) {
      final key = r['key'] as String;
      final val = r['value'] as String?;
      if (key == 'notifications') {
        map[key] = val == 'true';
      } else {
        map[key] = val;
      }
    }
    return map;
  }

  Future<void> savePrefs(Map<String, dynamic> prefs) async {
    final db = await database;
    for (final entry in prefs.entries) {
      await db.insert(
        'prefs',
        {'key': entry.key, 'value': entry.value.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ── RESET ─────────────────────────────────────────────────
  Future<void> resetAll() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('budgets');
  }
}