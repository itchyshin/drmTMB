# After-task report: native zero-one Beta and truncated NB2 smokes

## 1. Goal

Run bounded native integration smokes for zero-one Beta and truncated NB2 predictor-dependent random-effect SD routes.

## 2. Implemented

No package code changed. The existing zero-one Beta and truncated NB2 integration tests ran in the current candidate worktree.

## 3. Mathematical Contract

No model, formula, likelihood, or covariance contract changed.

## 3a. Decisions and Rejected Alternatives

These passing fixtures add focused smoke evidence for their tested routes. They do not close other endpoints, random-effect shapes, providers, layouts, or Julia combinations.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-10-20-native-zero-one-beta-truncated-nb2-smoke.md`
- `docs/dev-log/after-task/2026-10-20-native-zero-one-beta-truncated-nb2-smoke.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- Zero-one Beta: 13 passed, 0 failed, 0 warnings, 0 skipped, 188.0 seconds.
- Truncated NB2: 10 passed, 0 failed, 0 warnings, 0 skipped, 65.4 seconds.
- Both test runners reported no live Julia tests. Total runtime was 253.4 seconds.

## 6. Tests of the Tests

The existing tests exercise these two native routes on their synthetic fixtures. They do NOT establish interval coverage, complete family support, or Julia parity. No tests were added.

## 7a. Issue Ledger

No issue was opened, closed, or changed.

## 8. Consistency Audit

The results are recorded as focused native smoke evidence only. The broad capability matrix remains open.

## 9. What Did Not Go Smoothly

The zero-one Beta test took 188.0 seconds, longer than the truncated NB2 test. The combined sequence completed in 253.4 seconds, within the five-minute estimate.

## 10. Known Residuals

Other response families, endpoints, random-effect shapes, providers, layouts, Julia parity, and interval coverage remain open.

## 11. Team Learning

The zero-one Beta fit can dominate a short smoke batch. Keep separate per-test timings so a slow route remains visible.

## 12. Cross-Product Coverage

Native drmTMB only. This pair of native tests does NOT cover Julia, other distributions or effect/provider combinations, or interval coverage.

## Next Actions

Continue remaining supported families while the Julia source handoff remains pending.
