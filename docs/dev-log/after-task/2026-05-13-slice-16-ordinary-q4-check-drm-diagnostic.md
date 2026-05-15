# After Task: Slice 16 Ordinary q4 check_drm Diagnostic

## Goal

Make the new ordinary all-four bivariate q=4 covariance block visible in
`check_drm()` before users interpret its six latent correlations.

## Implemented

`check_drm()` now adds a `biv_q4_random_effect_covariance` row when a bivariate
Gaussian fit contains an implemented ordinary q=4 group-level covariance block
across `mu1`, `mu2`, `sigma1`, and `sigma2`. The diagnostic reports block
count, group count, minimum fitted observations per group, singleton groups,
the smallest location SD relative to its residual scale, the smallest
log-`sigma` random-effect SD, the maximum absolute latent correlation, and the
active `rho_boundary`.

## Mathematical Contract

The diagnostic does not change the likelihood. It checks whether the fitted
latent covariance block

```text
u_j = [b_mu1_j, b_mu2_j, a_sigma1_j, a_sigma2_j]'
u_j ~ MVN(0, Sigma_id)
```

has enough replication, non-negligible component SDs, and correlations away
from the boundary to support interpretation.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "check-drm", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm|biv-gaussian|summary|corpairs", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new test fits a real q4 bivariate Gaussian block and checks that
`check_drm()` returns exactly one q4 diagnostic row. It then mutates the fitted
object to force a near-boundary latent correlation warning and a tiny
log-`sigma` SD note, so both diagnostic branches are covered without relying on
fragile optimizer behavior.

## Consistency Audit

Updated the `check_drm()` roxygen text, regenerated `man/check_drm.Rd`, and
synchronized NEWS, the phylo/spatial common-math diagnostic inventory, and known
limitations.

## What Did Not Go Smoothly

The first q4 fixture used fewer groups and did not converge reliably. The final
test uses the same stable q4 scale as the bivariate likelihood test. The test
does not require the whole fit to have a positive-definite Hessian, because q4
covariance Hessians can remain weakly identified in small examples.

## Team Learning

Diagnostics should summarize q4 as a block rather than only through the older
pairwise `mu1`/`mu2`, `sigma1`/`sigma2`, and same-response mean-scale checks.

## Known Limitations

This is a first-pass diagnostic. It does not add q4 profile intervals,
simulation calibration for all diagnostic thresholds, phylogenetic q4
diagnostics, or spatial q4 diagnostics.

## Next Actions

Add q4 profile-target status hardening or move to the next Family B structured
SD slice, depending on which path is safer for the overnight run.
