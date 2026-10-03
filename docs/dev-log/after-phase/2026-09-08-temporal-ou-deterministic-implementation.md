# After Task: Gaussian temporal OU deterministic implementation

## Goal

Add a native Gaussian OU temporal provider for irregular numeric elapsed time while keeping stable series intercepts, temporal process variation, and residual `sigma` distinct. Do not make an OU Wald or campaign claim while the inherited AR1 C1 boundary remains unresolved.

## Implemented

`temporal(1 | id, time = elapsed, structure = "ou")` now fits a stationary positive-decay OU process, optionally beside `(1 | id)`. The parser preserves AR1 behavior, accepts finite numeric OU time, preserves supplied elapsed gaps and observation order, and rejects duplicate or incomplete keys. Public temporal output labels OU's positive decay rate; OU Wald requests return an explicit unavailable-inference error.

## Mathematical Contract

For a gap `d`, the standardized OU transition has correlation `exp(-decay * d)` and variance `1 - exp(-2 * decay * d)`. The native code retains the stationary first-state density and transition normalizers. The ordinary intercept, OU process, and residual noise are independent.

## Files Changed

The implementation changes `R/parse-formula.R`, `R/temporal.R`, `R/drmTMB.R`, and `src/drmTMB.cpp`; methods are synchronized in `R/methods.R` and `R/profile.R`. Tests, an Unlazy ledger, and an executable runner are in `tests/testthat/test-temporal-ou*.R`, `tools/temporal-ou-gates.R`, and `docs/dev-log/plans/2026-09-08-temporal-ou/`. Formula, likelihood, README, NEWS, limitation, roadmap, pkgdown, and vignette text were updated; `man/temporal.Rd` was regenerated.

## Checks Run

`devtools::test(filter = "temporal", reporter = "location")` passed the AR1 and OU temporal suites. The focused OU suite passed dense likelihood, score, two finite-difference Hessians, coefficient covariance, parser failures, method/simulation, and mutation checks. The source-loaded vignette render passed and contained the OU section. `git diff --check` passed. `R CMD build .` returned only its initial DESCRIPTION line and created no observed tarball in this session, so G12 remains pending.

## Tests Of The Tests

The initial OU parser test failed before parser support. The initial OU label test failed before labels were structure-aware. The interval test failed before the explicit calibration guard. The dense oracle is independent of the native sequential likelihood; mutation references detect compressed gaps, shared series, and omitted normalizers. Invalid duplicate, missing, and non-numeric metadata have direct rejection tests.

## Consistency Audit

The status inventory was searched for `temporal(`, `Temporal AR1`, `OU`, and `Ornstein` in README, NEWS, limitations, roadmap, grammar, vignettes, R, tests, and pkgdown configuration. Current status entries now name OU point fitting and the deferred OU Wald path.

## GitHub Issue Maintenance

Open-issue search was attempted with `gh issue list --state open --limit 100 --search temporal`; no issue output was available in this session. No remote issue was created or changed.

## What Did Not Go Smoothly

CppAD in this TMB build does not provide an `expm1()` overload, so a proposed short-gap numerical rewrite failed compilation and was reverted. The retained AR1 C1 pilot still has an interior-process but residual-SD boundary with an indefinite observed Hessian; it is kept as the shared OU inference blocker.

## Team Learning

Elapsed-time admission checks must retain fractional pairwise lags; truncating them can hide required variation even when the likelihood itself uses numeric gaps. The existing AR1 integer-gap contract must remain explicit when shared layout code widens to numeric OU time.

## Known Limitations

G7--G9 and G12--G15 remain pending: no OU Wald claim, retained OU recovery, pilot, package check, independent reviews, or campaign exists. Forecasting, `newdata`, non-Gaussian families, temporal slopes, negative OU correlation, and gllvmTMB implementation remain deferred.

## Next Actions

Diagnose the inherited AR1 residual-boundary geometry before enabling OU mean-coefficient Wald intervals. Then run retained OU recovery and the authorized pilot, repair the local build/check evidence path, obtain independent mathematical and reader reviews, and request separate campaign authority only if the measured evidence supports it.
