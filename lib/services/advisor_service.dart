import '../models/budget.dart';
import '../models/category.dart';
import '../models/expense.dart';

/// One piece of advice the advisor produces.
class Insight {
  final String title;
  final String detail;
  final InsightSeverity severity;

  Insight(this.title, this.detail, this.severity);
}

enum InsightSeverity { positive, info, warning, alert }

/// Abstraction for the "AI" layer.
///
/// The MVP ships [RuleBasedAdvisor]. Because everything depends on this
/// interface (not the concrete class), a future `ClaudeApiAdvisor` can be
/// dropped in without touching any UI code — useful to mention as
/// "future work" in your FYP report.
abstract class AdvisorService {
  /// Generate dashboard insights from the user's financial data.
  List<Insight> generateInsights({
    required List<Expense> monthExpenses,
    required List<Budget> budgets,
  });

  /// Answer a free-text question in the advisor chat.
  String answerQuestion({
    required String question,
    required List<Expense> monthExpenses,
    required List<Budget> budgets,
  });
}

/// Rule-based "AI" advisor.
///
/// This is deliberately deterministic: it analyses spending with a set of
/// heuristics rather than calling an LLM. That keeps the MVP fully offline
/// and demo-safe (no network, no API key, no failures during your defense).
class RuleBasedAdvisor implements AdvisorService {
  // -------------------------------------------------------------------
  // Insight generation
  // -------------------------------------------------------------------

  @override
  List<Insight> generateInsights({
    required List<Expense> monthExpenses,
    required List<Budget> budgets,
  }) {
    final insights = <Insight>[];

    if (monthExpenses.isEmpty) {
      insights.add(Insight(
        'No spending yet this month',
        'Add a few expenses and I will start analysing your habits.',
        InsightSeverity.info,
      ));
      return insights;
    }

    final total = _total(monthExpenses);
    final byCategory = _totalsByCategory(monthExpenses);

    // 1. Budget checks ------------------------------------------------
    for (final b in budgets) {
      final spent = byCategory[b.category] ?? 0;
      final ratio = b.monthlyLimit == 0 ? 0 : spent / b.monthlyLimit;

      if (ratio >= 1.0) {
        insights.add(Insight(
          '${b.category.label} budget exceeded',
          'You have spent ${_money(spent)} against a ${_money(b.monthlyLimit)} '
              'limit. Consider pausing non-essential ${b.category.label.toLowerCase()} spending.',
          InsightSeverity.alert,
        ));
      } else if (ratio >= 0.8) {
        insights.add(Insight(
          '${b.category.label} budget almost used',
          'You are at ${(ratio * 100).round()}% of your ${b.category.label} '
              'budget with ${_money(b.monthlyLimit - spent)} left.',
          InsightSeverity.warning,
        ));
      }
    }

    // 2. Dominant category -------------------------------------------
    final top = _topCategory(byCategory);
    if (top != null) {
      final share = byCategory[top]! / total;
      if (share >= 0.4) {
        insights.add(Insight(
          '${top.label} dominates your spending',
          '${(share * 100).round()}% of this month\'s spending went to '
              '${top.label}. Spreading spending out can make budgeting easier.',
          InsightSeverity.warning,
        ));
      } else {
        insights.add(Insight(
          'Biggest category: ${top.label}',
          '${top.label} is your largest category at ${_money(byCategory[top]!)} '
              '(${(share * 100).round()}% of spending).',
          InsightSeverity.info,
        ));
      }
    }

    // 3. Daily burn rate / projection --------------------------------
    final projection = _projectedMonthEnd(monthExpenses);
    insights.add(Insight(
      'Projected month-end spending',
      'At your current pace you are on track to spend about '
          '${_money(projection)} this month (so far: ${_money(total)}).',
      InsightSeverity.info,
    ));

    // 4. Categories with no budget set -------------------------------
    final budgeted = budgets.map((b) => b.category).toSet();
    final unbudgeted = byCategory.keys.where((c) => !budgeted.contains(c));
    if (unbudgeted.isNotEmpty) {
      final names = unbudgeted.map((c) => c.label).join(', ');
      insights.add(Insight(
        'Untracked categories',
        'You are spending in $names with no budget set. Adding budgets '
            'there will improve these insights.',
        InsightSeverity.info,
      ));
    }

    // 5. Positive reinforcement --------------------------------------
    final healthy = budgets.where((b) {
      final spent = byCategory[b.category] ?? 0;
      return b.monthlyLimit > 0 && spent / b.monthlyLimit < 0.5;
    }).toList();
    if (healthy.isNotEmpty) {
      insights.add(Insight(
        'Well within budget',
        'Nice work — ${healthy.map((b) => b.category.label).join(', ')} '
            'remain comfortably under budget this month.',
        InsightSeverity.positive,
      ));
    }

    return insights;
  }

  // -------------------------------------------------------------------
  // Chat-style Q&A
  // -------------------------------------------------------------------

  @override
  String answerQuestion({
    required String question,
    required List<Expense> monthExpenses,
    required List<Budget> budgets,
  }) {
    final q = question.toLowerCase();
    final total = _total(monthExpenses);
    final byCategory = _totalsByCategory(monthExpenses);

    if (monthExpenses.isEmpty) {
      return 'You have not recorded any expenses this month yet. '
          'Add some and I can analyse your spending.';
    }

    // Intent: total spending
    if (_matches(q, ['total', 'how much', 'spent', 'spending'])) {
      final top = _topCategory(byCategory);
      return 'You have spent ${_money(total)} this month across '
          '${byCategory.length} categories. '
          '${top != null ? 'Your biggest category is ${top.label} '
              'at ${_money(byCategory[top]!)}.' : ''}';
    }

    // Intent: saving advice
    if (_matches(q, ['save', 'saving', 'cut', 'reduce', 'advice', 'tip'])) {
      final top = _topCategory(byCategory);
      if (top == null) return 'Keep tracking and I will suggest savings soon.';
      final budget = budgets.where((b) => b.category == top).firstOrNull;
      final suggestion = budget == null
          ? 'Set a monthly budget for ${top.label} to keep it in check.'
          : 'Try trimming ${top.label} by 15% — that would save about '
              '${_money(byCategory[top]! * 0.15)} a month.';
      return 'Your largest spending area is ${top.label} '
          '(${_money(byCategory[top]!)}). $suggestion';
    }

    // Intent: budget status
    if (_matches(q, ['budget', 'limit', 'over', 'on track'])) {
      if (budgets.isEmpty) {
        return 'You have not set any budgets yet. Add budgets from the '
            'Budgets tab and I can track them for you.';
      }
      final lines = budgets.map((b) {
        final spent = byCategory[b.category] ?? 0;
        final pct = b.monthlyLimit == 0
            ? 0
            : (spent / b.monthlyLimit * 100).round();
        return '• ${b.category.label}: ${_money(spent)} of '
            '${_money(b.monthlyLimit)} ($pct%)';
      }).join('\n');
      return 'Here is your budget status:\n$lines';
    }

    // Intent: ask about a specific category
    for (final c in Category.values) {
      if (q.contains(c.label.toLowerCase()) ||
          q.contains(c.name.toLowerCase())) {
        final spent = byCategory[c] ?? 0;
        return 'You have spent ${_money(spent)} on ${c.label} this month '
            '(${total == 0 ? 0 : (spent / total * 100).round()}% of total '
            'spending).';
      }
    }

    // Intent: projection
    if (_matches(q, ['projection', 'forecast', 'end of month', 'will i'])) {
      return 'At your current pace, you are projected to spend about '
          '${_money(_projectedMonthEnd(monthExpenses))} by month-end.';
    }

    // Fallback
    return 'I can help with your total spending, budget status, savings '
        'tips, projections, or a specific category. Try asking '
        '"How much did I spend on food?" or "How can I save money?"';
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  bool _matches(String q, List<String> keywords) =>
      keywords.any(q.contains);

  double _total(List<Expense> es) =>
      es.fold(0.0, (sum, e) => sum + e.amount);

  Map<Category, double> _totalsByCategory(List<Expense> es) {
    final map = <Category, double>{};
    for (final e in es) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Category? _topCategory(Map<Category, double> byCategory) {
    if (byCategory.isEmpty) return null;
    return byCategory.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Linear projection: (spent so far / days elapsed) * days in month.
  double _projectedMonthEnd(List<Expense> es) {
    final now = DateTime.now();
    final daysElapsed = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final spent = _total(es);
    if (daysElapsed == 0) return spent;
    return (spent / daysElapsed) * daysInMonth;
  }

  String _money(double v) => 'Rs ${v.toStringAsFixed(0)}';
}

/// Small convenience extension used above.
extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
