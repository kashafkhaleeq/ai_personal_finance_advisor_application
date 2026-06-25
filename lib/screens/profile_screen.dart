import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _red = Color(0xFFE53935);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF7F9F7);
  static const _border = Color(0x14000000);

  String _userName = 'Your Name';
  String _memberSince = '';
  double _totalSpent = 0;
  int _totalTransactions = 0;
  int _totalBudgets = 0;
  bool _loading = true;

  // New state for settings
  String _selectedCurrency = 'PKR';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('user_name') ?? '';
    final since = prefs.getString('member_since') ?? '';

    if (since.isEmpty) {
      final now = DateTime.now();
      final formatted = '${_monthName(now.month)} ${now.year}';
      await prefs.setString('member_since', formatted);
    }

    // Load saved settings
    final currency = prefs.getString('currency') ?? 'PKR';
    final notifications = prefs.getBool('notifications_enabled') ?? true;

    final now = DateTime.now();
    final expenses = await DatabaseService.instance.getExpensesForMonth(now);
    final budgets = await DatabaseService.instance.getBudgets();

    final spent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    setState(() {
      _userName = name.isEmpty ? 'Your Name' : name;
      _memberSince = prefs.getString('member_since') ?? '';
      _totalSpent = spent;
      _totalTransactions = expenses.length;
      _totalBudgets = budgets.length;
      _selectedCurrency = currency;
      _notificationsEnabled = notifications;
      _loading = false;
    });
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  // ── EDIT NAME DIALOG ──────────────────────────────────────
  void _editName() {
    final controller = TextEditingController(
        text: _userName == 'Your Name' ? '' : _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Your Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', name);
                setState(() => _userName = name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── CURRENCY DIALOG ───────────────────────────────────────
  void _showCurrencyDialog() {
    final currencies = [
      {'code': 'PKR', 'label': 'Pakistani Rupee', 'symbol': 'Rs'},
      {'code': 'USD', 'label': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'label': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'label': 'British Pound', 'symbol': '£'},
    ];

    String tempSelected = _selectedCurrency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Currency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.map((c) {
              final isSelected = tempSelected == c['code'];
              return GestureDetector(
                onTap: () => setDialogState(() => tempSelected = c['code']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _greenLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? _green : _border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(c['symbol']!,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? _green : _muted)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['code']!,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? _green
                                        : const Color(0xFF1A1A1A))),
                            Text(c['label']!,
                                style: const TextStyle(
                                    fontSize: 11, color: _muted)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: _green, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _muted))),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('currency', tempSelected);
                setState(() => _selectedCurrency = tempSelected);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── NOTIFICATIONS DIALOG ──────────────────────────────────
  void _showNotificationsDialog() {
    bool tempEnabled = _notificationsEnabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: tempEnabled ? _greenLight : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.notifications_outlined,
                          size: 17,
                          color: tempEnabled ? _green : _muted),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budget alerts',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1A1A1A))),
                          Text('Notify when nearing limit',
                              style:
                              TextStyle(fontSize: 11, color: _muted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: tempEnabled,
                      onChanged: (val) =>
                          setDialogState(() => tempEnabled = val),
                      activeColor: _green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tempEnabled ? _greenLight : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      tempEnabled
                          ? Icons.check_circle_outline
                          : Icons.notifications_off_outlined,
                      size: 15,
                      color: tempEnabled ? _green : _muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tempEnabled
                          ? 'You\'ll be alerted at 80% & 100% of budget'
                          : 'Budget alerts are turned off',
                      style: TextStyle(
                          fontSize: 11,
                          color: tempEnabled ? _green : _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                const Text('Cancel', style: TextStyle(color: _muted))),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notifications_enabled', tempEnabled);
                setState(() => _notificationsEnabled = tempEnabled);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── EXPORT DATA DIALOG ────────────────────────────────────
  void _exportData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: _green)),
    );

    final now = DateTime.now();
    final expenses = await DatabaseService.instance.getExpensesForMonth(now);

    if (!mounted) return;
    Navigator.pop(context); // close loading

    // Build CSV string
    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Amount,Note');
    for (final e in expenses) {
      final date =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      final category = e.category.name;
      final amount = e.amount.toStringAsFixed(2);
      final note = (e.note ?? '').replaceAll(',', ' ');
      buffer.writeln('$date,$category,$amount,$note');
    }

    final csvData = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('Export Data',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${expenses.length} records',
                style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This month\'s expenses (CSV preview):',
                style: TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  expenses.isEmpty
                      ? 'No expenses this month.'
                      : csvData,
                  style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
                'Tip: Copy and paste into Excel or Google Sheets.',
                style: TextStyle(fontSize: 11, color: _muted)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: _muted))),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV copied to clipboard!'),
                  backgroundColor: _green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 15),
            label: const Text('Copy CSV'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  // ── RESET DATA DIALOG ─────────────────────────────────────
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset all data?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
            'This will delete all your expenses and budgets. This cannot be undone.',
            style: TextStyle(fontSize: 13, color: _muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _muted))),
          ElevatedButton(
            onPressed: () async {
              final expenses =
              await DatabaseService.instance.getExpenses();
              for (final e in expenses) {
                await DatabaseService.instance.deleteExpense(e.id!);
              }
              final budgets =
              await DatabaseService.instance.getBudgets();
              for (final b in budgets) {
                await DatabaseService.instance.deleteBudget(b.category);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("This month's summary",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _statBox(
                              'Rs ${_totalSpent.toStringAsFixed(0)}',
                              'Total spent',
                              _red)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _statBox(
                              '72', 'Health score', _green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _statBox('$_totalBudgets',
                              'Budgets set', const Color(0xFF1A1A1A))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _statBox('$_totalTransactions',
                              'Transactions', const Color(0xFF1A1A1A))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSettingsCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP GREEN HEADER ──────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _editName,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(24)),
              child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 20))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _editName,
                      child: const Icon(Icons.edit,
                          color: Colors.white70, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                    _memberSince.isEmpty
                        ? 'Welcome!'
                        : 'Member since $_memberSince',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STAT BOX ──────────────────────────────────────────────
  Widget _statBox(String value, String label, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
    );
  }

  // ── SETTINGS CARD ─────────────────────────────────────────
  Widget _buildSettingsCard() {
    // Currency symbol for subtitle
    final currencySubtitle = {
      'PKR': 'Pakistani Rupee (Rs)',
      'USD': 'US Dollar (\$)',
      'EUR': 'Euro (€)',
      'GBP': 'British Pound (£)',
    }[_selectedCurrency] ?? 'Pakistani Rupee (Rs)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SETTINGS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          _settingsItem(
              iconBg: _greenLight,
              icon: Icons.person_outline,
              iconColor: _green,
              title: 'Edit Name',
              subtitle: _userName,
              onTap: _editName),
          _settingsItem(
              iconBg: _greenLight,
              icon: Icons.currency_rupee,
              iconColor: _green,
              title: 'Currency',
              subtitle: currencySubtitle,
              onTap: _showCurrencyDialog),       // ← now responsive
          _settingsItem(
              iconBg: _greenLight,
              icon: Icons.notifications_outlined,
              iconColor: _green,
              title: 'Notifications',
              subtitle: _notificationsEnabled
                  ? 'Budget alerts enabled'
                  : 'Budget alerts disabled',
              onTap: _showNotificationsDialog),  // ← now responsive
          _settingsItem(
              iconBg: _greenLight,
              icon: Icons.download_outlined,
              iconColor: _green,
              title: 'Export data',
              subtitle: 'Download as CSV',
              onTap: _exportData),               // ← now responsive
          _settingsItem(
              iconBg: const Color(0xFFFFEBEE),
              icon: Icons.delete_outline,
              iconColor: _red,
              title: 'Reset all data',
              subtitle: 'Clear expenses & budgets',
              titleColor: _red,
              onTap: _confirmReset,
              isLast: true),
        ],
      ),
    );
  }

  Widget _settingsItem({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color titleColor = const Color(0xFF1A1A1A),
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: titleColor)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }
}