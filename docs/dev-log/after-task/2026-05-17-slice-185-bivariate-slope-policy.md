# After Task: Slice 185 Bivariate Slope Policy

## Goal

Define the first bivariate one-slope policy without opening q=8 endpoint
covariance blocks.

## Implemented

The code now gives explicit boundary messages when users try bivariate
ordinary random-slope terms in `mu1`/`mu2` or all-four
`mu1`/`mu2`/`sigma1`/`sigma2` formulas. The design docs state that the first
future bivariate slope path should be matching slope-only location terms such
as `(0 + x | p | id)` in `mu1` and `mu2`, not a q=4 intercept-plus-slope block
or a q=8 all-four location-scale endpoint.

## Mathematical Contract

The intended first slope estimand is:

```text
cor(b_mu1_xj, b_mu2_xj | p, id)
```

This is a group-level slope-slope correlation. It is not residual `rho12`.
It is also not the q=4 location block
`[b_mu1_0j, b_mu1_xj, b_mu2_0j, b_mu2_xj]` and not the q=8
location-scale endpoint that would add `sigma1` and `sigma2` intercept and
slope effects.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/04-random-effects.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-185-bivariate-slope-policy.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/04-random-effects.md docs/design/20-coscale-correlation-pairs.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new tests deliberately exercise unsupported syntax users are likely to try:
matching intercept-plus-slope `mu1`/`mu2` terms, matching slope-only
`mu1`/`mu2` terms, and all-four location-scale slope terms. They check that
the error messages point to the planned slope-only target and the q=8 endpoint
boundary.

## Consistency Audit

The roadmap, formula grammar, random-effects design note, and correlation-pair
design note now describe the same boundary: slope-only `mu1`/`mu2` is the
first future target; intercept-plus-slope and all-four location-scale slope
blocks remain later.

## What Did Not Go Smoothly

The parser already accepts slope syntax before the bivariate builder rejects
it, so the work was not a grammar change. The important fix was making the
rejection more informative and testing slope-only syntax separately.

## Team Learning

Ada kept this as a boundary slice. Boole checked that the public syntax remains
memorable. Noether separated the slope-slope estimand from residual `rho12`.
Fisher and Curie asked for explicit tests of rejected user syntax before any
fitting claim. Pat wanted the error to say what users should try later, not
only what failed. Grace kept the change documentation-only plus tests, avoiding
compiled-code risk. Rose recorded the q=4 versus q=8 distinction for future
simulation planning.

## Known Limitations

This slice does not fit bivariate random slopes. It does not add
coefficient-specific `sd1()`/`sd2()` targets, `corpairs()` slope rows,
profile targets, or simulation recovery for slope-slope correlations.

## Next Actions

Slice 186 should audit phylogenetic one-slope support and compare it directly
with the spatial one-slope lane before changing either surface.
