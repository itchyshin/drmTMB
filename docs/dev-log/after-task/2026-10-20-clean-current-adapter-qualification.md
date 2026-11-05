# After Task: Clean-Current Bernoulli Adapter Qualification

## 1. Goal

Make the Bernoulli stage-two worker accept the adapter's frozen one-probe receipt while preserving the stricter production calibration requirements.

## 2. Implemented

Added `native_sd_stage_two_validate_worker_receipt()` for the two distinct receipt modes. Adapter qualification requires one exact frozen probe and `calibration_claim=false`. Production still requires its external-go status, a true calibration claim, and all 3,000 rows in the batch. The worker now uses this shared validator before checking the full frozen batch mapping.

The updated worker passed the three source-bound Totoro probes. Each fit returned a valid profile interval and passed the independent Laplace-oracle check. The sealed receipt replay also passed. This result qualifies the adapter route only; it contributes no coverage evidence.

## 3a. Decisions and Rejected Alternatives

The adapter receipt must remain non-calibrating. I did not change its `calibration_claim` to true to satisfy the old worker check. Production receipt requirements remain unchanged, and no model likelihood or parameterization changed.

## Mathematical Contract

No statistical model or formula changed. The checked contract is operational: an adapter probe maps to one frozen look-two row, while a production worker must cover its complete frozen 3,000-row batch.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration/worker-095.R`
- `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261020/adapter-qualification-v13/`
- `docs/dev-log/check-log.d/2026-10-20-clean-current-adapter-qualification.md`
- `docs/dev-log/after-task/2026-10-20-clean-current-adapter-qualification.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `.unlazy/general-sd-regression/GATES.md`

No public model documentation, examples, package exports, or likelihood files changed in this bounded adapter repair.

## 5. Checks Run

- The R stage-two rules test passed with `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- The Python stage-two adapter suite passed all 57 tests in 28.6 seconds.
- R parsed the updated worker and shared stage-two rules successfully.
- The source-bound Totoro qualification passed all 3 probes in 27.552 seconds. The first-look seal, source registry, isolated binary, frozen look-two manifest, worker, and rules are hash-pinned in `evidence/calibration-20261020/adapter-qualification-v13/`.
- Independent replay returned `ADAPTER_QUALIFICATION_REPLAY_PASS status=PASS attempted=3`.
- `git diff --check` found an unrelated pre-existing blank line at EOF in `tests/testthat/test-binomial-sd-integration.R:225`. That file was not changed.

## 6. Tests of the Tests

The receipt-rule test rejects a probe with a true calibration claim, changed frozen source index, changed local probe index, or a production-mode flag. It also requires production mode to carry a true claim and the full ordered batch. The actual Totoro worker path failed on the prior production-only receipt condition, then passed after the mode-aware validation was wired into the worker. This checks both the helper and the integration path.

## 7a. Issue Ledger

The read-only search `gh issue list --state open --limit 100 --search 'Bernoulli SD regression calibration' --json number,title,url` returned no matching open issue. No issue was opened, commented on, or closed.

## 8. Consistency Audit

The adapter receipt continues to set `calibration_claim=false` and `campaign_complete=false`; the evidence note and acceptance ledger preserve that boundary. G2 remains open because 3 probes cannot establish recovery or interval calibration. No formula grammar, likelihood, status inventory, or pkgdown change was needed. The earlier v10 and v11 failures remain preserved as failure evidence.

## 9. What Did Not Go Smoothly

The first source-bound attempt used a noncanonical manifest path. The next exposed a worker that treated every stage-two receipt as a production calibration receipt. The first corrected overlay failed because its replacement hashes came from the adapter tooling directory, while the package copy carried the updated files. I preserved those attempts and created a versioned overlay and adapter-tool copy; the earlier evidence remains unchanged.

## 10. Known Residuals

The three-probe result is not calibration and does not authorize a 9,000-attempt look. A campaign-specific timing and resource review is still needed. All programme gates G0-G8 remain open. The broader family/effect matrix, Julia parity, recovery grids, calibrated uncertainty, public documentation, and independent programme closeout remain outstanding.

## 11. Team Learning

Qualification and production receipts need separate executable contracts, and the test must exercise the real worker path with the exact source-bound library. Source overlays also need to pin the replacement file in both the package copy and the adapter tooling copy used to construct batch registries.

## 12. Cross-Product Coverage

This task covers the clean-current Bernoulli adapter worker and receipt validator on native R/TMB. It does NOT cover model-family admission, random-effect types, Julia parity, recovery, calibrated uncertainty, prediction/extraction APIs, or public user documentation. G2 and all other programme gates remain open.
