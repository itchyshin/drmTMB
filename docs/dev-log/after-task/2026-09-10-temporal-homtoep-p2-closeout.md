# After Task: Homogeneous Toeplitz P2 closeout

## Goal

Close the Gaussian marginal homogeneous Toeplitz temporal covariance phase with
a usable fixed-mean profile interface, retained calibration evidence, and an
honest reader-facing scope.

## Implemented

`temporal(1 | id, time = occasion, structure = "homtoep")` fits a Gaussian
total within-series covariance on a common complete equally spaced panel of
three to twelve occasions. Mean-coefficient likelihood profiles are publicly
available in the retained primary-cell scope. Wald covariance and intervals
remain unavailable.

## Mathematical Contract

For series \(i\), \(y_i \sim N(X_i\beta, \sigma_T^2 R)\), where \(R\) is a
positive-definite homogeneous Toeplitz correlation matrix. Its free lag
correlations use partial-autocorrelation coordinates. There is no temporal
latent mode or separate iid residual scale in this one-row-per-ID--occasion
provider, because that wider decomposition is not identifiable here.

## Files Changed

The repair aligns `R/temporal.R`, `R/methods.R`, and `R/check.R`; regenerates
profile help; adds native/profile and factor-label parser regressions; and
records the exact closeout in the Unlazy ledger and check log.

## Checks Run

`T3-1`, `T3-3`, `T3-4`, and `T3-11` passed after the repair. The retained
campaign reverify remains `T3-10` on Totoro. A default `R CMD build .` followed
by `R CMD check --no-manual` completed tests and vignette rebuilding with two
known source-layout warnings described in the closeout receipt.

## Tests Of The Tests

Before the repair, the revised native test failed because `check_drm()` still
said profile calibration was pending. It now checks finite public profiles,
the qualified-profile/deferred-Wald distinction, and the dense marginal
likelihood, score, Hessian, whitening, and seeded simulation identities. The
parser test confirms an incomplete factor-labelled site reports its supplied
label rather than an internal index.

## Consistency Audit

The audit searched `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`docs/design/03-likelihoods.md`, `vignettes/formula-grammar.Rmd`,
`vignettes/temporal-random-effects.Rmd`, `_pkgdown.yml`, `R`, `man`, and
`tests` for `temporal`, `homtoep`, `profile`, and deferred interval wording.
The formula grammar, likelihood design, vignette, reference help, and runtime
diagnostics agree: homogeneous Toeplitz is a `mu` marginal covariance with
constant `sigma ~ 1`, and irregular elapsed time is directed to OU.

## GitHub Issue Maintenance

`gh issue list --state open --search temporal --limit 50` found only #1302,
the separate phylogenetically correlated temporal OU series work. No issue was
opened or changed for this completed homogeneous Toeplitz phase.

## What Did Not Go Smoothly

The first independent review exposed a stale refusal expectation and an
overbroad Wald-deferral message. An initial package-check tarball was built
with `--no-build-vignettes`, which made the same two source-layout warnings
less interpretable. Rebuilding without that flag confirmed that vignette
rendering succeeds; the tar still intentionally excludes generated `inst/doc`
outputs.

## Team Learning

Opening an inference route requires a corresponding native-method regression:
otherwise an earlier refusal test can silently contradict the public API. Error
messages must retain the user's factor labels, not internal series indices.

## Known Limitations

This phase does not support an ordinary intercept with homogeneous Toeplitz,
heterogeneous scale by occasion, temporal random slopes, non-Gaussian models,
forecasting, `newdata`, or temporal effects in `sigma`. Its campaign is a
fixed-primary-cell profile qualification, not a universal temporal-inference
claim.

## Next Actions

Do not write the planned temporal-capability article yet. Its prerequisite is
a separately designed and validated temporal `sigma` (scale) capability for
every structure it teaches: AR1, OU, homogeneous and heterogeneous Toeplitz,
and any later seasonal, random-walk, ARMA, or temporal Matérn route. Each must
have a clear scale interpretation, dense-oracle tests, simulation calibration,
and reader workflow before it appears in that article.
