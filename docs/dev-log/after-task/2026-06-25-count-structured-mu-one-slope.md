# After-Task Report: Count Structured Mu One-Slope Cells

Date: 2026-06-25

## 1. Goal

Admit exact ordinary Poisson/NB2 structured `mu` q1 one-slope cells for
`phylo()`, fixed-covariance `spatial()`, `animal()`, and `relmat()` without
widening the non-Gaussian structured random-effect claim. The accepted syntax is
one unlabelled intercept-plus-one-slope term such as `phylo(1 + x | species,
tree = tree)`. `phylo_interaction()` remains count intercept-only.

## 2. Implemented

- Relaxed the count structured validator so ordinary Poisson/NB2 `mu` terms may
  be either structured intercept-only terms or one unlabelled
  intercept-plus-one-slope term.
- Added a focused count one-slope data generator and eight source tests covering
  Poisson and NB2 crossed with `phylo()`, fixed-covariance `spatial()`,
  `animal()`, and `relmat()`.
- Checked convergence, positive Hessian, structured metadata, `sdpars`,
  `random_effects`, direct `log_sd_phylo` profile targets, predictions, and
  structured `check_drm()` rows for the admitted cells.
- Kept pure slopes, multiple slopes, labels, multiple structured count types,
  structured count scale, and zero-inflation rejected in neighbouring tests.
- Replaced the aggregate planned q-series row with exact provider/family
  support-cell rows and a planned-neighbour row.
- Updated README, ROADMAP, NEWS, formula grammar, family registry, likelihood,
  simulation/readiness, dashboard, and q-series design docs to match the exact
  admitted cells.
- Updated `man/phylo.Rd` via `devtools::document()`.

## 3a. Decisions and Rejected Alternatives

- The validator admits only intercept-only or intercept-plus-one-slope terms.
  Pure `0 + x`, multiple slopes, labelled count covariance, and simultaneous
  structured count types stay unsupported because they have different parameter
  identity and covariance contracts.
- `phylo_interaction()` stays intercept-only for ordinary Poisson/NB2 counts.
  Extending its Kronecker field to count slopes needs its own design and tests.
- The support-cell ledger records point-fit/extractor/source-test evidence only.
  It does not promote bridge parity, interval reliability, coverage, REML,
  AI-REML, or public support.
- The tests use deterministic small complete-response source fixtures. They are
  not operating-characteristic grids.

## 4. Files Touched

- `R/drmTMB.R`
- `R/formula-markers.R`
- `man/phylo.Rd`
- `tests/testthat/test-count-structured-mu.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/66-implementation-map-slices-356-405.md`
- `docs/design/71-nongaussian-structured-issue-ledger.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/147-phase6c-nongaussian-mu-slope-ademp.md`
- `docs/design/148-phase6c-random-slope-simulation-plan.md`
- `docs/design/151-phase6c-random-slope-tutorial-ledger.md`
- `docs/design/152-phase6c-random-slope-sprint-closeout.md`
- `docs/design/207-structured-random-effect-balance-100-slices.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-count-structured-mu-one-slope.md`

## 5. Checks Run

- `Rscript --vanilla -e "devtools::test(filter = 'count-structured-mu', stop_on_failure = TRUE)"`
  passed with 280 assertions, 0 failures, 0 warnings, and 0 skips.
- `Rscript --vanilla -e "devtools::test(filter = 'poisson-mean|nbinom2-location-scale|nongaussian-structured-boundary|count-structured-mu', stop_on_failure = TRUE)"`
  passed with 659 assertions after stale neighbouring-route tests were updated
  to reject pure count slopes instead of the newly admitted
  intercept-plus-one-slope count cell.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4576 assertions, 0 failures, 0 warnings, and 0 skips after the
  stale PR-stack row-count expectation was updated.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 85 structured
  RE q-series cells.
- `Rscript --vanilla -e "devtools::document()"` refreshed `man/phylo.Rd`.
- `gh issue list --repo itchyshin/drmTMB --search "count structured mu one slope q-series" --limit 20 --json number,title,state,url,labels`
  returned no matching issues.
- `git diff --check` passed.
- Manual R-CMD-check run
  `https://github.com/itchyshin/drmTMB/actions/runs/28179604462` failed on
  macOS because three older boundary tests still expected Poisson/NB2
  `phylo(1 + x | ...)` count terms to error. Those assertions now use pure
  count slopes as the still-unsupported neighbour.

## 6. Tests of the Tests

- The source tests fail if the structured metadata q-dimension is not 2, if the
  coefficient names are not `(Intercept)` and `x`, if the structured SD labels do
  not distinguish intercept and slope members, or if link predictions omit the
  structured contribution.
- Neighbouring rejection tests still exercise pure slopes, labels, ordinary
  random effects combined with structured count terms, zero-inflation, multiple
  structured types, and structured count scale.
- The conversion-contract suite caught a stale 15-row PR-stack expectation after
  the dashboard ledger had advanced to 17 rows, which confirms the dashboard
  contract is still checking drift rather than only the new model rows.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search "count structured mu one slope q-series" --limit 20 --json number,title,state,url,labels`
returned no matching issues. This slice is therefore tracked through the branch,
draft PR, q-series support-cell ledger, check-log entry, and this after-task
report.

## 8. Consistency Audit

- Formula grammar, family registry, likelihood notes, support-cell ledger,
  dashboard README, README, ROADMAP, NEWS, and `phylo()` documentation now use
  the same support boundary.
- The exact supported count one-slope providers are `phylo()`,
  fixed-covariance `spatial()`, `animal()`, and `relmat()`.
- The exact supported count intercept providers remain `phylo()`,
  `phylo_interaction()`, `spatial()`, `animal()`, and `relmat()`.
- q4 intervals, coverage, REML, AI-REML, broad bridge support, public support,
  and DRAC/Totoro execution remain out of scope.

## 9. What Did Not Go Smoothly

The structured-RE conversion-contract test failed at first because the PR-stack
merge-readiness ledger had advanced from 15 rows ending at PR #653 to 17 rows
ending at PR #655, while the test still had hard-coded expectations. The fix
made the expected PR range explicit as `639:655`, so the intended stack length is
less likely to drift silently.

The first manual R-CMD-check run then failed on macOS because three older
boundary tests used `phylo(1 + x | ...)` as a planned-neighbour rejection
example. That route is now the admitted cell, so those assertions were changed
to pure-slope forms.

## 10. Known Residuals

- No pure, multiple, or labelled structured count slopes.
- No `phylo_interaction()` count slope support.
- No simultaneous structured count types.
- No structured count `sigma`, shape, zero-inflation, hurdle, ordinal, or
  bounded-response route.
- No q2/q4 count covariance, bridge parity, interval reliability, coverage,
  REML, AI-REML, public support, or broad operating-characteristic claim.

## 11. Team Learning

The q-series support-cell row works well as the unit of truth: adding the exact
rows before widening prose made it easier to see stale “structured slopes remain
planned” wording and replace it with the narrower residual boundary. Future
q-series slices should update the support-cell row, validator, source tests, and
claim boundary together before touching higher-level README or ROADMAP language.
