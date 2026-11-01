# summary() flags non-converged fits

## 1. Goal

Close #1545: `summary()` printed only `convergence: 1` for a non-converged fit, while `print()` said "not converged".

## 2. Implemented

`summary.drmTMB()` now stores `convergence_message`. `print.summary.drmTMB()` reuses `drm_convergence_label()` to print "not converged" with the optimizer message and emits a warning of class `drmTMB_convergence_warning` (the fit-time warning's class), matching `print()`.

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

## 8. Review Round (R reviewer blockers)

Changes in 8bf475680:

- The `summary()` warning now has class `drmTMB_convergence_warning`, and both tests assert it with `expect_warning(class = ...)`. Removing the class makes each test fail exactly that expectation.
- `skip_on_cran()` guards both live fits. `inst/extdata/env-skip-census.tsv` gains one `cran-lane` row, regenerated with `tools/write-env-skip-census.R` (`--check` passes).
- A second test fits a real Student t model with a capped nlminb budget (`eval.max = 4`), so the warning is checked against a genuine optimizer message, not a mocked one. The #1545 false-convergence fits themselves no longer reproduce after #1504: 0 of 300 local `student()` fits (nu 30 to 1e6 and Gaussian data, n 50 to 1000) failed to converge, and the original data files sit on the sweep box.
- NEWS.md entry under Bug fixes.

Checks, all on this Mac at 63532a35a:

- C17 re-certified against 8bf475680 (record committed in 63532a35a): |change| 0.000e+00 on all three cells against the previous receipt, so it passes at exact tolerance too. Every command of the CI ledger step passes.
- Full testthat suite, 4 isolated shards: 454 of 456 files ran, 3,330 tests, 0 errors, 2 failing tests. They are the same two Mac-only failures listed in section 6, which fail identically on main. `numeric-kernel-oracle` was excluded up front because of the TMB 1.9.21 stall shown there; `julia-tmb-parity` skips. New tests: 6/6 and 5/5.
- `devtools::document()`: the same 39 #1571 `man/` rewrites and nothing else; not committed.

Julia fits (`engine = "julia"`) still print a clean summary without the warning until the #1129/#1564 pair lands; that is out of scope here.

## 9. Rebase onto main 5aa693bab (#1590)

The five branch commits rebased onto 5aa693bab without conflicts. #1590 changed only lss-tip-identity evidence files.

- lss-tip-identity receipt: `tools/ci-receipt-staleness.sh` named one stale hash, `R/methods.R`, which this branch changes. I regenerated `public-001.json` with the unchanged runner `tools/run-julia-phylo-labels-public.R`, Julia 1.13.0 and DRModels.jl `da8b3f871` (the #1590 pin; 95 of 95 Julia source hashes match), with one thread. PASS in 69.9 s, 8 of 8 checks. Every native, bridge and direct coefficient and log-likelihood is bit-identical to the #1590 receipt, and the checker log (`--current --self-test`) is byte-identical. The prior receipt is kept under `historical-pre-1545-2026-10-19/`.
- C17: `python3 tools/recertify-c17.py --label rebase-1545 --tolerance 1e-10`, with the 2d2db519f folder moved aside and restored byte-identical. |change| is 0 on all three cells. The manifest changes only the receipt paths and `current_source_sha`, which now names a4ce4172f instead of the pre-rebase 8bf475680. `dirty-state.txt` also lists one untracked agent-wiring file (`.claude/skills/graft/SKILL.md`).

Checks on this Mac at cf9652919:

- Full testthat suite (NOT_CRAN=true), 4 shards in isolated worktrees: 454 of 456 files ran, 3,330 tests, 0 errors, 2 failing tests. They are the two failures in section 6, with the same numbers. Main's `R/`, `src/`, `tests/` and `inst/` are identical at 46f914c11 and 5aa693bab, so the earlier A/B against main still applies. `numeric-kernel-oracle` was excluded up front (TMB is still 1.9.21) and `julia-tmb-parity` skips. New tests: 6/6 and 5/5.
- Every command of the CI "Validate generated capability ledger" step passes.
- `tools/ci-receipt-staleness.sh`: exit 0, 57 of 57 R/ hashes match; with `DRM_JL_PATH` set, 95 of 95 Julia hashes match.
- `devtools::document()`: the same 39 #1571 `man/` rewrites and nothing else; not committed.
