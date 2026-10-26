# Zero-inflated and hurdle count `mu` random intercept (lane N1, #1451)

## 1. Goal

Owner decision 1(a) on issue #1451: zero-inflated and hurdle count models must
accept one Gaussian random intercept on `mu`. Reader: applied ecologists who
fit Salamanders-style ZINB models with a site effect, and the DRModels.jl#940
port, which uses this R implementation as its oracle.

## 2. Implemented

`bf(count ~ x + (1 | site), sigma ~ 1, zi ~ 1)` now fits for `poisson()` +
`zi`, `nbinom2()` + `zi`, and `truncated_nbinom2()` + `hu` (hurdle NB2).
The group effect enters `log(mu)`; the response density is unchanged given the
effect; TMB integrates it with the Laplace approximation (model types 8, 9, 12
in `src/drmTMB.cpp`; likelihood in `docs/design/03-likelihoods.md`).

Admitted: exactly one unlabelled `(1 | g)`, intercept-only `zi ~ 1` / `hu ~ 1`,
fixed-effect `sigma`, complete data. Rejected with a message naming the
supported form: slopes, correlated blocks, a second grouping term, predictors on
`zi`/`hu`, structured (`phylo()`, `spatial()`, ...) or `sigma` random effects.

## 3a. Decisions and Rejected Alternatives

Reused the existing independent `mu` random-effect data plumbing and the
ordinary Poisson/NB2 start and map helpers rather than adding new parameters.
Did not widen to `zi`/`hu` predictors or slopes: the owner scoped the first
slice, and those need their own comparator evidence. `mu` random effects with
`mi()` were not touched (Cursor PR #1513).

## 4. Files Touched

`R/drmTMB.R` (validators, three builders, start/map helpers, TMB data for model
types 8/9/12), `src/drmTMB.cpp`, `NEWS.md`, `docs/design/01-formula-grammar.md`,
`docs/design/03-likelihoods.md`, the new
`tests/testthat/test-zi-hurdle-mu-random-intercept.R`, and six existing tests
whose old "random effects not implemented" expectation now uses the still
rejected `zi ~ x` / `hu ~ x` variant.

## 5. Evidence

Failing-first test (errors on main with "random effects are planned but not
implemented"), then a simulate-fit-check recovery test for all three families,
then a glmmTMB comparator on Salamanders (ZINB, ZIP, hurdle NB2 with
`(1 | site)`): log-likelihood to 1e-5, fixed effects to 1e-3, random-intercept
SD to 1e-3. Salamanders ZINB drives the zero-inflation intercept to the
boundary on both engines, so that comparison is on the probability scale.
Full-suite counts are in the PR description.

## 6. Open

No intervals, profiles, REML, missing-response integration, or Julia bridge
support are claimed for this route. DRModels.jl#940 ports against these tests.
