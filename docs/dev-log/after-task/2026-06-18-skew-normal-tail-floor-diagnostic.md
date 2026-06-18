# Skew-Normal Tail-Floor Diagnostic

## Task

Advance the `drmTMB#59` numerical-guard sensitivity lane with a narrow
source-level diagnostic for the skew-normal `log(Phi(alpha * z) + 1e-300)`
tail floor. The goal was to record what the guard does before any later
fit-level skew-normal tail-floor stress study uses it in a simulation claim.

## What Changed

Added
`docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-diagnostic/`
with a reproducible runner, source-level diagnostic grid, cell summary,
one-row run summary, session information, and README.

Updated `docs/design/176-numerical-guard-simulation-audit.md` so the
skew-normal tail-floor diagnostic sits beside the banked `log(sigma)` clamp
and Student-t finite-variance diagnostics. Also updated the capability matrix,
completion worklist, dashboard status, dashboard sweep, and check log while
keeping the mission-control metrics unchanged: 25/68 banked or verified, 1
active, 0 blocked, and 1 deferred.

The dashboard Grace row records the current post-#618 main evidence:
R-CMD-check run `27746395391` passed on macOS, Ubuntu, and Windows for
`5c019fd6`, and pkgdown run `27747933180` built and deployed for the same main
SHA.

## Result

The floor starts to dominate at about `alpha * z = -37.0471`, where
`Phi(alpha * z)` is approximately `1e-300`. In the ordinary source-level grid
from `alpha * z = -8` through `8`, the maximum absolute log-CDF lift was
`4.434133e-17`. In the near-floor grid, the largest lift was `35.78169` log
units at `alpha * z = -38`. In the floor-dominated extreme-tail grid, the
largest lift was `2514.526` log units at `alpha * z = -80`, because the guard
caps the tail contribution at `log(1e-300)`.

## Verification

Verification reran the artifact, checked the focused skew-normal density
contract with the package namespace loaded, validated mission-control JSON, ran
workspace and cached whitespace checks, ran `pkgdown::check_pkgdown()`,
smoke-tested the served dashboard, and scanned the touched files for
over-claiming language.

The initial bare `testthat::test_file()` command failed because the package was
not loaded and `skew_normal()` was unavailable. The corrected command,
`Rscript -e "devtools::load_all('.', quiet = TRUE); testthat::test_file('tests/testthat/test-skew-normal-density-contract.R')"`,
passed with 22 expectations, 0 failures, 0 warnings, and 0 skips.

The boundary scan found only intentional or pre-existing guardrail language. No
new release-readiness, CRAN-readiness, coverage, power, calibrated-interval,
Julia-bridge-control, or non-Gaussian AI-REML claim was added.

The cached whitespace check caught two trailing spaces in generated
`session-info.txt`; those spaces were stripped before commit.

## Boundaries

This is source-level numerical-guard evidence only. It does not show that
fitted skew-normal estimates, standard errors, Hessian status, intervals,
coverage, power, or scientific conclusions are unchanged under strong-skew or
outlier-heavy data. It does not add random effects, structured effects,
bivariate skew-normal models, residual `rho12`, latent `skew(id)`,
profile/bootstrap interval calibration, external comparator parity, release
readiness, CRAN readiness, or Julia bridge behavior.
