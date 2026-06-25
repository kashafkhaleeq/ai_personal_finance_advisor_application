import 'package:flutter/material.dart';

import '../services/advisor_service.dart';
import '../services/database_service.dart';

/// AI Advisor tab: auto-generated insights at the top, chat box at the bottom.
///
/// The advisor is injected as an [AdvisorService] so the rule-based engine
/// can later be swapped for an LLM-backed one without changing this screen.
class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  // Swap this line to use a different advisor implementation.
  final AdvisorService _advisor = RuleBasedAdvisor();

  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Insight> _insights = [];
  final List<_ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshInsights();
    _messages.add(_ChatMessage(
      'Hi! I\'m your finance advisor. Ask me about your spending, '
          'budgets, or how to save money.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshInsights() async {
    setState(() => _loading = true);
    final db = DatabaseService.instance;
    final expenses = await db.getExpensesForMonth(DateTime.now());
    final budgets = await db.getBudgets();
    setState(() {
      _insights = _advisor.generateInsights(
        monthExpenses: expenses,
        budgets: budgets,
      );
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();

    setState(() => _messages.add(_ChatMessage(text, isUser: true)));

    final db = DatabaseService.instance;
    final expenses = await db.getExpensesForMonth(DateTime.now());
    final budgets = await db.getBudgets();
    final reply = _advisor.answerQuestion(
      question: text,
      monthExpenses: expenses,
      budgets: budgets,
    );

    setState(() => _messages.add(_ChatMessage(reply, isUser: false)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInsights,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                Text('Insights',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ..._insights.map(_insightCard),
                const Divider(height: 32),
                Text('Ask the Advisor',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._messages.map(_chatBubble),
              ],
            ),
          ),
          _suggestedChips(),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _insightCard(Insight i) {
    final config = _severityConfig(i.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(config.icon, color: config.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(i.detail,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(_ChatMessage m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: m.isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _suggestedChips() {
    const prompts = [
      'How much did I spend?',
      'How can I save money?',
      'Show my budget status',
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: prompts
            .map((p) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(p),
            onPressed: () {
              _chatCtrl.text = p;
              _send();
            },
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask about your finances...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _send,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  _SeverityConfig _severityConfig(InsightSeverity s) {
    switch (s) {
      case InsightSeverity.positive:
        return const _SeverityConfig(Icons.check_circle, Colors.green);
      case InsightSeverity.info:
        return const _SeverityConfig(Icons.info, Colors.blue);
      case InsightSeverity.warning:
        return const _SeverityConfig(Icons.warning_amber, Colors.orange);
      case InsightSeverity.alert:
        return const _SeverityConfig(Icons.error, Colors.red);
    }
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, {required this.isUser});
}

class _SeverityConfig {
  final IconData icon;
  final Color color;
  const _SeverityConfig(this.icon, this.color);
}
