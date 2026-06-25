import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/formatting.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _bg = Color(0xFFF5F6F8);
  static const _border = Color(0x14000000);

  List<Expense> _expenses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final data =
    await DatabaseService.instance.getExpensesForMonth(DateTime.now());

    setState(() {
      _expenses = data;
      _loading = false;
    });
  }

  Map<Category, double> get _byCategory {
    final map = <Category, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  double get _total => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get _avgPerDay {
    final daysSoFar = DateTime.now().day;
    if (daysSoFar == 0) return 0;
    return _total / daysSoFar;
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (changed == true) _load();
  }

  Future<void> _openEdit(Expense e) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: e)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Expense e) async {
    if (e.id == null) return;
    await DatabaseService.instance.deleteExpense(e.id!);
    _load();
  }

  String _money(num value) => 'Rs ${NumberFormat('#,##0').format(value)}';

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());
    final scale = (MediaQuery.of(context).size.width / 375).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  monthLabel,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: _green,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth > 600
                ? 600.0
                : constraints.maxWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: ListView(
                  padding: EdgeInsets.all(16 * scale),
                  children: [
                    _summaryCard(monthLabel, scale),
                    SizedBox(height: 16 * scale),
                    if (_expenses.isNotEmpty) ...[
                      _chartCard(scale),
                      SizedBox(height: 16 * scale),
                    ],
                    Row(
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        if (_expenses.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 2 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_expenses.length}',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w600,
                                color: _green,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),
                    if (_expenses.isEmpty)
                      _emptyState(scale)
                    else
                      ..._expenses.map((e) => _expenseTile(e, scale)),
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

  Widget _summaryCard(String monthLabel, double scale) {
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
            color: _green.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 90 * scale,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14 * scale,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  SizedBox(width: 6 * scale),
                  Flexible(
                    child: Text(
                      'Spent in $monthLabel',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _money(_total),
                  style: TextStyle(
                    fontSize: 30 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 14 * scale),
              Wrap(
                spacing: 10 * scale,
                runSpacing: 8 * scale,
                children: [
                  _statChip(
                    icon: Icons.receipt_long_rounded,
                    label: '${_expenses.length} transactions',
                    scale: scale,
                  ),
                  _statChip(
                    icon: Icons.trending_up_rounded,
                    label: '${_money(_avgPerDay)}/day',
                    scale: scale,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required double scale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13 * scale, color: Colors.white),
          SizedBox(width: 5 * scale),
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * scale,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(double scale) {
    final entries = _byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              height: 180 * scale,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40 * scale,
                  sections: entries.map((e) {
                    final percent =
                    _total == 0 ? 0 : (e.value / _total * 100);

                    return PieChartSectionData(
                      value: e.value,
                      color: e.key.color,
                      title: '${percent.round()}%',
                      radius: 50 * scale,
                      titleStyle: TextStyle(
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 16 * scale),
            ...entries.map((e) {
              final percent = _total == 0 ? 0 : (e.value / _total * 100);
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 5 * scale),
                child: Row(
                  children: [
                    Container(
                      width: 10 * scale,
                      height: 10 * scale,
                      decoration: BoxDecoration(
                        color: e.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: Text(
                        e.key.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13 * scale),
                      ),
                    ),
                    Text(
                      '${percent.round()}%',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Text(
                      _money(e.value),
                      style: TextStyle(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40 * scale, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36 * scale,
              color: _green,
            ),
          ),
          SizedBox(height: 14 * scale),
          Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Tap below to add your first one',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13 * scale,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16 * scale),
          ElevatedButton.icon(
            onPressed: _openAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 10 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(Icons.add, size: 18 * scale),
            label: Text('Add Expense', style: TextStyle(fontSize: 13 * scale)),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(Expense e, double scale) {
    return Dismissible(
      key: ValueKey(e.id ?? e.hashCode),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(e),
      background: Container(
        margin: EdgeInsets.symmetric(vertical: 5 * scale),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20 * scale),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: () => _openEdit(e),
          leading: CircleAvatar(
            radius: 20 * scale,
            backgroundColor: e.category.color.withOpacity(0.15),
            child: Icon(e.category.icon, color: e.category.color, size: 20 * scale),
          ),
          title: Text(
            e.note.isEmpty ? e.category.label : e.note,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14 * scale),
          ),
          subtitle: Text(
            e.category.label,
            style: TextStyle(fontSize: 12 * scale),
          ),
          trailing: Text(
            _money(e.amount),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13 * scale),
          ),
        ),
      ),
    );
  }
}