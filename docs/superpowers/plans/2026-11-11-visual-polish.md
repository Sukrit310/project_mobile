# MoneyMate visual polish Implementation Plan

> Use independent UI/font workers and root integration, then one final review.

**Goal:** Improve visual craft and useful interactions, retain Thai comments and
all financial behavior, then publish to Sukrit310/project_mobile main as requested.
**Design:** `DESIGN.md`; existing blue/Thai Material app is the visual authority.

## Ownership / contracts

- Root: app_theme.dart, DashboardScreen, navigation, AnimatedMoney and
  TabSwitchTransition, integration/motion/privacy tests and docs/Git publication.
- Dashboard worker: home.dart, balance_card.dart, transaction_tile.dart,
  recent_transactions.dart and focused dashboard privacy tests only.
- Secondary worker: history/statistics/budget/form screens and budget editor;
  refine presentation only. No repository/model/rules or existingtest changes.
- Font worker: assets/fonts/NotoSansThai.ttf, OFL.txt and pubspec fonts only.

AppColors keeps every existing field and adds primaryDeep, mintSurface,
incomeSurface, expenseSurface, surfaceMuted, outline, accent. Root owns definitions.
`AnimatedMoney({required String amount, TextStyle? style, TextAlign? textAlign,
Key? valueKey})` is a StatelessWidget in widgets/animated_money.dart. It crossfades
exact formatted text, current child only, has tabular figures, honors reduced motion.
Home adds `bool showBalance=true`, `VoidCallback? onToggleBalanceVisibility` and
passes them to BalanceCard with the same fields. Toggle key: balance-visibility,
tooltip ซ่อนยอดบนการ์ด / แสดงยอดบนการ์ด. When hidden, all three card amounts are
replaced by ••••••; their exact strings/semantics are absent on that card.
Dashboard state owns the boolean so tab navigation retains the choice.

## Tasks

- [x] Font: download official licensed Thai font and register assets offline.
- [x] Dashboard: refine header/balance/recent rows, privacy control, focused checks.
- [x] Secondary: coherent surfaces/fields/filters/buttons across full user path.
- [x] Root: theme, Material NavigationBar, exact-value/reduced-motion transitions,
  privacy state; adapt tests of nav selection to actual Material3 navigation.
- [x] Full suite/analyze/Web+APK, bounded Thai-font visual QA, independent review.
- [x] README / preview, inspect git staged files, commit and push existing main;
  verify remote head. No real Firebase data writes or new Firestore rules.

## Evidence / decisions

- Existing main HEAD 28893100cb298b4685cd282bcf5617e49dc48955, clean local branch
  tracking origin/main. User's previous GitHub upload is already present.
- Default sandbox command/Node process setup failed; authorized escalated command
  execution reads workspace successfully. Use that runner for required commands.
- Impeccable context ran once; code/screenshot evidence establishes incumbent UI.
  Manual detector runs once at end. No skill updates are part of this user task.
- New behavior checked red/green: privacy masking, exact text updates, reduced
  motion, rapid navigation and zero-viewport Android startup. Full VM142pass;
  analyzer clean. Independent review found no blocking issues.
- Pixel_10 Android screenshots inspected across4tabs/form, maskedcard and1.3x
  fontscale (restored1.0). Wide1000x900 actual-font widget render passed. One native
  inspection batch led to stronger input boundaries and removal of chip checkmark
  overlapping an avatar. Mechanical detector ran once and returned[].
- Existing backend/models/Firestore rules are unchanged. User reports rules were
  updated in Console; no cloud financial data writes in this UI work.
- Normal Web and Android debug builds passed from lib/main.dart after preview
  verification; final full suite142pass and analyzer noissues. Native screenshot
  inspection used an explicit in-memory demo entrypoint; it is not shipped.
- The upstream OFL license is preserved verbatim, including one trailing space on
  line21; diff whitespace validation excludes only that vendored license file.
- Published UI source commit a10c3cf to origin/main (2889310..a10c3cf), preserving
  existing history. GitHub destination: https://github.com/Sukrit310/project_mobile.
