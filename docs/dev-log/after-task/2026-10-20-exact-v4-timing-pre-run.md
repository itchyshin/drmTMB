# After Task: Exact-v4 Bernoulli Timing Pre-run

## 1. Goal

Measure Totoro runtime for the current native Bernoulli 95% profile worker and preserve evidence for sizing the possible 9,000-fit second look.

## 2. Implemented

Copied the complete 45-fit timing-only capsule into versioned local evidence and recorded the exact receipts, hashes, and runtime projection. No model or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The existing calibration contract and 95% profile worker remain unchanged. I did not treat timing success as calibration evidence or infer permission to run production from the runtime projection.

## Mathematical Contract

No statistical model, formula, or inferential claim changed. The run used the frozen ordinary Bernoulli SD-regression worker at 95% profile level, with `calibration_claim=false`. Timing evidence does not establish recovery or interval calibration.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/calibration-20261020/timing-exact-v4-v2/`
- `docs/dev-log/check-log.d/2026-10-20-exact-v4-timing-pre-run.md`
- `docs/dev-log/after-task/2026-10-20-exact-v4-timing-pre-run.md`
- `docs/dev-log/after-task/2026-10-20-exact-v4-timing-pre-run.assessment.json`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `.unlazy/general-sd-regression/GATES.md`

## 5. Checks Run

- Totoro completed all 45 planned fits in 27.548 seconds with 16 workers. The capsule records 45 valid 95% profile intervals, 45 passing independent Laplace-oracle checks, and no profile failures, boundaries, warnings, or errors.
- Local Python readback checked the 45 result rows and key manifest, registry, supervisor, attempts, and summary digests. Digests are recorded in the evidence README.
- The conservative projection uses the largest observed fit time (9.757 seconds), 16 workers, 188 waves per 3,000-fit batch, and 180 seconds of overhead: 2,014.316 seconds per batch and 6,042.948 seconds (100.7 minutes) total. This is below the 10,500-second cap, but a new validated source-bound GO record remains required.
- The report validator confirmed structure. The prose lint returned no new findings. All programme gates G0-G8 remain open.
- `git diff --check` reports an existing blank line at EOF in `tests/testthat/test-binomial-sd-integration.R:225`; this file is outside the timing-evidence slice and was left unchanged.

## 6. Tests of the Tests

An independent local scan checked every result row for completion, profile validity, oracle pass, boundary, warning, error, and elapsed time. This confirms the timing inputs; it does not test coverage calibration.

## 7a. Issue Ledger

The prior read-only search for open Bernoulli SD regression calibration issues returned no matches. No issue was opened, edited, or closed.

## 8. Consistency Audit

The evidence README, check-log shard, checkpoint, and G2 ledger all preserve `calibration_claim=false` and identify the runtime as a projection. The estimate is calculated from the retained maximum per-fit time and frozen worker/cap settings. No equations, examples, API references, README status, roadmap, NEWS, known-limitations, formula grammar, or pkgdown navigation needed changes because package behavior did not change. Exact task-specific search: `rg -n "timing-only|calibration_claim|look2_required|100.7 minutes" docs/dev-log/general-sd-regression/evidence/calibration-20261020/timing-exact-v4-v2 docs/dev-log/after-task/2026-10-20-exact-v4-timing-pre-run.md docs/dev-log/check-log.d/2026-10-20-exact-v4-timing-pre-run.md LOOP/lanes/general-sd-regression/checkpoint.md .unlazy/general-sd-regression/GATES.md`.

## 9. What Did Not Go Smoothly

The first timing-root attempt stopped before any fits because its runner environment omitted `DRMTMB_SD_TEST_LIBRARY`. That root was preserved. A fresh versioned root completed the exact-v4 timing pre-run.

## 10. Known Residuals

One 45-fit timing capsule cannot establish runtime tail behavior, recovery, coverage, false-positive rates, or calibrated uncertainty. The stage-two source-bound GO chain and production execution authorization are incomplete. The broader response-family/effect matrix, Julia parity, public documentation, and independent programme closeout remain outstanding.

## 11. Team Learning

Pin the test library explicitly in the remote runner environment before starting timing work. Preserve failed preparation roots so later receipts do not obscure which attempt actually launched.

## 12. Cross-Product Coverage

This timing run covers one native Bernoulli route on Totoro. It does NOT cover Julia, other response families, other random-effect types, recovery, or calibrated inference. The next action is to validate the timing receipt against the current source-bound GO contract and retain all approval/source hashes before preparing any production capsule. Keep G0-G8 open until each programme acceptance condition is independently met.
