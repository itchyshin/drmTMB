# 2026-09-01 — Store the final gradient at fit time (`claude/rev-parity-b1-stored-gradient`)

## What this is

R-side half of DRM.jl #569's comparability clause (the Julia twin returns
the final gradient residual directly on its fit result). `drmTMB()` fits now
store the final outer gradient at `opt$par`, and the label of its largest
|component|, at fit time — so gradient diagnosis is a property of the fit
rather than something computed lazily (and only when `object$obj` was
retained) inside `check_drm()`'s `check_fixed_gradient()` (`R/check.R`,
untouched here).

## What changed (`R/drmTMB.R` only)

- New helper `drm_fit_gradient(obj, opt)`: calls `obj$gr(opt$par)`, returns
  `list(gradient = <named numeric>, max_component = <label>)`. Labels come
  from `fixed_gradient_component_label()` (defined in `R/check.R`, called
  not duplicated) so the stored label and the live `check_drm()` row can
  never drift onto two different labeling rules.
- In `drm_fit_spec()`, inserted right after `tmb_state <-
  drm_tmb_selected_state(obj, opt)` (before `drm_compute_uncertainty()` /
  `sdreport()` runs): compute `fit_gradient <- drm_fit_gradient(obj, opt)`,
  then immediately `drm_pin_tmb_object_to_optimum(obj, opt, tmb_state)`.
  `obj$gr()` mutates `obj$env$last.par` as a side effect independent of the
  `par` it is handed, so the re-pin is required to protect the
  selected-optimum invariant (docs/design/35) for the `report()` call later
  in the same function, which in fact reads `tmb_state$last.par.best`
  explicitly rather than from `obj$env` — so the re-pin is defence-in-depth,
  not strictly load-bearing for today's callers, but is cheap and matches
  the brief's constraint literally.
- Two new fields on the returned `fit` list: `gradient` (named numeric
  vector, same order/names as `opt$par`) and `gradient_max_component`
  (character label, `"none"` if the parameter vector is empty). These are
  added to the `fit <- list(...)` literal before
  `drm_apply_storage_control(fit, control)` runs, so they are unaffected by
  `keep_tmb_object`, `keep_data`, or `keep_model_frame` — `control.R`
  (untouched) only ever nulls `fit$obj`, never these two new fields.

## Verification (TDD)

- `tests/testthat/test-stored-gradient.R` written first; ran RED against
  the pre-change tree — `fit$gradient` was `NULL`, four separate assertion
  failures for the missing/wrong-typed field, confirming the test failed
  for the intended reason (feature absent), not a broken test.
- Implemented, then GREEN: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 16 ]` for the
  new file alone.
- Filtered suite `filter = "check|gradient|optimizer|start"`:
  **104 test blocks / 585 expectations passed, 0 failures, 4 skipped**
  (pre-existing CRAN skips only — optimizer-retry ladder tests and one
  check_drm() SE test). Two known `sd_phylo*()` deprecation warnings, both
  pre-existing and unrelated.

### The four "done well" checks from the brief

1. **Survives `keep_tmb_object = FALSE`** — tested directly: fit with
   `keep_tmb_object = FALSE` has `fit$obj == NULL` but
   `fit$gradient`/`fit$gradient_max_component` both non-NULL, and equal to
   the sibling fit's stored values with `keep_tmb_object = TRUE`.
2. **Agrees with live `check_drm()`** — tested directly: `check_drm(fit)`'s
   `fixed_gradient` row's `max=` value matches `max(abs(fit$gradient))`
   exactly, and the row's `component=` text contains
   `fit$gradient_max_component`.
3. **Selected-optimum invariant untouched** — tested that a second,
   post-fit `obj$gr(opt$par)` call reproduces `fit$gradient` exactly, and
   that `obj$report(tmb_state$last.par.best)`'s `phylo_penalty` still
   matches `fit$phylo_penalty` after the stored-gradient computation ran
   inside the fit — i.e. the extra `obj$gr()` call and its re-pin did not
   perturb what `report()` sees.
4. **Cost** — timed 20 repeated small fits (`bf(y~x, sigma~1)`, Gaussian, 8
   observations) with and without the change: 1.853s vs 1.947s elapsed for
   20 fits (~93ms vs ~97ms/fit) — within run-to-run noise, not material.
   One extra `obj$gr()` call is one AD backward pass over the fixed
   parameters; for large models (many fixed parameters, deep random-effect
   marginalization) this scales with the existing per-iteration gradient
   cost the optimizer already pays repeatedly, so it should stay
   proportionally cheap, but this was not measured at scale — flagging
   rather than asserting.

## Constraints honored

- Touched only `R/drmTMB.R` plus the two new files (test, this note) and
  `NEWS.md`. Did not touch `R/check.R`, `R/control.R`, `R/objective-at.R`,
  `R/julia-bridge.R`, `.unlazy/**`, the Julia capability ledger, the
  coordination board, or workflows.
- `devtools::document()` regenerated `man/confint.drmTMB.Rd` (unrelated
  roxygen drift) and two new man pages for `drm_julia_joint_prepare()` /
  `drm_julia_joint_result()` (another lane's undocumented functions,
  surfaced by roxygen version drift, not by this change) — reverted by
  hand so the diff stays scoped to this slice.
- No SE fallback added; no version bump, push, or merge.

## Files

- `R/drmTMB.R` — `drm_fit_gradient()`, fit-assembly insertion, two new
  `fit` list fields.
- `tests/testthat/test-stored-gradient.R` — new, four `test_that()` blocks.
- `NEWS.md` — new bullet under a new "Fitted objects now store the final
  gradient" heading.
