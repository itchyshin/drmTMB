# After Task: Bernoulli random-slope cross-engine check

## 1. Goal

Compare public Julia and native TMB fits for the same synthetic Bernoulli
random-slope SD regression.

## 2. Implemented

The live Julia bridge test now fits the same seeded data with both engines. It
compares the SD-regression coefficients and group-SD predictions, while
retaining checks against the known simulated coefficients.

## 3a. Decisions and Rejected Alternatives

For group `g`, the test uses `log(sd_g) = alpha_0 + alpha_1 w_g` and
`logit(p_ig) = beta_0 + x_ig beta_1 + x_ig b_g`, with independent
`b_g ~ Normal(0, sd_g^2)`. The fitted slopes are compared at absolute
tolerance 0.35 and the group SD predictions at absolute tolerance 0.45.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-sd.R`: same-data native TMB comparison
  for the existing public Julia random-slope fixture.
- `docs/design/18-random-effect-scale-models.md`: records the measured
  coefficient and group-SD comparison.
- `docs/dev-log/check-log.md` and this report.

## 5. Checks Run

With `DRMTMB_JULIA_TESTS=true`, `DRM_JL_PATH` set to the paired Julia
worktree, a writable temporary Julia depot, and BLAS/Julia thread counts
bounded to one and two, respectively,
`devtools::test(filter = "julia-binomial-sd")` passed 58 assertions in
51.1 seconds: zero failures, warnings, or skips. Two live Julia tests ran.
`git diff --check` and the after-task structure validator passed. The prose
checker reported zero findings.

## 6. Tests of the Tests

The seeded fixture checks recovery against the generating coefficients, checks
Julia and TMB convergence, compares fitted coefficients and public group-SD
predictions, and retains the independent scalar-normal quadrature oracle. The
same-data fit is a point-estimate check and provides no interval-calibration
evidence.

## 7a. Issue Ledger

An open-issue search for `Bernoulli random slope Julia SD regression` in
`itchyshin/drmTMB` returned no matches. No issue was opened or changed.

## 8. Consistency Audit

The design note now states the tested model and tolerances. Existing Bernoulli
wording distinguishes the single independent slope checked across both engines
from separate same-group coefficient targets that currently have native-only
support. The `[[drmTMB]]` project dossier informed the condition-specific scope
of this parity claim. No likelihood or admission rule changed.

## 9. What Did Not Go Smoothly

The first test invocation used an incorrect nested path and skipped both live
Julia cases. I corrected it to the sibling `general-sd-julia` worktree and
reran the filter; the final result has zero skips.

## 10. Known Residuals

This check covers one independent Bernoulli slope and one synthetic seed. It
does not establish likelihood approximation identity, interval calibration,
multiple coefficient-specific SD formulas on the same group in Julia,
structured effects, or family-wide parity. Profile/bootstrap coverage and the
full effect-family-backend ledger remain open.

## 11. Team Learning

For bridge tests, confirm the paired repository path and require live-test
counts to be nonzero before treating a green filtered run as engine evidence.

## 12. Cross-Product Coverage

This verifies the ordinary independent Bernoulli random-slope point-fit path
through the R-to-Julia bridge and native TMB on one seeded dataset, including
coefficient and group-SD prediction comparisons. It does NOT cover Julia
same-group multi-coefficient SD formulas, structured effects, other families,
interval calibration, profile/bootstrap coverage, or the complete capability
matrix.

## Next Actions

Extend Julia target identity and fitting for separate independent coefficient
SD formulas on one group, then continue the uncertainty-calibration ledger.

## Prose Assessment

**Style:** 2/10, medium confidence; the wording is specific to this test and
states its limits. **Genre/coverage:** technical after-task report, read in
full. **Evidence/repair:** the goal, exact model, tolerances, and test result
are concrete; no further repair was needed. **Gates:** science = pass for the
stated one-seed comparison only; facts = pass against the test output and
current design note; references = not applicable, no external sources used.
**Provenance:** self-review, version 1, 2026-10-18; no style controls were
consulted.
