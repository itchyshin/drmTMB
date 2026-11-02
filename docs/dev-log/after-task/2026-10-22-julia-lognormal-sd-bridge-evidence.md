# After Task: Julia LogNormal direct-SD bridge evidence

## 1. Goal

Record the tested boundary for Julia LogNormal predictor-dependent random-effect SDs and link the two exact capability rows to the source-bound test receipt.

## 2. Implemented

The paired development candidates admit one ordinary `mu` random intercept or one independent numeric `mu` slope with a matching SD formula and fixed `sigma ~ 1`. The live bridge fixtures compare coefficients and group and row predictions against native TMB. The intercept fixture also checks save/reload. Two unreviewed, exact-key receipts now point to the same source-bound test run.

## 3. Mathematical Contract

For the tested ordinary coefficient, the group-specific coefficient SD is `exp(W_g alpha)`. This slice leaves the LogNormal residual scale at `sigma ~ 1`. It does not change structured-kernel scaling or add random effects to the SD formula.

## 3a. Decisions and Rejected Alternatives

The evidence is recorded as two `focused_test` rows, not as broad recovery or parity for the entire LogNormal family. Combining these targets into one broad claim would exceed the two fitted fixtures.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/lognormal-julia-sd-20261022/receipt.md` records test scope and exact pins.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` links the intercept and independent-slope rows; the generated summary now reports 16 linked rows.
- `docs/dev-log/general-sd-regression/inventory.md`, `docs/design/01-formula-grammar.md`, and `docs/design/18-random-effect-scale-models.md` describe the narrow route.
- `docs/dev-log/check-log.md` records the check and reconciliation.
- `docs/dev-log/after-task/2026-10-22-julia-lognormal-sd-bridge-evidence.md` records this audit.

## 5. Checks Run

- Verified every entry in `sources-before.sha256`; all 11 source and test files matched. The focused live bridge test was rerun after the S3 registration change and still passed, with the updated NAMESPACE included in the manifest.
- Read the existing live test log: 16 structural admission expectations and two live Julia bridge tests passed, with no failures or skips.
- R version is 4.6.0, TMB is 1.9.21, and Julia is 1.10.0. Candidate source pins are drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.
- Reconciliation passed: 19,118 candidate rows, 16 linked rows, 19,102 unlinked rows, and 17 evidence records.
- GitHub open-issue search for LogNormal SD Julia returned no directly matching issue; the returned general test-sweep issue was unrelated. No issue was changed.

## 6. Tests of the Tests

The bridge gate checks accepted intercept and numeric-slope formulas and rejects mismatched, correlated, multiple-term, random-SD-predictor, and unsupported scale shapes. The live fixture uses synthetic data and compares target-aligned group outputs, so Julia's target-prefixed names are not mistaken for different groups.

## 8. Consistency Audit

The bridge admission, paired Julia fitter, test fixture, and public descriptions all refer to an ordinary `mu` intercept or independent numeric slope with fixed `sigma ~ 1`. The formula guide and inventory now say point parity is limited to these two fixtures. The evidence rows remain `unreviewed` and do not promote general support.

## 8. Documentation and Pkgdown

Updated the family inventory, formula-grammar design row, and random-effect scale overview. The Julia engine vignette and NEWS already described this route. No navigation change was needed. Full rendering and pkgdown checks were not run in this evidence-only update.

## 7a. Issue Ledger

A read-only search found no directly matching open issue. No issue was opened, commented on, or closed.

## 9. What Did Not Go Smoothly

The first receipt lookup exposed that the evidence summary was stale relative to several existing test reports. The reconciler itself ran cleanly after adding the two exact-row links. This slice raises the overlay count by two only.

## 11. Team Learning

Keep exact capability-row evidence separate from the full implementation inventory. A small receipt count is not a complete measure of code progress, but each linked row still needs a hash-bound test and an explicit claim boundary.

## 10. Known Residuals

This is complete-data point-parity evidence for two ordinary LogNormal `mu` targets in paired development candidates. It does not establish interval calibration, shared/released DRM.jl support, structured or correlated effects, other endpoints, missing-data parity, or broad family parity. Continue reconciling the remaining required rows, then run the agreed full R/Julia regression and independent closeout. Programme gates G0, G1, G3, G4, G6, G7, and G8 remain open; G5 interval calibration is deferred.

## Next Actions

Continue reconciling the remaining required rows against source-bound tests, and run full R/Julia regression checks before independent closeout.

## 12. Cross-Product Coverage

This update covers the drmTMB R bridge and paired DRM.jl development-candidate LogNormal ordinary `mu` intercept and independent numeric slope with fixed `sigma ~ 1`. It does NOT cover shared or released DRM.jl, the Julia public package outside this paired checkout, structured or correlated providers, other distributional parameters, missing-data behavior, or interval calibration.
