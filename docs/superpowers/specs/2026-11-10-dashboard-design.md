# MoneyMate Dashboard

Build the supplied Thai mobile Dashboard in the existing Flutter application.
Use Flutter Material widgets and existing dependencies. Work in the requested
workspace; this directory has no Git repository, so no worktree or commit applies.

## Approach

Use a typed, immutable transaction model and a derived summary, with small private
widgets in `home.dart`. This keeps the first screen easy to follow while allowing
Firestore records to replace the sample list later. Hardcoded summary labels
would drift from records; a repository/state-management package is unnecessary
for this initial screen. These are implementation choices made by the agent.

## Behavior

- Show greeting, MoneyMate, a blue balance card, monthly income and expenses,
  two newest transactions, add button, and four bottom navigation destinations.
- Use November 2026 demo data: salary +12,000 on November 1 at 09:00,
  housing expense -3,420 on November 1 at 08:00, food -80 on November 8.
  The newest two records therefore match the supplied image.
- Net balance is income minus expenses across all supplied records. Monthly
  income/expenses filter by both year and month. Store money as integer satang.
- Inject a reference month and transactions into Home for later integration.
- Scroll on short screens; keep cards and amounts readable with larger text.
- Unimplemented actions show a Thai informational SnackBar and keep Home selected.
- This step includes no form or Firebase connection. Explain widgets and next steps
  in Thai in README and in the delivery message.

## Verification

Replace the obsolete counter test. Check rendered totals, latest ordering,
placeholder actions, narrow/large-text layouts, empty records, cross-month/year
summary calculations, and baht formatting. Run Flutter tests and static analysis.
