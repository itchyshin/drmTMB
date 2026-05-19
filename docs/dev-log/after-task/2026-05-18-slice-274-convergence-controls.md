# After Task: Slice 274 Convergence Control Presets

## Goal

Keep ordinary optimizer defaults fast while giving users named, reproducible
optimizer-budget presets for difficult distributional models.

## Implemented

- Added `optimizer_preset = "default"`, `"careful"`, and `"robust"` to
  `drm_control()`.
- Expanded `"careful"` to `iter.max = 1000` and `eval.max = 1000`, and
  `"robust"` to `iter.max = 5000` and `eval.max = 5000`.
- Kept `optimizer = list(...)` as the explicit override path when a user needs a
  custom `nlminb()` setting on top of a preset.
- Recorded the selected preset and expanded optimizer list in fitted objects.
- Updated the convergence guide, optimizer contract design note, roadmap, NEWS,
  and roxygen reference documentation.

## Contract

Slice 274 adds only deterministic single-optimizer budget presets for
`stats::nlminb()`. It does not change the default fit, add user starts or maps,
run fallback optimizers, start BFGS or L-BFGS-B automatically, or implement
multi-start fitting.

## Files Changed

- `NEWS.md`
- `R/control.R`
- `ROADMAP.md`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/after-task/2026-05-18-slice-274-convergence-controls.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-194240-codex-checkpoint.md`
- `man/drm_control.Rd`
- `tests/testthat/test-optimizer-contract.R`
- `vignettes/convergence.Rmd`

## Checks Run

- `air format NEWS.md R/control.R ROADMAP.md docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-274-convergence-controls.md docs/dev-log/recovery-checkpoints/2026-05-18-194240-codex-checkpoint.md man/drm_control.Rd tests/testthat/test-optimizer-contract.R vignettes/convergence.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drm_control.Rd`.
- `Rscript -e "devtools::test(filter = 'optimizer-contract', reporter = 'summary')"`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = FALSE)'`:
  passed.
- `rg -n 'optimizer_preset|careful|robust|Control presets and defaults|Slice 274|nlminb\(\).*budget|expanded optimizer settings|recorded optimizer settings' NEWS.md ROADMAP.md R/control.R man/drm_control.Rd tests/testthat/test-optimizer-contract.R vignettes/convergence.Rmd docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-274-convergence-controls.md`:
  confirmed the API, tests, reference, article, design note, NEWS, and roadmap
  carry the preset contract.
- `rg -n 'fallback optimizer.*implemented|fallback optimizers.*implemented|multi-start.*implemented|multi_start.*implemented|warm-start.*implemented|warm starts.*implemented|BFGS.*automatic|L-BFGS-B.*automatic|many optimizers|automatic.*optimizers' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`:
  returned only planned-boundary text, not a fallback or multi-start
  implementation claim.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 274 convergence control presets" --next "stage, commit, push, and open draft PR"`:
  wrote `docs/dev-log/recovery-checkpoints/2026-05-18-194240-codex-checkpoint.md`.

## Tests Of The Tests

The new optimizer-contract tests would fail if presets stopped expanding to the
documented `nlminb()` budgets, if explicit optimizer settings stopped overriding
presets, if fitted objects did not record the selected preset, or if
`optimizer_preset` could be smuggled through a plain optimizer-only control
list.

## Consistency Audit

Ada kept the slice to a single-optimizer API addition. Boole checked that the
new argument stays in `drm_control()` rather than changing formula grammar or
plain-list semantics. Fisher kept convergence advice tied to `check_drm()`
instead of treating larger budgets as a cure for weak identifiability. Curie
added focused preset expansion and fitted-object recording tests. Pat checked
that users can copy a short robust-control example from the convergence guide.
Grace checked roxygen, vignette rendering, pkgdown, and diff hygiene. Rose
checked that fallback optimizers, starts, maps, and multi-start fitting remain
documented as planned rather than implemented.

## Known Limitations

- No warm-start, user-start, map, fallback-optimizer, or multi-start path was
  added.
- No optimizer comparison table, Hessian eigenvector culprit report, or
  automatic simplification advice was added.
- Presets tune only `iter.max` and `eval.max`; users still need `check_drm()`,
  simpler-model comparison, scaling, and profiles to diagnose weak fits.

## Next Actions

Slice 275 can design warm starts from simpler models, using the selected-optimum
invariant from `docs/design/35-optimizer-start-map-multistart.md` as the guard
rail.
