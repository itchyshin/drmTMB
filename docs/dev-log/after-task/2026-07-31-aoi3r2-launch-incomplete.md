# AOI-3R2 local diagnostic-smoke launch incomplete

## 1. Goal

Execute the owner-authorized frozen AOI-3R2 local diagnostic smoke with its
preflight and immutable output contract.

## 2. Implemented

Ran the required source/manifest preflight successfully and launched the
frozen command. The runner created only the additive shard directory, then
exited without any retained outer/inner rows, result manifest, session info,
completion marker, or diagnostic error text.

## 3a. Decisions and Rejected Alternatives

The incomplete root is retained unchanged. Reusing the same frozen seeds in a
new root, deleting the empty shard, inferring that no data were generated, or
calling this a smoke failure were rejected: none is supported by retained
attempt-level evidence. A source/launcher repair and a fresh immutable
replacement need a further owner decision.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-31-aoi3r2-launch-incomplete.md`

The following untracked local output root was created by the authorized launch
and is retained, not modified:

- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r2-local-diagnostic-smoke/`

## 5. Checks Run

- Computational-source diff against `4d2b1afac7c45bdef74b98487a16a69535db2b81` — PASS.
- AOI-3R2 manifest count/seed/source assertion — PASS: 60 rows, unique seeds,
  frozen source SHA.
- Fresh result-root assertion — PASS before launch.
- Direct runner invocation against the now-existing additive shard — correctly
  refuses overwrite; confirms the runner entry point and immutable-root guard.

## 6. Tests of the Tests

The immutable-root negative control attempted the same command against the
created additive shard and received the expected overwrite refusal. It proves
the observed directory was created by the run boundary, but cannot prove which
unrecorded computation occurred afterward.

## 7a. Issue Ledger

- AOI-3R2 launch retained no result rows or error diagnostic after creating its
  first shard — OPEN, fail closed.
- AOI-2 HOLD and AOI-3 public uncertainty fence — unchanged.

## 8. Consistency Audit

No AOI-3R2 output is suitable for the diagnostic reducer because its required
outer/inner artifacts do not exist. No DRAC submission, uncertainty API,
public documentation, capability ledger, or foreign-lane file changed.

## 9. What Did Not Go Smoothly

The screen launcher exited before creating any shard; a logged detached launcher
also produced no work. The managed foreground invocation created the additive
directory but completed without result files or console diagnostic. Process
inspection is restricted in this environment, so no additional cause is claimed.

## 10. Known Residuals

The exact post-directory exit cause is unknown. The frozen AOI-3R2 smoke is not
complete, invalid, passed, failed, or rerunnable from the available evidence.
It is an incomplete launch that must not be pooled with AOI-3R1.

## 11. Team Learning

Memory receipt: the AOI all-attempt/provenance rule required retaining this
incomplete root rather than silently retrying. Golden Set: not in scope; this
is a private launch-receipt, not a release or public capability change.

## 12. Cross-Product Coverage

This receipt covers ✓ the AOI-3R2 launch/provenance state. It does NOT cover ✗
any diagnostic result, recovery, covariance, interval, coverage, DRAC,
`vcov()`, `confint()`, other family pair, random/structured association effect,
missingness, weight, offset, REML, or public inference claim.
