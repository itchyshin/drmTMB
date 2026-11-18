# After-task report: Julia Gaussian phylogenetic SD-regression scale fix, 2026-11-02

Reader: the next agent on the Julia bridge, and Shinichi.

## 1. Goal

Restore `main`'s receipt-staleness check after PR #1663 merged, and fix the bridge defect the regenerated receipt exposed.

## 2. Implemented

`drm_julia_sd_regression_offsets()` in `R/julia-bridge.R` now takes `family_type` and returns no offset for Gaussian fits. A new live test, `tests/testthat/test-julia-phylo-sd-regression-tree-height.R`, compares bridge and native phylogenetic SD-regression coefficients and log-likelihoods on a tree of height 2 for Gaussian, Gamma, Binomial and Poisson. The `lss-tip-identity` receipt was regenerated against DRModels.jl `main` (`973bbb675`, Julia 1.13.0); the previous receipt is kept under `historical-pre-1663-bridge-fix-2026-11-02/`.

## 3a. Decisions and Rejected Alternatives

The offset was added in `b87566680` for every phylogenetic SD-regression route. Measured on a height-2 tree, bridge minus native was 0.3466 (log of the square root of 2) for Gaussian and 0 for Gamma, Binomial and Poisson. So the fix skips the offset for Gaussian only. Removing the offset everywhere was rejected, because the non-Gaussian routes need it.

## 4. Files Touched

`R/julia-bridge.R`, `tests/testthat/test-julia-phylo-sd-regression-tree-height.R`, `inst/extdata/env-skip-census.tsv`, `NEWS.md`, `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/` (new `public-001.json`, `public-001.log`, `checker-001.log`, historical folder), this note.

## 5. Checks Run

- Regenerated receipt: PASS, every bridge difference 0, source unchanged during the run.
- `tools/check-julia-phylo-labels-receipt.R --current`: PASS. `tools/ci-receipt-staleness.sh`: FRESH and PASS.
- New live test on the Mac against the DRModels.jl lane branch: 8 pass, 0 fail.
- Before the fix the receipt failed against both DRModels.jl `main` and the lane branch, with the same 0.3466 gap.

## 6. Tests of the Tests

The new test uses a tree of height 2, so a missing or doubled shift moves the intercept by 0.3466, which is 346 times the 1e-3 tolerance. Earlier live tests used height-1 trees, where the shift is zero, which is why the defect stayed hidden.

## 7a. Issue Ledger

Fixed: Gaussian phylogenetic SD-regression bridge intercept on non-unit tree heights. Open: none found in the other three families.

## 8. Consistency Audit

NEWS records the fix. The ledger is unaffected: its Julia Gaussian phylogenetic SD evidence used height-1 trees.

## 9. What Did Not Go Smoothly

The post-merge receipt failure was first read as a stale receipt. Regenerating it showed a real defect.

## 10. Known Residuals

The fix rests on one fixture per family. No calibration, interval or broad parity claim.

## 11. Team Learning

Live parity fixtures for structured fields should use non-unit scales (tree height, kernel diagonal), or scale errors stay invisible.

## 12. Cross-Product Coverage

Covered: Gaussian, Gamma, Binomial and Poisson phylogenetic SD regression with an intercept and one SD predictor, on the Julia engine. Not covered: slope SD routes, labelled blocks, NB2, Beta and other families, and simulation.
