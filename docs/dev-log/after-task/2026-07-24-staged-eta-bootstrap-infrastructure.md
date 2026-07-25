# After Task: staged Bernoulli × NB2 full-refit bootstrap infrastructure

## 1. Goal

Implement the approved S1–S5 developer infrastructure for uncertainty of the
fixed-effect, frozen-margin Bernoulli × ordinary-NB2 association-link
coefficients, while stopping before any smoke, campaign, public interval API,
or capability claim.

## 2. Implemented

The association optimizer's existing finite `[-8,8]` domain is now explicit: a
coefficient within `0.01` of either bound is `boundary_unresolved`. The
developer-only full-refit helper simulates both responses from fitted frozen
margins, refits both original margins, then refits `associate_pairs()` for every
bootstrap draw. It retains seeds, margin statuses/messages, association status,
and diagnostics. The dormant runner fixes the 24-cell, 200-all-attempt,
399-bootstrap-attempt ladder and writes outer, bootstrap, and diagnostic ledgers
only after its explicit execution guard is enabled.

## 3a. Decisions and Rejected Alternatives

The owner selected the existing finite `[-8,8]` association-link domain, with
near-bound hits unresolved, rather than changing the estimator to an
unconstrained optimizer. The owner also selected all generated outer data sets
as the coverage denominator. Conditional stage-2 curvature, Wald intervals,
profiles, a Godambe estimator, a public `confint()` method, and direct
`biv_lognormal()` generalisation remain rejected or deferred.

## 3b. Mathematical Contract

The estimand is the sampling distribution of the two-stage plug-in
association-link coefficients \(\hat\alpha\), with derived
\(\eta(x)=0.999999\tanh(\alpha_0+\alpha_1x)\) evaluated only at `x = -1, 0,
1`. It is neither direct-likelihood `rho12`, an observed-scale correlation, nor
joint-MLE inference. The DGP uses the literal Bernoulli upper-tail threshold and
ordinary NB2 `size = sigma^-2`; an independent test oracle does not reuse the
production NB2 quantile helper.

## 4. Files Touched

- `R/associate-pairs.R` and `R/associate-pairs-bootstrap.R`
- `tests/testthat/test-associate-pairs-staged-bootstrap.R`
- `inst/sim/run/sim_run_staged_eta_bernoulli_nbinom2_bootstrap.R`
- `docs/design/239-bernoulli-nbinom2-association-regression.md`
- `docs/design/240-arc6-staged-eta-uncertainty-followup.md`
- `docs/dev-log/simulation-designs/2026-07-24-staged-eta-full-refit-bootstrap/README.md`
- `docs/dev-log/2026-07-24-staged-eta-full-refit-bootstrap-ultra-plan.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-associate-pairs-staged-bootstrap.R"); testthat::test_file("tests/testthat/test-associate-pairs-bernoulli-nb2.R")'
Rscript --no-init-file inst/sim/run/sim_run_staged_eta_bernoulli_nbinom2_bootstrap.R
git diff --check
```

The staged-bootstrap test passed 19 expectations and the existing Bernoulli ×
NB2 contract test passed 69. The runner stopped at its guard with the expected
approval message before smoke approval. After approval, an isolated installed
library ran one 2-outer × 5-bootstrap-refit cell: all 10 refits were interior,
the four required output files were non-empty, and the RDS retained all ten
score/curvature/optimization-domain diagnostics. `git diff --check` passed.

## 6. Tests of the Tests

The new DGP test independently reconstructs tail-safe NB2 quantiles using
`size = sigma^-2`, so it would detect shared production-helper errors. The
summary test makes an unavailable interval reduce all-attempt but not
conditional coverage. The integration fixture performs three full margin and
association refits, verifies that every attempt is retained, and inspects nested
diagnostics.

## 7a. Issue Ledger

No existing issue was changed. The read-only search found no open issue that
specifically owns staged Bernoulli × NB2 full-refit bootstrap infrastructure.

## 8. Consistency Audit

The stale-surface search covered `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, `docs/design/`, `R/`, and
`tests/` with `staged eta`, `full refit`, `conditional curvature`,
`unconstrained optimization`, `[-8,8]`, and `association = ~ x`. The only
user-facing status remains point-estimate-only beta support; no direct `rho12`
claim was introduced. The design prose names the finite optimizer domain and
its effect on bootstrap-draw eligibility.

## 9. What Did Not Go Smoothly

The first test run exposed incorrect expected coverage values: only one of three
available intervals covered the stated truth. The corrected test asserts the
all-attempt `1/4` and conditional `1/3` denominators. An unavailable verbose
test reporter also failed before the valid focused checks were run.

## 10. Known Residuals

The DGP oracle and driver contract have passed only one tiny executable schema
check. They have not established bootstrap availability, recovery, calibration,
or coverage at any full-design cell. The current `associate_pairs()` public
boundary remains unchanged.

## 11. Team Learning

The finite optimizer limit was already code reality but not a documented part
of the estimand. Making it explicit prevents bootstrap code from treating
numerical-boundary fits as informative association estimates. The independent
DGP construction must remain separate from the production tail-safe quantile
helper.

## 12. Cross-Product Coverage

The staged estimator still has no SE, Wald, profile, `confint()`, coverage, or
public interval claim. The dormant driver has not had a smoke or campaign run;
its CSV/RDS schemas and diagnostics are infrastructure, not evidence. Direct
`biv_lognormal()` `rho12` results remain separate and closed.

This phase covers only fixed-effect literal-Bernoulli × ordinary-NB2 complete
pairs and its one numeric association slope. It does not cover other pair
classes, random effects, missingness, weights, offsets, REML, richer
association formulas, direct `rho12`, or any public inference API.

## Next Actions

Seek separate explicit approval for the DRAC campaign. Do not add a public
interval method before the immutable campaign and Fisher/Noether/Rose review.
