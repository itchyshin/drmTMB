# After Task: Gamma phylogenetic SD point parity

## 1. Goal

Check whether the native TMB and Julia engines return consistent estimates for
the same synthetic Gamma phylogenetic random-effect SD model.

## 2. Implemented

Added one live Julia bridge test that fits identical data through native TMB and
Julia. It compares convergence, SD-regression coefficients, and tip-level SD
predictions for a q1 phylogenetic intercept on a unit-height tree. The family
inventory now records this one point-parity cell.

## 3a. Decisions and Rejected Alternatives

The synthetic model uses `log(sd_t) = alpha_0 + alpha_1 z_t` and
`b ~ N(0, D K D)`. The tree is scaled to unit tip variance so both engines use
the same covariance scale. The comparison tests point estimates and predictions;
it does not test interval calibration.

## 4. Files Touched

- `tests/testthat/test-julia-gamma-sd.R`
- `docs/dev-log/general-sd-regression/inventory.md`
- This report and its check-log entry.

## 5. Checks Run

- `devtools::test(filter = "julia-gamma-sd", reporter = "summary")` with the
  active DRModels.jl checkout configured: passed; all three live Julia Gamma
  SD bridge tests ran, including the new parity test.
- `git diff --check -- docs/dev-log/general-sd-regression/inventory.md`: passed.
- The project after-task structure validator passed. Programme gates remain open
  and do not close with this slice.
- The acceptance-ledger reverify was not run because `node` is unavailable in
  this shell; the programme gates remain open.
- New and updated files passed a trailing-whitespace and blank-line-at-EOF
  check. The whole dirty diff still reports an unrelated blank line at EOF in
  `tests/testthat/test-binomial-sd-integration.R`; that pre-existing file was
  not changed for this task.
- Prose check: passed with zero findings.
- Inventory prose check: six contrast-pattern hits, zero findings.

## 6. Tests of the Tests

The first live run reached Julia and rejected the TMB-only `se = FALSE` control
in the Julia call. Removing that control allowed both fits to run; the final
test compares both fitted coefficient vectors and predicted tip SDs.

## 7a. Issue Ledger

The read-only `gh issue list` searches for “Gamma phylogenetic SD” and “Julia
phylogenetic SD” could not reach GitHub's API. No issue was changed; issue
overlap remains unchecked.

## 8. Consistency Audit

The test uses the public `sd(species, level = "phylogenetic") ~ z` formula and
the native Gamma model. The unit-height tree makes the raw Julia tree covariance
and the TMB correlation covariance comparable. The inventory limits the claim
to this one q1 fixture.

## 9. What Did Not Go Smoothly

The first configured run exposed an engine-specific control mismatch in the
test setup. The Julia bridge correctly refused the TMB-only option.

## 10. Known Residuals

This is one seeded point-parity comparison. It does not establish parity for
non-unit or non-ultrametric trees, other Gamma providers or effect shapes,
profiles, bootstrap inference, or interval calibration.

## 11. Team Learning

Paired engine tests should use only controls accepted by both engines, while
retaining engine-specific controls on their respective fits where needed.

## 12. Cross-Product Coverage

This slice covers a single Gamma phylogenetic q1 mean intercept, fixed SD
predictor, unit-height tree, and same-data point estimate and prediction
comparison. It does NOT cover other families, structured providers, random
slopes, non-ultrametric or non-unit cross-engine tree scaling, marginal
simulation parity, saved-object parity, profile or bootstrap parity, or interval
calibration. Continue the paired-engine audit across the remaining family and
effect rows; keep coverage calibration in its separate stage.
