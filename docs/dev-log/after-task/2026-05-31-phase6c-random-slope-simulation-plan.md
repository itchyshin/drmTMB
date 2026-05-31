# After Task: Phase 6c Random-Slope Simulation Plan

## Goal

Close #446 by recording the staged Phase 6c simulation plan that must happen
before large power, accuracy, and coverage grids are dispatched.

## Implemented

Added `docs/design/148-phase6c-random-slope-simulation-plan.md`. The note
turns the closed #439, #440, #441, #442, and #443 gates into a run order:
registry preflight, bivariate slope-only artifact pilot, ordinary Gaussian
`mu` and `sigma` slope pilots, ordinary Poisson/NB2 `mu` slope pilots,
source-tested non-Gaussian `mu` slope smoke artifacts, and structured Gaussian
one-slope wrapper pilots.

The plan names what each pilot can prove and what remains outside the claim.
It records compact surface-specific ADEMP sheets, shared ADEMP sections,
Williams-style reporting coverage, artifact-table requirements, worker limits,
MCSE targets, stop rules, and issue routing.

## Mathematical Contract

The simulation plan does not change likelihood parameterization. It keeps the
same fitted surfaces recorded by the Phase 6c gates:

```text
eta_mu_i = X_mu[i, ] beta_mu + random-slope contribution
eta_sigma_i = X_sigma[i, ] beta_sigma + independent scale-slope contribution
```

Bivariate residual `rho12` remains a residual-coscale parameter. Group-level
and structured slope correlations remain latent random-effect correlations,
not residual `rho12`.

## Files Changed

- `ROADMAP.md`
- `docs/design/148-phase6c-random-slope-simulation-plan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-phase6c-random-slope-simulation-plan.md`
- `inst/sim/README.md`

No parser, likelihood, TMB, extractor, simulation-runner, formula-grammar,
NEWS, pkgdown-navigation, or missing-data files changed.

## Checks Run

```sh
air format ROADMAP.md docs/design/148-phase6c-random-slope-simulation-plan.md docs/dev-log/after-task/2026-05-31-phase6c-random-slope-simulation-plan.md docs/dev-log/check-log.md inst/sim/README.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry|phase18-biv-gaussian-mu-slope|phase18-random-slope-grid-writers|phase18-gaussian-mu-random-slope|nongaussian-mu-random-slopes|poisson-mean|nbinom2-location-scale', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(lazy = TRUE, preview = FALSE)"
rg -n 'Phase 6c Random-Slope Simulation Plan|Surface ADEMP Sheets|#446|diagnostic pilots|registry preflight|bivariate slope-only artifact pilot|ordinary Gaussian `mu`/`sigma` slope pilots|source-tested non-Gaussian slope smoke artifacts|structured Gaussian one-slope wrapper|Morris|Williams|MCSE|stop rules' ROADMAP.md docs/design/148-phase6c-random-slope-simulation-plan.md docs/dev-log/after-task/2026-05-31-phase6c-random-slope-simulation-plan.md docs/dev-log/check-log.md inst/sim/README.md pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'Phase 6c.*(recovery|coverage|power) claims are now supported|diagnostic pilot.*creates.*(coverage|power)|source-tested.*coverage support|random effects in `rho12` (are )?(fitted|implemented)|correlated non-Gaussian slopes (are )?(fitted|implemented)|multiple structured slopes (are )?(fitted|implemented)|residual-scale structured slopes (are )?(fitted|implemented)|p8/q8 (is|are) (fitted|implemented|supported)' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes inst/sim tests/testthat pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!pkgdown-site/search.json'
git diff --check
```

Results:

- Focused tests passed for the registry, bivariate slope-only, random-slope
  grid-writer, Gaussian random-slope, non-Gaussian random-slope, Poisson, NB2,
  and truncated-NB2 filters.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(lazy = TRUE, preview = FALSE)` completed.
- The positive scan found the #446 handoff, surface ADEMP sheets, run order,
  Morris/Williams references, MCSE language, and stop rules in source files and
  rendered `pkgdown-site/ROADMAP.html`.
- The stale-claim scan returned no matches for unsupported recovery, coverage,
  power, random-`rho12`, correlated non-Gaussian slope, multiple structured
  slope, residual-scale structured slope, or p8/q8 implementation claims.
- `git diff --check` passed.

## Tests Of The Tests

This is a design and status slice. The relevant code-facing tests are the
registry tests and the existing focused random-slope tests that the plan names:
`phase18-structured-workflow-registry`, `phase18-biv-gaussian-mu-slope`,
`phase18-random-slope-grid-writers`, `phase18-gaussian-mu-random-slope`,
`nongaussian-mu-random-slopes`, `poisson-mean`, and
`nbinom2-location-scale`.

## Consistency Audit

The plan keeps diagnostic pilots separate from formal grids. It says a
diagnostic pilot can propose a formal grid, but cannot itself create public
recovery, coverage, or power claims. It also keeps residual `rho12`, ordinary
group-level slope correlations, and structured slope correlations in separate
reporting rows.

## GitHub Issue Maintenance

#446 is the direct issue for this plan. #59 remains open for the broader Phase
18 simulation programme. #444 remains open for the reader-facing tutorial and
release-ledger pass. #437 remains open for the cross-repo scout protocol and is
not evidence that sister-package performance transfers to `drmTMB`.

## What Did Not Go Smoothly

PR #445 still contains an older broad Phase 6c branch and is not mergeable. This
slice therefore re-records the #446 handoff as a small branch from current
`origin/main`, without trying to salvage the broad branch.

## Team Learning

Fisher: diagnostic pilots and formal coverage grids need different claim
levels. Curie: every new pilot needs artifact tables before a report consumes
it. Grace: manual Actions jobs need bounded workers, explicit timeouts, and
uploaded artifacts. Rose: stale-claim scans should look for unsupported
recovery, coverage, and power language, not just missing files.

## Known Limitations

This slice does not run any new simulation grid. It does not add a new Actions
task, DGP, fitter, summariser, report, or artifact writer. It does not promote
correlated non-Gaussian slopes, multiple structured slopes, random effects in
`rho12`, residual-scale structured slopes, q > 2 direct correlation intervals,
or mixed-response bivariate models.

## Next Actions

1. Implement the registry preflight and one diagnostic pilot from the #446 run
   order.
2. Keep #444 for the reader-facing tutorial and release-ledger pass after the
   pilot status is stable.
3. Keep large final power or coverage grids blocked until diagnostic pilots
   pass the stop rules and MCSE targets are affordable.
