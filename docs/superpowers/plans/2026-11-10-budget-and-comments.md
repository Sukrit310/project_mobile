# Budget and Thai comments Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development for independent model/data, progress/calculation and comment work, with root screen/integration and final review.

**Goal:** Complete monthly Budget and explain maintained code in Thai.
**Architecture:** Independent BudgetRepository and pure BudgetSummary; root feeds
existing transactions to BudgetScreen. Comments do not change existing behavior.
**Tech Stack:** Existing Flutter/Firebase/fl_chart, no new dependencies.
**Spec:** `docs/superpowers/specs/2026-11-10-budget-and-comments-design.md`.

## Global Constraints

- Integer satang; one total limit per year/month; no transaction schema changes.
- Same deterministic monthly doc on retries; owner-only rules in local file.
- Explicit demo only; no writes to real user records/cloud rules in this session.
- Keep Thai UI, shared theme/navigation and narrow/large-text behavior.
- No Git repository, so work in place with exclusive file ownership.

## Interfaces / ownership

Data worker owns NEW model/services and data tests only:
- BudgetModel({required DateTime month, required int limitSatang}) with normalized
  final month, final limitSatang and String get monthKey; valid years1..9999.
- BudgetFeed({BudgetModel? budget, bool isFromCache=false,
  bool hasPendingWrites=false}); BudgetRepository.watchBudget(DateTime month)
  returns Stream<BudgetFeed>, saveBudget(BudgetModel) returns Future<void>.
- FirestoreBudgetRepository({required FirebaseFirestore firestore, required String
  userId}); DemoBudgetRepository({List<BudgetModel> initialBudgets=const []}),
  Future<void> dispose(). BudgetCodec handles data validation/server timestamps.

Progress worker owns NEW model/utility/widget and tests only:
- BudgetSummary({required int limitSatang, required int expenseSatang}), getters
  hasBudget, remainingSatang, usedPercentage, progressValue, isOverBudget,
  isAtLimit, isNearLimit. Negative inputs rejected; int comparison for status.
- BudgetProgress({required int limitSatang,required int expenseSatang}) uses model
  and Thai state/progress with accessible exact information and bounded animation.

Comment worker owns existing lib except app/app.dart, app/firebase_bootstrap.dart,
screens/dashboard_screen.dart and screens/home.dart; owns all existing test files.
Add Thai comments only, no behavior changes or new budget files/tests. Root owns
those four lib files, new BudgetScreen/form integration/rules/docs/platform notes.

## Tasks

- [x] Data: red tests, model, codec, Firestore/demo repositories, focused green.
- [x] Progress: red tests, summary and progress states, focused green.
- [x] Comments: Thai file/class/key flow notes in existing Dart/test files.
- [x] Root: red Budget navigation/integration tests; screen/editor/root wiring.
- [x] Root: local budget rules, platform code comments and Thai code guide/README.
- [x] Full VM/analyze/builds, Thai visual QA, independent review, latest preview.

## Review Focus

- Fast month switches must not show stale budget or save to wrong month.
- Snapshot pending/cache and save timeout must never claim confirmed cloud success.
- Empty/zero/1satang/exactlimit/overlimit including large expense sums must be safe.
- Month filtering includes year; no previous budget inheritance or cloud demo seed.
- Comment changes must not alter code or annotate generated output falsely.

## Progress

- Existing shared plan read: budgets/YYYY-MM with monthKey/limitSatang/updatedAt;
  total monthly budget is the next authorized feature. Chosen separate repository
  avoids changing the existing transaction interface and fakes.
- Official Firebase docs checked for deterministic set and fields/type validation:
  https://firebase.google.com/docs/firestore/manage-data/add-data and
  https://firebase.google.com/docs/firestore/security/rules-fields.
- Data worker:19 focused tests; progress worker:15; root screen/integration:10.
- Existing Dart comment worker:45 files (28lib/17tests), verified original code
  after excluding comments/whitespace. Together with root/new files, all62
  maintained Dart files have Thai purpose headers. Native follow-up:51files,
  73commentblocks, byte-preserving removal check,13parsed XML documents.
- Fixed unset progress semantics to omit misleading negative remaining when
  no budget exists; regression red/green recorded by progress worker.
- Review found late save could pop a newer covering route. Root reproduced with
  a failing assertion, captured the dialog route and removes only that route;
  regression passes and scoped re-review confirms resolved, no remaining issues.
- Final full VM suite:133pass; analyzer:noissues; Web and Android debug APK pass.
  Thai-font budget and editor PNG previews inspected. No real user data changed;
  no remote rules deployment. Firebase CLI remains absent on command discovery.
- Latest Chrome debug app started on http://localhost:52674, attached debugger
  and entered main; HTTP200 confirmed. Interactive session42956 remains running.
  This verifies launch/HTTP, not live cloud Budget writes or browser visual QA.
