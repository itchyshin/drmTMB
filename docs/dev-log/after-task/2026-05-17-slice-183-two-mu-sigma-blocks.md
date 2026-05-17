# After Task: Slice 183 Two Mu-Sigma Blocks

## Goal

Prototype two independent matched univariate `mu`/`sigma` random-intercept
covariance blocks before adding stronger recovery and interval checks.

## Implemented

The R-side labelled covariance builder no longer caps univariate matched
`mu`/`sigma` random-intercept covariance at one block. Models can now fit
independent matched label/group pairs such as:

```r
bf(
  y ~ x + (1 | p | id) + (1 | q | site),
  sigma ~ z + (1 | p | id) + (1 | q | site)
)
```

Each matched block gets its own `eta_cor_mu_sigma` parameter, its own
`corpars$mu_sigma` entry, and its own `corpairs(class = "mean-scale")`,
`summary()`, and `profile_targets()` row.

## Mathematical Contract

For independent grouping factors `id` and `site`:

```text
mu_ijk = X_mu beta_mu + b_id[j] + b_site[k]
log(sigma_ijk) = X_sigma beta_sigma + a_id[j] + a_site[k]

cor(b_id[j], a_id[j]) = rho_id
cor(b_site[k], a_site[k]) = rho_site
```

The two mean-scale blocks are independent. This slice does not introduce
slope-level mean-scale covariance or a larger joint block tying all grouping
factors together.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/04-random-effects.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-183-two-mu-sigma-blocks.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-gaussian-random-intercepts.R NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/04-random-effects.md docs/design/33-phase-6c-core-random-effects.md`: passed.
- `Rscript -e 'devtools::test(filter = "gaussian-random-intercepts", reporter = "summary")'`: passed.
- `Rscript -e 'devtools::test(filter = "profile-targets|gaussian-random-intercepts|summary", reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new test fits two crossed matched blocks, checks `n_cors = 2`, verifies
separate `sdpars$mu`, `sdpars$sigma`, and `corpars$mu_sigma` rows, checks
`corpairs(class = "mean-scale")` and `summary()` row names, and confirms that
both correlation targets are direct profile-ready `eta_cor_mu_sigma` rows.

## Consistency Audit

The NEWS entry, roadmap, formula grammar, random-effects design note, and
Phase 6c status note now say "one or more independent matched blocks" rather
than "the first" or "only one" univariate mean-scale block.

## What Did Not Go Smoothly

The TMB likelihood already accepted multiple `eta_cor_mu_sigma` values. The
remaining cap lived in the R-side builder, so the main risk was preserving all
existing validation messages while changing one-block logic into a loop.

## Team Learning

Ada kept the slice to independent intercept-level blocks. Boole checked the
label/group syntax remains the existing `(1 | label | group)` grammar. Gauss
and Noether confirmed the C++ transform already indexes multiple
`eta_cor_mu_sigma` parameters. Fisher and Curie required reporting and
profile-target coverage, while leaving stronger recovery and interval coverage
for Slice 184. Pat and Darwin wanted the docs to say these are group-level
mean-scale correlations, not residual `rho12`. Grace kept the validation
focused because the likelihood algebra itself did not change.

## Known Limitations

Slope-level mean-scale covariance, correlated residual-scale slope blocks,
bivariate random slopes, and large all-endpoint covariance blocks remain later
slices. Slice 184 should add stronger recovery, diagnostics, and interval
checks for the two-block surface.

## Next Actions

Slice 184 should stress the two-block surface with recovery thresholds,
summary/profile interval checks, and weak-identification diagnostics before
the bivariate random-slope policy in Slice 185.
