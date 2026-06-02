# After Task: Random-Slope Capacity Closeout

## Goal

Close #128 by making the current random-effect slope capacity table explicit
and issue-linked before larger Phase 18 simulations use those rows.

## Implemented

The closeout is documentation/status work.
`docs/design/59-structural-slope-and-non-gaussian-map.md` now names #128 as
its closeout ledger, and ROADMAP Slice 77 records the current capacity boundary
across ordinary `mu`, residual-scale `sigma`, random-effect scale, bivariate
slope-only, structured Gaussian one-slope, selected non-Gaussian `mu`, and
count structured q=1 routes.

## Mathematical Contract

No likelihood, formula grammar, estimator, or extractor changed. The task
records which existing model surfaces are fitted and which neighbouring cells
remain planned:

- ordinary Gaussian `mu` random intercepts, independent slopes, one-slope
  correlated blocks, and q > 2 numeric multi-slope blocks are fitted;
- Gaussian residual-scale random intercepts and independent numeric slopes are
  fitted on log-`sigma`;
- `sd(group) ~ x_group` targets unlabelled Gaussian `mu` random-intercept SDs,
  not coefficient-specific slope SDs;
- bivariate Gaussian slope-only matching `mu1`/`mu2` blocks are fitted, while
  intercept-plus-slope q4 and p8/q8 endpoint covariance remain planned;
- `phylo()`, `spatial()`, `animal()`, and `relmat()` each fit one numeric
  univariate Gaussian `mu` slope as independent structured intercept and slope
  fields;
- selected non-Gaussian `mu` independent slopes are fitted, while correlated
  non-Gaussian slopes and broad non-Gaussian structured slopes remain planned.

## Files Changed

- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-01-random-slope-capacity-closeout.md`

## Checks Run

```sh
air format docs/design/59-structural-slope-and-non-gaussian-map.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-01-random-slope-capacity-closeout.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n '#128|Random-effect slope capacity closeout|ordinary Gaussian `mu`|residual-scale `sigma`|bivariate slope-only|structured Gaussian one-slope|p8/q8|coefficient-specific `sd`|correlated non-Gaussian slopes' README.md ROADMAP.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/dev-log/known-limitations.md tests/testthat
rg -n 'Gaussian location-scale models are implemented|Residual-scale random intercepts|Bivariate Gaussian location-scale-coscale models|Phylogenetic, coordinate-spatial|corpairs\(\) currently reports only correlations' docs/dev-log/known-limitations.md
rg -n 'Gaussian mu supports q > 2|Gaussian sigma supports independent residual-scale random slopes|random slopes in bivariate models remain planned|non-Gaussian mu supports independent numeric random slopes|Phase 18 random-slope workflow plan returns admitted rows' tests/testthat
rg -n 'random effects in `rho12` (are )?(fitted|implemented)|residual-scale structured slopes (are )?(fitted|implemented)|p8/q8 (is|are) (fitted|implemented|supported)|correlated non-Gaussian slopes (are )?(fitted|implemented)|coefficient-specific `sd`.*(fitted|implemented)' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat || true
git diff --check
```

Results:

- `pkgdown::check_pkgdown()` returned `No problems found`.
- The positive capacity scans found the issue-linked design map, ROADMAP row,
  known-limitations entries, and current test evidence for ordinary Gaussian
  q > 2, Gaussian residual-scale slopes, bivariate planned-boundary tests,
  selected non-Gaussian `mu` slopes, and Phase 18 random-slope workflow rows.
- The stale wording scan found no current claim that random effects in
  `rho12`, residual-scale structured slopes, p8/q8 endpoint covariance,
  correlated non-Gaussian slopes, or coefficient-specific `sd()` slope models
  are fitted.
- `git diff --check` passed.

## Tests Of The Tests

This task added no new runtime behaviour. Existing source evidence includes
ordinary Gaussian random-slope tests, Gaussian residual-scale slope tests,
bivariate planned-boundary tests, structured Gaussian one-slope tests, selected
non-Gaussian `mu` slope tests, and Phase 18 random-slope registry tests. The
stale scan checks that planned neighbours are not worded as fitted.

## Consistency Audit

README stable-core rows, `docs/dev-log/known-limitations.md`,
`docs/design/59-structural-slope-and-non-gaussian-map.md`, and ROADMAP Phase 6c
now agree that #128 is a capacity-status closeout, not a new implementation
slice.

## GitHub Issue Maintenance

This PR closes #128. Broader remaining surfaces stay in existing issues: #33
for structured/bivariate random slopes, #5 for larger covariance blocks, #59
for simulation evidence, #60 for comparators, and #444 for reader-facing
tutorial/release-ledger work.

## What Did Not Go Smoothly

The evidence is distributed across many earlier slices. The closeout therefore
links the existing map and tests instead of copying every test name into the
README.

## Team Learning

Capability closeouts should name the issue and the status table explicitly.
That avoids leaving an issue open after the code has already landed in smaller
slices.

## Known Limitations

The remaining planned cells are unchanged: residual-scale structured slopes,
coefficient-specific `sd()` slope models, bivariate intercept-plus-slope q4,
p8/q8 endpoint covariance, slope-specific `corpair()` regressions, correlated
non-Gaussian slopes, non-Gaussian structured slopes, and random effects in
`rho12`.

## Next Actions

Use #444 for the reader-facing tutorial/release ledger and #59/#60 for
simulation and comparator evidence.
