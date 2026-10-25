# FX3b t4 rescore (750 fits)

Rescored from `sweep-oct16/t4` data (`t4_gen_data.R`, seeds `20261016400 + 100*(k-1) + (rep-1)`) on drmTMB branch `cursor/fx3b-convergence-status-1f29` and local DRModels.jl `cursor/fx3b-convergence-status-1f29` (from pin `f71b292`). Boolean `is_converged` agreement is **716/750** (was 512/750 on the pin). Three-valued `convergence_status` agreement is **689/750**. The 61 remaining status disagreements are listed below and in `2026-10-16-fx3b-t4-status-disagreements.csv`.

# t4 edge-case grid: per-cell summary

Pass bar: every fit either converged with finite logLik, SEs and a correct flag, or a clear error/warning; never `converged=TRUE` with a silent wrong answer; R and Julia agree on the flag.

| cell | drmTMB verdicts | DRModels.jl verdicts | conv R/J | flag agree | signal agree | max |dlogLik| |
|---|---|---|---|---|---|---|
| gauss_n8 | FALSE_ALARM 6, PASS 44 | FALSE_ALARM 7, PASS 42, PASS_warned 1 | 44 / 43 | 49/50 | 50/50 | 13.6 |
| gauss_n12 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.84e-09 |
| gauss_n20 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.92e-09 |
| pois_n8 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.72e-09 |
| pois_n12 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.99e-09 |
| pois_n20 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.98e-09 |
| bin_complete | PASS_flagged 50 | PASS_flagged 50 | 0 / 0 | 50/50 | 50/50 | 1.45e-07 |
| bin_quasi | PASS_flagged 50 | PASS_flagged 50 | 0 / 0 | 50/50 | 50/50 | 2.52e-07 |
| nb2_poisdata | PASS_flagged 33, SILENT_BOUNDARY 17 | PASS_boundary_diag_only 17, PASS_flagged 33 | 17 / 17 | 50/50 | 50/50 | 4.95e-08 |
| beta_phi1e4 | PASS_boundary_diag_only 6, PASS_flagged 3, SILENT_BOUNDARY 41 | PASS_boundary_diag_only 50 | 47 / 50 | 47/50 | 50/50 | 5.79e-08 |
| student_gaussdata | PASS_flagged 30, SILENT_BOUNDARY 18, SILENT_BOUNDARY_SE 2 | PASS_boundary_diag_only 14, PASS_boundary_warned 1, PASS_flagged 35 | 20 / 15 | 43/50 | 50/50 | 1.02e+40 |
| re_sd1e-4 | PASS_flagged 29, SILENT_BOUNDARY 21 | PASS_boundary_diag_only 21, PASS_flagged 29 | 21 / 21 | 50/50 | 50/50 | 4.94e-08 |
| collin_sigma_exact | PASS_flagged 50 | PASS_flagged 50 | 0 / 23 | 27/50 | 50/50 | 4.96e-08 |
| collin_sigma_near | PASS_flagged 50 | PASS_flagged 50 | 0 / 0 | 50/50 | 50/50 | 5e-08 |
| pois_n8_lowmean | PASS 36, PASS_flagged 14 | PASS_flagged 50 | 36 / 36 | 50/50 | 50/50 | 6.82e-10 |

## Pass bar per cell and engine

| cell | engine | n | silent | false alarm | timeout/error | verdict | flag agree R/J |
|---|---|---|---|---|---|---|---|
| gauss_n8 | drmTMB | 50 | 0 | 6 | 0 | flag disagrees with geometry | 49/50 |
| gauss_n8 | DRModels.jl | 50 | 0 | 7 | 0 | flag disagrees with geometry |  |
| gauss_n12 | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| gauss_n12 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| gauss_n20 | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| gauss_n20 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| pois_n8 | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| pois_n8 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| pois_n12 | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| pois_n12 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| pois_n20 | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| pois_n20 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| bin_complete | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| bin_complete | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| bin_quasi | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| bin_quasi | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| nb2_poisdata | drmTMB | 50 | 17 | 0 | 0 | FAIL (silent wrong) | 50/50 |
| nb2_poisdata | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| beta_phi1e4 | drmTMB | 50 | 41 | 0 | 0 | FAIL (silent wrong) | 47/50 |
| beta_phi1e4 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| student_gaussdata | drmTMB | 50 | 20 | 0 | 0 | FAIL (silent wrong) | 43/50 |
| student_gaussdata | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| re_sd1e-4 | drmTMB | 50 | 21 | 0 | 0 | FAIL (silent wrong) | 50/50 |
| re_sd1e-4 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| collin_sigma_exact | drmTMB | 50 | 0 | 0 | 0 | pass | 27/50 |
| collin_sigma_exact | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| collin_sigma_near | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| collin_sigma_near | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| pois_n8_lowmean | drmTMB | 50 | 0 | 0 | 0 | pass | 50/50 |
| pois_n8_lowmean | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |

## Boolean `is_converged` disagreements: 34 of 750 datasets

- beta_phi1e4: 3
- collin_sigma_exact: 23
- gauss_n8: 1
- student_gaussdata: 7


## Three-valued `convergence_status` agreement: 689 of 750

| cell | status agree | R statuses | J statuses |
|---|---|---|---|
| gauss_n8 | 49/50 | converged 44, degenerate 6 | converged 43, degenerate 7 |
| gauss_n12 | 50/50 | converged 50 | converged 50 |
| gauss_n20 | 50/50 | converged 50 | converged 50 |
| pois_n8 | 50/50 | converged 50 | converged 50 |
| pois_n12 | 50/50 | converged 50 | converged 50 |
| pois_n20 | 50/50 | converged 50 | converged 50 |
| bin_complete | 50/50 | degenerate 50 | degenerate 50 |
| bin_quasi | 50/50 | degenerate 50 | degenerate 50 |
| nb2_poisdata | 50/50 | converged 17, degenerate 33 | converged 17, degenerate 33 |
| beta_phi1e4 | 47/50 | converged 47, degenerate 3 | converged 50 |
| student_gaussdata | 43/50 | converged 20, degenerate 30 | converged 15, degenerate 35 |
| re_sd1e-4 | 23/50 | boundary 29, converged 21 | boundary 2, converged 21, degenerate 27 |
| collin_sigma_exact | 27/50 | degenerate 50 | converged 23, degenerate 27 |
| collin_sigma_near | 50/50 | degenerate 50 | degenerate 50 |
| pois_n8_lowmean | 50/50 | converged 36, degenerate 14 | converged 36, degenerate 14 |

## Remaining status disagreements: 61 of 750

- beta_phi1e4 | degenerate | converged | R geometry/SE/Hessian screen; Julia optimiser-true with finite pseudo-SEs or no matching screen: 3
- collin_sigma_exact | degenerate | converged | R geometry/SE/Hessian screen; Julia optimiser-true with finite pseudo-SEs or no matching screen: 23
- gauss_n8 | converged | degenerate | same logLik; Julia optimiser g_tol / raw flag false, R nlminb code 0: 1
- re_sd1e-4 | boundary | degenerate | R boundary (RE SD / rho12 cut); Julia degenerate (non-PD vcov, Inf SE, or optimiser): 7
- re_sd1e-4 | boundary | degenerate | same logLik; Julia optimiser g_tol / raw flag false, R nlminb code 0: 20
- student_gaussdata | converged | degenerate | Julia degenerate (optimiser, non-PD vcov, or inflated SE); R interior: 4
- student_gaussdata | converged | degenerate | same logLik; Julia optimiser g_tol / raw flag false, R nlminb code 0: 2
- student_gaussdata | degenerate | converged | R geometry/SE/Hessian screen; Julia optimiser-true with finite pseudo-SEs or no matching screen: 1

