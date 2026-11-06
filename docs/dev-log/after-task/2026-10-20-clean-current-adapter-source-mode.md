# After Task: Clean-Current Bernoulli Adapter Source Mode

## 1. Goal

Allow the Bernoulli adapter qualification tooling to validate and run the
clean-current look-two probes against their exact frozen source manifest while
preserving the legacy route.

## 2. Implemented

Added a shared adapter-source resolver for the legacy and clean-current
manifests. The clean-current mode verifies the frozen `look2.csv` SHA, the
manifest schema and ordered rows, unique seeds, prior-stream disjointness, and
the three source-bound probe identities. Preparation registers the source and
writes a non-calibration adapter design receipt. The runner resolves the same
source mode, validates each transformed batch, dispatches the worker with the
matching design mode, and records source and worker modes in its receipt.
Replay now checks clean-current receipts against the source manifest and
retained batch artifacts. Legacy remains the default.

## 3a. Decisions and Rejected Alternatives

The clean-current manifest uses its own schema and seed stream. I kept its
validation separate from the legacy production-manifest rules and share only
the adapter source-selection contract. The earlier legacy PASS does not qualify
the clean-current package path. No distribution likelihood or parameterization
changed.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/prepare-adapter-qualification.py`
- `tools/general-sd-regression/native-calibration-stage-two/run-adapter-qualification.py`
- `tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/README.md`
- `docs/dev-log/check-log.d/2026-10-20-clean-current-adapter-source-mode.md`
- `docs/dev-log/after-task/2026-10-20-clean-current-adapter-source-mode.md`

The stage-two tooling directory is untracked in this shared worktree, so Git
reports its contents as untracked rather than as a tracked-file diff. No files
were staged.

## 5. Checks Run

- `python3 -m unittest test_stage_two.py`: PASS, 50 tests in 26.3 seconds.
- `python3 -m py_compile stage_two.py prepare-adapter-qualification.py run-adapter-qualification.py test_stage_two.py`: PASS.
- `git diff --check`: PASS.
- The clean-current runner test substitutes the supervisor, launches no model
  fits, checks all three probe positions, and successfully replays the resulting
  source-bound receipt.
- The legacy positive runner test remains in the same passing suite.
- No Totoro or DRAC job, calibration fit, email, push, merge, or release ran.

## 6. Tests of the Tests

The new source-resolver tests first failed because the shared resolver was
absent. They now pass after checking exact clean-current source identity and
rejecting both a modified manifest and a seed collision. The runner integration
test exercises the actual CLI, but replaces the worker supervisor with a
no-fit recorder. Its synthetic completed rows test receipt validation and
replay, not model fitting or numerical recovery.

## 7a. Issue Ledger

This is internal calibration tooling and does not alter the public formula or
model API. The existing issue search for adapter qualification found no
matching issue; no issue was opened or changed.

## 8. Consistency Audit

The old runner invocation remains the default and the existing legacy positive
test passes. Clean-current preparation and execution share one source resolver;
the runner also resolves the manifest from each registered batch before
dispatch. The README distinguishes fit-free plumbing from live qualification.
Formula grammar, likelihood documentation, package outputs, NEWS, public
vignettes, and pkgdown navigation were not changed because package behavior did
not change.

## 9. What Did Not Go Smoothly

Legacy receipts use `production` as their design label while the CLI option is
named `legacy`. The resolver now accepts that existing receipt label as a
compatibility value. The first full suite exposed this mismatch and its tests
passed after the compatibility branch was added.

## 10. Known Residuals

This work does not establish that the actual installed TMB library passes the
three clean-current probes. A source-bound Totoro adapter qualification remains
next. Bernoulli recovery and interval calibration remain open, as do the fresh
second-look decision and all programme gates G0-G8. Julia parity for calibrated
Bernoulli SD uncertainty is also unproven.

## 11. Team Learning

When a calibration adapter changes seed manifests, record both the source mode
and exact manifest digest in preparation and run receipts. Replaying those
receipts through the same resolver prevents an operational PASS from crossing
between seed streams.

## 12. Cross-Product Coverage

This slice covers clean-current Bernoulli adapter source selection, row mapping,
execution dispatch, and receipt replay in internal Python tooling. This slice
does NOT cover live package qualification, R/TMB numerical recovery, Julia
parity, calibrated uncertainty, other families or random-effect types, public
model outputs, or the full programme finish line.
