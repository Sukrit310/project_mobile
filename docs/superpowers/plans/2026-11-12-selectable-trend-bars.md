# Selectable expense trend bars

User request: replace the Statistics daily trend with the supplied mint/navy rounded bar chart and support monthly/weekly selection.

- [x] Aggregate real expense records as integer satang. Weekly is Monday–Sunday, including dates across calendar boundaries; show the actual date range. Monthly follows the selected month and retains the existing current-month cutoff.
- [x] Render a white outlined card with “แนวโน้มรายจ่าย” and a top-right period menu. Default to weekly to match the reference. Mint bars and navy selected/peak bar, weekday/date labels, no decorative grid.
- [x] Preserve accessible exact values and reduced motion. Let users navigate weeks intersecting the selected month, retain selection on transaction updates, and reset the anchor when the selected month changes.
- [x] Verify calculation, menu switching, edits/deletes, month changes, small screens/2x text, and real rendered appearance. Run the full suite, analyze and build the updated APK.

No dependencies, repository contracts or Firebase changes.

## Paired income bars follow-up

- [x] Add independent income amounts/totals without changing expense meanings; include recorded future income in the current month's displayed days.
- [x] Show income and expense rods together, stable mint/navy legend, separate totals and type-specific tooltips/daily details.
- [x] Verify income-only periods, exact same-day sums, cross-month weeks, edits/deletes, large values, small screens and actual rendered appearance.
- [x] Run full tests, analyze and build the updated APK.
