# After Task: Same-Response Mean-Scale Slope Covariance

## Goal

Implement the first same-response bivariate Gaussian `mu`/`sigma` random-slope
covariance slice, with source-level recovery evidence and status docs that do
not promote it to formal simulation evidence.

## Implemented

`biv_gaussian()` now fits one matching same-response slope-only labelled pair,
for example `mu1 = y1 ~ x + (0 + x | p | id)` with
`sigma1 = ~ x + (0 + x | p | id)`, or the analogous `mu2`/`sigma2` pair. The
fitted row is exposed through `sdpars$mu`, `sdpars$sigma`,
`corpars$mu_sigma`, `corpairs(class = "mean-scale-slope")`,
`summary()$parameters`, `profile_targets()`, and `check_drm()`.

Cross-response `mu1`/`sigma2` or `mu2`/`sigma1` pairs, mismatched
coefficients, univariate labelled `sigma` slopes, multiple same-response slope
pairs, random effects in `rho12`, and all-four p8/q8 endpoint blocks remain
closed.

## Mathematical Contract

The new slice is a q2 latent group-level covariance, not residual `rho12`. For a
same-response `mu1:x` and `sigma1:x` pair, the scale random effect enters
`log(sigma1)` and is conditionally transformed as
`sd_sigma * (rho * z_mu + sqrt(1 - rho^2) * z_sigma)`. The location-slope
effect enters `mu1` through the matching `x` design column. The residual
coscale `rho12` remains a row-level residual correlation.

## Files Changed

- Core parser and builder: `R/drmTMB.R`.
- Extractor documentation: `R/methods.R`, `man/corpairs.Rd`.
- Source tests: `tests/testthat/test-biv-gaussian.R`.
- User and status docs: `README.md`, `NEWS.md`, `ROADMAP.md`,
  `vignettes/implementation-map.Rmd`, and the affected design notes under
  `docs/design/`.
- Development records: `docs/dev-log/check-log.md` and this report.

## Checks Run

- `air format R/drmTMB.R R/methods.R tests/testthat/test-biv-gaussian.R`
  completed without errors.
- `Rscript -e "devtools::document()"` completed and wrote `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"` returned 1,312
  passes, no failures, warnings, or skips in 180.2s.
- `git diff --check` passed.

The required stale-wording scans were:

- `rg -n 'same-response location-scale slope covariance.*(remain|planned|closed|unsupported)|same-response.*mu.*/.*sigma.*(remain planned|closed|unsupported)|same-response.*mu.*sigma.*(remain planned|closed|unsupported)' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man`
- `rg -n 'p8/q8.*(fitted|implemented|supported|ready_grid|ready_existing_task)|q8.*(fitted|implemented|supported|ready_grid|ready_existing_task)|all-four p8/q8.*(fitted|implemented|supported)|all-four.*endpoint.*(fitted|implemented|supported)' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man`
- `rg -n 'same-response q2|same-response.*source-tested|same-response.*formal Actions|mean-scale-slope|cor\\(mu1:x,sigma1:x' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man`

They returned only intended current-status, source-test, or blocked-boundary
rows.

## Tests Of The Tests

The new source test uses a deterministic data generator with known `mu1:x`
and `sigma1:x` group effects and a known latent correlation. It checks the
assembled TMB data, reconstructs the conditional latent transform on the R side,
fits the model, checks fixed effects, SDs, and the correlation within focused
tolerances, and verifies `corpairs()`, `profile_targets()`, and `check_drm()`.

Malformed-input coverage still rejects cross-response slope sharing and now
rejects mismatched `mu`/`sigma` coefficients with a coefficient-specific
message.

## Consistency Audit

README, ROADMAP, NEWS, formula grammar, likelihood notes, the pre-simulation
readiness matrix, the capability worklist, the validation-debt register, the
simulation programme, and the implementation-map vignette now say the same
thing: same-response q2 `mu`/`sigma` slope covariance is fitted with focused
source recovery checks, but it does not yet have formal Actions artifacts or
power-grid admission. All-four p8/q8 endpoint covariance remains planned.

## GitHub Issue Maintenance

Issue #491 is the active local-R work queue. The GitHub connector could read the
issue but returned `403 Resource not accessible by integration` when asked to
comment. The local `gh` CLI succeeded:
<https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4636646218>.

## What Did Not Go Smoothly

Several design notes had line wraps that made broad patches fail; those were
fixed with smaller exact patches. The GitHub connector lacked write permission,
so issue maintenance had to use the local CLI.

## Team Learning

Rose and Fisher should keep the distinction between source-tested support and
formal Actions recovery evidence visible in every status surface. Grace should
treat a successful focused source test as implementation evidence, not
power-grid admission.

## Known Limitations

No formal same-response q2 recovery Actions lane was added in this task. Full
package tests, `devtools::check()`, `pkgdown::check_pkgdown()`, and
`pkgdown::build_site()` were not rerun. The feature is intentionally limited to
one matching same-response slope-only pair.

## Next Actions

Add a formal recovery lane for the same-response q2 `mu`/`sigma` slope route,
then audit convergence, Hessian status, warnings, fixed-effect recovery,
random-effect SD recovery, and correlation recovery before using this surface in
power-grid claims. The all-four p8/q8 endpoint should wait until that evidence
exists.
