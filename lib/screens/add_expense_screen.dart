import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;

  const AddExpenseScreen({
    super.key,
    this.existing,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF5F7F5);
  static const _border = Color(0x14000000);

  int _selectedCategory = 0;
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];
  bool _showError = false;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final List<Category> _categories = Category.values;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _amountController.text = e.amount.toString();
      _noteController.text = e.note;
      _selectedCategory = _categories.indexOf(e.category);
      _selectedDate = e.date.toIso8601String().split('T')[0];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {

    debugPrint('SUBMIT PRESSED - amount text: ${_amountController.text}');
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      setState(() => _showError = true);
      return;
    }

    final expense = Expense(
      id: widget.existing?.id,
      amount: amount,
      category: _categories[_selectedCategory],
      note: _noteController.text,
      date: DateTime.parse(_selectedDate),
    );

    await DatabaseService.instance.insertExpense(expense);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(isEditing),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    label: 'Category',
                    icon: Icons.category_rounded,
                    child: _buildCategoryGrid(),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    label: 'Date',
                    icon: Icons.calendar_today_rounded,
                    child: _buildDateField(),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    label: 'Note',
                    icon: Icons.notes_rounded,
                    child: _buildNoteField(),
                  ),
                  const SizedBox(height: 28),
                  _buildSaveButton(isEditing),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, _greenDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 48, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Text(
                isEditing ? 'Edit Expense' : 'Add Expense',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Rs ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onChanged: (_) {
                      if (_showError) setState(() => _showError = false);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showError)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Text(
                'Enter a valid amount',
                style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, i) {
        final c = _categories[i];
        final selected = i == _selectedCategory;

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? _greenLight : _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _green : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(c.icon, color: c.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? _greenDark : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (selected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: _green),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            _selectedDate = picked.toIso8601String().split('T')[0];
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: _green),
            const SizedBox(width: 10),
            Text(
              _selectedDate,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Add a note (optional)',
        hintStyle: const TextStyle(color: _muted, fontSize: 13),
        filled: true,
        fillColor: _bg,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _submit,
        icon: Icon(isEditing ? Icons.check_rounded : Icons.add_rounded),
        label: Text(
          isEditing ? 'Update Expense' : 'Save Expense',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}