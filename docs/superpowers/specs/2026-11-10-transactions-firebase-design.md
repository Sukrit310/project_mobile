# MoneyMate transaction form and Firebase

Continue the existing Dashboard with an add-transaction form and Firestore for
Firebase project `projectmoneymate`. Separate responsibilities into screens,
widgets, services, app configuration and utilities. The user's example tree is
guidance, not a requirement to create unused screens or budget/chart features.

Use the existing immutable MoneyTransaction and integer satang amounts. Form
fields: title (trimmed, 1–80 characters), income/expense, category, positive baht
amount with at most two decimal places, and date. Parse currency without doubles.
Save asynchronously, disable repeated submission, retain form on error, return
to an updated Dashboard on success. Generate one ID per opened form; retry the
same ID to avoid duplicate records after an uncertain network acknowledgement.

Implement TransactionRepository with memory demo and Firestore implementations.
Firestore writes to `users/{uid}/transactions/{id}`, using anonymous Firebase Auth
until a permanent sign-in feature is requested. Keep loading/error states visible.
Do not seed sample records into the live database. The live empty state shows zero.
Demo is an explicit choice and clearly marked as temporary, without cloud saving.

Firebase project ID alone is insufficient: obtain actual registered app options
through authorized project access. Do not fabricate app IDs or API keys. Until
access/configuration is available, show a setup screen with retry and explicit
demo choice. Prepare owner-scoped local Firestore rules for review/deployment;
do not overwrite unseen remote rules or enable public access. Anonymous accounts
are device/session identities; README must explain that reinstalling/signing out
can lose access until a permanent account/linking feature is added.

Verify form validation, satang precision, successful/failed saves, repeated taps,
Dashboard stream updates, empty/error/retry states, serialization and user paths.
Run the complete test suite, analysis and an available build. Report live Firebase
verification separately from local tests if project access remains unavailable.
