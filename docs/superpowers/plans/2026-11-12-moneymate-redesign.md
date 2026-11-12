# MoneyMate 2.0 Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task. Steps use checkboxes for tracking.

**Goal:** Implement the supplied MoneyMate redesign in the existing Flutter application, starting with Foundation and Dashboard, then History, Statistics and Form.

**Architecture:** Keep transaction and budget repositories and Firestore schema intact. DashboardScreen coordinates monthly budget and transaction streams; Home and reusable cards receive state and callbacks. New financial insights and trends use pure calculations over integer satang.

**Tech Stack:** Flutter, Dart, Material 3, existing fl_chart, Firebase and bundled NotoSansThai.

**Spec:** C:/Users/User/Downloads/MoneyMate_UIUX_Redesign_Codex.md

## Global Constraints

- Preserve the existing uncommitted removal of the greeting in home.dart.
- Keep CRUD, IDs, timestamps, validation, sync notices, demo isolation and privacy behavior.
- Use the specified navy, mint and semantic color tokens; no additional dependencies.
- Support 320 px, 2x text, keyboard, reduced motion and accessible controls.
- No push, deploy, Firebase mutations or schema changes. Category budgets are optional later work.

## Review Focus

- Switching budget repository/month must remove previous data while the new stream waits or errors.
- Missing/zero budget must show a real setup action instead of invented progress.
- Income and expense shortcuts must open the correct type and save through the existing form.
- Insight totals and latest records must track edits/deletes without mixing months or years.
- Enlarged text and all-tab add actions must remain usable without overflow or hidden amount leakage.

### Task 1: Baseline and shared presentation

Files: lib/app/app_theme.dart, lib/widgets/balance_card.dart, lib/widgets/transaction_tile.dart, lib/widgets/moneymate_navigation_bar.dart and focused visual tests.

- [x] Inspect current code, docs, rules, dirty diff and run baseline analyze/tests.
- [x] Polish existing components using the supplied tokens and preserve public APIs and privacy labels.
- [x] Verify responsive layouts and existing privacy/motion tests.

### Task 2: Dashboard data and interactions

Files: lib/screens/dashboard_screen.dart, lib/screens/home.dart, lib/models/money_transaction.dart, lib/widgets/budget_snapshot_card.dart, lib/widgets/quick_actions.dart, lib/widgets/finance_insight_card.dart, lib/utils/finance_insights.dart; test/dashboard_redesign_test.dart and test/finance_insights_test.dart.

Interfaces: Home accepts an AsyncSnapshot<BudgetFeed>, budget retry callback and typed add callback. DashboardScreen caches watchBudget(month) and replaces it on month/repository changes. TransactionFormScreen accepts optional TransactionType initialType. Finance insights return nullable highest category/monthly expense result from real records. Latest records increase from two to five.

- [x] Add failing tests for real budget stream state, CRUD changes, month/repository replacement, quick actions and exact insights.
- [x] Implement monthly budget coordination with a keyed StreamBuilder, real setup/retry actions and sync metadata.
- [x] Implement Home section order: header, balance, budget, shortcuts, latest five, compact top expense insight.
- [x] Verify focused tests and responsive/semantics behavior.

### Task 3: History, Statistics and Form

Files: lib/screens/history_screen.dart, lib/screens/statistics_screen.dart, lib/screens/transaction_form_screen.dart, lib/widgets/trend_chart.dart, related pure calculations/tests.

- [x] Preserve current search/filter/grouping/edit/delete behavior and stable state on stream updates.
- [x] Add daily expense trend with text totals, honest empty states and rule-based insights using real monthly records.
- [x] Add initialType to new transaction forms; retain existing transaction type when editing, precision and save/error semantics.
- [x] Improve form hierarchy, category icons and responsive field layout.
- [x] Run relevant history/statistics/form tests.

### Task 4: Integration, docs and verification

Files: README.md, DESIGN.md and integration tests where necessary.

- [x] Run flutter analyze, flutter test and flutter build apk --debug (or web if supported).
- [x] Review diff for regressions, reconcile tests intentionally affected by latest-five behavior.
- [x] Document implemented behavior and report actual check results and deferred category budgets.
