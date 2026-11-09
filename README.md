# AI Personal Accounting Advisor — FYP MVP

A Flutter mobile app that tracks expenses, manages budgets, and gives
financial advice through a rule-based "AI" advisor. Fully offline.

## Features

- **Expense tracking** — add, edit, delete expenses across 8 categories
- **Dashboard** — monthly total, category pie chart, recent transactions
- **Budgets** — set monthly limits per category with progress bars and
  over-budget warnings
- **AI Advisor** — auto-generated spending insights plus a chat interface
  that answers natural-language questions about your finances
- **Local storage** — all data in an on-device SQLite database

## Tech stack

| Layer       | Choice                              |
|-------------|-------------------------------------|
| Framework   | Flutter (Dart, Material 3)          |
| Database    | SQLite via `sqflite`                |
| Charts      | `fl_chart`                          |
| AI engine   | Rule-based heuristics (`AdvisorService`) |

## Project structure

```
lib/
├── main.dart                  App entry point
├── models/
│   ├── category.dart          Spending categories (enum)
│   ├── expense.dart           Expense model + DB mapping
│   └── budget.dart            Budget model + DB mapping
├── services/
│   ├── database_service.dart  SQLite CRUD + demo seeding
│   ├── advisor_service.dart   AI advisor (interface + rule-based impl)
│   └── formatting.dart        Currency / date helpers
└── screens/
    ├── home_shell.dart        Bottom-nav container
    ├── dashboard_screen.dart  Overview + chart
    ├── add_expense_screen.dart Add / edit form
    ├── budgets_screen.dart    Budget management
    └── advisor_screen.dart    Insights + chat
```

## How to run

1. Install Flutter (3.0+): https://docs.flutter.dev/get-started/install
2. From the project folder:
   ```bash
   flutter pub get
   flutter run
   ```
   The app seeds sample data on first launch, so it is demo-ready.
   
The advisor is built behind an abstract `AdvisorService` interface with
two methods: `generateInsights()` and `answerQuestion()`. The MVP ships
`RuleBasedAdvisor`, which analyses spending with deterministic heuristics:
- Budget threshold checks (80% warning, 100% alert)
- Dominant-category detection (concentration risk)
- Linear month-end spending projection
- Intent matching for the chat (total / save / budget / category / forecast)

**Why rule-based for the MVP:** it is fully offline, needs no API key,
and never fails during a live demo.

**Future work:** because all UI depends on the `AdvisorService` interface,
a `ClaudeApiAdvisor` (or any LLM backend) can be added later by
implementing the same two methods — no UI changes required. This is a
good point to highlight in your FYP evaluation as an extensibility win.


- Problem statement: people lack low-effort personal finance guidance
- Requirements: tracking, budgeting, advice — all offline / private
- Architecture: model–service–screen layering, swappable advisor
- Implementation: SQLite schema, heuristics, Flutter UI
- Limitations & future work: cloud sync, real LLM advisor, multi-currency,
  recurring expenses, income tracking
