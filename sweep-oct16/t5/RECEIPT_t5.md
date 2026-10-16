# RECEIPT t5 — Missing data and weights sweep (16 Oct 2026)

Reader: the next Engine A sweep agent, and Shinichi when scoring the
16 Oct 2026 DRM lane. Purpose: record what this cloud task actually ran
on the two pins, how each pass bar came out, and which GitHub issues
already cover the failures (none were newly filed from this host).

## Pins

Recorded with `git rev-parse HEAD` in this task:

| repo | pin requested | `HEAD` |
|---|---|---|
| itchyshin/drmTMB | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` |
| itchyshin/DRModels.jl | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` |

No PR head. Branch for this receipt: `sweep-oct16/t5` (drmTMB only).
DRModels.jl was cloned read-only at `/tmp/DRModels.jl` (no Manifest in
that pin; instantiated from General). Nothing was pushed to `main`.
Nothing was merged.

## Host

- R 4.3.3 (2024-02-29), x86_64-pc-linux-gnu, Ubuntu 24.04.5 LTS.
- drmTMB 0.7.1 installed from the pin (`sudo R CMD INSTALL --no-docs --no-multiarch .`).
- JuliaCall 0.17.6.
- Julia 1.12.7 official tarball at `/opt/julia` (commit `6d172b025e4`, 15 Aug 2026).
- DRModels.jl project: RCall 0.14.14, Suppressor 0.2.8, StatsModels 0.7.10,
  Optim 1.13.3. `JULIA_NUM_THREADS=1`.
- Hard timeout on every fit: `FIT_TIMEOUT=180` (R `setTimeLimit`; Julia
  `timedwait`). No fit hit the timeout. Native max 0.207 s.

## (1) Exact commands

```sh
export DRMODELS_JL_PATH=/tmp/DRModels.jl
export JULIA_PROJECT=/tmp/DRModels.jl
export JULIA_HOME=/opt/julia/bin
export PATH="/opt/julia/bin:$PATH"
export FIT_TIMEOUT=180
export LD_LIBRARY_PATH=/usr/lib/R/lib:${LD_LIBRARY_PATH}

git -C /workspace rev-parse HEAD
# ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
git clone https://github.com/itchyshin/DRModels.jl /tmp/DRModels.jl
git -C /tmp/DRModels.jl checkout f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
git -C /tmp/DRModels.jl rev-parse HEAD
# f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
julia --project=/tmp/DRModels.jl -e 'using Pkg; Pkg.instantiate()'

Rscript sweep-oct16/t5/R/gen_data.R sweep-oct16/t5/data
Rscript sweep-oct16/t5/R/run_native.R \
  sweep-oct16/t5/data sweep-oct16/t5/results/native.csv
# also writes results/native_fixedp.csv
timeout 900 Rscript sweep-oct16/t5/R/run_bridge.R \
  sweep-oct16/t5/data sweep-oct16/t5/results/bridge.csv
timeout 900 julia --project=/tmp/DRModels.jl \
  sweep-oct16/t5/julia/run_direct.jl \
  sweep-oct16/t5/data sweep-oct16/t5/results/julia_direct.csv
timeout 180 julia --project=/tmp/DRModels.jl \
  sweep-oct16/t5/julia/confirm_new.jl sweep-oct16/t5/data \
  > sweep-oct16/t5/results/confirm_new.log
Rscript sweep-oct16/t5/repro/smoke.R
Rscript sweep-oct16/t5/R/compare.R sweep-oct16/t5/results
```

The `%||%` shim in `R/run_bridge.R` is required on R 4.3.3 (drmTMB #1550).
It is a harness-only definition; package source was not patched.

Grid: Gaussian / Poisson / Gamma, each with `(1 | g)`; MCAR NA fraction
in `y` and in `x` ∈ {0, 5%, 20%}; 27 datasets, `n = 200` (25 groups × 8);
seeds nominal `20261016500+` (effective `nominal %% .Machine$integer.max`,
both recorded in `data/manifest.csv`). Weights: omitted, `NULL`, all-ones,
integer 1–3 vs row-duplicated data, random positive vs the same weights
on pre-dropped complete cases. `mi()` was not exercised (lane is
complete-case drop).

## (2) Results vs the pass bar

Computed by `R/compare.R` from this-run `native.csv` (216 rows),
`native_fixedp.csv`, `bridge.csv` (189 rows, all error), and
`julia_direct.csv` (180 rows). Full table: `results/summary.md`.
One row per dataset: `results/cells.csv`.

| Bar | Value | Verdict |
|---|---|---|
| Native integer weights = row duplication, logLik | max \|Δ\| = 1.740545e-10 | **PASS** (bar 1e-8) |
| Native integer weights = row duplication, coefficients | max \|Δ\| = 1.517529e-10 over β_μ, β_σ, log SD(g) | **PASS** |
| Same, objective at fixed θ | max \|Δ nll(θ̂)\| = 4.043841e-10 | **PASS** |
| `weights = NULL` and all-ones = omitted | 0 | **PASS** |
| Random positive weights: NA-row drop keeps weights aligned | 0 | **PASS** |
| Weighted logLik = independent Laplace oracle | max \|Δ\| = 4.109779e-10 | **PASS** |
| nobs: native = harness complete cases | 0 mismatches / 27 | **PASS** |
| nobs: `engine = "julia"` = native | 0 fits returned / 27 | **FAIL** (JuliaCall SIGSEGV, exit 139) |
| nobs: DRModels `drm_listwise` = native | 0 mismatches / 27 | **PASS** |
| nobs: DRModels raw data with `missing` = native | 7 fits / 7 matching; 20 errors | **FAIL** (#1089) |
| `engine = "julia"` = native (logLik / coef) | no Gaussian or Poisson/Gamma fits | **FAIL** (same SIGSEGV) |
| `engine = "julia"` with any `weights` (incl. `NULL`) | 0 / 108 | fenced (#1450) |
| DRModels complete cases = native, Gaussian | max \|ΔlogLik\| 2.4e-12 / \|Δcoef\| 1.8e-10 | **PASS** |
| DRModels `marginal = :Laplace` = native, Poisson/Gamma | 9.7e-11 / 4.4e-09 | **PASS** |
| DRModels default `:LA` (AGHQ-5) vs native Laplace | 4.5e-02 / 5.0e-03 | different integrator (informative, not a bar) |
| DRModels duplicated rows = native integer weights | 1.6e-10 / **3.041880e-08** | **FAIL** on coefficients (bar 1e-8); logLik PASS |
| DRModels `drm(...; weights = w)` | 0 / 27 `MethodError` | not implemented (#931) |
| Native `miss_control()` with NA in `x` | 18/18 error (fail-closed); 9/9 complete-x ok | native as specified |
| Bridge `miss_control()` vs native fail-closed | untested | Julia never started |

Native N6 `miss_control(predictor = "fail")` errors with “Missing values
in: `"x"`” on every cell with `na_x > 0`, and fits when `x` is complete
(including missing `y`, which native drops). That is the intended
fail-closed predictor rule. `mi()` weights (#1459 / PR #1513) were out
of lane.

### Per-cell pattern (27 datasets)

`JD_raw` (CSV-typed columns, so `Union{Missing,Float64}` only when a
column holds a missing):

- 7 `ok` (complete `y00_x00` for all three families, plus Poisson/Gamma
  with missing `y` only): `nobs` matches native.
- 18 `KeyError` (every cell with missing `x`).
- 2 `ArgumentError` (Gaussian missing `y` only: `gaussian_y05_x00`,
  `gaussian_y20_x00`).

`JD_listwise` and `JD_cc`: 27/27 `ok`, `nobs` = native complete cases.
`JD_weights`: 27/27 `MethodError`. `JD_dup`: 27/27 `ok`; the coefficient
bar fails on `gamma_y00_x00` (`log SD(g)` Δ = 3.041879670373504e-08).
`JD_nan`: Poisson returns a fit on NaN-coded `x` (wrong); Gamma
`DomainError`; Gaussian `ArgumentError`.

Standalone `confirm_new.jl` (this host, same pin):

```
KeyError_missing_x ERROR KeyError :: KeyError: key missing not found
weights_kwarg ERROR MethodError
union_eltype_complete_x OK nobs=200 ncoef_mu=200 loglik=6847.01725 conv=false
concrete_eltype_complete_x OK nobs=200 ncoef_mu=2 loglik=-294.0617208 conv=true
g_missing OK nobs=200 loglik=-295.3706635
g_dropped OK nobs=190 loglik=-282.9513345
poisson_nan_x OK nobs=200 loglik=-1e+18 conv=false
poisson_cc_laplace OK nobs=190 loglik=-331.0224734 conv=true
```

Native smoke on `gaussian_y00_x00`: logLik −294.0617, nobs 200, matching
`concrete_eltype_complete_x` and native `N0_omitted`.

### `engine = "julia"` on this host

All 81 unweighted bridge cells (`J0_omitted`, `J6_misscontrol`,
`J7_dup`) failed in JuliaCall before a DRModels.jl fit:

```
running command '.../JuliaCall/julia/install_dependency.jl' '/usr/lib/R'
had status 139
Error happens when you try to execute command ENV["R_HOME"] = "/usr/lib/R";
Base.include(Main, ".../JuliaCall/julia/setup.jl") in Julia.
```

Status 139 is SIGSEGV. Isolated `julia_call("sqrt", 4)` can succeed;
`drmTMB(..., engine = "julia")` does not. Standalone
`julia --project=/tmp/DRModels.jl` on the same CSVs does fit. This is
why the pass bar “`engine = "julia"` matches native” is FAIL here, while
direct Julia vs native (complete cases, Laplace) PASSES. A prior t5 pass
on conda-forge Julia did return Gaussian bridge fits; this official
1.12.7 tarball did not. #1551 (`resd` label on Poisson/Gamma) and #1454
(`miss_control` on the bridge) were not reachable.

The 108 weighted bridge cells failed earlier with the #1450 fence
(`engine = "julia" does not support weights yet`), including
`weights = NULL`. That fence does not need Julia to start.

## (3) Issues filed or commented

**None from this host.** GitHub writes are 403.

Attempts:

- GitHub MCP `add_issue_comment` on DRModels.jl #1089, #931, #1111,
  #1112, #1113 and drmTMB #1450, #1550:
  `403 Resource not accessible by personal access token`.
- GitHub MCP `issue_write` create on drmTMB (JuliaCall SIGSEGV):
  same 403.
- `gh issue comment` (CLI account `cursor`, `ghs_` token):
  `GraphQL: Resource not accessible by integration (addComment)`.

`gh auth status` is the `cursor` integration. MCP `get_me` reports
`itchyshin`, but writes still 403. Findings below were matched against
open issues with `gh issue list` / `gh issue view` (read works) and were
**not** re-filed.

| URL | One line | This run |
|---|---|---|
| https://github.com/itchyshin/DRModels.jl/issues/1089 | KeyError on missing `x`; Gaussian `(1\|g)` ArgumentError on missing `y` | reproduced, 18 KeyError + 2 ArgumentError; `drm_listwise` nobs matches |
| https://github.com/itchyshin/DRModels.jl/issues/931 | `drm(...; weights = w)` MethodError | reproduced, 27/27 |
| https://github.com/itchyshin/DRModels.jl/issues/1111 | `Union{Missing,Float64}` predictor dummy-coded as a factor | reproduced, 200 μ coefs / loglik +6847 vs 2 / −294.06 |
| https://github.com/itchyshin/DRModels.jl/issues/1112 | missing in `g` fitted as an extra RE level | reproduced, nobs 200 vs dropped 190 |
| https://github.com/itchyshin/DRModels.jl/issues/1113 | NaN predictor: Poisson returns −1e18 start-value fit | reproduced, nobs 200 vs cc 190 |
| https://github.com/itchyshin/drmTMB/issues/1450 | `engine = "julia"` refuses `weights` including `NULL` | reproduced, 108/108 |
| https://github.com/itchyshin/drmTMB/issues/1550 | `%||%` missing on R &lt; 4.4 | confirmed on R 4.3.3; harness shims it |
| https://github.com/itchyshin/drmTMB/issues/1459 | `mi()` weights | **not exercised** (out of lane) |
| https://github.com/itchyshin/drmTMB/pull/1513 | draft `mi()` weight pins | **not exercised** |
| https://github.com/itchyshin/drmTMB/issues/1551 | Poisson/Gamma `resd` abort | **untested** (Julia never started) |
| https://github.com/itchyshin/drmTMB/issues/1454 | Julia `miss_control` NA handling | **untested** (Julia never started) |
| https://github.com/itchyshin/drmTMB/issues/1157 | red boot ERROR that still fits | **not this bug** (this host SIGSEGVs) |

Two confirmed findings have **no** matching open issue. They could not
be filed from this token. Paste-ready titles:

1. drmTMB — `engine = "julia"` SIGSEGV (exit 139) in JuliaCall
   `install_dependency.jl` on official Julia 1.12.7; standalone
   `julia --project` fits. Not #1157, not #1550. Repro: `%||%` shim +
   `drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(),
   data = gaussian_y00_x00, engine = "julia")`. Data:
   `sweep-oct16/t5/data/gaussian_y00_x00.csv`.
2. DRModels.jl — row-duplication workaround vs drmTMB integer weights
   fails the 1e-8 coefficient bar on Gamma `(1 | g)` (`gamma_y00_x00`,
   Δ log SD(g) = 3.041879670373504e-08). logLik PASSES (1.4e-11 on that
   cell; 1.6e-10 grid max). Native integer vs native duplication on the
   same cell is 1.5e-10. Refs #931.

#1111 / #1112 / #1113 were opened earlier today by a parallel t5 agent
(~21:32 UTC) with full repros. This host independently confirmed them
in `confirm_new.jl` and did not open duplicates.

## (4) Commits used

- drmTMB pin: `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`
- DRModels.jl pin: `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`
- PR head SHA: none (this lane does not open a PR)
- Receipt branch: `sweep-oct16/t5` on itchyshin/drmTMB

Harness, CSVs, logs, `results/`, and this file live only on that branch.
`.Rbuildignore` contains `^sweep-oct16$` so the lane is not a CRAN file.
