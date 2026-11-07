# After Task: Clean-Current First-Look Manifest Verifier

## 1. Goal

Allow the source-bound first-look replay verifier to validate the frozen clean-current Bernoulli manifest without weakening its legacy production-manifest check.

## 2. Implemented

Added `native_sd_stage_two_validate_first_look_manifest()` to enforce the 3,000-row ordered truth grid, positive unique seeds, the clean-current `look1` and master-seed identity, and its frozen design constants. The verifier now calls this shared rule instead of rejecting all manifests except the legacy design.

## 3a. Decisions and Rejected Alternatives

Kept distinct validation branches for `clean_current` and legacy `production`. This preserves the existing legacy source contract and avoids silently treating either seed stream as the other. Assumption: the frozen clean-current look-one contract is the manifest produced from `clean-current-seed-design-v1/look1.csv`; if that manifest changes, update the constants and independent source receipt together.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/verify-first-look.R`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-20-clean-current-first-look-manifest-validator.md`

The stage-two tool directory is untracked in this shared worktree. No files were staged.

## 5. Checks Run

- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: PASS.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R tools/general-sd-regression/native-calibration-stage-two`: PASS.
- `python3 -m unittest discover -s tools/general-sd-regression/native-calibration-stage-two -p 'test_*.py'`: PASS, 50 tests.
- Inspected Totoro's retained clean-current replay manifest, result registry, supervisor receipt, and installed-library paths. No fits were launched.
- `docs/dev-log/check-log.md` was not edited because lane preflight found 424 refs with work on that path.

## 6. Tests of the Tests

The R tests accept synthetic clean-current and legacy manifests. They reject a changed master seed, design mode, look label, row order, and duplicate seed. The separate registry test retains its copied-manifest tamper control. The 50 Python tests cover the surrounding adapter preparation and runner contracts, including clean-current mode routing.

## 7a. Issue Ledger

No issue was opened. The adapter's live clean-current preparation remains blocked on a retained external first-look seal that binds the replay inputs and reconstruction sources. Existing Totoro results alone do not satisfy that replay gate.

## 8. Consistency Audit

Checked the legacy validator path, current clean-current manifest constants, the replay verifier call site, the copied-manifest registry check, and the adapter's first-look replay dependency. The R rule tests, registry test, and Python adapter suite pass. Public formula grammar, likelihood code, model outputs, and Julia code were not changed.

## 9. What Did Not Go Smoothly

The verifier still assumed the historical legacy master seed and design label, which would reject the clean-current manifest. The project closeout generator resolves paths under the canonical hub when invoked from this worktree; its misplaced scaffold was removed, and this report was written directly in the package worktree.

## 10. Known Residuals

This validates manifest identity and verifier plumbing only. It does not authenticate or replay the retained 3,000-result campaign, qualify the installed binary on the three adapter probes, establish Bernoulli uncertainty calibration, or authorize the second calibration look. G0-G8 remain open.

## 11. Team Learning

When a staged-calibration workflow introduces a new frozen seed mode, the first-look replay verifier must validate that mode at the manifest boundary before adapter preparation can reuse its results. The check-log file remains untouched until its shared-path owner releases it.

Memory receipt: the supplied project instructions, source graph, and local test files informed this slice. No LOAD-FIRST manifest was returned by `route.py`; the Golden Set was not run because this change does not touch model behavior.

## 12. Cross-Product Coverage

Covers: clean-current and legacy first-look manifest validation in the native Bernoulli stage-two verifier.

Does NOT cover: live Totoro adapter qualification, second-look fits, calibration, Julia parity, other response families, other random-effect types, or the full general SD-regression programme.
