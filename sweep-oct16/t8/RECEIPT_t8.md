# RECEIPT t8 — Real-data parity, second pass (16 Oct 2026)

Lane t8 of the Engine A DRM sweep. Fifteen datasets not used in the 3 Oct catalogue (#1463) or the Oct sweep trackers (#1464, DRModels.jl#973). Natural location-scale model in drmTMB and DRModels.jl, plus the matching glmmTMB or lme4 fit. Pass bar: `|ΔlogLik| ≤ 1e-4` (Laplace where both engines expose it), coefficient relative `|a-b|/max(|a|,|b|,ε) ≤ 1e-4`, SE absolute `|a-b| ≤ 1e-3`.

No PR. Branch `sweep-oct16/t8` only. Never pushed to `main`. Never merged.

## Commits used

| tree | SHA | note |
|---|---|---|
| drmTMB pin (also this branch's merge-base) | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` | `git rev-parse HEAD` at checkout |
| DRModels.jl pin | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` | cloned to `/tmp/DRModels.jl`; `git rev-parse HEAD` |
| this receipt branch | recorded after `git push` as the tip of `sweep-oct16/t8` | evidence + harness + this file |

drmTMB 0.7.1. DRModels.jl 0.7.2.

## Exact commands

Host: Ubuntu 24.04.5 LTS, 4 CPU, 15 GB RAM. R 4.3.3 from apt (`TMB` 1.9.25). Julia 1.11.6 at `/tmp/julia-1.11.6`. glmmTMB 1.1.15.2 installed via archived `Deriv_4.1.6` because current Deriv needs R ≥ 4.5. R user library `/home/ubuntu/R/library`.

```sh
git rev-parse HEAD
# ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
git checkout -b sweep-oct16/t8

git clone https://github.com/itchyshin/DRModels.jl /tmp/DRModels.jl
git -C /tmp/DRModels.jl checkout f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
git -C /tmp/DRModels.jl rev-parse HEAD
# f71b2923360e9e5d4591e0d6e15a9ef9db0356d7

export T8_ROOT=/workspace/sweep-oct16/t8
export R_LIBS_USER=/home/ubuntu/R/library
export PATH="/tmp/julia-1.11.6/bin:$PATH"
# Julia project at /tmp/DRModels.jl; CSV and JSON added for the harness

# Per case, hard timeout (timeout(1) SIGKILL). run_case.sh:
#   timeout --signal=KILL $TO Rscript prepare_and_fit_r.R $ID
#   timeout --signal=KILL $TO julia --project=/tmp/DRModels.jl fit_jl.jl $ID
#   timeout --signal=KILL 60 Rscript compare_case.R $ID
bash "$T8_ROOT/run_all.sh"
```

Cases and timeouts (seconds): warpbreaks 120, ToothGrowth 120, Prestige 120, GasolineYield 180, ReadingSkills 180, quine 180, crowder_seeds 180, beall_webworms 180, cbpp 180, epil 180, Orthodont 180, yates_oats 180, Pastes 180, bacteria 180, Owls 180. No hang. No timeout (exit 124).

Harness notes that are not product bugs:

- `jsonlite` writes `digits = NA` so coefficient comparisons are not rounded to 4 digits.
- All-digit factor labels (`batch`, `herd`, `period`) are prefixed `g`. Without that, CSV.jl parses them as numeric and Julia fits the wrong model.
- `marginal = :Laplace` is requested only for NB2/Binomial/Poisson/Gamma/Beta ordinary `(1|g)`. Gaussian mean RE and BetaBinomial RE use the default integrator (Julia refuses `:Laplace` there; see #943 comment draft).
- Owls ZI+RE is a probe, not the scored cell.

## Datasets skipped (already in Oct sweeps)

From #1463: `lme4::sleepstudy` (df2-p01), `glmmTMB::Salamanders` (df2-c01), `datasets::InsectSprays` (df2b-c07), `datasets::ChickWeight` (df2b-e07).

## Results per cell vs pass bar

13 / 15 PASS. 2 / 15 FAIL_BAR. 0 hangs. 0 BOTH_FAIL after harness fixes.

`dLL_RJ` is `|logLik(drmTMB) − logLik(DRModels.jl)|`. `dLL_Rref` is `|logLik(drmTMB) − logLik(glmmTMB or lme4)|`. Coef/SE columns are name-normalized matches.

| id | source | family | n | model (mu / sigma) | verdict | dLL_RJ | dLL_Rref | coef pass | SE pass | conv R/J |
|---|---|---|---|---|---|---|---|---|---|---|
| warpbreaks | datasets::warpbreaks | gaussian | 54 | `breaks ~ wool * tension` / `~ wool` | **PASS** | 2.6e-13 | 3.0e-12 | 8/8 | 8/8 | T/T |
| ToothGrowth | datasets::ToothGrowth | gaussian | 60 | `len ~ dose * supp` / `~ supp` | **PASS** | 2.8e-14 | 2.4e-11 | 6/6 | 6/6 | T/T |
| Prestige | carData::Prestige | gaussian | 98 | `prestige ~ education + log(income) + type` / `~ type` (type NA dropped) | **PASS** | 1.0e-12 | 7.4e-10 | 8/8 | 8/8 | T/T |
| quine | MASS::quine | nbinom2 | 146 | `Days ~ Eth + Sex + Age + Lrn` / `~ Eth` | **PASS** | 1.1e-13 | 2.6e-8 | 9/9 | 9/9 | T/T |
| crowder_seeds | agridat::crowder.seeds | beta_binomial | 21 | `cbind(germ, fail) ~ gen * extract` / `~ 1` | **PASS** | 5.5e-12 | 7.3e-12 | 5/5 | 5/5 | T/T |
| beall_webworms | agridat::beall.webworms | nbinom2 | 1300 | `y ~ spray * lead` / `~ spray` | **PASS** | 4.5e-11 | 3.5e-8 | 6/6 | 6/6 | T/T |
| ReadingSkills | betareg::ReadingSkills | beta | 44 | `accuracy ~ dyslexia * iq` / `~ dyslexia` | **PASS** | 5.1e-12 | 4.0e-12 | 6/6 | 6/6 | T/T |
| GasolineYield | betareg::GasolineYield | beta | 32 | `yield ~ temp + batch` / `~ batch` | **FAIL_BAR** | 0.0168 | 2.9e-10 | 0/21 | 0/0 | F/F |
| epil | MASS::epil | nbinom2 | 236 | `y ~ lbase + trt + lage + V4 + (1\|subject)` / `~ 1` | **PASS** | 3.4e-11 | 2.8e-9 | 6/6 | 6/6 | T/T |
| Owls | glmmTMB::Owls | nbinom2 | 599 | `NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize)` / `~ FoodTreatment` | **FAIL_BAR** | 1.426 | 2.0e-11 | 0/6 | 5/6 | T/T |
| bacteria | MASS::bacteria | binomial | 220 | `y01 ~ week + trt + (1\|ID)` / (none) | **PASS** | 2.7e-13 | 2.4e-5 | 4/4 | 4/4 | T/T |
| Orthodont | nlme::Orthodont | gaussian | 108 | `distance ~ age * Sex + (1\|Subject)` / `~ Sex` | **PASS** | 2.8e-13 | 5.0e-12 | 6/6 | 6/6 | T/T |
| yates_oats | agridat::yates.oats | gaussian | 72 | `yield ~ nitro * gen + (1\|block)` / `~ gen` | **PASS** | 9.7e-13 | 1.0e-11 | 9/9 | 9/9 | T/T |
| Pastes | lme4::Pastes | gaussian | 60 | `strength ~ 1 + (1\|batch) + (1\|sample)` / `~ 1` (lme4 ref) | **PASS** | 5.1e-13 | 2.3e-10 | 2/2 | 2/2 | T/T |
| cbpp | lme4::cbpp | beta_binomial | 56 | `cbind(incidence, fail) ~ period + (1\|herd)` / `~ 1` | **PASS** | 4.5e-10 | 1.1e-8 | 5/5 | 5/5 | T/T |

Full numeric dump: `sweep-oct16/t8/results.csv`. Per-fit JSON: `sweep-oct16/t8/fits/<id>/{r,jl,ref,compare}.json`.

bacteria `dLL_Rref = 2.4e-5` still passes the 1e-4 bar (lme4 Laplace vs drmTMB). Julia matched drmTMB to 2.7e-13.

## FAIL_BAR detail

### Owls — duplicate of DRModels.jl#1097 / #938

Julia estimates `offset(logBroodSize)` as a free coefficient 0.755 (should be 1). drmTMB and glmmTMB logLik −1699.24301683246 (Δ 2e-11). Julia −1697.81701775589. Coef relative max 0.1487.

ZI+RE probe (not scored): drmTMB refuses with the #1451 message. Julia with `marginal = :Laplace` refuses because of `zi` (harness miss). Retry without Laplace: `NegBinomial2() random effects cannot be combined with zi/hu yet` (#940).

### GasolineYield — weakly identified Beta loc-scale

10 batches, 2–4 rows each, `sigma ~ batch`. drmTMB logLik 92.0596218477018 matches glmmTMB 92.0596218474146 (Δ 2.9e-10) but `is_converged = FALSE` (Hessian not PD; `vcov` refused; opt "relative convergence (4)"). Julia logLik 92.04282636918045 (Δ 0.0168), also not converged, but prints 21 finite SEs. Not #1470 (no exact alias). New Julia issue drafted; R flag behaviour comments on #1554.

## Issues filed or commented

GitHub writes from this cloud task returned 403 (MCP PAT: "Resource not accessible by personal access token"; Cursor GitHub App `gh`: "Resource not accessible by integration"). Findings are not re-filed as new issues. Complete, postable bodies with source, prep, repro, SHAs, sessionInfo, and prepared data live under `sweep-oct16/t8/issues/`.

| intended action | URL | one line | this-run status |
|---|---|---|---|
| comment | https://github.com/itchyshin/DRModels.jl/issues/1097 | Owls NB2 loc-scale: Julia estimates `offset(logBroodSize)` = 0.755; logLik Δ 1.426 vs drmTMB/glmmTMB | 403; body in `issues/COMMENT_DRModels_1097.md` |
| comment | https://github.com/itchyshin/drmTMB/issues/1451 | Owls ZINB `(1\|Nest)` still refused at `ca3ddef` (same planned-not-implemented message) | 403; body in `issues/COMMENT_drmTMB_1451.md` |
| comment | https://github.com/itchyshin/DRModels.jl/issues/940 | Owls ZI+RE, default integrator: `NegBinomial2() random effects cannot be combined with zi/hu yet` | 403; body in `issues/COMMENT_DRModels_940.md` |
| comment | https://github.com/itchyshin/DRModels.jl/issues/943 | cbpp BetaBinomial `(1\|herd)`: `:Laplace` refused; default GHQ matched drmTMB to 4.5e-10 | 403; body in `issues/COMMENT_DRModels_943.md` |
| comment | https://github.com/itchyshin/drmTMB/issues/1554 | GasolineYield: drmTMB/glmmTMB same optimum, drmTMB FALSE (non-PD Hessian), glmmTMB TRUE | 403; body in `issues/COMMENT_drmTMB_1554.md` |
| new issue | (DRModels.jl, not created) | GasolineYield: Julia misses the R/glmmTMB optimum by 0.017 and still prints SEs when not converged | 403; body in `issues/NEW_DRModels_GasolineYield.md` |

Known issues not re-filed: #1451, #1097, #938, #943, #1452, #1470, #1478, #1554. Gaussian mean-RE `:Laplace` refuse is documented (Woodbury = Laplace; Orthodont/yates_oats/Pastes PASS).

## Session

See `sweep-oct16/t8/sessionInfo_full.txt` and `sweep-oct16/t8/versioninfo.txt`.

R 4.3.3, Ubuntu 24.04.5 LTS x86_64, drmTMB 0.7.1, glmmTMB 1.1.15.2, lme4 2.0-6, TMB 1.9.25, MASS 7.3-60.0.1, nlme 3.1-164, carData 3.0-6, betareg 3.2-6, agridat 1.26.

Julia 1.11.6, 1 thread, DRModels 0.7.2.
