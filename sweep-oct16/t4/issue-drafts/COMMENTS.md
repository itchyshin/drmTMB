# Comments that this agent could not post (GitHub 403)

Do not re-file: #1469, #1470, #1496, #1535, #983, #1069, #1072, #1088.
Sibling t4 lane already filed #1553, #1554, DRModels.jl #1109, #1110.

## Comment on https://github.com/itchyshin/drmTMB/issues/1469

Independent t4 replicate, pins ca3ddefa / f71b292, Julia 1.11.6.

Cell `gauss_n8` (`y ~ x`, `sigma ~ x`, n = 8, 50 seeds). drmTMB `is_converged() = TRUE` on 50/50. On 6/50 DRModels.jl reaches a higher logLik (0.50 to 13.62 nats) on an unbounded location-scale ridge and reports false with a singular-Hessian warning. drmTMB stops short with no user-facing warning. Worst case (rep 6): R logLik 16.376 conv TRUE vs Julia 29.344 conv false. Distinct from the original two-finite-optima scale test; same tiny-n location-scale class. Prep: `set.seed(as.integer((20261016400+(rep-1)) %% 2^31)); x <- rnorm(8); y <- 1+0.5*x+exp(-0.4+0.3*x)*rnorm(8)`. Other 44/50 agree to 5e-9.

## Comment on https://github.com/itchyshin/drmTMB/issues/1553

Independent replicate, same pins, Julia 1.11.6 instead of 1.12.7. Cell `pois_n8_lowmean`: drmTMB silent `converged` + `check_drm` ok on 13/50, including all-zero rep 3 (`y = 0,0,0,0,0,0,0,0`). Standalone: intercept −24.30, SEs 7.40e4 and 7.43e4, logLik −2.2e-10, `is_converged() = TRUE`. Julia flags all 50 of this cell (`check_drm` not ok or a warning). Same 13 silent reps as this issue (3, 4, 6, 11, 21, 22, 25, 27, 32, 33, 38, 39, 48).

## Comment on https://github.com/itchyshin/drmTMB/issues/1554

Independent replicate of the same 15-cell grid. Flag disagreements: **238 of 750** (this issue reported 236 of 700 without counting `pois_n8_lowmean` in that table). Julia here is 1.11.6; numbers match the per-cell table. Additional: 6 `gauss_n8` rows are not a mere flag-semantics split — Julia's logLik is 0.5–13.6 nats higher (unbounded ridge).

## Comment on https://github.com/itchyshin/drmTMB/issues/1270

Independent replicate. `bin_complete` 50/50: drmTMB `is_converged() = TRUE`, `check_drm` ok, no warning, SEs 1e4–1e5, logLik ≈ 0. `bin_quasi` 50/50: drmTMB `degenerate` / FALSE; Julia `is_converged = true` with a separation `@warn`. Matches the 16 Oct comment on this issue. Rep 1 complete-sep: coef (−16.50, 367.6), max SE 1.72e5.

## Comment on https://github.com/itchyshin/drmTMB/issues/1462

Independent replicate at n = 100 (this issue used n = 300). `student_gaussdata` rep 15: Student logLik **1.020847e+40** vs Gaussian logLik −145.2645 on the same data; `nu` eta 120.76; `is_converged() = FALSE` / `degenerate` (flagged, so not a silent pass-bar fail, but the logLik is still wrong). Julia on the same cell stays finite. Seed: `20261016400 + 100*10 + 14`.

## Comment on https://github.com/itchyshin/drmTMB/issues/1470

At pin ca3ddefa, exact collinear `sigma ~ x + z` with `z = 2x+1` is no longer `converged = TRUE`: 50/50 `convergence_status() = "degenerate"`, `is_converged() = FALSE`, `vcov()` errors with a non-PD Hessian. Still no alias drop. Julia 50/50 `is_converged = true` with a warning and finite pseudo-inverse SEs (DRModels.jl #1110). Near-collinear `z = x + 1e-6 N(0,1)`: same R degenerate / Julia true split, logLik agrees to 5e-8.

## Comment on https://github.com/itchyshin/drmTMB/issues/1535 and #1496

`nb2_poisdata` (Poisson data, n = 100, `sigma ~ 1`): drmTMB `is_converged` TRUE on 17/50 (interior overdispersion, log-sigma about −1.2 to −3.4) and FALSE/`degenerate` on 33/50 (sigma SE inflated, no boundary flag). Julia TRUE on 49/50 with warnings. Same Poisson-limit reporting split as these issues; not re-filed. #1069 / #1088 (RE / crossed heavy OD) were not in this grid.

## Comment on https://github.com/itchyshin/DRModels.jl/issues/1109

Independent replicate, Julia 1.11.6. `pois_n8_lowmean` 50/50 Julia `is_converged = true`; 5 warn; 9 huge SEs; `check_drm` ok on 45/50. R silent on 13 of the no-MLE sets. Twin of drmTMB #1553.

## Comment on https://github.com/itchyshin/DRModels.jl/issues/1110

Independent replicate. `collin_sigma_exact` 50/50 Julia `is_converged = true` with a warning and finite pseudo-inverse SEs; drmTMB 0/50 (degenerate). `collin_sigma_near` same flag split, Julia `check_drm` ok 50/50 despite SEs ~1e4.

## Comment on https://github.com/itchyshin/DRModels.jl/issues/983

Related, not the same cell: this grid's `re_sd1e-4` is **RE** SD 1e-4, not residual SD 1e-4. Julia `is_converged = false` on 20/50 with logLik matching drmTMB to 5e-8 (absolute g_tol). drmTMB 50/50 TRUE, 29 of them `convergence_status() = "boundary"`. Tracked as numerics in #1554 / DRModels.jl #1050. Not re-filed.

## Not triggered

#1069 (NB2 `(1|g)` Poisson-limit interior miss), #1072 (bladdercancer SEs), #1088 (crossed heavy OD runaway).
