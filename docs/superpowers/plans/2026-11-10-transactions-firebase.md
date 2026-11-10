# Transactions and Firebase Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development for independent screen work and superpowers:executing-plans for root integration.

**Goal:** Add a validated transaction form and owner-scoped Firestore persistence.
**Architecture:** App bootstrap selects authenticated Firestore or explicit demo;
a repository supplies the transaction stream and saves; Home stays presentational.
**Tech Stack:** Flutter, firebase_core, firebase_auth, cloud_firestore.
**Spec:** `docs/superpowers/specs/2026-11-10-transactions-firebase-design.md`

## Global Constraints

- Project ID is `projectmoneymate`; never fabricate registered app options.
- Integer satang, Thai UI, existing Dashboard appearance and entry names retained.
- User's folder tree is illustrative; create files only for implemented behavior.
- No Git repository; edit current authorized workspace, without commits.

## Review Focus

- Retrying uncertain saves must reuse one document ID.
- Empty live data must never silently display sample records.
- Auth and Firestore failures must be visible and retryable.
- Data must remain under the authenticated user's path.
- Short screens, keyboard and larger text must leave the form usable.

## Tasks

- [x] Form worker: create `screens/transaction_form_screen.dart`,
  `utils/transaction_validation.dart`, `utils/categories.dart`, focused tests.
  Interface: `TransactionFormScreen({required String transactionId, required
  Future<void> Function(MoneyTransaction) onSave, DateTime? initialDate})`;
  successful save pops `true`, errors retain input, saving prevents duplicate taps.
- [x] Dashboard worker: extract `widgets/balance_card.dart`,
  `widgets/transaction_tile.dart`, `widgets/recent_transactions.dart`,
  `app/app_theme.dart`, `utils/date_formatter.dart` from Home. Preserve Home inputs;
  add optional `VoidCallback? onAddTransaction` and `String? notice`.
  Theme interface: `ThemeData buildAppTheme()` and `AppColors` constants.
- [x] Root: implement repository interface (`watchTransactions`, `newTransactionId`,
  `saveTransaction`), demo repository, Firestore codec/service and anonymous auth.
- [x] Root: bootstrap Firebase with actual options or explicit setup/demo UI;
  integrate stream Dashboard and form route, update obsolete placeholder tests.
- [x] Root: prepare Firebase project/rules files and Android internet permission;
  document configuration and current access limits in Thai README.
- [x] Verify complete suite, static analysis, available build, and independent review.

## Progress / decisions

- Baseline 10 tests passed after adding the Firebase dependencies.
- Browser access host is unavailable; Firebase CLI and cached sign-in are absent.
- Official Firebase plugin discovered and suggested; waiting for account connection
  or actual Android app options. Independent implementation continues.
- Package installation resolved the dependencies, but Flutter's Windows desktop
  symlink generation is unavailable without Developer Mode. `flutter test --no-pub`
  runs successfully; do not alter the user's OS security/settings to work around it.
- Rules verification probe: fake_cloud_firestore cannot evaluate rules functions
  or request.resource. Removed that incompatible probe rather than weakening the
  production rules. Service path/serialization tests pass; the rules file still
  requires validation with the official Firebase emulator before deployment.
- Form, Dashboard extraction and integration completed. All 32 tests passed after
  Thai localization was added; Flutter analysis reports no issues. Web build
  passed (including Wasm dry run). Android debug APK build passed (200.7 seconds).
- Independent code review found no blocking defects. The outdated README was
  replaced with current Thai setup, architecture, demo/live and anonymous guidance.
- Rendered the actual form route at 401 x 800 with Thai fonts and Material icons;
  visual inspection found no clipping. Keyboard/large text covered by widget tests.
- Public Hosting config lookup returned 404; actual registered app options and
  live Firebase auth/database/rules remain unverified pending project access.

## Android configuration follow-up

- User supplied `android/app/google-services.json`; project/package were verified
  as projectmoneymate / com.example.project_moneymate. Wired actual Android options
  and Google Services Gradle plugin 4.5.0 (current official setup documentation).
- Android config regression test first failed on missing options, then passed.
  Tests use unsupported Linux for setup/demo coverage, avoiding native Firebase
  calls and no longer assuming Android is unconfigured. Full suite: 37 passed.
- Live Anonymous Auth REST request returned HTTP 400 CONFIGURATION_NOT_FOUND.
  No transaction writes were performed. Added tested setup guidance for this error.
  Cloud Firestore read/write and rules remain unverified until Auth is configured.
- Android debug APK and Flutter analysis passed. No ADB device/emulator connected.
  CLI/Console access is separate from app runtime config and remains unavailable.
- Final APK rebuilt after adding Auth setup guidance (10.6 seconds). Generated
  Google Services Android resources independently match the supplied JSON for
  project ID, app ID, sender ID and API key; output recorded matching booleans only.
- Independent review noted native Android may wrap CONFIGURATION_NOT_FOUND in
  an internal-error message. Added a failing regression case, recognized that
  exact backend marker, then verified all 37 tests pass. No on-device run claimed.

## Registered Web configuration follow-up

- User supplied the Web firebaseConfig. Added static Web FirebaseOptions and
  selected it with kIsWeb before the Android branch; no dart-define flags needed.
  Android options remain unchanged; no Analytics dependency or tracking added.
- Live REST verification with the Web API key succeeded: anonymous sign-in and
  own-user Firestore read returned zero documents. Wrote no transaction records;
  deleted only the newly created temporary test Auth account afterwards.
- VM suite passed 37 tests, Flutter analysis clean, Web build passed with actual
  config. Browser-only selection test added, but headless Chrome harness stalled
  while loading before assertions (also on verbose retry); interrupted it rather
  than claiming browser-test success. No browser-test/UI success is inferred from it.
- Independent read-only review found no configuration or platform-selection defect.
  README updated to current Web setup and live Auth/read verification boundaries.
- Started the actual app with `flutter run -d chrome --no-pub --web-port=52674`.
  Chrome attached to the debug service, started main, and the app URL returned
  HTTP 200 with Flutter bootstrap. Dev server remains running for user testing.
  Browser UI and saving a transaction through it were not directly observed.
