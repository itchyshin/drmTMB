# After Task: route-aware Julia diagnostics consumer (`a9d-diagnostics`)

**Worktree.** `claude/parity-a9d-diagnostics` at
`~/local-scratch/parity-joint/wt-a9d-diagnostics`.
**Issues.** [drmTMB#1108](https://github.com/itchyshin/drmTMB/issues/1108) /
[DRM.jl#569](https://github.com/itchyshin/DRM.jl/issues/569), against the
route-aware gradient DRM.jl#632 exposes on the bridge payload. Pin:
DRM.jl `430ef64cc`.

## Resume note

This is a resumed leaf; a prior attempt (killed by a session cap) had
already written `R/julia-diagnostics.R`,
`tests/testthat/test-julia-diagnostics.R`, and the storage block in
`R/julia-bridge.R`. All three were re-verified rather than trusted:

- The mocked test file had a genuine bug (`raw_gradient` in the first test
  used `-0.005` where the mock's actual default gradient carries `-0.0005`)
  — it FAILED on first run. Fixed.
- The live test asserted that a `sigma ~ (1 | g)` multi-random-effect
  Gaussian fit carries a gradient. It does not (confirmed live: DRM.jl's
  base Gaussian/GLMM fitter, `src/gaussian_core.jl`, never assigns
  `fit.nllgrad`). The comment blocks in both R files had invented a route
  list ("multi-random-effect Gaussian, sparse-Laplace GLMM, bivariate
  q4/q2 structured, and location-only routes") that was never grepped
  against DRM.jl source. Verified instead with `grep nllgrad src/*.jl`:
  only `src/gaussian_bivariate.jl` (bivariate structured q2/q4) and
  `src/gaussian_sparse_lss.jl` (ML only) construct a non-`nothing`
  gradient closure; `src/gaussian_core.jl` and
  `src/sparse_laplace_glmm.jl` (non-Gaussian phylo Laplace) never do.
  Comments corrected to state only what was grepped and live-tested.
- The field-mapping logic itself (`diagnostics = list(route = ...,
  gradient = ..., converged = ...)` in `new_drmTMB_julia()`, and
  `check_drm.drmTMB_julia()`'s two check rows) was sound and is kept as-is.

## What landed

- `R/julia-diagnostics.R` (new): `check_drm.drmTMB_julia()`, dispatching
  through the SAME generic a TMB fit uses. Two rows: `optimizer_convergence`
  (mirrors `object$diagnostics$converged`, falling back to
  `opt$convergence`) and `fixed_gradient` (numeric `max|gradient|` +
  largest component when the route carries one; a NOTE naming the route,
  never a fabricated number, when it does not).
- `R/julia-bridge.R`: one contiguous `diagnostics = list(...)` block added
  to `new_drmTMB_julia()`'s output, storing `route` (= `family_type`),
  `gradient` (named with the same public `coef_names` used for
  `coefficients`, `NULL` when the bridge omits the field), and `converged`.
- `tests/testthat/test-julia-diagnostics.R` (new): 7 mocked tests (no Julia
  needed) pin the field mapping, the tolerance/dots validation, the
  print-summary line shape, and the route-aware NOTE branch. 2 live tests
  (skip without `DRM_JL_PATH`) each exercise a real DRM.jl fit — one on a
  route confirmed to omit the gradient (`sigma ~ (1 | g)`, the note branch),
  one on a route confirmed to carry it (the committed `biv-q4-phylo-reml`
  fixture from `test-julia-phylo-q4-corpairs.R`, REML, the numeric branch).
- `man/check_drm.Rd` / `NAMESPACE`: `@rdname check_drm` on the new method so
  it documents alongside `check_drm.drmTMB`, matching that method's own
  pattern, rather than a standalone page.
- `NEWS.md`: one bullet under a new `0.7.0` heading.

## Evidence measured this run

- Mocked suite: 27 passed, 0 failed, 2 skipped (no `DRM_JL_PATH`) —
  `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-julia-diagnostics.R")'`.
- Live suite (`DRM_JL_PATH` set to the pin, `OPENBLAS_NUM_THREADS=1`,
  `threads=FALSE`): 29 passed, 0 failed, 0 skipped, ~71s wall (one Julia
  session covering both live fits: a simple `sigma ~ (1|g)` Gaussian fit
  and the q4 phylo REML biv_gaussian fixture).
- G1 (RED, pre-change): with `R/julia-diagnostics.R` temporarily moved out
  and the package reloaded, `check_drm()` on a mocked `drmTMB_julia` object
  errored `no applicable method for 'check_drm' applied to an object of
  class "drmTMB_julia"`, while the SAME call on a TMB fit printed the full
  `drm_check` table (`fixed_gradient` row `max=0.0000000002422`). The raw
  bridge result carried `gradient = c(2e-04, -5e-04, 1e-04)` throughout —
  present but unreachable. File restored afterward (verified present again).
- G4 (RED CONTROL): planted a defect scaling the stored gradient by 10x in
  `new_drmTMB_julia()`. Mocked suite went from 27/0/2 to 21 passed / 6
  failed / 2 skipped (the exact rows checking the numeric value, the
  `max=` string, the `ok` status, and the summary line). Restored
  byte-identical (`diff` against a pre-edit backup confirmed no diff).
- Regression check: ran every other test file that calls
  `new_drmTMB_julia()` directly (`test-coefficient-labels.R`,
  `test-julia-bridge-coef-labels.R`, `test-julia-bridge.R`,
  `test-julia-conditional-prediction.R`, `test-julia-inference.R`,
  `test-julia-objective-at-bridge.R`, `test-julia-phylo-q4-corpairs.R`,
  `test-julia-sigma-phylo-reml.R`, `test-julia-structured-inference.R`) —
  no failures; live-only tests skipped as expected without env vars set.
  Also ran `test-check-drm.R` (TMB's own `check_drm()` suite) — no
  failures, only pre-existing `sd_phylo()` deprecation warnings unrelated
  to this change.

## Scope held (G6)

`git diff --stat` under `R/` touches exactly `R/julia-bridge.R` (the one
documented `diagnostics = list(...)` block) and the new
`R/julia-diagnostics.R`. `man/` touches only `check_drm.Rd` (regenerated,
reverted two unrelated pre-existing roxygen-drift files —
`man/drm_julia_joint_prepare.Rd`, `man/drm_julia_joint_result.Rd`, and a
whitespace-only re-render of `man/confint.drmTMB.Rd` — that `devtools::
document()` produced but that predate this leaf and are out of scope).

## `engine_control_surface` TSV row (G5)

**Not updated, and should not be.** That row's `next_action` — "Design
`engine_control` explicitly before relaxing the gate" — is about drmTMB#1108's
OTHER half: widening the set of Julia-native options `drm_control()` accepts
and forwards (`g_tol`, `algorithm`, `sparse`, …). This leaf implements only
the diagnostics-CONSUMER half (DRM.jl#569 / the `check_drm()` accessor); it
adds no new `drm_control()` option and does not touch
`drm_julia_bridge_check_control()` or the option-forwarding path. The row
stands as the permanent-boundary template it already is.

## Not this leaf

- No `engine_control` option widening (separate half of #1108, untouched).
- No claim that DRM.jl's gradient scale is comparable to TMB's raw fixed
  gradient — `check_drm.drmTMB_julia()` reports it as DRM.jl's own number,
  the same "not implying equality" boundary DRM.jl#569's acceptance
  evidence asks for.
- The `location_only.jl` internal fitter also constructs an `nllgrad!`
  closure but was not confirmed reachable through `drm_bridge` at this pin
  (not named in `src/bridge.jl`, and no R-side formula shape was found that
  reaches it in the time budget) — left uncharacterized rather than
  guessed at.
