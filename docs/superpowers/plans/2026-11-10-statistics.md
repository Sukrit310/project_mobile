# Statistics Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development for calculation/charts, with root screen integration and independent final review.

**Goal:** Add monthly Statistics with expense categories and income/expense comparison.
**Architecture:** Pure calculator returns an immutable monthly summary; chart
widgets render it; StatisticsScreen receives the existing repository feed.
**Tech Stack:** Existing Flutter/Firebase and fl_chart. No Firestore schema/rule changes.
**Spec:** `docs/superpowers/specs/2026-11-10-statistics-design.md`

## Global Constraints

- Integer satang for totals; chart coordinates/ratios may be double.
- Existing categories and five-field schema remain compatible.
- No changes to user cloud data; no Budget/Analytics feature in this step.
- Work in place (no Git repository in the workspace).

## Review Focus

- Same month in different years and changing selected months must filter correctly.
- Zero/tiny values must not produce NaN, overflow or misleading chart labels.
- Every valid stored category must be represented, including legacy combinations.
- Incoming updates must recompute charts without resetting the selected month.
- Large text and long money values must remain readable in narrow layouts.

## Interfaces

`MonthlyStatistics({required DateTime month, required int incomeSatang,
required int expenseSatang, required int transactionCount,
required Map<TransactionCategory, int> expensesByCategory})` has final fields,
an immutable category map and derived `int get netSatang`.

`MonthlyStatistics calculateMonthlyStatistics(List<MoneyTransaction> transactions,
DateTime month)` lives in `utils/statistics_calculator.dart`.

`ExpenseChart({required Map<TransactionCategory,int> expensesByCategory})` and
`IncomeExpenseChart({required int incomeSatang, required int expenseSatang})`
are separate widgets using fl_chart. Category legend preserves exact amounts.

`StatisticsScreen({required List<MoneyTransaction> transactions, required DateTime
initialMonth, required VoidCallback onAddTransaction, required ValueChanged<int>
onDestinationSelected, String? notice})` owns selected-month UI state.

## Tasks

- [x] Calculator worker: monthly model, pure aggregation, focused boundary tests.
- [x] Chart worker: donut/legend and two-bar comparison with zero/large-text tests.
- [x] Root: failing navigation/stream integration tests, StatisticsScreen and index2 wiring.
- [x] Verify full VM suite, analysis, Web/Android builds and Thai-font visual render.
- [x] Independent review, Thai README update and refresh latest Chrome app.

## Decisions / progress

- Statistics is the next self-contained step; Budget follows after it.
- Comparison graph shows income vs expense for the selected month (two bars),
  rather than introducing an additional multi-month trend scope.
- Calculation: 7 focused tests; chart widgets: 9; integration/screen: 5.
- Root observed navigation test fail because Statistics was not yet implemented,
  then pass after integration. Corrected a test to use the form's existing custom
  Thai Back tooltip. All 89 VM tests pass on integrated code.
- Fixed analyzer's missing-braces info; analyzer now reports no issues.
- Web and Android debug APK builds pass. Thai-font rendered preview inspected at
  `build/statistics-preview.png`; aligned content to the top on tall displays.
- Independent read-only review (`statistics_review`) returned spec PASS and
  quality APPROVE with no important issues. README describes Widgets in Thai.
- Browser-only automated Firebase options test remains unverified in this
  environment as previously documented; no real user data was mutated.
- Latest Chrome debug app started successfully on port 52674, debugger attached,
  main method started and localhost HTTP returned 200. Interactive Flutter
  session: 81214. This is a launch/HTTP check, not a live browser visual assertion.
