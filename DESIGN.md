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
