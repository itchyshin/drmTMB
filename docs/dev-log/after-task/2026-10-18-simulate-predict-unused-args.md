# After-task: refuse unused arguments in `simulate()` and `predict()` (#1536)

## What was wrong

`simulate.drmTMB()` had no `newdata` formal, so `simulate(fit, newdata = nd)`
sent `newdata` into `...`, ignored it, and returned one row per training
observation. `predict.drmTMB()` accepted `...` and never checked it, so
`predict(fit, se.fit = TRUE)` or a typo returned the plain vector.

## What changed

- `simulate.drmTMB()` gains `newdata = NULL`. A non-`NULL` value aborts with a
  message that names `predict_parameters()` as the route for new rows. Drawing
  for new rows (random effects, trial denominators, known `V`, per-family
  draws) is not implemented and is out of scope here.
- `simulate.drmTMB()` and `predict.drmTMB()` abort on any value in `...`
  ("`...` is reserved for future options"), matching `predict_parameters()`.
- Roxygen text and `NEWS.md` updated.

## Evidence

`tests/testthat/test-simulate-predict-unused-args.R`: 6 failures before the
change, 0 after.

## Not done (still open under #1536 follow-ups)

`fitted.drmTMB()` and
`residuals.drmTMB()` still leave `...` unchecked: they are standard generics
where other packages pass extra arguments, so tightening them needs its own
review. `predict.drmTMB_julia()` now refuses unused `...` too. This PR is limited to the
methods in the issue title and the Julia predict method. The issue therefore stays partly open for
those methods; see the PR description.

## Capability-ledger receipt refresh

Editing `R/methods.R` changed the blob hash that the C14/C17 model-15
receipt pins, so `capability_ledger.py --check-c14-receipt-equivalence` failed
in CI as a stale receipt. No model-15 code path changed. I reran the committed
runner (`tools/run-lane-c-c17c1-c14-model15-compatibility.R`) on the committed
head: 12/12 attempts pass, and the cell means agree with the previous receipt
to about 1e-11. The ledger rows now point at
`docs/dev-log/implementation-recovery/2026-10-18-simulate-predict-unused-args-c14-compatibility/`
with `current_source_sha` set to the run head; `source_fingerprint` is
unchanged.
