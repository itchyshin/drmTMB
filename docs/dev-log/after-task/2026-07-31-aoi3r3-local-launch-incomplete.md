# AOI-3R3 local diagnostic-smoke launch incomplete

## 1. Goal

Execute the owner-authorized AOI-3R3 replacement local diagnostic smoke after
repairing the private runner's observability and atomic retention.

## 2. Implemented

The runner now retains `run-startup.csv`, `runner-events.csv`, and atomic
attempt-table checkpoints.  A disposable `n = 40` smoke verified all four
events (`startup_retained`, `package_loaded`, `outer_checkpoint_retained`, and
`run_complete`) and retained one outer and one inner row.

The frozen R3 source/manifest preflight then passed.  Its authorized `n = 720`
run retained the additive shard's startup record and two events:
`startup_retained` and `package_loaded`.  It retained no outer checkpoint and
no `run_complete` event.  No later formula shard was created.

## 3a. Decisions and Rejected Alternatives

The R3 root is retained unchanged.  Its seeds are consumed by the attempted
launch and will not be reused.  The result is not called a model, sandwich,
recovery, covariance, interval, or coverage failure because no attempt row was
retained.  A further replacement requires fresh seeds and separate owner
authorization; it is not inferred from this R3 authorization.

## 4. Files Touched

- `tools/run-aoi3-bernoulli-nb2-full-refit.R`
- `tests/testthat/test-aoi3-full-refit-runner.R`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r3-diagnostic-manifest/manifest.csv`
- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r3-diagnostic-manifest/README.md`
- `docs/dev-log/after-task/2026-07-31-aoi3r3-local-launch-incomplete.md`

The following untracked result root is retained and deliberately not modified:

- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r3-local-diagnostic-smoke/`

## 5. Checks Run

- Focused runner test — PASS, 35 expectations.
- Disposable local retention smoke (`n = 40`, one outer and one inner) — PASS:
  startup, package-load, checkpoint, and completion records exist.
- R3 manifest assertion — PASS: 60 rows, 60 unique seeds, 15 outer and 45
  inner allocations, all disjoint from R1 and R2.
- Computational-source diff from `f787599a705e8f2653391adda148155d888bc956`
  across `R`, `src`, `DESCRIPTION`, `NAMESPACE`, and the runner — PASS.
- R3 fresh-root assertion — PASS before launch.

## 6. Tests of the Tests

The focused test requires the startup file, event log, atomic writer, and
per-outer checkpoint event in the runner source.  The separate disposable
invocation exercised those paths on disk, rather than relying only on a static
test.  R3's retained event sequence distinguishes this interrupted launch from
the previous unclassifiable R2 directory.

## 7a. Issue Ledger

- AOI-3 local execution host interrupts an `n = 720` process after package
  loading and before its first outer checkpoint — OPEN.
- AOI-3 runner observability/retention defect — FIXED.
- AOI-2 HOLD and AOI-3 public uncertainty fence — unchanged.

## 8. Consistency Audit

No R3 result table, completion marker, reducer analysis, DRAC submission,
uncertainty API, capability ledger, or public article was created.  The only
retained R3 evidence is a source-pinned startup record and event sequence.
Lane B and all foreign Association lanes remain untouched.

## 9. What Did Not Go Smoothly

The managed foreground execution completed without the shell's expected
per-formula status text after package loading.  A separate `n = 720` disposable
probe showed the same behavior, whereas the small disposable smoke completed.
This supports an execution-host time-limit diagnosis, but does not identify a
package/model failure and is not used as one.

## 10. Known Residuals

R3 does not satisfy the diagnostic-completeness gate: it lacks all 15 outer
and 45 inner rows.  The next executable design must use a launcher whose
process lifetime exceeds the local `n = 720` workload, fresh immutable seeds,
and a separate owner authorization.  DRAC remains unapproved.

## 11. Team Learning

Incremental startup and checkpoint retention turned an empty directory into a
precise operational diagnosis.  For private long-running local evidence runs,
launcher lifetime is part of reproducibility provenance, not merely operator
convenience.

Memory receipt: the local execution interruption and the requirement for a
long-lived launcher are recorded here as AOI-specific provenance, rather than
as a public model or inference finding.  No durable brain-memory update is
warranted.

Golden Set: not in scope; this is a private diagnostic-launch receipt, not a
release or public capability change.

## 12. Cross-Product Coverage

This work covers ✓ private AOI-3 runner observability and the exact R3 launch
state.  It does NOT cover ✗ completed diagnostics, point recovery, covariance
calibration, intervals, coverage, DRAC, `vcov()`, `confint()`, standard errors,
other family pairs, random/structured association effects, missingness,
weights, offsets, REML, capability promotion, or public inference.
