# S2: start/multi_start guard on the engine="julia" bridge, post-#1112

## 1. Scope

Slice S2 of the true-parity plan, on branch
`claude/rev-parity-integration-post1112` (the reverse-parity integration branch
merged with PR #1112's head, 90f61f3da). Closed one defect left by that merge:
`drm_control(start = ..., multi_start = ...)` passed with `engine = "julia"`
was silently ignored rather than refused.

## 2. Defect

`drm_julia_translate_control()` in `R/julia-bridge.R` rejects a fixed list of
`drm_control()` fields that have no effect on the Julia bridge (`se`,
`keep_data`, `keep_model_frame`, `keep_tmb_object`, `sparse_fixed`,
`aggregate_gaussian`, `optimizer_preset`). PR #1112 wrote that list before the
reverse-parity branch added `drm_control(start = NULL, multi_start = 1L)`, so
neither field was in the rejection loop. A user calling
`drmTMB(..., engine = "julia", control = drm_control(start = list(...)))`
would have the start values dropped without any error or warning -- exactly
the failure class (silent divergence between the TMB and Julia engines) this
lane exists to remove.

## 3. Change

- `R/julia-bridge.R`: added `"start"` and `"multi_start"` to the unsupported-
  field loop in `drm_julia_translate_control()`; a non-default value of either
  now aborts with the same "does not support ... setting" message as the
  other TMB-only controls. Updated the abort's third hint line to mention
  `start`/`multi_start` alongside the other native-engine-only controls.
- `R/control.R`: extended the roxygen paragraph #1112 added on `drm_control()`
  ("For `engine = "julia"` base bridge fits, only ...") with one sentence
  noting `start` and `multi_start` are rejected under `engine = "julia"`
  rather than ignored. Regenerated docs; kept only the resulting
  `man/drm_control.Rd` diff (unrelated Rd churn from `devtools::document()`
  in this environment -- a version-format change in `confint.drmTMB.Rd` and
  two newly-generated Rd stubs for previously undocumented internal
  functions -- was discarded).
- `tests/testthat/test-julia-bridge.R`: appended three `test_that()` blocks
  calling `drmTMB:::drm_julia_translate_control()` directly (pure R, no live
  Julia needed): one asserting a supplied `start` list aborts with a message
  mentioning "start", one asserting `multi_start = 3L` aborts with a message
  mentioning "multi_start", and one no-regression check that
  `drm_julia_translate_control(drm_control())` still returns `list()`.

## 4. Evidence

- Filtered test run (`julia-bridge`, `start-contract`, `objective-at`) is
  green: 0 failed, 0 errored (2 CRAN-gated skips in `objective-at`, expected).
- Gate-check (`.unlazy/true-parity/gates/leaf-s2.md`): all 4 gates MET
  (S2-G1 merge ancestry, S2-G2 start-test pass, S2-G3 red control, S2-G4
  filtered suite).
- S2-G3 red control: with `"start"`/`"multi_start"` temporarily removed from
  the loop, the two new tests failed with
  "Expected `drmTMB:::drm_julia_translate_control(ctrl)` to throw a error."
  Restoring the file made `git diff R/julia-bridge.R` show only the intended
  two-hunk edit, and the same test run returned to green.

## 5. Not covered

No live-Julia test exercises the abort at the `drmTMB()` call level (i.e.
`drmTMB(..., engine = "julia", control = drm_control(start = ...))` end to
end); the existing `"engine = 'julia' guardrails fail before JuliaCall
setup"` test in the same file shows that class of guard fires before any
JuliaCall session is needed, but this task only adds direct unit coverage of
`drm_julia_translate_control()`. No design-doc update was made because this
is a control-surface bug fix, not a new likelihood or estimator; the fix
narrows an existing documented boundary rather than changing model semantics.

## 6. Ownership

`R/julia-bridge.R` (`drm_julia_translate_control()` only), `R/control.R`
(roxygen only), `man/drm_control.Rd`, and
`tests/testthat/test-julia-bridge.R` were touched under S2's OWNS line in
`leaf-s2.md`.
