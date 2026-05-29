# After Task: Bootstrap Log-Scale Positive Intervals

## Goal

Turn Claude's GLLVM.jl bootstrap-SD suggestion into a small, verified
`drmTMB` interval change without broadening the bootstrap surface.

## Implemented

`confint(..., method = "bootstrap")` now stores each refit's link-scale target
estimate alongside the response-scale estimate. Direct positive targets with
`transformation = "exp"` take percentile endpoints on the fitted log scale and
then use the existing `exp` response-scale transformation.

Fixed-effect targets and direct correlation targets keep their previous target
scales. This slice does not add bootstrap intervals to `summary()`,
`corpairs()`, prediction tables, or derived summaries.

## Mathematical Contract

For a positive direct target such as a residual scale or random-effect SD,
the refit draw is treated as

```text
theta_b = log(s_b)
```

The bootstrap interval is

```text
[exp(Q_alpha/2(theta_b)), exp(Q_1-alpha/2(theta_b))]
```

rather than

```text
[Q_alpha/2(s_b), Q_1-alpha/2(s_b)].
```

This keeps the interval positive and aligns bootstrap scale handling with the
existing Wald and profile transformations for direct `exp` targets.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `README.md`
- `NEWS.md`
- `man/confint.drmTMB.Rd`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-bootstrap-log-scale-positive-intervals.md`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-targets.R README.md NEWS.md docs/design/12-profile-likelihood-cis.md
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
git diff --check
rg -n "bootstrap.*raw|raw.*bootstrap|bootstrap.*log|log-scale.*bootstrap|positive scale|SD bootstrap|percentile" README.md NEWS.md ROADMAP.md docs/design R tests/testthat man --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'bootstrap log scale SD confint percentile' --limit 20 --json number,title,state,url,labels
```

Result: `test-profile-targets.R` passed, `git diff --check` was clean, and the
GitHub issue search returned `[]`.

## Tests Of The Tests

The new regression test uses deliberately skewed positive draws where
raw-scale percentiles and log-scale percentiles differ. It asserts that
`transformation = "exp"` uses the log-scale quantiles and that
`transformation = "linear_predictor"` keeps the raw target values. Existing
bootstrap smoke tests in the same file continue to exercise real simulate/refit
paths for scale, random-effect SD, and structured targets.

## Consistency Audit

The public help, README uncertainty paragraph, NEWS entry, and profile-CI design
doc now say that positive scale and SD bootstrap intervals use log-scale
percentiles before exponentiating endpoints. The stale-wording scan found
compatible bootstrap references rather than contradictory raw-scale claims.

## GitHub Issue Maintenance

The issue search for bootstrap log-scale, SD, `confint()`, and percentile
overlap returned `[]`. No issue action was needed.

## What Did Not Go Smoothly

The first `devtools::document()` run produced unrelated roxygen churn in
`DESCRIPTION` and two generated Rd files. I removed that noise and kept only
the generated `confint.drmTMB` help change.

## Team Learning

Ada kept the slice to one interval behavior. Fisher treated the GLLVM.jl result
as a scale-handling hint rather than a `drmTMB` coverage claim. Grace kept the
validation focused on `test-profile-targets.R` and `git diff --check`. Rose
checked that docs describe the new bootstrap scale without overclaiming
coverage.

No spawned subagents were running.

## Known Limitations

This change does not prove bootstrap coverage for SD targets. It also does not
route bootstrap intervals through `summary()`, `corpairs()`, prediction tables,
q4 derived correlations, repeatability, or phylogenetic signal. Those remain
separate design and validation slices.

## Next Actions

Continue the autonomous queue with the next bootstrap/profile hardening slice:
either add a small direct-target bootstrap draw-scale audit for correlation
targets or move to the sparse-phylo source-map slice if the interval surface is
stable enough for now.
