# summary() flags non-converged fits

## 1. Goal

Close #1545: `summary()` printed only `convergence: 1` for a non-converged fit, while `print()` said "not converged".

## 2. Implemented

`summary.drmTMB()` now stores `convergence_message`. `print.summary.drmTMB()` reuses `drm_convergence_label()` to print "not converged" with the optimizer message and emits a warning, matching `print()`.

## 3a. Decisions and Rejected Alternatives

Warn at print time, not at `summary()` time, so programmatic use of the summary object stays quiet. The Julia-bridge summaries are out of scope.

The first CI run failed in the capability-ledger step, not in a test. The C17 guard pins the whole `R/methods.R` blob, so this edit staled the mc-0568/0569/0576 receipt. The fix is the documented re-certification, not a code or test change.

Re-certification ran with `--tolerance 1e-10`, not exact. The prior receipt (#1513) was produced on Totoro (Linux). On this Mac the runner gives mc-0568 0.0990031773657071, mc-0569 0.166077467316444 and mc-0576 0.0613049351662347, both on this branch and on unmodified origin/main `R/methods.R`. This change therefore moves model-15 behaviour by exactly 0. The 1.3e-11 against the prior receipt is the Linux/macOS difference. 1e-10 follows the af8d397ad precedent.

## 4. Files Touched

- `R/methods.R`, `tests/testthat/test-summary-nonconverged.R`: the fix and its test.
- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv` and `docs/dev-log/implementation-recovery/2026-10-19-summary-nonconverged-1545-c17c2-c14-final-source-compatibility/`: C17 re-certification. Only the receipt paths and `current_source_sha` changed; `source_fingerprint` and `claim_boundary` are untouched.
- This after-task report.

## 5. Checks Run

All on the branch rebased onto main 46f914c11 (#1513), on a macOS arm64 Mac (R 4.6.0, TMB 1.9.21).

- `python3 tools/recertify-c17.py --label summary-nonconverged-1545 --tolerance 1e-10`: pass. `tools/recertify-c17.py` refuses to run while the committed `2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1/` folder (from 2d2db519f) exists, so it was moved aside for the run and restored byte-identical afterwards. The receipt's `dirty-state.txt` records only that move, as in the #1513 receipt.
- Every command of the CI "Validate generated capability ledger" step: pass, including `--check-c14-receipt-equivalence` (C17 current-source compatibility PASS) and `tools/check-capability-runtime.R` (18 routes verified).
- Full testthat suite (NOT_CRAN=true), split with `DRMTMB_TEST_SHARD` k/4 across isolated clones: 454 of 456 files ran, 0 errors, 2 failing tests. `julia-tmb-parity` skips at file level (no Julia). `numeric-kernel-oracle` stalls in TMB 1.9.21's `tweedie_logW` series loop and was stopped.
- `devtools::document()`: no change from this branch. It rewrites the same 39 `man/` files on main (#1571); those rewrites are not committed.

## 6. Tests of the Tests

The new test fails 4 ways against main's code (no `convergence_message`, no warning, no "not converged", no optimizer message) and passes 6/6 with the fix.

Each local failure was re-run on unmodified origin/main 46f914c11 on the same Mac and fails identically:

- `associate-pairs-bernoulli-bernoulli.R:40`: `eta` 0.551583976 vs 0.551583956, a 2e-8 miss of the default tolerance. Passes on Linux.
- `nbinom2-sigma-structured-recovery.R:52-53`: log-likelihood gap 9.0, below the 15 and 10 thresholds. Related to #1444.
- `numeric-kernel-oracle`: stalls at expectation 364 in the same TMB tweedie loop. Totoro (TMB 1.9.25) ran it to completion on the pre-rebase branch.

None of these paths reaches `summary()` or `print.summary.drmTMB()`.

## 7. What This Does Not Cover

The Julia-bridge `summary()` methods still do not warn. The three Mac-only failures above are not fixed here.
