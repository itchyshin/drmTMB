# Binomial fixed-effect profile-interval calibration artifact

This artifact banks an MCSE-backed **profile** (tmbprofile) interval-calibration
run for the native `stats::binomial(link = "logit")` first slice, complementing
the 2026-06-17 Wald artifact. It covers the two public response encodings (a 0/1
Bernoulli column and `cbind(successes, failures)`) and the fixed-effect `mu`
coefficients only.

Interpretation label: `promotion_candidate`. The run is strong enough to support
promoting the binomial **fixed-effect profile** interval cell from `planned` to
`covered`, mirroring how the Wald cell was treated. It is not headline coverage
evidence for every binomial use case.

## Provenance

- Source SHA: `3a43f897ab2ee82e05b1f7bfdbfbca21db59aa48`
- Branch: `shannon/overnight-audit-gaps-20260619`
- Package version: `drmTMB 0.1.3.9000`; R 4.5.2; TMB 1.9.21
- Master seed: `20260620`
- Conditions: 4 cells (encoding {binary, cbind} x n {240, 480})
- Replicates: 500 per cell -> 2,000 fits -> 4,000 profile intervals
- True coefficients: `mu:(Intercept) = -0.3`, `mu:x = 0.8` (logit scale)
- Interval: `confint(fit, parm = c("mu:(Intercept)", "mu:x"), method = "profile")`
  on the link scale; coverage checks the true value against `[lower, upper]`.
- Elapsed: 1697.3 s. Dirty state after generation: this artifact directory only.

Reproduce with `Rscript --vanilla run.R 500` from the package root.

## Results

`profile_ok_rate = 1.000`; 0 fit/profile errors out of 4,000.

| encoding | n | target | coverage | MCSE | mean width |
|---|---|---|---|---|---|
| binary | 240 | mu:(Intercept) | 0.952 | 0.0096 | 0.5524 |
| binary | 240 | mu:x | 0.962 | 0.0086 | 0.6261 |
| binary | 480 | mu:(Intercept) | 0.950 | 0.0097 | 0.3895 |
| binary | 480 | mu:x | 0.940 | 0.0106 | 0.4425 |
| cbind | 240 | mu:(Intercept) | 0.950 | 0.0097 | 0.1227 |
| cbind | 240 | mu:x | 0.930 | 0.0114 | 0.1386 |
| cbind | 480 | mu:(Intercept) | 0.950 | 0.0097 | 0.0867 |
| cbind | 480 | mu:x | 0.972 | 0.0074 | 0.0981 |

All eight cells bracket the nominal 0.95 (range 0.930-0.972) within roughly one
to two MCSE, every profile returned `profile.message = "ok"` with
`profile.boundary = FALSE`, and widths shrink with `n` as expected. This matches
the Wald artifact's calibration (0.946-0.964) for the same fixed-effect cells.

## Boundary

Native R/TMB, fixed-effect `mu` only, complete data. It says nothing about
random-effect, structured, bivariate, or mixed binomial routes, profile
intervals for other families, bootstrap intervals, headline coverage, or any
Julia bridge. Those remain `planned`/`unsupported`. No recovery/power claim is
made; this measures interval coverage for a correctly specified model.

## Effect on the capability matrix

Promotes the binomial fixed-effect `profile` cell from `planned` to `covered`
(native lane) in `docs/design/168-r-julia-finish-capability-matrix.md` and the
mission-control finish board, scoped to fixed-effect `mu`. All other binomial
profile routes stay planned.
