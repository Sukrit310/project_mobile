# MoneyMate visual system

MoneyMate is a Thai personal finance app for recording income/expenses, reviewing
history, viewing monthly statistics and managing a monthly total budget.
Mode: Operate. This pass refines the existing blue identity and Material 3 flows.

- Keep primary #20536B; deepen large balance surfaces with #173E50. Use soft mint
  #DCF2E9 for selection/positive accents, warm white #F5F8F6 canvas and white panels.
- Semantic income #087453 / expense #BE414B with pale tinted icon backgrounds.
  Text #173B45, secondary #566B70, outline #DCE6E3, input boundary #7B918B.
  Semantic colors stay consistent; input boundaries exceed3:1 on white.
- Bundle Noto Sans Thai from official google/fonts with its OFL license; no runtime
  font requests. Use strong type hierarchy and tabular numerals for money.
- Preserve dashboard's prominent balance card and all real financial copy/values.
  Panels use 16px radii, groups12/16px apart, sections24px apart, one border or tonal
  elevation. No promotional claims, fake financial insight, loops or raster scenery.
- Material 3 navigation uses visible labels and a mint selection indicator. Buttons,
  inputs, chips, dialogs, snackbars and top bars share color/shape/type treatment.
- Money updates crossfade the exact formatted integer value for180ms, never tween
  floating point amounts. One180ms tab continuity fade; no reveal on every section.
  Respect MediaQuery.disableAnimations; content is always present for semantics.
- Add eye control to hide amounts on the dashboard balance card; keep its setting
  during tab changes for this app session and never expose hidden card amounts in
  accessibility text. Transaction rows retain their own values as before.
- Keep all four tabs, form CRUD, metadata/error states, month filtering and schema.
  Verify320px/2x text, keyboard, phone401px and wide1000px render in a bounded pass.

## MoneyMate 2.0 — 12 November 2026

- Dashboard order: dated brand header, accumulated balance and monthly totals,
  actual monthly budget, typed add/statistics shortcuts, latest five transactions,
  and one factual highest-expense-category insight. Keep the existing greeting removal.
- Budget snapshots consume presentation state from DashboardScreen. Loading,
  missing/zero budgets, errors with retry, cache and pending writes have separate
  states. Changing month or repository resets the snapshot; one resolved month
  drives both budget and monthly expenses, including automatic month rollover.
- Keep four navigation destinations and a visible add FAB on every available tab.
  Hide unsupported standalone Home actions instead of showing placeholder messages.
- History keeps search/filter state on stream updates and form return, distinguishes
  collection emptiness from no matches, and labels today/yesterday by local calendar.
- Statistics adds exact daily expenses, accessible daily values, highest category
  and record counts. Compare completed months only when a positive prior expense
  base exists. Current-month charts stop at today unless real future records exist.
- The form starts with type and prominent amount, followed by detail fields and
  accessible icon category chips. Typed shortcuts preselect new entries; editing
  retains stored type/category, ID and timestamp with existing validation/save flow.
- No new dependencies, Firestore schema changes or category budget persistence.
  Category budgets remain the optional later phase described in the supplied brief.

### Selectable trend bars

Replace the daily line graph with the supplied mint/navy rounded-bar treatment.
The card owns its heading and a top-right weekly/monthly menu, defaults to weekly,
and keeps the chosen period/week when records update. Weekly shows full Monday–Sunday
dates, with navigation through weeks intersecting the selected month and explicit
cross-month ranges. Monthly shows dates within the selected month. The current-month
cutoff includes existing income or expense records beyond today. Each date has two
adjacent rods: mint income on the left, navy expense on the right. Colors identify
the transaction type consistently, with matching legend dots and separate totals.
The vertical scale covers both types and income-only periods still render. Exact
satang values and type names remain available through tooltips and a daily-detail
sheet, including zero days. Income and expenses are aggregated independently.
Date-axis ticks leave space before the final date and thin out for enlarged text.
