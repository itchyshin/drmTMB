# 2026-10-16: sweep-oct16 lane t5, missing data × weights

Reader: Engine A and the maintainers triaging the sweep findings. Also the next
agent who touches weights, NA handling, or the Julia bridge for ordinary `(1 | g)`.

## What was done

This was a test-only lane at drmTMB `ca3ddefa` and DRModels.jl `f71b2923`. No
package code was changed. The harness, data, results, repros and the receipt
are under `sweep-oct16/t5/` (build-ignored). The receipt is
`sweep-oct16/t5/RECEIPT_t5.md`.

The grid covered Gaussian, Poisson and Gamma(log), each with `(1 | g)`, crossed
with NA in y and x at {0, 5, 20}% MCAR (27 datasets) and with weights NULL,
ones, integer 1–3 (compared against row duplication) and random positive. Three
legs were run: native, `engine = "julia"`, and DRModels.jl directly. An
independent per-group Laplace oracle checked the weighted logLik.

## What we learned

- **Native weights are correct.** Weights multiply the row log-density and the
  random-effect prior is unweighted.
  - Integer weights equal row duplication to 1.7e-10 in logLik and 1.5e-10 in
    coefficients.
  - The oracle agrees to 4.1e-10 for every weighting.
  - Zero weights equal row deletion.
  - NA weights on dropped rows are ignored, and on kept rows give a named
    error.
- **The R-side NA drop is consistent.** It is identical across native and
  bridge (Gaussian), and DRModels' `drm_listwise` reproduces it exactly.
- **Defects found:**
  - drmTMB#1550: `%||%` undefined on R < 4.4.
  - drmTMB#1551: Poisson/Gamma `(1 | g)` bridge crash, with `marginal` never
    forwarded.
  - DRModels.jl#1111: a `Union{Missing,Float64}` predictor with no missing
    value is dummy-coded as a factor.
  - DRModels.jl#1112: a missing group label is pooled into an extra level.
  - DRModels.jl#1113: a NaN predictor returns a start-value fit.
  - Comments posted on drmTMB#1454 and #1450, and on DRModels.jl#1089, #931
    and #947.

## Mistakes and corrections

- drmTMB#1550 was filed before checking open PR bodies. MCP issue search had
  returned nothing, but draft PRs #1502 and #1504 already define `%||%`. A
  cross-reference comment turns #1550 into their tracker. Lesson: when issue
  search is empty, also grep open PR bodies before filing.
- The first direct DRModels.jl run typed every raw column as
  `Union{Missing,Float64}`, which CSV.jl would not do. One pathological fit ran
  for more than 7 minutes. That run was stopped and discarded. The Union hazard
  now runs as a bounded per-process probe, and the main grid uses CSV.jl-style
  typing.
- The early claim that "`g_tol` has no effect" on DRModels' `:Laplace` route
  was too strong. Verification showed that `g_tol` changes 17 of 36 fits,
  non-monotonically. The receipt and the #947 comment use the corrected
  mechanism (`ordinary_laplace.jl:165`).

## Next

- Rerun the Poisson/Gamma rows of the bridge leg once drmTMB#1551 sends the
  `resd` label and `marginal = "Laplace"`. Use the 1e-8 bar.
- Rerun the weights rows once drmTMB#1502 (bridge weights) and DRModels.jl#1061
  (prior weights) land. The duplication identity in `R/compare.R` is the
  acceptance test.
