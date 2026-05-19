# After Task: Slice 275 Warm-Start Boundary

## Goal

Design the simpler-fit warm-start route without letting unimplemented start
controls pass silently into `stats::nlminb()`.

## Implemented

- Reserved `start_from`, `warm_start`, `warm_starts`, and `warm_start_from` in
  `drm_control()`'s optimizer-control boundary.
- Extended the optimizer-contract tests so those warm-start names error in both
  plain `control = list(...)` and `drm_control(optimizer = list(...))` paths.
- Documented the future simpler-fit warm-start ladder and provenance contract in
  the optimizer/start/map/multi-start design note.
- Updated the convergence guide, roadmap, and NEWS to present warm starts as
  planned names, not fitted controls.

## Contract

Slice 275 does not copy parameters from a source fit. Future warm starts must
map through the public target namespace, check family/response/row/contrast
compatibility before optimization, record provenance on the fitted object, and
keep inference tied to the selected optimum of the final model.

## Files Changed

- `NEWS.md`
- `R/control.R`
- `ROADMAP.md`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/after-task/2026-05-18-slice-275-warm-start-boundary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-194822-codex-checkpoint.md`
- `tests/testthat/test-optimizer-contract.R`
- `vignettes/convergence.Rmd`

## Checks Run

- `air format NEWS.md R/control.R ROADMAP.md docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-275-warm-start-boundary.md docs/dev-log/recovery-checkpoints/2026-05-18-194822-codex-checkpoint.md tests/testthat/test-optimizer-contract.R vignettes/convergence.Rmd`:
  passed.
- `Rscript -e "devtools::test(filter = 'optimizer-contract|control', reporter = 'summary')"`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = FALSE)'`:
  passed.
- `rg -n 'Slice 275|start_from|warm_start|warm_starts|warm_start_from|simpler-fit|source-fit contract|warm-start names|Warm starts from simpler models' NEWS.md ROADMAP.md R/control.R tests/testthat/test-optimizer-contract.R vignettes/convergence.Rmd docs/design/35-optimizer-start-map-multistart.md`:
  confirmed the reserved names, tests, design contract, convergence guide,
  roadmap, and NEWS.
- `rg -n 'warm-start.*implemented|warm starts.*implemented|start_from.*implemented|warm_start.*implemented|source-fit.*implemented|copies.*source fit|copied.*source fit' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`:
  returned only negative or planned-boundary wording, not an implemented
  warm-start claim.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 275 warm-start boundary" --next "stage, commit, push, and open draft PR"`:
  wrote `docs/dev-log/recovery-checkpoints/2026-05-18-194822-codex-checkpoint.md`.

## Tests Of The Tests

The expanded optimizer-contract loop would fail if a future edit allowed a
warm-start name to be interpreted as an `nlminb()` optimizer setting or accepted
through `drm_control(optimizer = list(...))` before the warm-start route has a
source-fit contract.

## Consistency Audit

Ada kept the slice as a design boundary rather than a partial implementation.
Boole checked that the new names live in `drm_control()` and do not change
formula grammar. Fisher kept the future route tied to selected-optimum
provenance. Curie extended existing reserved-name tests instead of adding a
slow model-fitting grid. Pat checked the convergence guide tells users the
names are planned. Grace checked focused tests, vignette rendering, pkgdown, and
formatting. Rose checked for accidental claims that warm starts now copy source
fit parameters.

## Known Limitations

- No warm-start fitting, source-fit validation, target-name mapping, or
  parameter-copying path was added.
- No `check_drm()` warm-start provenance row exists yet.
- No simpler-to-richer route has simulation recovery or optimizer comparison
  evidence yet.

## Next Actions

Slice 276 can design fallback optimizer provenance, or a later warm-start slice
can first implement target-name mapping from a same-family fixed-effect source
fit to a richer final fit.
