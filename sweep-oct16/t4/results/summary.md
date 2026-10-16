# t4 edge-case grid: per-cell summary

Tolerances: material logLik deficit > 0.0001 nats vs the engine-independent reference; logLik above the exact supremum by > 1e-06 flags a wrong likelihood (boundary cells).

| cell | regimes (reference) | drmTMB verdicts | DRModels.jl verdicts | converged R/J | flag agree | signal agree | max abs dlogLik R-J |
|---|---|---|---|---|---|---|---|
| gauss_n8 | interior 47, nonexistent 3 | PASS 41, PASS_flagged 1, SILENT_NONEXIST 1, SILENT_NONEXIST_diag_only 1, SILENT_WRONG 6 | FALSE_ALARM 3, PASS 39, PASS_flagged 4, PASS_warned 1, SILENT_WRONG 3 | 50 / 43 | 43/50 | 43/50 | 16.4 |
| gauss_n12 | interior 50 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.84e-09 |
| gauss_n20 | interior 50 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.92e-09 |
| pois_n8 | interior 50 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.72e-09 |
| pois_n12 | interior 50 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.99e-09 |
| pois_n20 | interior 50 | PASS 50 | PASS 50 | 50 / 50 | 50/50 | 50/50 | 4.98e-09 |
| bin_complete | nonexistent 50 | SILENT_NONEXIST 50 | PASS_flagged 50 | 50 / 50 | 50/50 | 0/50 | 1.45e-07 |
| bin_quasi | nonexistent 50 | PASS_flagged 50 | PASS_flagged 50 | 0 / 50 | 0/50 | 50/50 | 2.52e-07 |
| nb2_poisdata | boundary 32, interior 18 | FALSE_ALARM 33, PASS 17 | FALSE_ALARM 1, PASS 18, PASS_boundary_warned 31 | 17 / 49 | 18/50 | 49/50 | 4.95e-08 |
| beta_phi1e4 | interior 50 | FALSE_ALARM 3, PASS 47 | PASS 50 | 47 / 50 | 47/50 | 47/50 | 5.79e-08 |
| student_gaussdata | boundary 36, interior 14 | FALSE_ALARM 7, LL_ABOVE_SUP_flagged 23, PASS 14, SILENT_BOUNDARY 2, SILENT_LL_ABOVE_SUP 4 | FALSE_ALARM 8, PASS 14, PASS_boundary_warned 28 | 20 / 42 | 28/50 | 44/50 | 1.02e+40 |
| re_sd1e-4 | boundary 29, interior 21 | PASS 21, PASS_boundary_diag_only 29 | FALSE_ALARM 22, PASS 21, PASS_boundary_warned 7 | 50 / 28 | 28/50 | 21/50 | 4.94e-08 |
| collin_sigma_exact | aliased 50 | PASS_flagged 50 | CONV_WARNED_alias 50 | 0 / 50 | 0/50 | 50/50 | 4.96e-08 |
| collin_sigma_near | interior 50 | FALSE_ALARM 50 | PASS_warned 50 | 0 / 50 | 0/50 | 50/50 | 5e-08 |
| pois_n8_lowmean | interior 36, nonexistent 14 | PASS 36, PASS_flagged 1, SILENT_NONEXIST 13 | PASS 36, PASS_flagged 5, SILENT_NONEXIST 9 | 49 / 50 | 49/50 | 46/50 | 6.82e-10 |

## Pass bar per cell and engine

| cell | engine | silent wrong / nonexistent / boundary-unflagged | false alarm (correct answer, converged = FALSE) | other (converged + misleading warning; logLik above sup but flagged; warned wrong) | verdict | flags agree R/J |
|---|---|---|---|---|---|---|
| gauss_n8 | drmTMB | 8 | 0 | 0 | FAIL (silent wrong) | 43/50 |
| gauss_n8 | DRModels.jl | 3 | 3 | 0 | FAIL (silent wrong) |  |
| gauss_n12 | drmTMB | 0 | 0 | 0 | pass | 50/50 |
| gauss_n12 | DRModels.jl | 0 | 0 | 0 | pass |  |
| gauss_n20 | drmTMB | 0 | 0 | 0 | pass | 50/50 |
| gauss_n20 | DRModels.jl | 0 | 0 | 0 | pass |  |
| pois_n8 | drmTMB | 0 | 0 | 0 | pass | 50/50 |
| pois_n8 | DRModels.jl | 0 | 0 | 0 | pass |  |
| pois_n12 | drmTMB | 0 | 0 | 0 | pass | 50/50 |
| pois_n12 | DRModels.jl | 0 | 0 | 0 | pass |  |
| pois_n20 | drmTMB | 0 | 0 | 0 | pass | 50/50 |
| pois_n20 | DRModels.jl | 0 | 0 | 0 | pass |  |
| bin_complete | drmTMB | 50 | 0 | 0 | FAIL (silent wrong) | 50/50 |
| bin_complete | DRModels.jl | 0 | 0 | 0 | pass |  |
| bin_quasi | drmTMB | 0 | 0 | 0 | pass | 0/50 |
| bin_quasi | DRModels.jl | 0 | 0 | 0 | pass |  |
| nb2_poisdata | drmTMB | 0 | 33 | 0 | flag/answer wrong but signalled | 18/50 |
| nb2_poisdata | DRModels.jl | 0 | 1 | 0 | flag/answer wrong but signalled |  |
| beta_phi1e4 | drmTMB | 0 | 3 | 0 | flag/answer wrong but signalled | 47/50 |
| beta_phi1e4 | DRModels.jl | 0 | 0 | 0 | pass |  |
| student_gaussdata | drmTMB | 6 | 7 | 23 | FAIL (silent wrong) | 28/50 |
| student_gaussdata | DRModels.jl | 0 | 8 | 0 | flag/answer wrong but signalled |  |
| re_sd1e-4 | drmTMB | 0 | 0 | 0 | pass | 28/50 |
| re_sd1e-4 | DRModels.jl | 0 | 22 | 0 | flag/answer wrong but signalled |  |
| collin_sigma_exact | drmTMB | 0 | 0 | 0 | pass | 0/50 |
| collin_sigma_exact | DRModels.jl | 0 | 0 | 50 | flag/answer wrong but signalled |  |
| collin_sigma_near | drmTMB | 0 | 50 | 0 | flag/answer wrong but signalled | 0/50 |
| collin_sigma_near | DRModels.jl | 0 | 0 | 0 | pass |  |
| pois_n8_lowmean | drmTMB | 13 | 0 | 0 | FAIL (silent wrong) | 49/50 |
| pois_n8_lowmean | DRModels.jl | 9 | 0 | 0 | FAIL (silent wrong) |  |
