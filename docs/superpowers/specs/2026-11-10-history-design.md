# MoneyMate History, edit and delete

Continue the approved next step from the shared MoneyMate plan: History with
month/type/title filters, editing and confirmed deletion, sharing the Dashboard's
repository stream. Statistics and Budget remain later steps.

Use existing `title`, `amountSatang`, `type`, `category`, `date` documents and IDs;
do not migrate stored records just to match illustrative names in the shared plan.
Keep integer satang, current Thai UI/theme and the Android/Web configurations.

History shows all matching records, newest first, grouped by calendar date, with
an all-months option and a clear empty state. Filters persist across stream
updates and form routes. Search matches title case-insensitively. Show income /
expense totals for the filtered records. Keep filters/list scrollable on small
screens and with a keyboard or large text. Shared bottom navigation opens Home
and History; Statistics/Budget still explain their future status.

Reuse TransactionFormScreen for edits: prefill original ID, title, amount, type,
category and exact timestamp; use edit-specific titles/buttons. An unchanged date
must not silently be clamped. Choosing another day preserves time of day. Errors
retain input. Update an existing document with update(), never recreate a deleted
record; raise a domain not-found exception if it no longer exists.

Delete only after a dialog names the selected transaction and asks for confirmation.
Cancel does nothing. Prevent duplicate requests and show pending/error feedback.
Timeouts must describe uncertain acknowledgement; retry uses the same ID. Demo
repository must mirror update/not-found/delete semantics and emit new feeds.

Local Firestore rules retain owner checks and validation; allow deletion only for
the owner UID. Remote publication requires project-admin access; do not claim it
deployed without evidence or delete existing user records for verification.

Verify filters across years/months, order, mutation-free input, empty search,
prefill/exact satang/timestamp preservation, not-found edits, cancellation and
delete failures, repository user scoping, and Dashboard totals after edit/delete.
