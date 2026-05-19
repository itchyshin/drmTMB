# After Task: Slice 276 Fallback Optimizer Boundary

## Goal

Design the multi-optimizer fallback route without making fallback BFGS or
L-BFGS-B refits automatic for ordinary models.

## Implemented

- Reserved `fallback_optimizers`, `optimizer_fallback`, and
  `optimizer_fallbacks` alongside the existing `fallback_optimizer` control
  name.
- Extended the optimizer-contract tests so those fallback names cannot pass
  through plain `control = list(...)` or `drm_control(optimizer = list(...))`.
- Expanded the optimizer/start/map/multi-start design note with the future
  `nlminb()`/BFGS/L-BFGS-B sequence, selected-optimizer rule, and comparison
  provenance table.
- Updated the convergence guide, roadmap, and NEWS to state that fallback
  optimizers remain planned, not automatic.

## Contract

Slice 276 adds no fallback fitting. Future fallback optimizers must record every
attempt, select one deterministic optimum, and make `summary()`, `vcov()`,
profiles, `check_drm()`, and extractors use only that selected optimizer result.
The comparison record must include convergence status, objective, gradient
summary, elapsed time, eligibility, and rejection reasons for each attempted
optimizer.

## Files Changed

- `NEWS.md`
- `R/control.R`
- `ROADMAP.md`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/after-task/2026-05-18-slice-276-fallback-optimizer-boundary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-195332-codex-checkpoint.md`
- `tests/testthat/test-optimizer-contract.R`
- `vignettes/convergence.Rmd`

## Checks Run

- `air format NEWS.md R/control.R ROADMAP.md docs/design/35-optimizer-start-map-multistart.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-276-fallback-optimizer-boundary.md docs/dev-log/recovery-checkpoints/2026-05-18-195332-codex-checkpoint.md tests/testthat/test-optimizer-contract.R vignettes/convergence.Rmd`:
  passed.
- `Rscript -e "devtools::test(filter = 'optimizer-contract|control', reporter = 'summary')"`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = FALSE)'`:
  passed.
- `rg -n 'Slice 276|fallback_optimizer|fallback_optimizers|optimizer_fallback|optimizer_fallbacks|BFGS|L-BFGS-B|selected-optimizer|selected optimizer|optimizer comparison|fallback-control names' NEWS.md ROADMAP.md R/control.R tests/testthat/test-optimizer-contract.R vignettes/convergence.Rmd docs/design/35-optimizer-start-map-multistart.md`:
  confirmed the reserved names, tests, design contract, convergence guide,
  roadmap, and NEWS.
- `rg -n 'fallback optimizer.*implemented|fallback optimizers.*implemented|fallback refits.*implemented|fallback.*automatic|BFGS.*automatic|L-BFGS-B.*automatic|optimizer_fallback.*implemented|fallback_optimizer.*implemented|optimizer comparison.*implemented' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`:
  returned only negative or planned-boundary wording, not a fallback
  implementation claim.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 276 fallback optimizer boundary" --next "stage, commit, push, and open draft PR"`:
  wrote `docs/dev-log/recovery-checkpoints/2026-05-18-195332-codex-checkpoint.md`.

## Tests Of The Tests

The expanded optimizer-contract loop would fail if a future edit allowed a
fallback-control name to be interpreted as an `nlminb()` setting or accepted
through `drm_control(optimizer = list(...))` before fallback provenance exists.

## Consistency Audit

Ada kept the slice as a boundary and design contract. Boole checked the names
stay in `drm_control()` rather than formula grammar. Fisher kept the future
fallback rule tied to objective and gradient evidence, not convenience.
Curie extended the existing reserved-name loop. Pat checked the convergence
guide says fallback optimizers are planned. Grace checked focused tests,
vignette rendering, pkgdown, and formatting. Rose checked for accidental claims
that BFGS or L-BFGS-B now run automatically.

## Known Limitations

- No fallback optimizer is run.
- No optimizer comparison table is stored on fitted objects.
- No selected-optimizer provenance row is added to `check_drm()`.
- No BFGS or L-BFGS-B parameter-scale compatibility tests exist yet.

## Next Actions

Slice 277 can move to Hessian and boundary diagnostics, keeping fallback
implementation separate until selected-optimizer provenance is tested.
