# After Task: Sigma Profile-Out Audit

## Goal

Audit Claude's GLLVM.jl sigma profile-out suggestion against the current
`drmTMB` fit path before treating it as implementation work.

## Implemented

The current implementation is now documented and tested: intercept-only
Gaussian `sigma`, bivariate `sigma1`, and bivariate `sigma2` remain optimized
fixed-effect parameters. They are not analytically profiled out before
optimization.

## Mathematical Contract

For the current univariate Gaussian route,

```text
log(sigma_i) = X_sigma[i, ] beta_sigma
```

and for the bivariate Gaussian route,

```text
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
```

When the scale formula is intercept-only, the corresponding design matrix has
one column, but the coefficient remains in `fit$opt$par`. Existing constant
scale profile intervals profile that optimized link-scale coefficient. They are
not Bates-style profile likelihoods where sigma is eliminated from the
optimization problem by a closed-form residual-variance update.

## Files Changed

- `tests/testthat/test-optimizer-contract.R`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-sigma-profile-out-audit.md`

## Checks Run

```sh
air format tests/testthat/test-optimizer-contract.R docs/design/35-optimizer-start-map-multistart.md
Rscript --vanilla -e "devtools::test(filter = 'optimizer-contract', reporter = 'summary')"
rg -n "profile.?out|profiled out|analytically profile|profile =|Bates|sigma.*eliminat|remove.*beta_sigma|map.*beta_sigma|constant residual scale" README.md NEWS.md ROADMAP.md docs/design R tests/testthat --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'sigma profile out beta_sigma MakeADFun profile' --limit 20 --json number,title,state,url,labels
git diff --check
```

Result: `test-optimizer-contract.R` passed, the issue search returned `[]`,
and `git diff --check` was clean.

## Tests Of The Tests

The new tests compare the fitted object's optimized parameter vector against
the model matrices. They assert that `beta_sigma`, `beta_sigma1`, and
`beta_sigma2` appear in `fit$opt$par`, that the maps do not remove them, and
that `fit$df` matches the optimized-parameter length. This directly catches an
accidental future change that silently removes constant residual scale from the
optimized vector.

## Consistency Audit

The design note now says that `TMB::MakeADFun()` is called without a
`profile =` argument and that `spec$map` does not map off constant Gaussian
scale coefficients. It also records why a future analytic profile-out slice
must handle degrees of freedom, `sdreport()` / `vcov()`, direct profile targets,
known sampling variance, aggregation, and random or structured scale
contributions before it can be treated as a safe optimizer shortcut.

## GitHub Issue Maintenance

The issue search for a matching sigma profile-out or optimizer-profile issue
returned `[]`. No issue action was needed for this audit-only PR.

## What Did Not Go Smoothly

The raw Claude note was directionally useful, but its implementation guidance
made profile-out sound like a small map change. The source audit shows it is a
larger likelihood and inference contract because fitted object degrees of
freedom, standard-error reporting, and existing profile targets all assume the
scale coefficients remain optimized parameters.

## Team Learning

Ada kept the work to an audit-and-lock slice. Gauss and Noether checked that
the current likelihood still evaluates scale through link-scale fixed effects
inside TMB. Grace kept validation focused on the optimizer-contract tests. Rose
separated a useful sister-package idea from a current `drmTMB` fact.

No spawned subagents were running.

## Known Limitations

This task does not implement analytic profile-out for `sigma ~ 1`,
`sigma1 ~ 1`, or `sigma2 ~ 1`. It also does not benchmark whether eliminating
those parameters would improve runtime or stability in `drmTMB`; that belongs
to a later design-and-measurement slice.

## Next Actions

Design the future profile-out path only after specifying how it interacts with
known sampling variance, Gaussian aggregation, random or structured scale
terms, `df`, `sdreport()` / `vcov()`, and `profile_targets()`.
