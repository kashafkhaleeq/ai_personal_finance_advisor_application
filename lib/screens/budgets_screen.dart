import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _bg = Color(0xFFF5F6F8);
  static const _border = Color(0x14000000);

  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final budgets = await DatabaseService.instance.getBudgets();
    final expenses = await DatabaseService.instance
        .getExpensesForMonth(DateTime.now());
    setState(() {
      _budgets = budgets;
      _expenses = expenses;
      _loading = false;
    });
  }

  double _spentFor(Category cat) {
    return _expenses
        .where((e) => e.category == cat)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  String _money(num v) =>
      'Rs ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  void _openBudgetDialog({Budget? existing}) {
    final category = existing?.category ?? Category.values.first;
    final controller = TextEditingController(
      text: existing != null ? existing.monthlyLimit.toStringAsFixed(0) : '',
    );
    Category selectedCategory = category;
    bool showError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      existing != null ? 'Edit Budget' : 'Set Budget',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (existing == null) ...[
                      const Text(
                        'Category',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: Category.values.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final cat = Category.values[i];
                            final sel = cat == selectedCategory;
                            return GestureDetector(
                              onTap: () =>
                                  setModal(() => selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _green.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? _green : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(cat.icon,
                                        size: 16,
                                        color: sel ? _green : cat.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: sel
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: sel ? _green : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Monthly Limit',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixText: 'Rs ',
                        hintText: '0',
                        errorText: showError ? 'Enter a valid amount' : null,
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: _green, width: 1.5),
                        ),
                      ),
                      onChanged: (_) {
                        if (showError) setModal(() => showError = false);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final limit = double.tryParse(controller.text);
                          if (limit == null || limit <= 0) {
                            setModal(() => showError = true);
                            return;
                          }
                          await DatabaseService.instance.upsertBudget(
                            Budget(
                              category: existing?.category ?? selectedCategory,
                              monthlyLimit: limit,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                        },
                        child: Text(
                          existing != null ? 'Update Budget' : 'Set Budget',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBudget(Category cat) async {
    await DatabaseService.instance.deleteBudget(cat);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Budgets'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetDialog(),
        backgroundColor: _green,
        icon: const Icon(Icons.add),
        label: const Text('Set Budget'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _budgets.isEmpty
            ? _emptyState(scale)
            : LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth > 600
                ? 600.0
                : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView(
                  padding: EdgeInsets.all(16 * scale),
                  children: [
                    _summaryCard(scale),
                    SizedBox(height: 16 * scale),
                    Text(
                      'Your Budgets',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    ..._budgets
                        .map((b) => _budgetCard(b, scale)),
                    SizedBox(height: 80 * scale),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(double scale) {
    final totalBudget =
    _budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
    final totalSpent =
    _budgets.fold(0.0, (sum, b) => sum + _spentFor(b.category));
    final remaining = totalBudget - totalSpent;
    final overBudget = remaining < 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, _greenDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 13 * scale,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 10 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _overviewStat('Total Budget', _money(totalBudget), scale),
              _overviewStat('Spent', _money(totalSpent), scale),
              _overviewStat(
                overBudget ? 'Over By' : 'Remaining',
                _money(remaining.abs()),
                scale,
                highlight: overBudget,
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalBudget == 0
                  ? 0
                  : (totalSpent / totalBudget).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                overBudget ? Colors.red.shade300 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(String label, String value, double scale,
      {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11 * scale,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.red.shade200 : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _budgetCard(Budget b, double scale) {
    final spent = _spentFor(b.category);
    final progress =
    b.monthlyLimit == 0 ? 0.0 : (spent / b.monthlyLimit).clamp(0.0, 1.0);
    final overBudget = spent > b.monthlyLimit;
    final remaining = b.monthlyLimit - spent;

    return Dismissible(
      key: ValueKey(b.category.name),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteBudget(b.category),
      background: Container(
        margin: EdgeInsets.symmetric(vertical: 6 * scale),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20 * scale),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6 * scale),
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18 * scale,
                  backgroundColor:
                  b.category.color.withValues(alpha: 0.15),
                  child: Icon(b.category.icon,
                      color: b.category.color, size: 18 * scale),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Text(
                    b.category.label,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openBudgetDialog(existing: b),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10 * scale, vertical: 5 * scale),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  overBudget
                      ? Colors.red
                      : progress > 0.75
                      ? Colors.orange
                      : _green,
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_money(spent)} spent',
                  style: TextStyle(
                      fontSize: 12 * scale, color: Colors.grey.shade600),
                ),
                Text(
                  overBudget
                      ? '${_money(remaining.abs())} over!'
                      : '${_money(remaining)} left',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                    color: overBudget ? Colors.red : _green,
                  ),
                ),
                Text(
                  'of ${_money(b.monthlyLimit)}',
                  style: TextStyle(
                      fontSize: 12 * scale, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20 * scale),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 40 * scale,
              color: _green,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'No budgets set',
            style: TextStyle(
                fontSize: 16 * scale, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6 * scale),
          Text(
            'Tap below to set a monthly limit',
            style: TextStyle(
                fontSize: 13 * scale, color: Colors.grey.shade600),
          ),
          SizedBox(height: 20 * scale),
          ElevatedButton.icon(
            onPressed: () => _openBudgetDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale, vertical: 12 * scale),
            ),
            icon: Icon(Icons.add, size: 18 * scale),
            label:
            Text('Set Budget', style: TextStyle(fontSize: 14 * scale)),
          ),
        ],
      ),
    );
  }
}