# MoneyMate monthly statistics

Implement the approved next step: Statistics after Dashboard/Form/History.
Use the existing repository feed and five-field transaction schema without writes
or migrations. Budget remains the next feature. Thai UI and current theme apply.

The Statistics tab selects a calendar month/year, including previous/next month
navigation and available months. It shows monthly income, expense, net and record
count; an expense-category donut chart with exact amounts and percentages; and
two bars comparing that month's income and expense. A readable legend/text must
convey chart values, including tiny slices and users of larger text/screen readers.

Aggregate money using int satang; convert to double only for graph coordinates and
display percentages. Match both year and month. Include every valid category,
including legacy cross-type combinations; never mutate input records. Category
charts exclude nonpositive slices and handle zero expenses without division by zero.
Bar charts handle both-zero, income-only, expense-only and satang-sized values.

Statistics uses the same live stream as the other tabs, retains month selection
through incoming snapshots and form routes, and recomputes after add/edit/delete.
Keep selected month in the dropdown even after its last transaction disappears.
Reuse shared bottom navigation (index 2), pending/cache/demo notices and Add action.
Keep all content scrollable on narrow screens and at 2x text scale.

Use fl_chart for graph rendering, with bounded animation and no chart dependency
in calculation logic. No Analytics, new Firebase rules or cloud mutations here.

Verification: pure aggregation tests, chart empty/data/update cases, screen month
navigation/stream updates/responsiveness, integrated repository mutation updates,
full VM suite, analysis, Web/Android builds, Thai-font visual render, independent review.
