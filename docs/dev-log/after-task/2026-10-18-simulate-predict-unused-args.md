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
