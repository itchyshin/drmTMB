# After Task: Slice 267 Florence closeout

## Task

Close the Florence figure-gallery lane by deciding which display patterns should
be exported helpers and which should remain tutorial-level `ggplot2` recipes.

## What Changed

- Added a Slice 267 closeout decision to
  `docs/design/39-visualization-grammar.md`.
- Kept `plot_parameter_surface()` and `plot_corpairs()` as the current exported
  visualization helpers because their input table contracts are stable.
- Recorded raw data plus fitted lines, `emmeans` displays, conditional
  random-effect modes, variance-component dot plots, status strips, and source
  maps as tutorial-level recipes for now.
- Recorded simulation operating-characteristic and failure-ledger plots as
  future helper candidates after Phase 18 result schemas stabilize.
- Updated the roadmap, NEWS, check log, and recovery checkpoint.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/after-task/2026-05-18-slice-267-florence-closeout.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-183410-codex-checkpoint.md`

## Checks

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/dev-log/recovery-checkpoints/2026-05-18-183410-codex-checkpoint.md`
- `rg -n "Slice 267|helper-versus-recipe|plot_parameter_surface\\(\\).*plot_corpairs|Future helper candidate|Florence closeout|Plot helper backlog" docs/design/39-visualization-grammar.md ROADMAP.md NEWS.md`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the closeout as a design decision rather than adding another helper
  or plot.
- Pat checked that reader-facing recipes remain visible and usable.
- Fisher kept helper export tied to stable data contracts and interval status.
- Grace checked pkgdown and diff hygiene before closure.
- Rose checked that the closeout reduces future scope drift in the
  visualization lane.
- Florence made the core call: export only stable table consumers now, and
  defer broader plotting helpers until the schemas are real.

## Known Limits

- This slice records a helper backlog; it does not implement new plotting
  helpers.
- Simulation and failure-ledger helper names remain provisional until Phase 18
  aggregate and ledger schemas stabilize.
