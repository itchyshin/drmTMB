2026-10-16 21:29:45 UTC — start. Lane t9 expected over 3 h (pre-approved). Finished 2026-10-16 22:21:43 UTC.

# RECEIPT t9 — Wald vs profile vs bootstrap coverage

Gaussian location-scale with `(1|g)`. Pins checked out exactly. Never pushed to main. No PR. Issues only (`Refs`, never `Closes`). Hard timeouts on every fit. Token could **create** issues but **could not comment** on existing threads (`403 Resource not accessible by integration`), so matching evidence is recorded here and in new t9 issues that `Refs` the known ones.

## Pins (`git rev-parse HEAD`)

- drmTMB: `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`
- DRModels.jl: `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`
- Branch: `sweep-oct16/t9` (receipt commit SHA is this branch HEAD after push)
- PR head SHA: none (spec forbids a PR)

## Design

`y = 0 + 0.5 x + u_g + exp(0 + 0.3 x) ε`, `u_g ~ N(0, sd_g)`, `ε ~ N(0, 1)`.

- `n_g = 10` observations per group; `x` equally spaced in `[-1, 1]` within each group
- `G ∈ {10, 30}`, `sd_g ∈ {0.1, 0.5}` → four cells
- 300 reps; seeds `20261016900 + (cell_index-1)*300 + (rep-1)`
- R `set.seed(spec_seed %% 2147483647)` because `20261016900` overflows 32-bit integers
- 95% intervals for sigma intercept, sigma slope, and `sd_g`
- Wald and profile on all 300 reps; parametric bootstrap `B = 199` on the first 100 reps
- Pass bar: **profile coverage in [93%, 97%]**; report Wald/bootstrap; **no silent NaN intervals**
- Timeouts: fit 30 s, Wald 15 s, profile 60–90 s, bootstrap 180 s (plus process `timeout 4h`)

Cell index: (1) G=10, sd_g=0.1; (2) G=10, sd_g=0.5; (3) G=30, sd_g=0.1; (4) G=30, sd_g=0.5.

Truth: sigma intercept `0` (log residual-SD intercept); sigma slope `0.3`; `sd_g` on the SD scale in R and on `log(sd_g)` in Julia.

## Exact commands run

```sh
git -C /workspace rev-parse HEAD
# ca3ddefa5ea11bbfd3b765615dfbb89305d2485a

git clone --no-checkout https://github.com/itchyshin/DRModels.jl /tmp/DRModels.jl
git -C /tmp/DRModels.jl fetch --depth=1 origin f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
git -C /tmp/DRModels.jl checkout f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
git -C /tmp/DRModels.jl rev-parse HEAD
# f71b2923360e9e5d4591e0d6e15a9ef9db0356d7

sudo apt-get install -y r-base r-base-dev gfortran cmake   # R 4.3.3
# Julia 1.10.10 tarball → /opt/julia
Rscript -e 'install.packages(c("TMB","RcppEigen","cli","lifecycle"), ...)'
R CMD INSTALL /workspace
julia --project=/tmp/DRModels.jl -e 'using Pkg; Pkg.instantiate()'

# four R cells + Julia, hard process timeout 4h
Rscript sweep-oct16/t9/run_t9_r.R --G 10 --sd_g 0.1 --n_rep 300 --n_boot_rep 100 --B 199 --cell_index 1 --out sweep-oct16/t9/results/r_cell1.tsv
Rscript sweep-oct16/t9/run_t9_r.R --G 10 --sd_g 0.5 --n_rep 300 --n_boot_rep 100 --B 199 --cell_index 2 --out sweep-oct16/t9/results/r_cell2.tsv
Rscript sweep-oct16/t9/run_t9_r.R --G 30 --sd_g 0.1 --n_rep 300 --n_boot_rep 100 --B 199 --cell_index 3 --out sweep-oct16/t9/results/r_cell3.tsv
Rscript sweep-oct16/t9/run_t9_r.R --G 30 --sd_g 0.5 --n_rep 300 --n_boot_rep 100 --B 199 --cell_index 4 --out sweep-oct16/t9/results/r_cell4.tsv
julia --project=/tmp/DRModels.jl sweep-oct16/t9/run_t9_jl.jl
Rscript sweep-oct16/t9/summarize_t9.R
```

Smoke timings (compiled): drmTMB fit ~0.05–0.13 s, profile ~0.7–1.3 s, bootstrap B=19 ~0.3 s. DRModels.jl fit ~0.001–0.002 s, profile ~0.003–0.06 s, bootstrap B=19 ~0.03–0.63 s.

Zero timeouts, zero harness errors, zero silent NaN in 8,400 R rows and 8,400 Julia rows.

## Results per cell vs the pass bar

Profile pass = coverage of all 300 attempts in **[0.93, 0.97]**. Wald and bootstrap are reported only.

### drmTMB (R) — profile

| cell | G | sd_g | sigma intercept | sigma slope | sd_g | pass? |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 10 | 0.1 | 0.9400 | 0.9467 | **0.9733** (287/300 boundary) | intercept/slope pass; sd_g over |
| 2 | 10 | 0.5 | 0.9467 | 0.9467 | **0.9267** | intercept/slope pass; sd_g under |
| 3 | 30 | 0.1 | 0.9400 | **0.9267** | **0.9833** (282/300 boundary) | intercept pass; slope under; sd_g over |
| 4 | 30 | 0.5 | 0.9300 | **0.9033** | 0.9567 | intercept and sd_g pass; slope under |

### drmTMB (R) — Wald / bootstrap (report only)

| cell | G | sd_g | method | sigma intercept | sigma slope | sd_g |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 10 | 0.1 | Wald | 0.9200 | 0.9467 | 0.3600 (159 Inf, 157 boundary) |
| 1 | 10 | 0.1 | boot | 0.8700 | 0.9700 | 1.0000 (100/100 boundary) |
| 2 | 10 | 0.5 | Wald | 0.9400 | 0.9467 | 0.9700 |
| 2 | 10 | 0.5 | boot | 0.9100 | 0.9500 | 0.7900 |
| 3 | 30 | 0.1 | Wald | 0.9367 | 0.9300 | 0.4167 (147 Inf) |
| 3 | 30 | 0.1 | boot | 0.8800 | 0.9300 | 0.9900 |
| 4 | 30 | 0.5 | Wald | 0.9233 | 0.9033 | 0.9800 |
| 4 | 30 | 0.5 | boot | 0.9700 | 0.9000 | 0.9100 |

### DRModels.jl — profile

Julia intervals are on the working scale (`log σ`, `log σ_b`). Coverage uses that scale.

| cell | G | sd_g | sigma intercept | sigma slope | sd_g (`log`) | pass? |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 10 | 0.1 | **0.9167** | 0.9367 | **0.0033** (4/300 finite; 151 failed) | slope only |
| 2 | 10 | 0.5 | 0.9400 | 0.9367 | **0.7167** (221/300 finite; 72 failed) | intercept/slope pass |
| 3 | 30 | 0.1 | 0.9300 | **0.9733** | **0.0267** (15/300 finite; 166 failed) | intercept pass |
| 4 | 30 | 0.5 | 0.9300 | 0.9333 | **0.9200** | intercept/slope pass; sd_g just under |

`confint(..., method = :profile)` **throws** when a `resd:g` lower arm is `not_converged`. `profile_result` keeps `(-Inf, x]`. When `log σ_b` hits ≈ −20, both engines of `confint` return `(-Inf, Inf)` as success.

### DRModels.jl — Wald / bootstrap (report only)

| cell | G | sd_g | method | sigma intercept | sigma slope | sd_g (`log`) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 10 | 0.1 | Wald | 0.9233 | 0.9367 | 0.4000 |
| 1 | 10 | 0.1 | boot | 0.8400 | 0.9500 | 1.0000 |
| 2 | 10 | 0.5 | Wald | 0.9367 | 0.9367 | 0.9600 |
| 2 | 10 | 0.5 | boot | 0.8800 | 0.9100 | 0.8200 |
| 3 | 30 | 0.1 | Wald | 0.9333 | 0.9733 | 0.4800 |
| 3 | 30 | 0.1 | boot | 0.9000 | 0.9400 | 0.9700 |
| 4 | 30 | 0.5 | Wald | 0.9267 | 0.9333 | 0.9467 |
| 4 | 30 | 0.5 | boot | 0.8300 | 0.9500 | 0.8900 |

## Silent NaN

None. R: 0 NaN in 8,400 rows. Julia: 0 NaN in 8,400 rows. Non-finite values were signed `Inf` with an explicit failed/boundary/unbounded status, or a thrown `ArgumentError` from Julia `confint` (caught via `profile_result` in the harness).

## Issues filed or referenced

Commenting on existing issues was blocked (`gh api …/comments` → 403). New issues were filed for new breaks; known issues were not re-filed.

| action | URL | one line |
| --- | --- | --- |
| filed | https://github.com/itchyshin/DRModels.jl/issues/1117 | Julia profile for ordinary `(1\|g)` SD at G=10, sd_g=0.1: `confint` throws or returns `(-Inf, Inf)` |
| filed | https://github.com/itchyshin/DRModels.jl/issues/1119 | Julia percentile bootstrap under-covers the sigma intercept (83–90% in all 4 cells; one-sided). Twin of drmTMB #1315 |
| filed | https://github.com/itchyshin/drmTMB/issues/1562 | R profile: sigma slope 90.3% at G=30, sd_g=0.5; sd_g overcovers at sd_g=0.1; no silent NaN. Refs #1315, #1558 |
| known, not re-filed | https://github.com/itchyshin/drmTMB/issues/1315 | Percentile bootstrap doubles ML bias and under-covers (Dinnage S6). t9 R bootstrap sigma intercept 0.87–0.91 in 3/4 cells |
| known, not re-filed | https://github.com/itchyshin/drmTMB/issues/1558 | Wald ordinary `(1\|g)` SD under-cover; `small_sample_df` does not reach `log_sd_mu`. t9 Wald sd_g at sd_g=0.1 is 0.36–0.42 with many Inf |
| comment blocked | https://github.com/itchyshin/DRModels.jl/issues/1117 | Could not add the G=30 / sd_g=0.5 addendum (coverage 0.027 and 0.717) |

## Artifacts

- `sweep-oct16/t9/run_t9_r.R`, `run_t9_jl.jl`, `summarize_t9.R`, `launch_t9.sh`
- `sweep-oct16/t9/results/r_reps.tsv`, `jl_reps.tsv` (one row per engine × cell × rep × method × target)
- `sweep-oct16/t9/results/r_coverage.tsv`, `jl_coverage.tsv`, `coverage_summary.tsv`

## Environment

R 4.3.3, drmTMB 0.7.1 (source pin above), TMB 1.9.25, Matrix 1.6-5. Julia 1.10.10, DRModels.jl 0.7.2 at the pin. 4 CPUs, Ubuntu 24.04.5.
