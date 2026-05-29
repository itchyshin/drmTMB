# After Task: Gaussian Start Contract

## Goal

Turn Claude's GLLVM.jl warm-start lesson into a verified `drmTMB` contract
without adding a public `start`, `start_from`, or `warm_start` API.

## Implemented

The slice records and tests the internal deterministic starts that already
exist for Gaussian and bivariate Gaussian fits. The package now has focused
regression checks that inspect `fit$model$start` before interpreting optimizer
output:

- univariate Gaussian fixed-effect `mu` starts come from dense `lm.fit()`;
- univariate Gaussian `sigma` intercept starts from the residual standard
  deviation, while non-intercept `sigma` coefficients remain zero;
- bivariate Gaussian `mu1` and `mu2` starts come from response-specific OLS;
- bivariate Gaussian `sigma1`, `sigma2`, and constant `rho12` start from the
  residual standard deviations and Fisher-z transformed residual correlation.

`docs/design/35-optimizer-start-map-multistart.md` now separates these internal
family-builder starts from future user starts and future simpler-fit warm
starts.

## Mathematical Contract

For dense univariate Gaussian fixed-effect starts, `beta_mu^(0)` is the
ordinary least-squares estimate from `lm.fit(X_mu, y)`. The residual-scale
intercept start is `log(sigma0)`, where `sigma0` is based on the residual
standard deviation with the existing known-variance and scale-floor guards.

For bivariate Gaussian starts, `beta_mu1^(0)` and `beta_mu2^(0)` are separate
OLS fits. The residual correlation start is the residual sample correlation,
clipped to `[-0.8, 0.8]`, then mapped to the internal unconstrained scale with
`atanh()`.

## Files Changed

- `tests/testthat/test-optimizer-contract.R`
- `docs/design/35-optimizer-start-map-multistart.md`

## Checks Run

```sh
air format tests/testthat/test-optimizer-contract.R docs/design/35-optimizer-start-map-multistart.md
Rscript --vanilla -e "devtools::test(filter = 'optimizer-contract', reporter = 'summary')"
gh issue list --repo itchyshin/drmTMB --state open --search 'Gaussian start warm start rho12 lm.fit sigma start' --limit 20 --json number,title,state,url,labels
rg -n "intercepts-only with zero slopes|default initial values are.*zero|warm starts.*implemented|start_from.*implemented|init_strategy|closed_form|closed-form warm" README.md NEWS.md ROADMAP.md docs/design R tests/testthat --glob '!docs/dev-log/**'
git diff --check
```

Result:

- `test-optimizer-contract.R` passed.
- The GitHub issue search returned `[]`; no issue action was needed.
- The stale-wording scan returned the intended NEWS and ROADMAP statements that
  future public warm-start names are reserved, not implemented.
- `git diff --check` was clean.

## Tests Of The Tests

The new tests compare `fit$model$start` to independent OLS, residual-SD, and
Fisher-z calculations. They would fail if the Gaussian starts reverted to
all-zero fixed effects, if bivariate `rho12` stopped using the residual
correlation, or if non-intercept `sigma` starts were accidentally described as
closed-form heteroscedastic starts without implementation.

## Consistency Audit

This slice changes an internal optimizer-start contract, not the likelihood,
formula grammar, fitted parameterization, or user-facing control surface. The
existing `NEWS.md` and `ROADMAP.md` language about reserved public warm-start
names remains correct.

## GitHub Issue Maintenance

No matching open GitHub issue was found for the narrow internal start-contract
check, so no issue was opened or updated.

## What Did Not Go Smoothly

The merge of PR #379 had to use the GitHub API because the local `gh pr merge`
path tried to touch `main`, which is checked out in another worktree.

## Team Learning

Ada and Rose should keep treating Claude or sister-package notes as hypotheses
until source and tests confirm what is already implemented. Fisher should keep
separating a useful optimizer start from an inferential claim about coverage or
identifiability.

## Known Limitations

The tests do not add a public start API and do not implement a closed-form
heteroscedastic `sigma ~ x` start. They intentionally document that
non-intercept `sigma` starts are still zero.

## Next Actions

The next substantive GLLVM.jl lesson should be a design-only slice for
`sigma ~ 1` analytic profile-out or sparse phylogenetic precision. Both change
optimization or likelihood geometry enough to need a separate plan and
validation gate before code.
