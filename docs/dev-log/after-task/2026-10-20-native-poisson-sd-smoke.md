# After-task report: native Poisson SD smoke

## 1. Goal

Run bounded native integration smokes for ordinary and zero-inflated Poisson predictor-dependent random-effect SD routes.

## 2. Implemented

No package code changed. The existing ordinary Poisson and zero-inflated Poisson integration tests ran in the current candidate worktree.

## 3. Mathematical Contract

No model, formula, likelihood, or covariance contract changed.

## 3a. Decisions and Rejected Alternatives

The two passing fixtures add smoke evidence only for their tested routes. They do not close all Poisson-family, random-effect, provider, layout, or Julia combinations.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-10-20-native-poisson-sd-smoke.md`
- `docs/dev-log/after-task/2026-10-20-native-poisson-sd-smoke.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "poisson-sd-integration")'`: 58 passed, 0 failed, 0 warnings, 0 skipped, 65.9 seconds.
- The filter matched ordinary Poisson (43 checks) and zero-inflated Poisson (15 checks).
- The test runner reported no live Julia tests.

## 6. Tests of the Tests

Both existing tests exercise the native integration routes on their synthetic fixtures. This does NOT establish interval coverage, broad family support, or Julia parity. No new tests were added.

## 7a. Issue Ledger

No issue was opened, closed, or changed.

## 8. Consistency Audit

The result is reported as a focused native smoke. The open capability matrix and Julia source-ownership boundary remain unchanged.

## 9. What Did Not Go Smoothly

The filter also matched the zero-inflated Poisson test, which added 59.7 seconds to the run. Both tests passed.

## 10. Known Residuals

Other Poisson providers and random-effect shapes remain open. Julia parity and interval coverage are not established by this run.

## 11. Team Learning

Use a narrower filter when a single route is intended; here, the shared test-name fragment intentionally exercised the ordinary and zero-inflated Poisson integration checks together.

## 12. Cross-Product Coverage

Native drmTMB only. This smoke does NOT cover Julia, non-Poisson families, other Poisson random-effect/provider combinations, or interval coverage.

## Next Actions

Continue native smoke checks for remaining core families and obtain a clear Julia source handoff before the source-pinned Bernoulli bridge rerun.
