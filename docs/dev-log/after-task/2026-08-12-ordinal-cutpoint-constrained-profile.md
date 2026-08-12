# After Task: constrained ordinal-cutpoint profile intervals

## Goal

Implement a narrow, response-scale profile-interval route for every ordered
cutpoint in an ML/Laplace `cumulative_logit()` fit, without turning the raw
`theta_ord` log gaps into a public estimand or making a calibration claim.

## Implemented

`profile_targets()` now publishes `ordinal:cutpoint:<label>` rows with
`scale = "cutpoint"`, `transformation = "ordered_cutpoint"`, and
`target_type = "constrained"`. Their `confint(..., method = "profile",
profile_engine = "auto")` call uses a pure-R constrained refit. Raw
`ordinal:theta_ord:<label>` rows remain visible only as unready internal
diagnostics. The default `confint(fit)` route remains unchanged.

## Mathematical Contract

The public estimand is the cumulative threshold `c_j`, where `c_1 = theta_1`
and `c_j = c_{j-1} + exp(theta_j)`. For a fixed `c_j = a`, the evaluator uses
`theta_1 = a - sum(exp(theta_2), ..., exp(theta_j))`, retains positive log
gaps, and evaluates the unchanged TMB objective with its chain-rule gradient.
There is no Jacobian term because this is constrained MLE optimization, not a
density transformation. A profile objective below the fitted objective fails
closed.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `man/confint.drmTMB.Rd`
- `man/profile_targets.Rd`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/25-ordinal-scale-discrimination.md`
- `docs/design/254-ordinal-cutpoint-constrained-profile.md`
- `docs/dev-log/interval-availability/2026-08-12-ordinal-cutpoint-profile-drac-contract.md`
- `vignettes/includes/capability-ledger-missing-response.md`

## Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document(quiet = TRUE)'` regenerated the two affected Rd files.
- The focused `tests/testthat/test-profile-targets.R` suite passed after loading
  the local package, including the independent likelihood oracle and
  `ordinal::clm` comparator checks.
- `pkgdown::check_pkgdown()` returned `No problems found.`
- `devtools::check(args = "--as-cran", error_on = "warning")` passed source
  compilation, installation, R code, Rd, examples, and the new `ordinal`
  dependency declaration, but package-wide test rendering is presently blocked
  by unrelated Phase 18 reports that abort because the
  `student_shape_grid` artifact is absent. This is not an ordinal-cutpoint
  failure and is not repaired in this lane.

## Tests Of The Tests

The target test covers both the first cutpoint and the nonlinear second
cutpoint, asserts public estimates equal cumulative cutpoints rather than raw
`theta_ord`, and rejects raw-theta and generic-profile routes. A deterministic
fixed-effect fixture compares cutpoint estimates and log likelihood with
`ordinal::clm(link = "logit", threshold = "flexible")`.

## Consistency Audit

The source profile documentation, generated Rd files, the profile-CI design
note, the ordinal design note, and the missing-response capability wording were
updated. The G5 missing-response claim remains keyed only to `fixef:mu:x`; this
work does not attach ordinal-cutpoint calibration to that artifact.

## GitHub Issue Maintenance

Issue #967 is the governing design record. No issue was closed or commented on
from this isolated implementation branch: mergeability and review are still
required, and the immutable campaign contract retains the separate calibration
decision.

## What Did Not Go Smoothly

The first direct `testthat::test_file()` invocation did not load the package,
so it failed with `drmTMB()` unavailable; rerunning through `devtools::load_all()`
was clean. The installed `ordinal` version verifies threshold MLEs and log
likelihood but does not expose threshold profiles through its public profiler,
so it is not represented as an endpoint oracle.

## Team Learning

The ordinal target name must encode the estimand, not the storage coordinate:
one raw vector contains both a first threshold and later log gaps. Treating all
entries as direct public cutpoints would silently change the scientific question
for every later threshold.

## Known Limitations

This is an implementation-correctness claim only. It excludes Wald/bootstrap
cutpoint intervals, exported full profile curves, AGHQ, REML, MSPL, and any G5
or coverage promotion. Failed, non-crossing, or non-finite profiles remain
unavailable rather than receiving fabricated finite endpoints.

## Next Actions

Resolve or isolate the unrelated Phase 18 artifact prerequisite, then rerun
the full `--as-cran` gate before merge. After merge, before any DRAC campaign,
run the separately approved one-fit-per-cell timing smoke specified in the
immutable contract and return for explicit compute approval.
