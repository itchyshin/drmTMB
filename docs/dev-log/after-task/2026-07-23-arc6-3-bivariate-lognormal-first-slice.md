# After Task: Arc 6.3 exact bivariate lognormal first slice

## Goal

Implement one bounded exact bivariate-lognormal model from clean `origin/main`.
The headline estimand is `rho12`, the within-row residual correlation on the
log-response scale; it is neither frozen-margin `eta` nor raw-scale Pearson
correlation.

## Implemented

`biv_lognormal()` is a distinct family and TMB model type. It admits complete,
finite, strictly positive pairs; fixed-effect `mu1` and `mu2` formulas; and
intercept-only `sigma1`, `sigma2`, and `rho12`. `fitted()` returns each
original-scale marginal mean and `simulate()` draws a correlated normal pair on
the log scale before exponentiating.

## Mathematical Contract

The likelihood is the bivariate normal density for `(log(y1), log(y2))` minus
both log-Jacobians. Positive SDs use log links and `rho12` uses the guarded
`0.999999 * tanh()` transform. The independent R oracle and simulator in
`test-biv-lognormal.R` implement this equation without calling the package
likelihood. Full equations and the alignment table are in design 233.

## Files Changed

The implementation changes `R/family.R`, `R/drmTMB.R`, `R/methods.R`, and
`src/drmTMB.cpp`; generated `NAMESPACE` and `man/biv_lognormal.Rd` accompany
the new export. Design, family registry, link contract, grammar, limitations,
NEWS, check-log, and family vignette surfaces state the same bounded scope.

## Checks Run

- `devtools::document(quiet = TRUE)`: PASS.
- `devtools::test(filter = "biv-lognormal", reporter = "summary")`: PASS.
- `devtools::test(filter = "biv-gaussian", reporter = "summary")`: PASS with
  the comparator suite's pre-existing warnings only.
- `devtools::test(filter = "biv-lognormal|family-link-contract", reporter =
  "summary")`: PASS; the unrelated family-link fixture issued its existing
  singular-convergence warning.
- R parse of touched R files and `git diff --check`: PASS.
- `python3 tools/capability_ledger.py --write` followed by `--check`: PASS.

## Tests Of The Tests

The new source test compares package `logLik()` with an independent
transformed-scale bivariate-normal calculation including both Jacobians. It
also fixes package `rho12` at zero and checks its likelihood against the product
of the two lognormal margins; checks response swapping, unequal SDs,
response-scale fitted means, positive joint simulation, guarded boundary
behaviour, zero/negative/missing/non-finite response rejection, weights, random
effects, rho predictors, and every public interval/profile entry point.

## Consistency Audit

The stale-surface search used:

```sh
rg -n "bivariate.*lognormal|lognormal.*bivariate|biv_lognormal|mixed.*lognormal|rho12" README.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes _pkgdown.yml
```

The grammar, registry, likelihood, link contract, limitations, NEWS, family
vignette, and generated capability surface were updated. No README or
navigation entry was added: this is a bounded development slice without a
tutorial or capability claim.

## GitHub Issue Maintenance

No issue was opened or updated. This task was started from the owner-approved
Arc 6.3 handover and does not close a public capability or release issue.

## What Did Not Go Smoothly

The first clean worktree creation required an approved Git metadata write
because the original checkout was intentionally read-only/dirty. During the
method audit, a fitted-response block had landed in a response-name helper;
Rose's neighbour inspection found it and it was removed before validation.
Fresh review also found latent interval/profile entry points outside
`confint()`; all five public routes now explicitly reject requests rather than
returning unvalidated intervals.

## Team Learning

The bivariate Gaussian helper is reusable only after the log response and both
Jacobians are made explicit. Reusing the full Gaussian specification unchanged
would silently inherit unsupported `meta_V`, partial-response, and
random-covariance surfaces. Any first-slice inference exclusion must fence all
public interval entry points, not only `confint()`.

## Known Limitations

No sigma/rho predictors, random or structured effects, incomplete pairs,
weights, offsets, `meta_V`, `mi()`, REML, Julia, intervals, coverage,
recovery campaign, capability promotion, or CRAN claim is included. Near
`|rho12| = 1` remains weakly identified even though the guarded transform is
finite.

## Next Actions

Obtain fresh Fisher/Gauss/Rose review of this implementation before merging.
If an owner later approves a recovery programme, first write a smoke contract;
then obtain separate Totoro or DRAC authority and retain every attempt in an
immutable ledger.
