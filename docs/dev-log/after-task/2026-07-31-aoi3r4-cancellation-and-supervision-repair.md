# AOI-3R4 cancellation and hard-supervision repair

## 1. Goal

Retain the owner-authorized, stalled AOI-3R4 local diagnostic output after
cancellation, then redesign the private runner with a true per-outer wall-time
boundary before any fresh-seed replacement.

## 2. Implemented

Cancelled the supervised R4 terminal session after its additive third outer
attempt exceeded eight minutes without a checkpoint.  The immutable R4 root
retains all output: additive has three outer and nine inner rows plus
`run_complete`; mixed retains only startup/package-load events; no other shard
exists and the top-level `COMPLETE` marker is absent.

Added `tools/run-aoi3-bernoulli-nb2-supervised.py`.  It runs each outer attempt
as an isolated `Rscript` process with Python's `subprocess.run(..., timeout=)`;
each completion, process error, or hard wall-time termination is flushed to
`supervisor-events.csv`.  Any non-complete outer marks the root `INCOMPLETE`
and stops fail closed.

## 3a. Decisions and Rejected Alternatives

R's `setTimeLimit()` was tested and rejected: a one-second limit permitted a
native TMB outer attempt to run for about eight seconds.  It is not presented
as a wall-time guarantee and was removed before commit.  Retrying R4, deleting
its output, pooling its partial rows, or treating its statuses as an uncertainty
finding were rejected.  No fresh seed manifest was created.

## 4. Files Touched

- `tools/run-aoi3-bernoulli-nb2-supervised.py`
- `tests/testthat/test-aoi3-full-refit-runner.R`
- `docs/dev-log/after-task/2026-07-31-aoi3r4-cancellation-and-supervision-repair.md`

The following untracked local root is retained unchanged:

- `docs/dev-log/simulation-artifacts/2026-07-31-aoi3r4-local-diagnostic-smoke/`

## 5. Checks Run

- Focused AOI-3 runner test — PASS, 39 expectations.
- `python3 -m py_compile tools/run-aoi3-bernoulli-nb2-supervised.py` — PASS.
- `git diff --check` — PASS before commit.
- Interactive-terminal survival probe — PASS beyond the former managed
  foreground cutoff.
- Disposable R timeout probe — FAIL as a hard-wall guarantee by design: the
  requested one-second limit yielded an approximately eight-second native TMB
  attempt; the rejected implementation was removed.

## 6. Tests of the Tests

The focused test checks that the supervisor exists and contains the process
launch, `outer_wall_time_exceeded` event, and durable event-file contract.
Python byte-compilation independently checks the supervisor syntax.  The
disposable timeout probe was intentionally adversarial: it caught that an
R-level elapsed limit is cooperative and cannot control the native optimizer.

## 7a. Issue Ledger

- R4 diagnostic completeness — OPEN: partial output only; not reducible.
- Native TMB outer-attempt hang/long-tail — OPEN and now bounded for a future
  supervised replacement.
- AOI-2 point-recovery HOLD and AOI-3 public uncertainty fence — unchanged.

## 8. Consistency Audit

No R4 partial result was reduced or pooled.  The supervisor is private tooling,
not a public API.  No DRAC submission, uncertainty calibration, `vcov()`,
`confint()`, standard-error surface, capability ledger, public article, Lane B,
or foreign Association lane changed.

## 9. What Did Not Go Smoothly

The original long-lived terminal solved the host cutoff but revealed an
unbounded native optimization in additive outer 3.  The first attempted repair
used R's elapsed-time facility, which did not hard-stop native TMB work.  The
replacement process supervisor corrects that specific failure mode.

## 10. Known Residuals

The new supervisor has syntax and structural tests, but has not yet been used
with a fresh AOI manifest.  A separate owner authorization must freeze fresh
seeds, choose the wall-time value, and run that replacement.  R4 remains an
incomplete local launch, not evidence about sandwich validity.

## 11. Team Learning

Memory receipt: native optimizers require an operating-system process boundary
for a true reproducible wall-time limit; an R interpreter timer is insufficient.
This is a private AOI runner lesson, not a public modelling claim.  No durable
brain-memory update is warranted.

Golden Set: not in scope; this is a private execution-control repair, not a
release or capability change.

## 12. Cross-Product Coverage

This work covers ✓ private AOI-3 outer-attempt supervision and R4 launch
retention.  It does NOT cover ✗ a complete smoke, point recovery, covariance
or interval calibration, coverage, DRAC, `vcov()`, `confint()`, standard errors,
other family pairs, random/structured association effects, missingness,
weights, offsets, REML, capability promotion, or public inference.
