# After-task report: native Gamma and NB2 SD smokes

## 1. Goal

Run bounded native integration smokes for predictor-dependent random-effect SD regression in Gamma and NB2 response families.

## 2. Implemented

No package code changed. The existing Gamma and NB2 integration tests ran in the current candidate worktree.

## 3. Mathematical Contract

No model, formula, likelihood, or covariance contract changed.

## 3a. Decisions and Rejected Alternatives

These passing fixtures add smoke evidence for the tested ordinary-effect routes only. They do not close all family, endpoint, effect, provider, layout, or Julia combinations.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-10-20-native-gamma-nb2-sd-smoke.md`
- `docs/dev-log/after-task/2026-10-20-native-gamma-nb2-sd-smoke.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^(gamma|nbinom2)-sd-integration$")'`: 75 passed, 0 failed, 0 warnings, 0 skipped, 148.9 seconds.
- Gamma: 23 checks, 7.4 seconds. NB2: 52 checks, 141.5 seconds.
- The test runner reported no live Julia tests.

## 6. Tests of the Tests

The existing integration fixtures check the tested Gamma and NB2 SD-regression routes. This does NOT establish interval coverage, complete family support, or Julia parity. No tests were added.

## 7a. Issue Ledger

No issue was opened, closed, or changed.

## 8. Consistency Audit

The result is recorded as focused native evidence only. The broader capability matrix and Julia source-ownership boundary remain open.

## 9. What Did Not Go Smoothly

The NB2 fixture took 141.5 seconds. Both tests completed without errors.

## 10. Known Residuals

Other family endpoints, structured providers, random-effect shapes and layouts remain open. Julia parity and interval coverage are not established by this run.

## 11. Team Learning

The exact filter `^(gamma|nbinom2)-sd-integration$` selected only the intended two test files, avoiding the broader route matches seen with an unanchored filter.

## 12. Cross-Product Coverage

Native drmTMB only. This smoke does NOT cover Julia, non-Gamma/NB2 distributions, other effect/provider combinations, or interval coverage.

## Next Actions

Continue bounded tests for remaining families, while seeking the Julia source handoff required for a source-pinned Bernoulli bridge rerun.
