# After Task: Phase 18 Count Structured q1 Warning Diagnostic

Date: 2026-05-29

## Goal

Inspect the single warning replicate from the first manual
`count_structured_q1` Actions smoke audit before any larger count structured
q=1 grid.

## Implemented

The saved Actions artifact identified `count_structured_q1_020` replicate 2 as
an NB2 spatial cell with `n_level = 16`, `n_per_level = 8`,
`sd_structured = 0.60`, `mean_count = 3.0`, and `sigma_baseline = 0.45`. The
Ubuntu run recorded warning `NaNs produced`, `pdHess = FALSE`, and a fitted
spatial SD of about `2.51e-17`.

The exact seed, `1409019402`, replayed locally with the same near-zero spatial
SD estimate and fixed-effect estimates. The local macOS fit reported a
positive-definite Hessian, but `check_drm()` still flagged
`random_effect_sd_boundary` as `warning`. This makes the case
boundary-sensitive and platform-sensitive, not a parser or DGP failure.

`phase18_summarise_count_structured_q1_fit()` now adds six replicate-table
columns: `fit_diagnostic_status`, `fit_diagnostic_message`, `hessian_status`,
`hessian_message`, `sd_boundary_status`, and `sd_boundary_message`. The
source-specific `diagnostic_status` column remains separate, so a structured
source row can still say the `spatial()` replication diagnostics are `ok` while
the fit-level rollup reports a boundary warning.

## Mathematical Contract

The model contract did not change. The DGP remains

```text
b_site ~ Normal(0, sd_structured^2 K)
eta_mu_i = beta0 + beta1 x_i + b_site[i]
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 z_i
sigma_i = exp(eta_sigma_i)
count_i ~ NB2(mu_i, sigma_i)
```

The diagnostic hardening changes what the artifact records about a fitted
replicate. It does not change the likelihood, formula grammar, interval
targets, or count structured q=1 support boundary.

## Files Changed

- `inst/sim/fit/sim_summarise_count_structured_q1.R`
- `tests/testthat/test-phase18-count-structured-q1.R`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/fit/sim_summarise_count_structured_q1.R tests/testthat/test-phase18-count-structured-q1.R inst/sim/README.md ROADMAP.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-warning-diagnostic.md
Rscript --vanilla -e 'devtools::test(filter = "phase18-count-structured-q1")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-actions-runner|phase18-count-structured-q1")'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 warning OR count structured q1 diagnostic' --limit 20 --json number,title,state,url,labels
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
Rscript --vanilla -e 'devtools::test()'
Rscript --vanilla -e 'devtools::check(error_on = "never")'
```

Result: 66 expectations passed, 0 failures, 0 warnings, 0 skips.

The adjacent Actions-runner plus count structured q=1 test filter passed with
131 expectations. `pkgdown::check_pkgdown()` reported no problems. The
open-issue search returned no matching open issues. The stale-claim scan
returned only the intended NEWS boundary wording and standing formula-grammar
planned-neighbour row. `git diff --check` was clean. The full package test
suite passed with 7,565 expectations, 0 failures, 0 warnings, and 0 skips.
`devtools::check(error_on = "never")` completed with 0 errors, 0 warnings, and
1 local environment NOTE: `unable to verify current time`.

## Tests Of The Tests

The new focused test uses the exact Actions artifact seed and condition cell.
It asserts that the replayed structured SD is near zero, that
`sd_boundary_status` is `warning`, and that `hessian_status` follows the local
`fit$sdr$pdHess` value instead of assuming a platform-stable Hessian outcome.

## Consistency Audit

`inst/sim/README.md`, `ROADMAP.md`, and the count structured q=1 design note
now separate fit-level diagnostics from marker-specific `spatial()`,
`animal()`, and `relmat()` source diagnostics. The docs still describe this
lane as opt-in smoke evidence, not formal recovery or coverage evidence.

## GitHub Issue Maintenance

No new GitHub issue was opened during this local diagnostic slice.
`gh issue list --repo itchyshin/drmTMB --state open --search
'count_structured_q1 warning OR count structured q1 diagnostic' --limit 20`
returned no open overlapping issue.

## What Did Not Go Smoothly

The first local replay used the smoke runner defaults instead of the grid
writer defaults, so it tested the wrong condition cell. Replaying from the
saved artifact registry corrected the condition to `n_per_level = 8`,
`sd_structured = 0.60`, `mean_count = 3.0`, and `sigma_baseline = 0.45`.

## Team Learning

Curie and Fisher should inspect boundary and Hessian rates together in future
simulation artifacts. A green workflow, `converged = TRUE`, and a source
diagnostic of `ok` can still hide a boundary-sensitive replicate unless the
fit-level diagnostic rows are carried into the replicate table.

## Known Limitations

This slice does not rerun the GitHub Actions grid, estimate boundary rates, or
alter the condition table. It adds the diagnostic columns needed for the next
bounded pilot.

## Next Actions

Run a bounded count structured q=1 pilot only after deciding how many boundary
or Hessian warnings are acceptable for smoke evidence. Use the new
`sd_boundary_status` and `hessian_status` columns as review gates before
claiming recovery or coverage.
