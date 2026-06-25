import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'budgets_screen.dart';
import 'add_expense_screen.dart';
import 'advisor_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _dashboardRefreshKey = 0;
  int _budgetsRefreshKey = 0;

  static const Color _green = Color(0xFF2E7D32);
  static const Color _muted = Color(0xFF6B7280);

  List<Widget> get _pages => [
    DashboardScreen(key: ValueKey(_dashboardRefreshKey)),
    BudgetsScreen(key: ValueKey(_budgetsRefreshKey)),
    const SizedBox(),
    const AdvisorScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0x14000000))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.grid_view_rounded, 'Home'),
                _navItem(1, Icons.account_balance_wallet_outlined, 'Budgets'),
                _addButton(),
                _navItem(3, Icons.tips_and_updates_outlined, 'Advisor'),
                _navItem(4, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? _green : _muted),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? _green : _muted,
                fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const AddExpenseScreen(),
          ),
        );

        if (changed == true) {
          setState(() {
            _dashboardRefreshKey++;
            _budgetsRefreshKey++;
            _currentIndex = 0;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}