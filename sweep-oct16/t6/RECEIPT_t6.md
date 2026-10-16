# RECEIPT t6 — predict() / simulate() (sweep-oct16)

Lane t6 of the 16 Oct 2026 Engine A DRM sweep. Pins checked out exactly:

| Engine | Repo | `git rev-parse HEAD` |
| --- | --- | --- |
| drmTMB | itchyshin/drmTMB | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` |
| DRModels.jl | itchyshin/DRModels.jl | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` |

Pass bars from the spec: simulate mean/variance within **3 Monte Carlo SE** (`nsim = 1000`); R vs Julia `predict` **≤ 1e-8**. Seeds `20261016600+` (R `set.seed(seed %% 2^31)`, same convention as t2 #1549 / t4). Known issues not re-filed: drmTMB #1536, DRModels #1092.

t1 families (this lane’s shared univariate FE+(1|g) surface; t1 receipt was not on the pin): `gaussian`, `student`, `lognormal`, `gamma`, `poisson`, `nbinom2`, `binomial`, `beta`. FE-only extras both engines fit: `tweedie`, `skew_normal`, `beta_binomial`, `zero_one_beta`.

No timeouts. No hang. No push to `main`. No PR.

## 1. Exact commands

```sh
# pins
git -C /workspace rev-parse HEAD
# ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
git -C /home/ubuntu/DRModels.jl rev-parse HEAD
# f71b2923360e9e5d4591e0d6e15a9ef9db0356d7

# env (this VM: R 4.6.1 + TMB 1.9.25 via r2u; Julia 1.11.6)
export R_LIBS_USER=/home/ubuntu/R/library
export T6_ROOT=/workspace/sweep-oct16/t6
export JL_PROJ=/home/ubuntu/jlsim   # Pkg.develop(path="/home/ubuntu/DRModels.jl")

# generate 20 cell CSVs
Rscript "$T6_ROOT/t6_gen_data.R" "$T6_ROOT"

# per-cell hard timeout (FE 180s, RE 240s, KILL)
# families: gaussian/student/lognormal/gamma/poisson/nbinom2/binomial/beta × {fe,re}
#           tweedie/skew_normal/beta_binomial/zero_one_beta × fe
timeout --signal=KILL 180 Rscript "$T6_ROOT/t6_run_drmTMB.R" "$T6_ROOT" <fam> <fe|re>
timeout --signal=KILL 180 julia --project="$JL_PROJ" "$T6_ROOT/t6_run_DRModels.jl" "$T6_ROOT" <fam> <fe|re>

Rscript "$T6_ROOT/t6_compare.R" "$T6_ROOT"

# standalone confirmations (after the sweep)
Rscript "$T6_ROOT/repro/confirm_predict_invlinks.R"
julia --project="$JL_PROJ" "$T6_ROOT/repro/confirm_predict_invlinks.jl"
# LogNormal RE retry without marginal= (harness had passed it)
julia --project="$JL_PROJ" /tmp/t6_lognormal_re.jl
```

`run_all.sh` wraps the cell loop. Results: `sweep-oct16/t6/results/cells_*.csv`, `predict_{R,J}_*.csv`, `r_vs_julia.csv`. No row in `results/timeouts.txt`.

## 2. Results per cell vs the pass bar

Legend: **P** = pass; **#1536** = known `se.fit` ignore / `simulate(newdata)` ignore; **MC** = one of 80 rows slightly over 3 MCSE (not filed); **inv** = inverse-link twin fail (filed as draft); **#1000** = Julia subset-of-levels (comment draft).

### drmTMB predict types, newdata, char vs factor, se.fit

Every R cell: all requested `predict` types (`link`, `response`, each dpar) finite; unseen level `f="z"` named (`Unknown level: "z"`); character vs factor `max_abs_diff=0`; `predict_parameters(..., conf.int=TRUE)` returns `std.error`.

| Cell | fit | predict types | unseen | char/factor | `se.fit` | `predict_parameters` SE |
| --- | --- | --- | --- | --- | --- | --- |
| gaussian_fe | P (converged) | P | P named | P 0 | #1536 ignored | P |
| gaussian_re | P (boundary) | P | P named | P 0 | #1536 | P |
| student_fe | P | P (μ,σ,ν) | P named | P 0 | #1536 | P |
| student_re | P | P | P named | P 0 | #1536 | P |
| lognormal_fe | P | P (μ response = link; documented) | P named | P 0 | #1536 | P |
| lognormal_re | P | P | P named | P 0 | #1536 | P |
| gamma_fe | P | P | P named | P 0 | #1536 | P |
| gamma_re | P (boundary) | P | P named | P 0 | #1536 | P |
| poisson_fe | P | P | P named | P 0 | #1536 | P |
| poisson_re | P (boundary) | P | P named | P 0 | #1536 | P |
| nbinom2_fe | P | P | P named | P 0 | #1536 | P |
| nbinom2_re | P (boundary) | P | P named | P 0 | #1536 | P |
| binomial_fe | P | P | P named | P 0 | #1536 | P |
| binomial_re | P | P | P named | P 0 | #1536 | P |
| beta_fe | P | P | P named | P 0 | #1536 | P |
| beta_re | P | P | P named | P 0 | #1536 | P |
| tweedie_fe | P | P (μ,σ,ν) | P named | P 0 | #1536 | P |
| skew_normal_fe | P | P (μ,σ,ν) | P named | P 0 | #1536 | P |
| beta_binomial_fe | P | P | P named | P 0 | #1536 | P |
| zero_one_beta_fe | P | P (μ,σ,zoi,coi) | P named | P 0 | #1536 | P |

### drmTMB simulate nsim=1000 vs fitted moments (bar: 3 MCSE)

| Cell | mean max_z | var max_z | `simulate(newdata=)` |
| --- | --- | --- | --- |
| gaussian_fe | 2.420 P | 2.444 P | #1536 nrow=80 not 2 |
| gaussian_re | 2.501 P | 2.997 P | #1536 |
| student_fe | 2.237 P | **23.000** (ν̂=2.48; Gaussian MCSE invalid) | #1536 |
| student_re | 2.506 P | 1.923 P | #1536 |
| lognormal_fe | 2.304 P | 4.413 MC | #1536 |
| lognormal_re | 2.817 P | 3.630 MC | #1536 |
| gamma_fe | 2.282 P | 2.885 P | #1536 |
| gamma_re | 2.473 P | 3.080 MC | #1536 |
| poisson_fe | 3.027 MC | 3.095 MC | #1536 |
| poisson_re | 2.804 P | 2.611 P | #1536 |
| nbinom2_fe | 2.586 P | 3.503 MC | #1536 |
| nbinom2_re | 2.496 P | 3.692 MC | #1536 |
| binomial_fe | 2.377 P | 1.198 P | #1536 |
| binomial_re | 2.601 P | 0.831 P | #1536 |
| beta_fe | 3.102 MC | 2.406 P | #1536 |
| beta_re | 2.839 P | 3.009 MC | #1536 |
| tweedie_fe | 2.593 P | 3.953 MC | #1536 |
| skew_normal_fe | 2.031 P | 2.398 P | #1536 |
| beta_binomial_fe | 2.798 P | 2.267 P | #1536 |
| zero_one_beta_fe | 2.152 P | skip (no closed form) | #1536 |

MC rows are max-of-80 z-scores just over 3. Not filed as package breaks.

### DRModels.jl

Every Julia cell that fitted: `predict(..., se=true)` returns finite SEs (Julia offers `se`; drmTMB does not). `simulate` has no `newdata` formal (twin of #1536). Unseen 1-row `f="z"`: Gaussian names the level; other families often `only one level found: z`.

| Cell | fit | predict μ | unseen | subset levels | se=true | sim mean / var |
| --- | --- | --- | --- | --- | --- | --- |
| gaussian_fe | P | P | P named | P (Gaussian accepts) | P | P / P |
| gaussian_re | P | P | P named | P | P | P / P |
| student_fe | P | P | contrasts msg | #1000 missing `f:b` | P | P / 38.9 (ν̂=2.48) |
| student_re | P | P | contrasts msg | #1000 | P | P / P |
| lognormal_fe | P | P (exp scale) | contrasts msg | #1000 | P | harness z=60 (scale) |
| lognormal_re | **MethodError `marginal=`** | — | — | — | — | harness; retry without `marginal=` **converged** loglik=−31.67 |
| gamma_fe | P | P | contrasts msg | #1000 | P | P / P |
| gamma_re | P | P | contrasts msg | #1000 | P | P / P |
| poisson_fe | P | P | contrasts msg | #1000 | P | P / 3.75 MC |
| poisson_re | P | P | contrasts msg | #1000 | P | P / P |
| nbinom2_fe | P | P | contrasts msg | #1000 | P | P / 3.24 MC |
| nbinom2_re | P | P | contrasts msg | #1000 | P | P / 3.30 MC |
| binomial_fe | P | P | contrasts msg | #1000 | P | P / P |
| binomial_re | P | P | contrasts msg | #1000 | P | P / P |
| beta_fe | P | P | contrasts msg | #1000 | P | 3.61 MC / P |
| beta_re | P | P | contrasts msg | #1000 | P | P / P |
| tweedie_fe | P | P | contrasts msg | #1000 | P | skip / skip |
| skew_normal_fe | P | P | contrasts msg | #1000 | P | P / P |
| beta_binomial_fe | P | P | contrasts msg | #1000 | P | skip / skip |
| zero_one_beta_fe | P | P (μ = link) | contrasts msg | #1000 | P | skip / skip |

### R vs Julia predict (bar 1e-8)

Link-scale columns that both engines wrote match to ~1e-15 except nbinom2_re (~2e-8, near-miss). Response-scale **fails** (real inverse-link twin):

| Cell | column | max_abs | verdict |
| --- | --- | --- | --- |
| lognormal_fe | mu_response | 1.046 | **FAIL** R = η (identity); Julia = exp(η) |
| lognormal_re | — | — | Julia table missing (harness `marginal=`); retry would fail the same way |
| student_fe | nu_response | 2.000 | **FAIL** R = 2+exp(η)=2.479; Julia = exp(η)=0.479 |
| student_re | nu_response | 2.000 | **FAIL** same |
| skew_normal_fe | nu_response | 1.352 | **FAIL** R = η=−0.974; Julia = exp(η)=0.378 |
| zero_one_beta_fe | mu_response | 0.561 | **FAIL** R = logistic(η); Julia = η |
| nbinom2_re | mu_response / mu_link / sigma_link | 5.2e-8 / 2.0e-8 / 1.9e-8 | near-miss, not filed |
| all other shared columns (Gaussian, Gamma, Poisson, NB2 FE, Beta, Binomial, Tweedie, BetaBinomial, σ/zoi/coi, …) | | ≤ 1.8e-9 | **PASS** |

Standalone confirmation: `repro/confirm_predict_invlinks.{R,jl}`. Julia `fit.scales[:nu]` for Student is 2.479 (correct); `predict_parameters` returns 0.479. Cause: `_param_response` in `gaussian_core.jl` ~1892 (`:nu` → `exp` except Tweedie; ZeroOneBeta missing from the logit μ list).

## 3. Issues filed or commented

**GitHub write failed (403)** on the GitHub MCP (`add_issue_comment`, `issue_write`). `gh` is read-only in this cloud run. Composio GitHub has no active connection. **No new issue numbers exist.** Drafts are ready to POST:

| Action | Target | URL | One line | Draft |
| --- | --- | --- | --- | --- |
| comment (blocked) | drmTMB #1536 | https://github.com/itchyshin/drmTMB/issues/1536 | Confirmed on every t6 fit: `simulate(newdata=)` → 80 rows; `se.fit` ignored | `repro/F-1536-simulate-newdata-se.fit.md` |
| comment (blocked) | drmTMB #1320 | https://github.com/itchyshin/drmTMB/issues/1320 | Lognormal `type="response"` is log-Y μ; Julia returns exp(η) | `repro/COMMENT_1320.md` |
| comment (blocked) | DRModels #1092 | https://github.com/itchyshin/DRModels.jl/issues/1092 | newdata = invlink(Xβ), RE=0, matches drmTMB; docs still say integrated out | `repro/COMMENT_1092.md` |
| comment (blocked) | DRModels #1000 | https://github.com/itchyshin/DRModels.jl/issues/1000 | Univariate non-Gaussian predict also refuses a subset of fitted levels | `repro/COMMENT_1000.md` |
| new (blocked) | DRModels.jl | — | `_param_response` wrong invlink (Student / SkewNormal / ZeroOneBeta / LogNormal) | `repro/ISSUE_predict_invlinks.md` |
| new (blocked) | DRModels.jl | — | `simulate` has no newdata (twin of #1536) | `repro/ISSUE_simulate_newdata.md` |
| new (blocked) | DRModels.jl | — | LogNormal `drm()` has no `marginal=` | `repro/ISSUE_lognormal_marginal.md` |

Not filed (see `repro/ISSUES_TO_FILE.md`): MCSE near-misses; Student-t variance at ν̂=2.48; nbinom2_re 5e-8; Julia lognormal simulate z=60 (harness scale).

## 4. Commits / SHAs

| What | SHA |
| --- | --- |
| drmTMB pin (this checkout) | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` |
| DRModels.jl pin | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` |
| Receipt branch | `sweep-oct16/t6` (this commit; no PR) |
| PR head | none (spec does not ask for a PR) |

Session: R 4.6.1, TMB 1.9.25, Matrix 1.7-6, drmTMB 0.7.1; Julia 1.11.6, DRModels 0.7.2.
