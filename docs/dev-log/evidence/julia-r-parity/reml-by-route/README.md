# Evidence for docs/design/261-reml-by-route.md (arc A9f)

Leaf A9f: drmTMB #1142 remainder ("REML support in one generated table per
route"). Measured 2026-09-05 in worktree `~/local-scratch/parity-joint/wt-a9f-reml-table`
(branch `claude/parity-a9f-reml-table` off `origin/main`), DRM.jl pin
`430ef64cc` at `~/local-scratch/parity-joint/drmjl-430ef64cc`.

## What is here

- `native_reml_probe.R` / `native_reml_probe.log` -- 13 native `engine = "tmb"`
  REML probes (no Julia). Run: `Rscript native_reml_probe.R`, no env vars
  needed. Wall time: well under a minute (TMB templates already compiled by
  `load_all()`).
- `bridge_reml_probe.R` / `bridge_reml_probe.log` -- 10 bridge
  (`engine = "julia"`) REML probes, ONE warm Julia session. Run:
  ```
  OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true \
    DRM_JL_PATH=~/local-scratch/parity-joint/drmjl-430ef64cc \
    DRM_JL_PHYLO_PATH=~/local-scratch/parity-joint/drmjl-430ef64cc \
    Rscript bridge_reml_probe.R
  ```
  Measured wall time: 39.4s total (first cell pays the ~31s Julia boot; every
  subsequent cell is under a second, except the phylo Laplace fit at 6.3s).
- `bridge_reml_probe2.R` / `bridge_reml_probe2.log` -- one follow-up bridge
  probe (Poisson + `relmat()`, REML=TRUE), run the same way; a second, ~25s
  Julia boot, then a single near-instant call.
- `a5-census-verbatim.tsv` -- verbatim copy of A5's
  `docs/dev-log/evidence/julia-r-parity/ordinary-re-census/census.tsv`
  (`origin/claude/parity-a5`, PR #1170), reproduced here (not re-measured)
  because that branch is not yet merged and its receipts are cited by three
  rows in the generated table (`gaussian_random_intercept`,
  `gaussian_random_slope`, `gaussian_sigma_random_intercept`).

## D-139 estimate vs actual

Estimated before running: native probes <5 min (no Julia); bridge probes
~3-5 min (one Julia boot + ~10 cheap cells); the follow-up relmat probe
<2 min (one more boot). Actual: native probe log shows all 13 cells
completing in the time it takes `load_all()` to finish (a few seconds each);
bridge probe log's own `TOTAL WALL TIME` line reads 39.4s; the follow-up
probe's own `elapsed` line reads 0.1s post-boot. Total live-Julia wall time
across both bridge sessions: well under 2 minutes, against a stated budget of
under 10.

## Key findings surfaced (see the generated table's "Gaps" section for the
full, cited list)

1. **New capability gaps, native TMB ahead of DRM.jl** (both native and via
   the bridge): plain fixed-effect bivariate Gaussian REML
   (`biv_gaussian_residual`), and mean-only Gaussian `relmat()` REML (the
   Gaussian row of `general_covariance_structured`, the same shape as
   DRM.jl #624 item (c) but for `relmat()` instead of `phylo()`).
2. **New bridge under-admission**: DRM.jl's own test suite
   (`test_cox_reid_poisson_phylo.jl:134-142`, DRM.jl #450) fits
   `Poisson() + relmat(1|id)` under `method = :REML`, but `engine = "julia"`
   refuses it unconditionally, because the bridge's structured-term gate
   (`drm_julia_has_structured_term()`) fires for every family before the
   Poisson-specific REML gate is ever consulted (`bridge_reml_probe2.log`).
3. **Honesty-of-interface gap, four cells**: `fe_poisson`, `zi_poisson`
   (measured live this run), and `gaussian_random_slope` (cited from A5's
   census, which already measured it) all reach a RAW Julia
   `ArgumentError` + stack trace instead of the polished
   `drm_julia_refuse_reml_unsupported()` message, because
   `drm_julia_reml_supported()`'s Gaussian and Poisson branches only check
   for phylo/`sd()`/structured-term presence, never for "does this model have
   any random effect at all" or "is the random effect a plain single
   intercept, not a slope". `gaussian_sigma_random_intercept` is the control
   showing the polished refusal DOES fire when the maintainers already special-
   cased a shape (`drm_julia_check_ordinary_sigma_ranef_route_limits()`).

None of these were fixed in this leaf (scope: measure and table only, per the
task brief's "Do NOT implement REML anywhere"). All are recorded in the
generated table's Gaps section with their evidence; none were filed as new
GitHub issues in this leaf.

## RED CONTROL (G4)

`tools/write-reml-route-table.R`'s `drm_reml_route_table_rows()` asserts every
TSV-sourced `capability_id` exists in `inst/extdata/julia-capabilities.tsv`.
Planted defect: renamed the first row's id to
`RED_CONTROL_bogus_capability_id_not_in_tsv`. Result:
`tests/testthat/test-reml-route-table.R` went from 5/5 pass to 1 error + 2
failures (all three naming the planted id in the `stop()` message). The file
was then restored from a saved copy; `shasum -a 256` before and after the
plant/restore matched exactly
(`8ac1e7d431fa68139f645d1d24b0e54d4aaf88fc422e83a037a178f5be56627f`), and the
test suite returned to 5/5.
