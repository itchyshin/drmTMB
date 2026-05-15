# After Task: Slice 54 Response-Scale Row Profiles

## Goal

Close the row-specific profile interval surface for currently fitted response
parameters before moving to random-effect SD and correlation interval
integration. The slice should verify `newdata` profile intervals for
`sigma`, `sigma1`, `sigma2`, residual `rho12`, and fitted q=2 ordinary or
phylogenetic `corpair()` values, while rejecting ambiguous requests early.

## Implemented

- Added bivariate `sigma1` and `sigma2` `newdata` profile tests with two
  supplied rows.
- Added explicit ambiguity tests for multiple `parm` values, non-data-frame
  `newdata`, and empty `newdata`.
- Extended the q=2 phylogenetic `corpair()` smoke test to call
  `confint(..., newdata = ...)` and verify the response-scale interval.
- Updated `NEWS.md`, `ROADMAP.md`, and
  `docs/design/12-profile-likelihood-cis.md` to mark Slice 54 as tested.

## Mathematical Contract

For a supplied row `x_i`, `confint(..., newdata = x_i)` profiles the scalar
linear predictor

```text
eta_i = x_i^T beta
```

with all other fitted parameters treated as nuisance parameters. The returned
interval is transformed to the public scale:

- `sigma`, `sigma1`, `sigma2`: `exp(eta_i)`;
- residual `rho12`: guarded residual-correlation transform;
- q=2 ordinary or phylogenetic `corpair()`: guarded latent random-effect
  correlation transform.

This is not a profile interval for the `corpairs()` summary mean/range. Those
summary rows still report `newdata_required` because they are aggregates over
many fitted group or species correlations.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-phylo-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-slice-54-response-scale-row-profiles.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format tests/testthat/test-profile-targets.R tests/testthat/test-phylo-gaussian.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-slice-54-response-scale-row-profiles.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "profile-targets|biv-gaussian|phylo-gaussian", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `git diff --check`
- `rg -n "Slice 54|Response-Scale Row Profiles|newdata_required|sigma1\\[cool\\]|typical_species|must be one distributional-parameter|ordinary or phylogenetic q=2|ambiguous newdata" NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-slice-54-response-scale-row-profiles.md tests/testthat/test-profile-targets.R tests/testthat/test-phylo-gaussian.R pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`

## Consistency Audit

The source roadmap and design note now say that q=2 ordinary and phylogenetic
`corpair()` row profiles are covered. The extractor boundary remains explicit:
`corpairs(conf.int = TRUE)` can attach direct intervals only for profile-ready
constant rows, while modelled q=2 `corpair()` summaries need `newdata`.

## Team Learning

- Ada should keep Slice 54 as an evidence slice, not a likelihood rewrite.
- Boole should keep `parm` single-valued when `newdata` is supplied.
- Gauss should continue to profile one scalar linear predictor per supplied row.
- Noether should keep the response transformation attached to the distributional
  parameter link.
- Fisher should treat `corpairs()` aggregate rows and `newdata` row profiles as
  different inferential targets.
- Pat should see a clear error before TMB runs when `newdata` is malformed.
- Grace should rerun the broader profile/bivariate/phylogenetic suite after
  formatting and docs updates.
- Rose should watch future docs for accidental claims that q=4 or aggregate
  `corpairs()` intervals are covered by this row-profile route.

## Known Limitations

- Row-specific profiles are one target at a time and can be slow over large
  grids.
- q=4 latent correlations, ICCs, repeatability, phylogenetic signal, and
  arbitrary nonlinear contrasts remain derived or planned interval targets.
- The current slice adds coverage; it does not add automatic profile plotting,
  `tmbroot()` intervals, or fallback bootstrap intervals.

## Next Actions

Slice 55 should stabilize direct profile intervals for currently fitted
ordinary, phylogenetic, and spatial random-effect SD/correlation targets and
make sure `summary()` and `corpairs()` attach intervals only where the target
is profile-ready.
