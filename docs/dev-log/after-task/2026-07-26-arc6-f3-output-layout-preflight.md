# After-task report — Arc 6 F3 output-layout preflight failure

## 1. Goal

Make exactly one approved F3 provenance invocation at its pinned source SHA and
audit the resulting immutable output without entering F4.

## 2. Implemented

Created a clean detached worktree at `af2fb9ead5fc9a48d68af8965e34db79e71bf551`,
verified the pinned blobs and absent output path, then made the exact approved
invocation once. It failed before data generation because the layout creator
could not make a missing nested parent path.

## 3a. Decisions and Rejected Alternatives

Did not retry, pre-create the parent directory, change the output path, alter
the CLI, source the runner manually, or begin F4. Each would exceed the
one-attempt authorization or weaken its provenance contract.

## 4. Files Touched

- `docs/dev-log/2026-07-26-arc6-f3-output-layout-negative-disposition.md`
- this report and its plan-versus-actual record

No runner, test, package, ledger, API, public documentation, or Arc D/F5 file
changed in this closeout.

## 5. Checks Run

Before invocation, detached `HEAD` matched the approved SHA, the two F1M blobs
matched, and the approved output path was absent. After failure, the attempted
directory, dataset, and receipt remain absent; the detached worktree is clean.

## 6. Tests of the Tests

The prior focused suite covered the literal output-path identity but not the
case where the canonical nested parent directory is absent. The real one-shot
preflight exposed that missing lifecycle case.

## 7a. Issue Ledger

New: `f3r_layout()` is non-recursive even though the approved output path can
have absent parents. Deferred: a narrow layout-contract repair, regression
test, new source SHA, separate replacement F3 approval, F4, and public
inference.

## 8. Consistency Audit

The failure occurred after local namespace/helper validation and before output
layout creation. No artifact directory, data, fit, private result, or receipt
exists, so no immutable-output contract was violated.

## 9. What Did Not Go Smoothly

The two earlier preflight repairs let the literal approved command reach its
next lifecycle boundary: the layout function assumed parents already existed.

## 10. Known Residuals

All three F3 authorizations are consumed. A source repair and a separate exact
written approval are required before any later F3 invocation.

## 11. Team Learning

The immutable output-path contract needs an explicit parent-creation rule. A
path may be canonical and absent while still requiring recursive creation by
the approved runner itself.

## 12. Cross-Product Coverage

This covers only the F3 output-layout preflight failure. It does NOT cover F3
success, F4, public inference, API exposure, intervals, recovery, coverage,
other association pairs, or Arc D/F5.
