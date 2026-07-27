# After-task report — Arc 6 F3R local-helper lifecycle repair

## 1. Goal

Repair only the F3R helper-validation lifecycle exposed by the consumed
one-shot F3 attempt, without generating data, fitting models, or rerunning F3.

## 2. Implemented

The runner now loads the preflighted local package source, validates its two
required private helpers in that namespace, and only then creates the immutable
output layout. The installed `drmTMB` namespace is no longer part of that
validation decision.

## 3a. Decisions and Rejected Alternatives

Did not bypass the check with `.libPaths()`, source private functions directly,
loosen the SHA/blob guard, or create the output directory before local-source
validation. Those alternatives would weaken the pinned, one-attempt contract.

## 4. Files Touched

- `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R`
- `tests/testthat/test-arc6-f3-provenance-smoke-runner.R`
- `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`
- this report and its plan-versus-actual record

## 5. Checks Run

`devtools::test(filter = "arc6-f3-provenance-smoke-runner")` passed with 52
expectations. `git diff --check` passed. No F3 runner invocation occurred.

## 6. Tests of the Tests

The added regression test uses a synthetic local namespace to verify helper
availability and checks source order: local-source loading, helper validation,
then output layout. It does not call `f3r_main()` and therefore cannot generate
data or fit a model.

## 7a. Issue Ledger

Resolved: helper validation incorrectly inspected the installed namespace
before the source-pinned local namespace was loaded. Deferred: a separately
approved one-shot F3 execution, F4 calibration or compute, and any public API
or inference route.

## 8. Consistency Audit

The repair preserves the exact CLI, source SHA/blob checks, absent-directory
requirement, immutable attempt path, seed, and no-overwrite behavior. Failed
local-source loading or helper validation occurs before layout creation.

## 9. What Did Not Go Smoothly

The previous path repair made the literal approved CLI reach the next genuine
preflight boundary, revealing that helper provenance was checked at the wrong
point in the lifecycle.

## 10. Known Residuals

Both earlier F3 authorizations remain consumed. This repair needs its own
committed SHA and then a fresh written, SHA-specific approval before one F3
attempt can occur.

## 11. Team Learning

For source-pinned developer runners, validate private helper provenance only
after loading and authenticating the pinned local namespace; installed-package
state is not evidence about source-pinned code.

## 12. Cross-Product Coverage

This covers only local helper-validation ordering. It does NOT cover F3
execution or success, F4, public inference, API exposure, intervals, recovery,
coverage, other response pairs, or Arc D/F5.
