# t10 receipt — LRT / AIC / anova sweep (16 Oct 2026)

This receipt is for Shinichi and the next agent on the oct-16 DRM campaign. It records the model-comparison sweep on the two pinned trees: 500 null replicates of three nested pairs, the [4%, 6%] type-I bar at α = 0.05, R–Julia LRT agreement to 1e-6 under Laplace, and the mixing-approximation guards.

## Pins (exact `git rev-parse HEAD`)

| repo | SHA | version |
| --- | --- | --- |
| itchyshin/drmTMB | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` | 0.7.1 |
| itchyshin/DRModels.jl | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` | 0.7.2 |

No PR was opened. This branch is `sweep-oct16/t10` only. Receipt commit SHA is this branch's HEAD after the push.

Host: Ubuntu 24.04.5, 4 CPUs. R 4.3.3 (`Angel Food Cake`), TMB 1.9.10, Matrix 1.6-5. Julia 1.12.6 (official tarball). drmTMB installed from the pin into `/tmp/t10-lib`. DRModels developed from `/tmp/DRModels.jl` into `/tmp/t10-jl`.

## Seed map

Official campaign seeds are `20261017000 + i` for `i = 0..499`. Both R `set.seed` and a raw `UInt32` overflow at `20261017000` (max signed 32-bit is `2147483647`). The `seed` column in every CSV stores the official id (exact in IEEE double). The RNG actually used is `official - 19000000000` (`1261017000 + i`). Shared CSVs were generated once in R and read by both engines, so the paired LRT comparison is on identical rows.

## Exact commands

```sh
# pins
cd /workspace && git rev-parse HEAD
# ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
git clone https://github.com/itchyshin/DRModels.jl /tmp/DRModels.jl
cd /tmp/DRModels.jl && git checkout f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
git rev-parse HEAD
# f71b2923360e9e5d4591e0d6e15a9ef9db0356d7

# R + TMB (Ubuntu binaries) + local drmTMB
sudo apt-get install -y r-base r-base-dev r-cran-tmb r-cran-matrix r-cran-cli \
  r-cran-lifecycle r-cran-nlme r-cran-rcppeigen r-cran-testthat
export R_LIBS_USER=/tmp/t10-lib
R CMD INSTALL --library=/tmp/t10-lib --no-docs /workspace

# Julia 1.12.6 + DRModels
curl -fsSL -o /tmp/julia-1.12.6-linux-x86_64.tar.gz \
  https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.6-linux-x86_64.tar.gz
sudo tar -xzf /tmp/julia-1.12.6-linux-x86_64.tar.gz -C /opt/julia
sudo ln -sfn /opt/julia/julia-1.12.6/bin/julia /usr/local/bin/julia
cd /tmp/t10-jl && julia --project=. setup.jl   # Pkg.develop(/tmp/DRModels.jl)

# shared null data (500 seeds)
export T10_NREP=500 T10_DATA=/tmp/t10-data R_LIBS_USER=/tmp/t10-lib
Rscript sweep-oct16/t10/scripts/gen_data.R

# smoke (one draw + mixing guards); hard timeouts inside the scripts
Rscript sweep-oct16/t10/scripts/smoke_r.R
julia --project=/tmp/t10-jl sweep-oct16/t10/scripts/smoke_jl.jl
julia --project=/tmp/t10-jl sweep-oct16/t10/scripts/smoke_mix_la_laplace.jl

# 500-rep sweeps (per-fit timeout: gauss 30s, nb2 60s, re 90s)
T10_CELL=gauss Rscript sweep-oct16/t10/scripts/sweep_r.R
T10_CELL=nb2   Rscript sweep-oct16/t10/scripts/sweep_r.R
T10_CELL=re    Rscript sweep-oct16/t10/scripts/sweep_r.R
T10_CELL=gauss julia --project=/tmp/t10-jl sweep-oct16/t10/scripts/sweep_jl.jl
T10_CELL=nb2   julia --project=/tmp/t10-jl sweep-oct16/t10/scripts/sweep_jl.jl
T10_CELL=re    julia --project=/tmp/t10-jl sweep-oct16/t10/scripts/sweep_jl.jl
```

No fit hit its hard timeout. Every cell is 500/500 `OK` on both engines. `se = FALSE` on R; Julia Gaussian has no `se` keyword (DRModels #942, confirmed, not re-filed).

## DGPs (null)

1. **gauss** — interior. `n = 200`, `y = 0.3 + 0.5 x + ε`, `z` unused. Reduced `sigma ~ 1`, full `sigma ~ z`. χ²₁.
2. **nb2** — boundary, chi-bar 50:50. `n = 250`, `y ~ Poisson(exp(0.4 + 0.3 x))`. Reduced `poisson()`, full `nbinom2()` / `NegBinomial2()` with `sigma ~ 1`.
3. **re** — boundary, chi-bar 50:50. `G = 25`, `m = 12`, `sd_b = 0`, `y = 0.4 − 0.5 x + 0.7 ε`. Reduced no RE, full `(1 | g)`. Julia Gaussian mean `(1 | g)` refuses `marginal = :Laplace` (that flag is sigma-RE only); the default `:LA` is the closed-form Gaussian marginal and is the Laplace-comparable number. R uses TMB Laplace, which is exact here.

## Results vs the pass bar

Pass bar: type-I at α = 0.05 in **[4%, 6%]** with the correct boundary mixture; R and Julia LRT statistics equal to **1e-6** when both use Laplace; mixing approximations must error or warn.

Numeric table: `sweep-oct16/t10/logs/summary_vs_passbar.csv`. Per-rep CSVs: `r_*.csv`, `jl_*.csv`.

| cell | correct p | R type-I | Julia type-I | bar | max \|Δ LRT\| (n = 500) | LRT bar |
| --- | --- | --- | --- | --- | --- | --- |
| gauss (interior χ²) | `anova` / `lrtest` χ²₁ | **5.8%** (29/500) | **5.8%** (29/500) | **PASS** | 6.25e-12 | **PASS** |
| nb2 (chi-bar 50:50) | `chibar_pvalue` / `lrt_boundary` | **3.0%** (15/500); packaged `anova`/`lrtest` χ² = **1.8%** | same 3.0% / 1.8% | **FAIL** | 9.99e-9 | **PASS** |
| re (chi-bar 50:50) | `anova` chi-bar (R); `lrt_boundary` (Julia) | **3.4%** (17/500); naive χ² = **1.2%** | **3.4%** / **1.2%** | **FAIL** | 9.72e-9 | **PASS** |

R `anova()` `p.method`: `chisq` on gauss (correct) and on nb2 (wrong — should be chi-bar or at least warn); `chibar` on re (correct, with warning). Julia `lrtest` is always naive χ²; it warns on re and is silent on nb2. `anova == lrtest` on Julia.

AIC under the null (not a type-I bar; recorded): full wins 18.2% (gauss), 5.4% (nb2), 4.8% (re). Gaussian ~16% is the usual AIC false-selection rate. Boundary cells stay near the atom, so AIC rarely prefers the larger model.

Atom mass on the boundary cells: 55.0% of NB2 LR statistics and 58.6% of RE LR statistics have `|stat| < 1e-8`. That extra atom (vs the asymptotic 50%) is why chi-bar type-I sits at 3.0–3.4% rather than 5% on these n.

## Mixing approximations

| pair | verb | result | vs bar |
| --- | --- | --- | --- |
| Poisson `(1\|g)` `:VA` vs `:VA` | `lrtest` | **no error**; statistic 6.77, p = 0.009 on the smoke draw | FAIL — known DRModels **#1036** (not re-filed; comment 403) |
| Poisson `(1\|g)` `:VA` | `aic` | errors (ELBO is not a log-likelihood) | PASS |
| Poisson `(1\|g)` `:VA` vs `:Laplace` | `lrtest` | errors | PASS |
| Poisson `(1\|g)` `:LA` vs `:Laplace` | `lrtest` | errors (names GHQ-32 vs Laplace) | PASS |
| Poisson `(1\|g)` `:LA` vs `:Laplace` | `lrt_boundary` | **no error**; mixes the two logliks | FAIL — known DRModels **#1002** (not re-filed; comment 403) |
| Gaussian mean `(1\|g)` `:Laplace` | `drm` | ArgumentError: `:Laplace` is sigma-RE only | by design; used default `:LA` |
| R TMB vs `drmTMB_julia` stub | `anova` | errors (engine mix refused) | PASS |

`:LA` vs `:Laplace` loglik on one Poisson `(1|g)` smoke draw differed by 4.48e-5. That is DRModels **#1071** (not re-filed; comment 403). The 500-rep RE cell compared R TMB Laplace to Julia's exact Gaussian `:LA`, which is the Laplace-equivalent number for this family; they agreed to 1e-8.

## Issues filed or commented

Comments on existing issues were refused (`403 Resource not accessible by integration`) on both `gh issue comment` and the GitHub MCP. New issues could be created. Known issues were **not** re-filed.

### Filed (this lane)

| URL | one line |
| --- | --- |
| https://github.com/itchyshin/drmTMB/issues/1557 | `anova(poisson, nbinom2)` uses naive χ² and does not warn; `lrt_boundary` gives the 50:50 chi-bar p. |
| https://github.com/itchyshin/drmTMB/issues/1559 | NB2 vs Poisson type-I is 1.8% (anova) / 3.0% (chi-bar) in 500 Poisson-null reps; outside [4%, 6%]. |
| https://github.com/itchyshin/drmTMB/issues/1560 | `(1\|g)` vs none: anova correctly uses chi-bar; type-I is 3.4% in 500 null reps; outside [4%, 6%]. |
| https://github.com/itchyshin/DRModels.jl/issues/1115 | `lrtest(Poisson, NegBinomial2)` uses naive χ² and does not warn (twin of drmTMB #1557). |
| https://github.com/itchyshin/DRModels.jl/issues/1116 | NB2 vs Poisson type-I 1.8% / 3.0% on the same 500 CSVs (twin of drmTMB #1559). |
| https://github.com/itchyshin/DRModels.jl/issues/1118 | `(1\|g)` vs none: `lrtest` warns; chi-bar type-I 3.4% (twin of drmTMB #1560). |
| https://github.com/itchyshin/drmTMB/issues/1556 | Accidental auth-probe issue (`test-auth-t10-please-ignore`). Could not close (403). Please close as not planned. |

### Confirmed, not re-filed (comment 403)

| URL | one line of new evidence |
| --- | --- |
| https://github.com/itchyshin/DRModels.jl/issues/1036 | `lrtest` of two Poisson `(1\|g)` `:VA` fits returns a χ² p-value from an ELBO difference (smoke: stat 6.77, p = 0.009). `aic` on the same fit errors. |
| https://github.com/itchyshin/DRModels.jl/issues/1071 | Poisson `(1\|g)` `:LA` vs `:Laplace` loglik differ by 4.48e-5 on the smoke draw; `lrtest` refuses the pair (good) but the printed `loglik` still does not name the approximation. |
| https://github.com/itchyshin/DRModels.jl/issues/1002 | `lrt_boundary` on `:LA` vs `:Laplace` Poisson `(1\|g)` returns a statistic and does not throw; `lrtest` on the same pair does throw. |
| https://github.com/itchyshin/DRModels.jl/issues/942 | `drm(Gaussian(); se = false)` is still a raw MethodError at `f71b292`; Poisson/NB2 accept `se = false`. |

## Artifacts on this branch

- `sweep-oct16/t10/scripts/` — `gen_data.R`, `smoke_r.R`, `smoke_jl.jl`, `smoke_mix_la_laplace.jl`, `sweep_r.R`, `sweep_jl.jl`
- `sweep-oct16/t10/logs/` — per-rep CSVs, smoke JSONL, `summary_vs_passbar.csv`, `sessionInfo_r.txt`, `versioninfo_jl.txt`, `dat_b_dput.txt`
- Shared data lived in `/tmp/t10-data/` (not committed; 19 MB; regenerable)

## What a user should try when a comparison is unsupported

For a variance on the boundary (`(1 | g)`, or NB2 vs Poisson), do not read the packaged χ² p-value as calibrated. In drmTMB call `lrt_boundary(full, reduced, q = 1)` (anova already does this for an added RE SD, not for NB2). In Julia call `lrt_boundary` after `lrtest`'s warning. Do not compare `:VA` ELBOs, or `:LA` with `:Laplace`, in an LRT; refit both with the same `marginal`. For Gaussian mean `(1 | g)` omit `marginal = :Laplace` and use the default exact `:LA`.
