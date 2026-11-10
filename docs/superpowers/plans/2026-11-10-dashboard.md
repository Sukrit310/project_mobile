# MoneyMate Dashboard Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans for inline implementation, with an independent final review.

**Goal:** Implement the supplied Thai Dashboard using consistent demo transactions.
**Architecture:** Immutable Dart records and derived summary feed a stateless Home;
small private widgets build the screen with standard Material controls.
**Tech Stack:** Existing Flutter/Dart SDK; no new dependencies.
**Spec:** `docs/superpowers/specs/2026-11-10-dashboard-design.md`

## Global Constraints

- Keep `MyApp` and `Home` entry points; use Thai copy and Gregorian 2026 demo dates.
- Store amounts in integer satang; derive totals from the same records as the list.
- Do not implement the form or Firestore in this step.
- No Git repository exists; execute in place without commits.

## Review Focus

- Month boundaries and prior-year records must not pollute monthly totals.
- Empty records must produce zero totals and a helpful empty state.
- A negative balance must keep its minus sign and satang precision.
- Narrow screens and large text must remain scrollable without overflow.
- Future feature taps must explain their status without implying they exist.

## Task 1: Dashboard and data

Files: `lib/main.dart`, `lib/screens/home.dart`,
`lib/models/money_transaction.dart`, `lib/data/sample_transactions.dart`,
`lib/utils/money_format.dart`, `test/widget_test.dart`, `test/dashboard_data_test.dart`.

Interfaces: `MoneyTransaction` (id/title/amountSatang/type/category/date),
`DashboardSummary.fromTransactions(List<MoneyTransaction>, {required DateTime month})`,
`formatBaht(int amountSatang, {bool decimalPlaces = false, bool showPlus = false})`,
`Home({List<MoneyTransaction>? transactions, DateTime? referenceMonth})`.

- [x] Replace counter test with Dashboard totals, recent ordering, action and layout checks; run and observe failures before implementation.
- [x] Implement model, derived summary and formatting with focused empty/month/precision tests.
- [x] Implement sample list and Home, and set the MoneyMate theme/title.
- [x] Run `flutter test --no-pub` and `flutter analyze --no-pub`; expect success.

## Task 2: Explain and review

Files: `README.md` and this plan.

- [x] Explain widgets, demo data, commands and next form/Firestore steps in Thai.
- [x] Independent read-only review of changed files; address material defects.
- [x] Verify the complete suite and record final results below.

## Execution notes

Request and reference image provide the screen specification; proceed directly
within the authorized scope. The third sample record predates the salary so the
two visible latest records remain food and salary, as in the reference.

Task 1 complete: all 10 Flutter tests passed; static analysis reported no issues.
Task 2 complete: Thai README added and independent review found no concrete issues.
Rendered the 401 x 577 layout with Thai fonts for visual inspection. Large text
at 401 x 577 and 320 x 568 was also verified by the widget tests.
Flutter commands require access to the installed SDK cache outside the workspace;
the approved test/analyze commands ran successfully with that access.
