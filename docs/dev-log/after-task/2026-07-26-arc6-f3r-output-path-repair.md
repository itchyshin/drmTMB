# After-task report — Arc 6 F3R output-path contract repair

## 1. Goal

Repair the F3R preflight contract so the frozen relative output path in the
approval packet is canonicalized against the package root before its exact
SHA-specific path comparison, without invoking F3.

## 2. Implemented

Added `f3r_canonical_out_dir()`; relative paths now join a normalized package
root before `f3r_check_out_dir()` compares them with the frozen expected
`attempt-001` path. The packet states this contract explicitly.

## 3a. Decisions and Rejected Alternatives

Kept the approved relative CLI rather than replacing it with an absolute
machine-specific path. Did not weaken the SHA-specific target, clean-tree,
no-overwrite, source-blob, seed, or one-attempt guards. No runner invocation,
data generation, fit, retry, F4 work, or public exposure occurred.

## 4. Files Touched

- `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R`
- `tests/testthat/test-arc6-f3-provenance-smoke-runner.R`
- `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`
- this report and its plan-versus-actual record

## 5. Checks Run

`devtools::test(filter = "arc6-f3-provenance-smoke-runner")` passed 48
expectations with 0 failures, warnings, or skips. `git diff --check` passed.

## 6. Tests of the Tests

The new expectation supplies the literal packet-shaped relative path to
`f3r_check_out_dir()`. It failed before the repair and passes only when the
path is resolved against the normalized package root; an unrelated absolute
path remains rejected.

## 7a. Issue Ledger

Resolved: relative output paths could fail before layout because they were
compared with an absolute expected path. Deferred: a new F3 authorization and
every F3/F4/public-inference question.

## 8. Consistency Audit

The runner still requires an exact SHA-specific `attempt-001` target. The
packet, parser, and test now agree that a relative target is package-root
relative. No public API or capability surface changed.

## 9. What Did Not Go Smoothly

Formatting the two legacy R files expanded the diff substantially; that churn
was reverted, leaving only the narrow repair.

## 10. Known Residuals

The original F3 authorization remains consumed. This repair does not establish
a successful smoke or authorize another invocation.

## 11. Team Learning

For a one-attempt command, a pure test must exercise the literal approved CLI
shape against an absent target path, including platform path canonicalization.

## 12. Cross-Product Coverage

This covers only the private F3R output-path preflight contract for the
fixed-effect complete-pair Bernoulli × ordinary-NB2 association route. It does NOT cover
F3 execution, inference validity, F4, public inference, other pairs, or Arc D/F5.
