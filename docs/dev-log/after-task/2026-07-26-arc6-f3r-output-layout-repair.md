# After-task report — Arc 6 F3R output-layout preflight repair

## 1. Goal

Repair only the F3R output-layout lifecycle exposed by the consumed one-shot
F3 attempt, without generating data, fitting models, or rerunning F3.

## 2. Implemented

`f3r_layout()` now recursively creates the already-preflighted canonical output
path and then its five required subdirectories. The literal-CLI regression test
starts with absent parents, validates the frozen path, and verifies that layout.

## 3a. Decisions and Rejected Alternatives

Did not pre-create the parent outside the runner, relax the canonical-path
check, allow an alternate output path, change the seed or CLI, or rerun F3.
Those alternatives would weaken the SHA-pinned, one-attempt contract.

## 4. Files Touched

- `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R`
- `tests/testthat/test-arc6-f3-provenance-smoke-runner.R`
- `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`
- this report and its plan-versus-actual record

## 5. Checks Run

`devtools::test(filter = "arc6-f3-provenance-smoke-runner")` passed with 57
expectations. `git diff --check` passed. No F3 runner invocation occurred.

## 6. Tests of the Tests

The new pure regression starts with an absent parent path, parses the literal
approved CLI, applies the frozen canonical-path check, calls only `f3r_layout()`,
and asserts that the canonical attempt directory and five required children
exist. It neither calls `f3r_main()` nor generates data or fits.

## 7a. Issue Ledger

Resolved: non-recursive directory creation rejected the approved nested output
path before logging. Deferred: a new source SHA, a separately approved one-shot
F3 invocation, F4, public inference, and API exposure.

## 8. Consistency Audit

`f3r_main()` still calls the exact CLI parser, source/blob preflight, local
namespace validation, and helper validation before layout. The preflight
requires the output directory to be absent and canonical before recursion runs.

## 9. What Did Not Go Smoothly

The output-path identity contract was correct but incomplete: a valid absent
nested path needs the runner, rather than an operator, to create its parents.

## 10. Known Residuals

All previous F3 authorizations are consumed. The repaired runner must be
committed and receive a fresh source-SHA-specific approval before one attempt.

## 11. Team Learning

An immutable output contract needs both an exact identity check and an explicit
creation rule. The creation rule belongs after preflight, not in manual setup.

## 12. Cross-Product Coverage

This covers only output-layout creation. It does NOT cover F3 execution or
success, F4, public inference, API exposure, intervals, recovery, coverage,
other association pairs, or Arc D/F5.
