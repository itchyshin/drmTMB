# After-task report — Arc 6 F3 local-helper preflight failure

## 1. Goal

Make one newly approved local F3 provenance invocation from the repaired
SHA-pinned source, then audit its immutable receipt without entering F4.

## 2. Implemented

Created a clean detached worktree at
`b1cf4d5dac50db43013e1c84c2911a3f6cb37855`, verified the F1M blobs, and made
the single exact invocation. It failed before layout because the runner checked
the installed namespace before loading the local source.

## 3a. Decisions and Rejected Alternatives

Did not retry with a loaded namespace, modify `.libPaths()`, source private
helpers, change CLI arguments, alter seed/start/tolerance, or begin F4. Those
would invalidate the one-attempt contract and require a fresh repair decision.

## 4. Files Touched

- `docs/dev-log/2026-07-26-arc6-f3-local-helper-negative-disposition.md`
- this report and its plan-versus-actual record

No runner, test, package, public-documentation, ledger, or Arc D/F5 source
changed in this closeout.

## 5. Checks Run

The detached worktree was clean at the approved SHA and its two F1M blobs
matched. The requested output directory is absent. The focused runner-contract
suite passed 48 expectations with 0 failures, warnings, or skips.

## 6. Tests of the Tests

The passing suite covers path canonicalization but does not exercise
`f3r_preflight()` with an installed namespace lacking a helper that exists in
the local source. The one-shot preflight exposed that lifecycle gap.

## 7a. Issue Ledger

New: helper availability is checked before local namespace loading. Deferred:
a lifecycle-contract repair, its regression test, a new source SHA, a
replacement F3 authorization, F4, and public inference.

## 8. Consistency Audit

The failure follows the source order in `f3r_main()`: preflight precedes
`f3r_load_local_namespace()`. No receipt exists because `f3r_layout()` is
called only after preflight returns.

## 9. What Did Not Go Smoothly

The output-path repair exposed the next live preflight boundary, which the pure
tests had not exercised.

## 10. Known Residuals

Both prior F3 authorizations are consumed. The F3 runner needs a separately
authorized lifecycle repair before another invocation can be considered.

## 11. Team Learning

For a pinned local source, helper validation must prove the helper belongs to
that source; validating the installed namespace before loading the source is
neither sufficient nor operational.

## 12. Cross-Product Coverage

This covers only the private F3 local-helper preflight failure. It does NOT cover
F3 success, interval or SE validity, recovery, coverage, F4, public inference,
other pair classes, or Arc D/F5.
