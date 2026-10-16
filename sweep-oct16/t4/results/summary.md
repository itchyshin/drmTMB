# t4 edge-case grid: per-cell summary

Pass bar: every fit either converged with finite logLik, SEs and a correct flag, or a clear error/warning; never `converged=TRUE` with a silent wrong answer; R and Julia agree on the flag.

| cell | drmTMB verdicts | DRModels.jl verdicts | conv R/J | flag agree | signal agree | max |dlogLik| |
|---|---|---|---|---|---|---|
| gauss_n8 | PASS 50 | FALSE_ALARM 7, PASS 42, PASS_warned 1 | 50 / 43 | 43/50 | 50/50 | 13.6 |
| gauss_n12 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.84e-09 |
| gauss_n20 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.92e-09 |
| pois_n8 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.72e-09 |
| pois_n12 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.99e-09 |
| pois_n20 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.98e-09 |
| bin_complete | SILENT_NONEXIST 50 | PASS_flagged 50 | 50 / 50 | 50/50 | 50/50 | 1.45e-07 |
| bin_quasi | PASS_flagged 50 | PASS_flagged 50 | 0 / 50 | 0/50 | 50/50 | 2.52e-07 |
| nb2_poisdata | PASS_flagged 33, SILENT_BOUNDARY 17 | PASS_boundary_diag_only 18, PASS_boundary_warned 31, PASS_flagged 1 | 17 / 49 | 18/50 | 50/50 | 4.95e-08 |
| beta_phi1e4 | PASS_boundary_diag_only 6, PASS_flagged 3, SILENT_BOUNDARY 41 | PASS_boundary_diag_only 50 | 47 / 50 | 47/50 | 50/50 | 5.79e-08 |
| student_gaussdata | PASS_flagged 30, SILENT_BOUNDARY 18, SILENT_BOUNDARY_SE 2 | PASS_boundary_diag_only 14, PASS_boundary_warned 27, PASS_flagged 9 | 20 / 41 | 25/50 | 50/50 | 1.02e+40 |
| re_sd1e-4 | PASS_boundary_diag_only 29, SILENT_BOUNDARY 21 | PASS_boundary_diag_only 21, PASS_boundary_warned 9, PASS_flagged 20 | 50 / 30 | 30/50 | 50/50 | 4.94e-08 |
| collin_sigma_exact | PASS_flagged 50 | PASS_flagged 50 | 0 / 50 | 0/50 | 50/50 | 4.96e-08 |
| collin_sigma_near | PASS_flagged 50 | PASS_warned 50 | 0 / 50 | 0/50 | 50/50 | 5e-08 |
| pois_n8_lowmean | PASS 36, PASS_flagged 1, SILENT_NONEXIST 13 | PASS_flagged 50 | 49 / 50 | 49/50 | 50/50 | 6.82e-10 |

## Pass bar per cell and engine

| cell | engine | n | silent | false alarm | timeout/error | verdict | flag agree R/J |
|---|---|---|---|---|---|---|---|
| gauss_n8 | drmTMB | 50 | 0 | 0 | 0 | pass | 43/50 |
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
| bin_complete | drmTMB | 50 | 50 | 0 | 0 | FAIL (silent wrong) | 50/50 |
| bin_complete | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| bin_quasi | drmTMB | 50 | 0 | 0 | 0 | pass | 0/50 |
| bin_quasi | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| nb2_poisdata | drmTMB | 50 | 17 | 0 | 0 | FAIL (silent wrong) | 18/50 |
| nb2_poisdata | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| beta_phi1e4 | drmTMB | 50 | 41 | 0 | 0 | FAIL (silent wrong) | 47/50 |
| beta_phi1e4 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| student_gaussdata | drmTMB | 50 | 20 | 0 | 0 | FAIL (silent wrong) | 25/50 |
| student_gaussdata | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| re_sd1e-4 | drmTMB | 50 | 21 | 0 | 0 | FAIL (silent wrong) | 30/50 |
| re_sd1e-4 | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| collin_sigma_exact | drmTMB | 50 | 0 | 0 | 0 | pass | 0/50 |
| collin_sigma_exact | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| collin_sigma_near | drmTMB | 50 | 0 | 0 | 0 | pass | 0/50 |
| collin_sigma_near | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |
| pois_n8_lowmean | drmTMB | 50 | 13 | 0 | 0 | FAIL (silent wrong) | 49/50 |
| pois_n8_lowmean | DRModels.jl | 50 | 0 | 0 | 0 | pass |  |

## Flag disagreements: 238 of 750 datasets

- beta_phi1e4: 3
- bin_quasi: 50
- collin_sigma_exact: 50
- collin_sigma_near: 50
- gauss_n8: 7
- nb2_poisdata: 32
- pois_n8_lowmean: 1
- re_sd1e-4: 20
- student_gaussdata: 25

