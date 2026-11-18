# After Task: Non-unit-kernel Gamma animal SD simulation

## 1. Goal

Verify that Julia Gamma animal marginal simulation preserves the existing covariance-kernel scale when intercept and numeric-slope SDs both depend on fixed predictors.

## 2. Implemented

Added a separate test fixture with an animal relationship matrix of the form `A = D R D`, where `R` has unit diagonal and `D` gives each animal a different positive scale. The fit uses the Julia engine and the existing Gamma animal intercept-and-slope SD route. The test compares the simulator against an independently reconstructed seeded draw using `t(chol(A))`.

No product source changed in this slice. The test passed and establishes one non-unit-kernel simulation case; it does not establish broad structured-effect support.

## 3. Mathematical Contract

For group `g` and coefficient `a`, the tested latent coefficient is `b[g,a] = tau[g,a] u[g,a]`, with `log(tau[g,a])` given by the fixed SD formula and `Cov(u[,a]) = A`. Thus the marginal SD is `tau[g,a] * sqrt(A[g,g])`. The R oracle generates each field as `t(chol(A)) %*% z` before multiplying by group-specific `tau`. It does not normalize `A` or add intercept-slope correlation.

## 3a. Decisions and Rejected Alternatives

Kept this as a new focused test rather than changing the actively leased Gamma bridge test. Used a non-unit diagonal in the supplied kernel instead of altering the established covariance parameterization. No public support claim or generated help was changed.

## 4. Files Touched

- `tests/testthat/test-gamma-animal-q2-nonunit-kernel-simulation.R`: new deterministic Julia bridge fit and independent marginal-draw oracle.
- `docs/dev-log/general-sd-regression/inventory.md`: added a dated evidence entry that distinguishes the unit-diagonal parity fixture from the non-unit simulation fixture.
- `docs/dev-log/evidence/gamma-animal-nonunit-kernel-simulation-20261024/`: console output and source manifest.
- `docs/dev-log/check-log.d/2026-10-24-gamma-animal-nonunit-kernel-simulation.md`: exact command and result.
- `docs/dev-log/after-task/2026-10-24-gamma-animal-nonunit-kernel-simulation.md`: this bounded report.

## 5. Checks Run

- `devtools::test(filter = "gamma-animal-q2-nonunit-kernel-simulation", reporter = "summary", stop_on_failure = TRUE)`: passed, one live Julia fit and seven expectations, exit code 0, approximately 34 seconds.
- `git diff --check` on the simulator and new test: passed.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <report>`: structure passed; the validator reported an unavailable Node or `gate-check`, so the acceptance-ledger state remains UNKNOWN.
- `python3 ~/shinichi-brain/tools/slop_check.py <report>`: passed with zero findings.
- `gh issue list --search 'Gamma animal non-unit kernel simulation' --state open --limit 10`: no matching open issue; no issue was opened, commented on, or closed.
- Scope scan: `rg -n -i 'Gamma.*animal.*simulation|animal.*Gamma.*simulation|Gamma animal SD' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. It found broad capability text in the formula-grammar design table. This test adds one simulator evidence case and leaves existing formula-grammar support claims unchanged.
- Source pins and hashes are recorded in `docs/dev-log/evidence/gamma-animal-nonunit-kernel-simulation-20261024/source-manifest.md`.

## 6. Tests of the Tests

The exact seeded oracle uses the non-unit matrix itself, so replacing `A` with its correlation-normalized form would change the expected response draws. The fixture also asserts that the kernel diagonal differs materially from one, checks group order and both SD target names, and requires repeatability at the same simulation seed. The test exercises one complete-data synthetic case only.

## 7. Design and Documentation Updates

No public documentation, formula grammar, likelihood, generated help, or pkgdown navigation changed. The internal inventory records the new evidence and its limits. The active Gamma combined-target test and shared generated help were left untouched.

## 7a. Issue Ledger

Searched open issues with `gh issue list --search 'Gamma animal non-unit kernel simulation' --state open --limit 10`. No matching open issue was found. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The simulator draws the supplied relationship covariance first, then multiplies by the group-specific SD predictions. The test's formula, DGP, and oracle use the same group order and covariance. The test does not imply that every provider or structured effect is supported by this simulator route.

## 9. What Did Not Go Smoothly

The full lane preflight took about 90 seconds and reported the existing Gamma bridge test as leased by another active claim. The test and report therefore use new, separate paths. `graft` was not installed, and `route.py` found no LOAD-FIRST manifest for either the worktree or repository root; I inspected only the exact simulator and fixture spans already identified by the previous implementation work.

## 10. Known Residuals

The test is Julia-only for the non-unit-diagonal case and checks simulation, not fit recovery or interval calibration. It covers a supplied animal relationship matrix, one Gamma DGP, and two independent coefficient fields. Phylogenetic, spatial, mesh, relmat, non-unit projected kernels, correlated coefficient blocks, missing data, and other response families remain untested here. This slice closes no programme-wide capability or calibration gate.

## 11. Team Learning

When a shared bridge test is leased, a standalone test file can add a mathematical edge case without modifying that file. For structured SDs, the test should distinguish the covariance multiplier from the marginal SD by deliberately using a non-unit kernel diagonal.

## 12. Cross-Product Coverage

One Julia bridge fit and its marginal response simulation passed. This does NOT cover non-unit-kernel parity with native TMB, interval calibration, other structured-effect providers, or other families.

## Prose Assessment

Style review: Style 2/10, medium confidence; genre: internal engineering report; coverage: the full report. The test's single-case scope and the limits on parity and calibration are explicit. Science gate: pass for the stated covariance draw, checked against the formula and independent oracle. Facts gate: pass against the test output, source manifest, issue search, and scoped checks. References gate: not applicable; no external sources are cited. Provenance: self-review after the exact draft and test output were available.

## Next Actions

Run the required prose and after-task checks, inspect the targeted issue search, and release the narrow file lease. Continue with uncovered routes in the full family/effect/backend inventory; do not treat this test as calibrated or programme-complete evidence.
