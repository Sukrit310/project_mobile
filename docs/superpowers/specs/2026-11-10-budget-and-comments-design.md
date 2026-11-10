# MoneyMate monthly budget and Thai code comments

User authorized the next step (Budget) and Thai explanations in every code file.
Follow the existing shared plan: one total monthly limit, editable, with spent,
remaining and progress. Category limits would add scope; transaction spending is
already available from the shared feed and must not be stored a second time.

## Design

- BudgetModel stores normalized month and integer limitSatang, 0..99999999999.
  Zero/missing budget means unset. Form requires a positive amount, same decimal
  grammar and maximum as transaction amounts. No migrations to transaction data.
- BudgetRepository is independent from TransactionRepository. BudgetFeed carries
  nullable budget plus cache/pending metadata. Firestore and demo implementations
  watch one month and save to the same deterministic ID, making retries idempotent.
- Firestore path users/{uid}/budgets/YYYY-MM, fields monthKey, limitSatang,
  updatedAt (server timestamp). Owner-only read/create/update, exact field checks,
  valid month key equal to ID, integer amount bound, timestamp. No delete UI.
- Production bootstrap supplies Firestore repositories using the same Firebase app
  and UID. Explicit demo supplies in-memory repositories, demo budget 500000 satang
  for November 2026; no demo seeding into Firestore. Injected test apps may omit
  budgets, in which case Budget shows a clear unavailable state, never fake data.
- BudgetScreen receives transactions, initialMonth, budget repository, notices and
  callbacks. State owns selected month and subscription. Switching month replaces
  the stream; never display the previous month's snapshot as the new month's budget.
- Monthly expenses come from calculateMonthlyStatistics, including legacy category
  combinations. Changes to transactions recalculate spending without losing month.
- User can create/edit a month limit in a validated dialog. Prefill exact baht,
  no grouping. Disable duplicate save/back/edits while saving, preserve input on
  failure/timeout. A late save result cannot close a different route or update an
  unmounted state. Snapshot metadata never claims pending writes are confirmed.
- Display monthly limit, spent, signed remaining, progress and percentage. Zero
  guard, clamped progress 0..1, true over-budget percentage, warning at >=80%,
  separate exact-limit/exceeded states. UI is Thai, scrollable at320px/2x text.
- Reuse bottom nav index3, add transaction action and demo/cache/pending notices.
  All four tabs work; home wallet shortcut can open Budget.

## Thai comments

Add file-purpose comments and explanations of classes/functions/key UI and data
flows to all maintained Dart source/test files, as well as handwritten platform
entrypoints/build configuration/web index. Explain why around money precision,
streams, validation and error states. Keep behavior unchanged in comment-only work.
Generated Flutter plugin files, build/cache/dependency outputs, binary assets and
JSON are not edited; document their purpose in a Thai code guide because generators
overwrite source comments and JSON syntax does not permit comments.

## Verification and limits

TDD for new behavior, calculator/progress/codec/repository tests with fake Firestore,
widget states/failures/responsiveness and integration live expense updates. Full VM
suite, analyzer, Web and Android builds, Thai-font preview and independent review.
No mutations to real user records or cloud rules from this session. Updated local
rules must be merged/published by project owner before Budget cloud access works;
the Firebase CLI/admin browser connection is unavailable in this environment.
