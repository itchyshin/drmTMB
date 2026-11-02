# After task: live check of the reopened Julia ordinary SD routes

Date: 2026-11-02. Lane: general-sd-regression (drmTMB HEAD 1d23c75da), paired with
the DRModels.jl worktree general-sd-julia (HEAD 5ac051eed, read-only).

## Goal

Commit 53504dd39 reopened the Julia bridge fence for ordinary (1|g) and (0+x|g) mu
bars that carry an sd() formula, for Poisson, NB2, Gamma, Beta and Binomial.
Commit 6a7bfbc79 fixed the selected-coefficient label echo, but only
test-julia-poisson-sd.R had been run live (30 pass, 0 fail). This task ran the
other four ordinary-route test files live on the Mac, one R process at a time.

## Result

All four files pass live with no failures, errors or skips. Counts are
expectations from the testthat result data frame.

| File | Route | tests | expectations | fail | error | skip |
|---|---|---|---|---|---|---|
| test-julia-gamma-sd.R | Gamma ordinary, plus relmat and phylo-style routes in the same file | 6 | 54 | 0 | 0 | 0 |
| test-julia-negbinomial-sd.R | NB2 ordinary, plus relmat in the same file | 3 | 35 | 0 | 0 | 0 |
| test-julia-beta-sd.R | Beta ordinary | 3 | 27 | 0 | 0 | 0 |
| test-julia-binomial-sd.R | Binomial ordinary, links, crossed-adjacent payloads | 9 | 155 | 0 | 0 | 0 |

Together with Poisson (30/0) all five reopened families are now live verified.

## Failure classification

There were no failures, so there is nothing to classify as label echo, engine gap
or stale expectation, and no R-side change and no Julia patch is needed.
This batch is documentation only.

## Native versus Julia agreement

The tests do not print differences. They assert agreement within fixed
tolerances, and all assertions held:

- Gamma: SD-formula coefficients and row SDs within 0.15 to 0.25 relative of the
  native TMB fit on the simulated routes; fitted SD equals predict() to 1e-10;
  one route compares at 1e-3.
- NB2: SD coefficients within 0.4 relative on the ordinary route, and within 0.1
  on the structured routes; fitted SD equals predict() to 1e-10.
- Beta: SD coefficients within 0.2 (intercept route) and 0.25 (slope route),
  predict() within 0.25 of native; fitted SD equals predict() to 1e-10.
- Binomial: payload link and response scales agree exactly; fitted SD agrees with
  the public object and prediction.

The tolerances are loose because the fits are small simulations where the
Julia and TMB optima differ slightly. They were not changed.

## Observations that are not failures

- Beta test emits one deprecation warning: beta() is deprecated in 0.7.1 and the
  test (test-julia-beta-sd.R line 18) should use beta_family(). Not fixed here, to
  keep this change surgical.
- Binomial runs emit DRModels "Hessian is numerically singular" warnings from
  vcov_guard.jl at variance boundaries (one coordinate flagged, rcond about 1e-9
  to 1e-17). Standard errors there are untrustworthy; the tests do not assert on them.
- Bridge is live-verified on the Mac only; nothing was run on Totoro (segfault).

## What this does not cover

Only the ordinary single-bar routes in these four files. Structured, q2, relmat
and spatial routes are covered by their own test files, which were not re-run.
