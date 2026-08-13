# After task: ordinal cutpoint profile rebase and review

## Goal

Rebase the issue #967 implementation-only branch on current `origin/main`,
then establish that its public cumulative-cutpoint profile route is internally
consistent and honestly bounded. This is not a calibration, DRAC, CRAN, MSPL,
or missing-response promotion.

## Reconciliation

The implementation commit was rebased on `origin/main` at `02b9041f0`. The
reviewed branch deliberately changes only the pure-R profile route, its
deterministic tests, and its design wording. No compiled source, capability
ledger status, or simulation artifact changes in this receipt.

## Repairs made during independent review

- The fitted constrained objective now uses an absolute `1e-6` equality
  tolerance, rather than a relative comparison.
- Raw `theta_ord` coordinates and ambiguous ordinal aliases fail with an
  actionable public-cutpoint alternative; generic `TMB::tmbprofile` controls
  cannot silently switch engines.
- The route rejects every non-ML objective, including MAP/penalized, REML, and
  MSPL fits, because a likelihood-ratio cutpoint interval is not defined for
  those objectives.
- Wald requests for known public cutpoints explicitly direct the reader to
  `method = "profile"`.
- Any endpoint failure yields `profile_failed` and two missing endpoints; it
  never manufactures a one-sided finite interval.
- The scope now accurately includes ordinary supported `mu` random-effect
  nuisance layouts while retaining the ML-only, uncalibrated boundary.

## Verification

- Focused current-source check:
  `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document(quiet = TRUE); devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-profile-targets.R", reporter = "summary")'`
  passed after the final repairs.
- The acceptance suite checks the public-vs-raw scale sentinel, constrained
  objective equality, strict ordering, later-cutpoint independent likelihood
  oracle, `ordinal::clm` estimates/log likelihood, failure closure, weighted
  geometry, and first-cutpoint agreement with `TMB::tmbprofile()`.
- `pkgdown::check_pkgdown()` reported no problems before the tests-only final
  repair set; `git diff --check` is clean.
- PR CI initially found the generated missing-response capability include stale.
  Regenerating it with `python3 tools/capability_ledger.py --write` changed only
  its ordinal row, preserving the statement that the pre-existing G5 claim is
  for `fixef:mu:x` only and does not calibrate cutpoint intervals. The generator
  check and its ledger/profile-truth unit tests passed locally.
- A `devtools::check(args = "--as-cran")` snapshot passed compilation,
  installation, R code, Rd, examples, and vignettes. Its package-wide test
  phase was red because it was built before the final ordinal-test repairs
  (three stale ordinal expectations) and also carried unrelated missing-response
  G4/G5 failures. The known Phase 18 `student_shape_grid` missing-artifact
  prerequisite is separately outside this lane. The final focused source test
  is the applicable deterministic result; this lane does not claim a green
  package-wide check.

## Independent review receipt

Three fresh reviewers examined the rebased branch. They identified the
non-ML scope leak, the mixed-ordinal wording mismatch, missing fail-closed
coverage, an unclear Wald rejection, and the missing first-cutpoint TMB
comparator. Each was repaired and sent back for re-review. No calibration claim
was approved or made.

## Deferred

The immutable DRAC campaign contract remains a no-compute design artifact.
No timing smoke, coverage run, G5 promotion, CRAN candidate work, or MSPL work
was started by this branch.
