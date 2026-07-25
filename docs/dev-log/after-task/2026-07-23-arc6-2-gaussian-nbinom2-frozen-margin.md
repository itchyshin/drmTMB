# After Task: Arc 6.2 Gaussian × ordinary NB2 frozen-margin association

## Goal

Extend the existing post-fit `associate_pairs()` architecture to fixed-effect
Gaussian × ordinary-NB2 pairs while preserving the two separately fitted
margins exactly and reporting only a conditional latent-normal point estimate.

## Implemented

`associate_pairs()` now accepts one standard Gaussian margin and one ordinary
`nbinom2()` margin in either input order. It freezes rowwise Gaussian `mu` and
`sigma`, and NB2 `mu` and `sigma`, supports fixed covariates on all four margin
predictors, and retains intercept-only `association = ~ 1`. The public object
remains a post-fit R-layer association object, not a new `biv_*` family or TMB
likelihood.

## Mathematical Contract

For NB2 count `y`, the implementation evaluates the exact conditional frozen-
margin CDF interval, not a jittered PIT or continuous-extension shortcut. It
uses `size = 1 / sigma^2`, `F(-1) = 0`, smaller-tail normal quantiles from
NB2 log-CDF/log-survival values, and a log-space normal interval difference.
At `eta = 0`, it reduces to the Gaussian × NB2 product margin. `eta` is a
bounded latent-normal association conditional on fitted margins; it is not
`rho12`, observed correlation, joint-MLE inference, or an uncertainty claim.

## Files Changed

- `R/associate-pairs.R`: pair dispatch, ordinary-NB2 validation, tail-stable
  CDF interval likelihood, diagnostics, and tail-safe coupled simulation.
- `tests/testthat/test-associate-pairs-gaussian-nb2.R`: independent
  bivariate-normal integration oracle, product-margin, normalization, swap,
  extreme-tail, simulation, and rejection tests.
- Formula, likelihood, cross-family, limits, NEWS, research, and smoke
  records synchronize the public development boundary.

## Checks Run

- `devtools::document()` regenerated `man/associate_pairs.Rd`.
- Focused Arc 6.2 tests: 32 pass, 0 fail/warn/skip.
- Focused Arc 6.1 regression tests: 26 pass, 0 fail/warn, 2 expected CRAN
  skips.
- Two separate local smoke ledgers: Arc 6.1 regression and Arc 6.2 new-pair;
  both interior and input-order symmetric. Their reports record all attempts
  and the no-clobber check.
- A broad `devtools::check()` was started but did not return a terminal result
  through this session's command channel. It is therefore not evidence for an
  Arc 6.2 package-check claim.

## Tests Of The Tests

The NB2 test compares the production likelihood to a direct bivariate-normal
integration oracle and checks the `eta = 0` product limit. Fisher found that a
plain `pnorm()` followed by `qnbinom()` could round to `Inf` in the upper tail;
the repaired simulator now uses matching log-tail calls and has an explicit
`z = 9` finite-count regression test.

## Consistency Audit

The formula grammar, likelihood specification, vignette, NEWS, limitations,
series overview, generated reference page, research report, and smoke records
all describe two bounded Arc 6 pair classes. Historical Arc 6.1 planning and
after-task notes are retained as historical evidence rather than rewritten.

## GitHub Issue Maintenance

No overlapping open issue was changed. This bounded post-0.6 development lane
does not create a release or capability issue.

## What Did Not Go Smoothly

NotebookLM auto-imported several blocked landing pages; source fulltext checks
excluded them. The first full smoke output was retained but superseded by
tail-safe and no-clobber-verified lane-specific ledgers. A direct
`test_file()` call without `devtools::load_all()` and an over-broad
`tools::checkRd("man")` call were rejected as invalid invocations; both were
rerun correctly with package loading and the individual Rd path.

## Team Learning

Gauss and Noether passed the exact CDF-interval contract. Fisher caught the
upper-tail `qnbinom(1)` simulator defect before merge; Rose required neutral
Arc 6 error wording, separate immutable smoke receipts, and the complete
closeout trail. The count-CDF adapter is therefore a reusable pattern, but not
evidence for any later count pair.

## Known Limitations

Only fixed-effect ML, complete-row Gaussian × literal-Bernoulli and Gaussian ×
ordinary-NB2 pairs are admitted. Random/structured effects, association
slopes, zero-modified counts, missingness, weights, offsets, `mi()`, `meta_V`,
REML, inference, recovery, intervals, coverage, and capability promotion remain
outside scope.

## Next Actions

Stop Arc 6.2. Reconsider Arc 6.3, a direct kernel, or the Q-series only under
a new owner-approved plan; do not open another pair automatically.
