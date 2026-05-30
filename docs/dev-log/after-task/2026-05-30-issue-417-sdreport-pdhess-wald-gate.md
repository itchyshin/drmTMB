# After Task: Issue #417 sdreport pdHess Wald Gate

## Goal

Issue #417 reported a weak-Hessian `meta_V()` location-scale example and used
`fit$sdreport$pdHess` as the discoverable check. This task made that object
slot discoverable and made Wald uncertainty require a positive-definite
`TMB::sdreport()` Hessian.

## Implemented

- `drmTMB()` now stores the returned `TMB::sdreport()` object as both
  `fit$sdr` and `fit$sdreport`.
- `vcov()` and summary standard errors now require `fit$sdr$pdHess = TRUE`.
- Wald confidence intervals keep point-estimate rows available but report
  `conf.status = "wald_unavailable"` when `sdreport()` returned with
  `pdHess = FALSE`.
- `NEWS.md` and `man/model-fit-extractors.Rd` now say that Hessian-based
  covariance requires `pdHess = TRUE`.

## Mathematical Contract

For Gaussian known-sampling-covariance fits, the issue #417 regression keeps the
existing likelihood contract: `meta_V(V = v)` adds known observation-level
variance, and predictor-dependent `sigma` models residual heterogeneity on the
log scale. The change does not alter the likelihood or formula grammar. It only
changes the inference gate: Wald covariance, standard errors, and Wald intervals
are trusted only when `TMB::sdreport()` reports `pdHess = TRUE`.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `R/profile.R`
- `tests/testthat/test-meta-known-v.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-control.R`
- `man/model-fit-extractors.Rd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-issue-417-sdreport-pdhess-wald-gate.md`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-meta-known-v.R", reporter = "summary"); testthat::test_file("tests/testthat/test-profile-targets.R", reporter = "summary"); testthat::test_file("tests/testthat/test-control.R", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "meta-known-v|profile-targets|control", reporter = "summary")'
Rscript --vanilla -e 'devtools::document()'
air format R/drmTMB.R R/methods.R R/profile.R NEWS.md tests/testthat/test-meta-known-v.R tests/testthat/test-profile-targets.R tests/testthat/test-control.R man/model-fit-extractors.Rd man/drmTMB-package.Rd DESCRIPTION
git diff --check
```

Results: the three focused `testthat::test_file()` runs passed, the filtered
`devtools::test()` run passed, `devtools::document()` completed, `air format`
passed, and `git diff --check` reported no whitespace errors.

## Tests Of The Tests

The new issue #417 regression checks that the seeded `meta_V(V = v)` plus
`sigma ~ habitat` example converges with `fit$sdr$pdHess = TRUE`, exposes the
same object at `fit$sdreport`, and returns finite Wald intervals. The same fit
is then mutated to `pdHess = FALSE`; that path now makes `vcov()` error with a
positive-definite-Hessian message and makes `confint()` return
`wald_unavailable` rows rather than finite Wald intervals.

The control and profile-target tests add a package-generic non-positive-Hessian
path so the behavior is not tied only to the meta-analysis example.

## Consistency Audit

```sh
rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\([^V]|fit\$sdreport|fit\$sdr|sdreport_non_pd_hessian|wald_unavailable|positive-definite Hessian|pdHess = FALSE' README.md ROADMAP.md NEWS.md R tests/testthat man docs/design docs/dev-log/known-limitations.md vignettes
```

The scan found expected historical or design-scope references to
`meta_gaussian()`, `tau ~`, `pdHess = FALSE`, and `wald_unavailable`. No new
contradiction was found for this issue #417 code slice.

## GitHub Issue Maintenance

`gh issue view 417 --repo itchyshin/drmTMB --comments` confirmed that PR #434
already left a docs-only guardrail comment and deliberately kept issue #417
open for the code-level diagnostic fix. After PR #435 was opened, the issue was
updated with the PR link:
`https://github.com/itchyshin/drmTMB/issues/417#issuecomment-4584982371`.

## What Did Not Go Smoothly

The first regression used `expect_equal(..., tolerance = ...)` for seeded
simulation recovery, which behaved like a relative-tolerance check and was too
brittle for the intercept. It was replaced with explicit absolute-error checks.

Nash also caught an important integration trap: after making `vcov()` reject
`pdHess = FALSE`, direct `confint()` needed a separate route that returns
`wald_unavailable` rows instead of aborting. That route is now covered.

## Team Learning

For weak-Hessian work, keep the distinction sharp: `pdHess = FALSE` blocks
naive Wald inference but does not make point estimates useless. Future changes
that harden `vcov()` should also check direct `confint()`, `summary()`
coefficient tables, and response-scale parameter tables in the same pass.

## Known Limitations

- `fit$sdr` remains the canonical internal slot. `fit$sdreport` is a
  construction-time discoverability alias, not a live binding if users mutate
  one slot by hand.
- This task does not add optimizer rescue, profile-likelihood fallback, or
  bootstrap intervals for weak-Hessian fits.
- The docs-only PR #434 remains separate from this code-level fix.

## Next Actions

- Open a focused PR for this branch and link it to issue #417.
- Let CI decide whether a broader platform-specific check is needed.
