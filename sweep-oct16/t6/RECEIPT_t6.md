# RECEIPT: sweep-oct16 lane t6, `predict()` and `simulate()` methods

**For:** Engine A (sweep coordination) and the maintainers triaging the issues below.
**Date:** 16 Oct 2026, cloud session only (never the shared box).
**Pins:** drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` · DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`.
**Lane PR (test material only):** itchyshin/drmTMB#1561.

## Bottom line

**Filed: 9 new issues.**
- Silent wrong answers: 2. DRModels.jl#1120 (response-scale inverse links) and drmTMB#1566 (bridge `fitted()`).
- Crashes: 2. DRModels.jl#1121 and DRModels.jl#1123 (the latter incidental).
- Bridge refusals or gaps: 2. drmTMB#1567 and drmTMB#1570.
- Docs contradictions: 2. drmTMB#1568 and drmTMB#1569.
- Twin capability gaps: 1. DRModels.jl#1122.

**Added evidence to 7 existing issues** (comment on a matching issue first): drmTMB#1536, drmTMB#1551, DRModels.jl#1000, #1102, #943, #1092, #1104. The #1102 comment carries a new silent wrong answer: crossed-route LogNormal `simulate()`.

**drmTMB native (`engine = "tmb"`) passes every SPEC test in all 28 cells**, including P6 Tweedie once the `tweedie` package was installed. Its open items are documentation and argument checking: #1568, and #1536 (now executed).

**The SPEC's 1e-8 R-vs-Julia bar:**
- Met on the link scale in every comparable cell: ≤ 8.9e-15 at shared coefficients (P9).
- Met by the bridge: ≤ 2.2e-16 (P11).
- Fails on the response scale where DRModels.jl applies the wrong inverse link (#1120).
- Not evaluable for CumulativeLogit (#1121).
- Fit-vs-fit (P10) meets it for all 13 evaluable fixed-effect cells (≤ 1.2e-10) but not for most `(1 | g)` cells. There the gap comes entirely from GHQ vs Laplace coefficients (#943, #1071), not from the predict code.

## Scope, interpretation and deviations (read before the numbers)

1. **"Each family in t1".** No definition of lane t1's family list was reachable. It is not in either repository, the issue trackers or any pushed branch. I used the **14 univariate families common to both engines**: gaussian, student, skew_normal, lognormal, gamma, beta, zero_one_beta, beta_binomial, binomial, poisson, nbinom2, truncated_nbinom2, tweedie and cumulative_logit. Each was run with and without `(1 | g)`, giving 28 cells. If t1 used a different list, cross-check before merging tables.
2. **Seeds.** Julia uses the literal seeds 20261016600 + k. R's `set.seed()` rejects values above 2³¹−1, so R uses **seed − 2·10¹⁰** (261016600 + k). Lane t5 (#1550) used `seed %% .Machine$integer.max` instead. Both mappings are deterministic and documented, but they differ. Simulation seeds are cell seed + 100. The mapping is in `data/cells.csv`.
3. **"R vs Julia predict equal to 1e-8"** was tested three ways, because fits from two optimizers cannot agree to 1e-8 in general:
   - **P9:** R's coefficients injected into the Julia fit, so the prediction layer alone is compared.
   - **P10:** each engine's own fit.
   - **P11:** the `engine = "julia"` bridge against DRModels.jl on the identical optimizer path.
4. **Environment.** CRAN, r-universe and every Julia host are blocked by this environment's network policy. So:
   - R packages come from Ubuntu `r-cran-*` binaries;
   - Julia 1.12.7 comes from conda-forge (an unofficial build), with packages and artifacts from GitHub (`JULIA_PKG_SERVER=""`);
   - JuliaCall comes from GitHub (`947d1f3`);
   - `tweedie` 3.1.0 comes from GitHub's `cran/tweedie` mirror (`9d3ff48`).

   Both packages under test are built from the pinned checkouts. Full `sessionInfo()` and `versioninfo()` are in `logs/`.
5. **#1550 workaround.** R 4.3.3 lacks base `%||%`, so every `engine = "julia"` call needed the global-environment shim that #1550 documents (lane t5). It reproduced here, but I added no comment because there was nothing new.
6. **Julia `(1 | g)` fits.** These were run with the default marginal and also with `marginal = :Laplace` where accepted (student, binomial, poisson). P10 uses the Laplace fit where one exists.

## Method

- **Spec:** `SPEC_t6.md` (P1–P11).
- **Data:** `data/` (from `R/00_make_data.R`). n = 240 with 24 groups of 10; x ~ N(0, 1); f is a 3-level character variable; b ~ N(0, 0.5²) in `ri` cells. Newdata files:
  - `nd_main`: 18 rows, seen and unseen g;
  - `nd_subset`: one f level;
  - `nd_unseen_f`: f = "d".
- **Orchestration:** two Claude Code workflows.
  1. R harness ∥ Julia harness → shared-parameter parity ∥ bridge → triage (5 agents).
  2. Fresh-process repro verifiers for Julia, R and the bridge, plus an adversarial refuter (4 agents).

  Every filed claim was re-run from a short, standalone repro (`repro/`) in a fresh process. The refuter's dispositions moved several candidates from "new issue" to "comment" (record: `results/verify_wf2.json`).
- **P8 pass rule:** global mean z, and a batch-means variance z (40 batches × 25 draws), with pass at |z| < 3. Per-row z counts and a residual-on-x/f regression are diagnostics. For marginal draws, expected moments come from 64-node Gauss–Hermite.

## Results matrix

Built by `R/90_receipt_matrix.R` from `results/*_summary.csv` and `results/parity_p9_p10.csv`.

| cell | seed | R P1-P7 | R P8 z mean/var | Julia P1-P7 | Julia P8 z mean/var (b = 0) | P9 shared-theta | P10 own fits | P11 bridge |
|---|---|---|---|---|---|---|---|---|
| gaussian_fixed | 20261016600 | PPPPPPP | 0.7/0.3 | PPPPP-P | -0.2/1.4 | P (link 4.0e-15) | P (link 1.3e-12) | PASS (5.6e-17) |
| gaussian_ri | 20261016601 | PPPPPPP | -0.4/-0.6; re.form=NULL 0.1/-0.1 | PPPPP-P | -0.1/1.0 (vs marginal var z -71.2) | P (link 4.4e-15) | P (link 2.4e-11) | refused |
| student_fixed | 20261016602 | PPPPPPP | -1.2/-0.1 | FFFPF-P | -1.1/-1.8 | F (link 4.0e-15) | P (link 6.8e-11) | PASS (0.0e+00) |
| student_ri | 20261016603 | PPPPPPP | -0.6/-0.7; re.form=NULL -1.0/1.0 | FFFPF-P | -1.7/-0.4 (vs marginal var z -51.5) | F (link 3.1e-15) | P (link 7.2e-11) | refused |
| skew_normal_fixed | 20261016604 | PPPPPPP | 0.0/-2.2 | FFFPF-F | -0.3/0.1 | F (link 4.9e-15) | P (link 1.1e-10) | PASS (5.6e-17) |
| skew_normal_ri | 20261016605 | PPPPPPP | 0.9/-0.8; re.form=NULL 0.1/0.8 | refused | NA | NA | NA | refused |
| lognormal_fixed | 20261016606 | PPPPPPP | 0.2/-2.9 | FPFPF-P | 1.3/-0.8 | P (link 4.7e-15) | P (link 3.0e-11) | PASS (2.2e-16) |
| lognormal_ri | 20261016607 | PPPPPPP | -0.0/-0.4; re.form=NULL 1.6/0.8 | FPFPF-P | 2.0/1.2 (vs marginal var z -38.8) | P (link 4.0e-15) | P (link 1.6e-12) | refused |
| gamma_fixed | 20261016608 | PPPPPPP | -0.9/0.3 | PPFPF-P | 0.2/-0.9 | P (link 8.4e-15) | P (link 2.5e-12) | PASS (2.8e-17) |
| gamma_ri | 20261016609 | PPPPPPP | 0.1/-0.1; re.form=NULL -1.2/-0.1 | PPFPF-P | -0.2/-0.1 (vs marginal var z -34.8) | P (link 6.4e-15) | F (link 7.7e-05) | refused |
| beta_fixed | 20261016610 | PPPPPPP | 0.8/0.0 | PPFPF-P | 1.0/1.2 | P (link 4.2e-15) | P (link 2.4e-11) | PASS (0.0e+00) |
| beta_ri | 20261016611 | PPPPPPP | -0.6/-0.3; re.form=NULL 1.1/0.9 | PPFPF-P | -0.5/-1.2 (vs marginal var z -238.1) | P (link 4.2e-15) | F (link 4.0e-04) | refused |
| zero_one_beta_fixed | 20261016612 | PPPPPPP | -1.5/1.2 | FFFPF-F | -1.4/1.5 | F (link 4.0e-15) | P (link 2.2e-12) | PASS (0.0e+00) |
| zero_one_beta_ri | 20261016613 | PPPPPPP | -0.5/0.2; re.form=NULL 0.1/-0.6 | FFFPF-F | 0.7/0.7 (vs marginal var z -21.7) | F (link 6.0e-15) | F (link 2.7e-04) | refused |
| beta_binomial_fixed | 20261016614 | PPPPPPP | -0.5/0.2 | PPFPF-P | -0.8/1.5 | P (link 2.0e-15) | P (link 3.5e-11) | PASS (0.0e+00) |
| beta_binomial_ri | 20261016615 | PPPPPPP | 0.2/1.8; re.form=NULL 1.8/-0.8 | PPFPF-P | 0.1/0.6 (vs marginal var z -73.3) | P (link 4.0e-15) | F (link 3.3e-04) | refused |
| binomial_fixed | 20261016616 | PPPPPPP | 0.9/-0.5 | PPFPF-P | 0.8/0.4 | P (link 3.3e-16) | P (link 2.2e-13) | PASS (0.0e+00) |
| binomial_ri | 20261016617 | PPPPPPP | 0.8/0.7; re.form=NULL -0.2/0.6 | PPFPF-P | -1.7/0.4 (vs marginal var z -148.5) | P (link 2.0e-15) | P (link 5.0e-11) | refused |
| poisson_fixed | 20261016618 | PPPPPPP | 0.5/-0.2 | PPFPF-P | 1.2/0.0 | P (link 3.1e-15) | P (link 8.0e-13) | PASS (0.0e+00) |
| poisson_ri | 20261016619 | PPPPPPP | 0.1/-1.3; re.form=NULL 0.7/0.4 | PPFPF-P | -0.7/-1.0 (vs marginal var z -223.4) | P (link 4.0e-15) | F (link 1.4e-08) | refused |
| nbinom2_fixed | 20261016620 | PPPPPPP | -2.0/-2.1 | PPFPF-P | 1.0/0.7 | P (link 2.9e-15) | P (link 1.1e-10) | PASS (2.2e-16) |
| nbinom2_ri | 20261016621 | PPPPPPP | -0.1/-0.9; re.form=NULL 1.3/0.6 | PPFPF-P | 1.6/1.2 (vs marginal var z -22.1) | P (link 5.3e-15) | F (link 1.2e-03) | refused |
| truncated_nbinom2_fixed | 20261016622 | PPPPPPP | 0.6/1.0 | FPFPF-P | 0.4/1.2 | P (link 4.9e-15) | P (link 1.2e-10) | PASS (5.6e-17) |
| truncated_nbinom2_ri | 20261016623 | PPPPPPP | 0.9/-1.5; re.form=NULL -0.1/0.1 | refused | NA | NA | NA | refused |
| tweedie_fixed | 20261016624 | PPPPP*P | 2.7/2.2 | PPFPF-P | -0.1/-1.1 | P (link 8.9e-15) | P (link 2.4e-11) | PASS (2.8e-17) |
| tweedie_ri | 20261016625 | PPPPP*P | -0.2/-0.5; re.form=NULL -1.0/-0.6 | PPFPF-P | 0.4/-0.3 (vs marginal var z -257.9) | P (link 7.1e-15) | F (link 1.0e-03) | refused |
| cumulative_logit_fixed | 20261016626 | PPPPPPP | 0.2/1.1 | FFEPE-F | -0.3/-0.4 | F | E | admitted; P11 NA (native predict errors) |
| cumulative_logit_ri | 20261016627 | PPPPPPP | 0.3/-0.6; re.form=NULL 0.3/-0.1 | FFEPE-F | 0.1/1.0 (vs marginal var z -43.6) | F | E | refused |

**Legend:**
- P = pass, F = fail, E = error, - = not applicable. The seven letters are P1..P7 in order.
- \* R P6 for Tweedie was NA in the harness (no `tweedie` package). The verifier then ran it with tweedie 3.1.0: **PASS, max |Δ| = 0**, with |F(Q) − p| ≤ 3.4e-13 off the zero atom (`repro/r_p6_tweedie.R`).
- Julia P6 is "-" everywhere: there is no quantile API.
- P9/P10 give the largest link-scale max |Δ| over dpars on `nd_main`. A P9 F next to a link value of about 1e-15 is a response-scale (inverse-link) failure.

### By test

| test | drmTMB native | DRModels.jl native | notes |
|---|---|---|---|
| P1 in-sample predict / fitted | 28/28 | 16/26 fitted cells | fails: Student/SkewNormal ν and ZOB μ (#1120); LogNormal and TruncNB2 `fitted()` is not E[y] (#1104 comment); CumulativeLogit errors (#1121) |
| P2 unseen group levels | 28/28 | 19/26 | the failures are the #1120 and #1121 cells; unseen `g` itself works everywhere (population level, as documented) |
| P3 level subset | 28/28 | 2/26 (Gaussian only) | 22 refused with a raw StatsModels message (#1000 comment); no silent wrong value |
| P4 unseen fixed-effect level | 28/28 | 26/26 | all refuse; non-Gaussian refusals come from the #1000 guard, not the #1015 message |
| P5 character vs factor | 28/28 | 2/26 | cross-type newdata refused for non-Gaussian (#1000 comment) |
| P6 quantile | 28/28 (Tweedie via verifier) | no API | in-sample R quantiles are conditional on b̂, but the docs say population (#1568) |
| P7 SEs | 28/28 via `predict_parameters(conf.int = TRUE)`, delta-method agreement ≤ 3.5e-16; `predict(se.fit = TRUE)` silently ignored (#1536) | 21/26 | SkewNormal ν and ZOB μ response SEs are wrong (#1120); CumulativeLogit errors |
| P8 simulate, 1000 draws, 3 MC SE | 28/28 default (marginal) + 14/14 `re.form = NULL` | 26/26 against the documented b = 0 moments | DRModels.jl draws at b = 0, which drmTMB has no mode for (#1092 comment); missing-response Student draws use the wrong ν (#1120); crossed LogNormal draws are wrong (#1102 comment); `simulate(newdata =)` is ignored (#1536) |
| P9 shared θ, 1e-8 | — | link ≤ 8.9e-15 in all 24 evaluable cells | response fails in 5 cells (#1120); lognormal μ response differs by design (R meanlog, Julia exp); CumulativeLogit errors (#1121) |
| P10 own fits, 1e-8 | — | all 13 evaluable fixed cells ≤ 1.2e-10; `ri`: 4 pass, poisson_ri 1.45e-8 (Julia Laplace stops at \|∇\| 3e-6), 6 GHQ-vs-Laplace cells at 7.7e-5–1.2e-3 (cumulative_logit_ri: coefficient level only, max \|Δβ\| 1.9e-3) | every evaluated P10 gap decomposes into X·Δβ (residual ≤ 7.1e-15), so it is not a predict defect |
| P11 bridge same fit | — | 13/13 admitted fixed cells, link ≤ 2.2e-16 | all 14 `ri` cells refused: Gaussian on factor labels (#1567); 5 non-Gaussian after the full fit (#1551 comment); the rest fenced by design. Bridge `fitted()` contract: #1566. No `simulate`/`predict_parameters`: #1570. Bridge P6 quantiles match native to ≤ 5.3e-9 in all 14 fixed cells |

## Issues filed

| issue | repo | severity | what | tests |
|---|---|---|---|---|
| [DRModels.jl#1120](https://github.com/itchyshin/DRModels.jl/issues/1120) | DRModels.jl | silent wrong answer | `type = :response` uses the wrong inverse link for Student ν (and bivariate Student ν: value 2 too low), SkewNormal ν (exp instead of identity) and ZeroOneBeta μ (no logistic); SEs are wrong for the latter two; missing-response fits store the wrong ν, so `simulate()` variance is 43% too wide | P1 P2 P7 P8 P9 |
| [drmTMB#1566](https://github.com/itchyshin/drmTMB/issues/1566) | drmTMB | silent wrong answer | bridge `fitted()`/`residuals()` give DRModels.jl's values: lognormal median (Δ 5.92), truncated NB2 untruncated mean (Δ 7.05), Gaussian `(1 \| g)` at b = 0 (Δ 0.98) | P1 P11 |
| [DRModels.jl#1121](https://github.com/itchyshin/DRModels.jl/issues/1121) | DRModels.jl | crash | CumulativeLogit `predict`/`predict_parameters` throw on any newdata, the training data included; the error blames factor levels | P1–P3 P5 P7 P9 P10 |
| [drmTMB#1567](https://github.com/itchyshin/drmTMB/issues/1567) | drmTMB | refusal | bridge refuses every Gaussian `(1 \| g)` model with a factor fixed effect, after a 96 s Julia fit (conditional entry skips the label contract) | P11 |
| [drmTMB#1568](https://github.com/itchyshin/drmTMB/issues/1568) | drmTMB | wrong docs | mirror of DRModels.jl#1101: in-sample quantile, exceedance, quantile residuals, `qq_plot` and `worm_plot` are conditional on b̂ in all 14 `(1 \| g)` families; the Rd says population level | P6 |
| [drmTMB#1569](https://github.com/itchyshin/drmTMB/issues/1569) | drmTMB | wrong docs | four docs say skew_normal/binomial are not admitted by the bridge, but they are; `@param engine` omits four admitted families | P11 admission |
| [drmTMB#1570](https://github.com/itchyshin/drmTMB/issues/1570) | drmTMB | gap | `drmTMB_julia` has no `simulate()` or `predict_parameters()` method, hence no prediction-SE route | P7 P8 |
| [DRModels.jl#1122](https://github.com/itchyshin/DRModels.jl/issues/1122) | DRModels.jl | twin gap | SkewNormal and TruncNB2 refuse `(1 \| g)` that drmTMB fits; the capabilities table also mislists ZOB mean random effects | all, `ri` cells |
| [DRModels.jl#1123](https://github.com/itchyshin/DRModels.jl/issues/1123) | DRModels.jl | crash (incidental) | SkewNormal with one missing response throws "matrix contains Infs or NaNs" (no observed-rows wrapper) | — |

Every issue carries:
- both commits;
- a data link at a permanent commit;
- the seed;
- a minimal fresh-process repro with its verbatim output;
- `sessionInfo()` / `versioninfo()` links.

## Comments added to existing issues

- [drmTMB#1536](https://github.com/itchyshin/drmTMB/issues/1536#issuecomment-6226367619): executed confirmation (the issue said "not run"). Also extends it to `predict.drmTMB_julia`, names the working SE route, and adjusts the severity.
- [drmTMB#1551](https://github.com/itchyshin/drmTMB/issues/1551#issuecomment-6226370695): nbinom2, beta_family and binomial also abort after the full fit. The "send Laplace" option cannot work with `sigma ~ x`. Also notes an incidental `beta()` deprecation warning from the bridge path (source not traced).
- [DRModels.jl#1000](https://github.com/itchyshin/DRModels.jl/issues/1000#issuecomment-6226375700): the training-schema cache is Gaussian-only. Non-Gaussian level-subset and cross-type newdata are refused with a raw message, and there are no silent wrong values. PR #1086 defers this.
- [DRModels.jl#1102](https://github.com/itchyshin/DRModels.jl/issues/1102#issuecomment-6226378443): **new silent wrong answer, same root.** On the crossed LogNormal route `fitted()` returns meanlog, and `simulate()` draws `exp(log(meanlog) + σz)`: mean 1.10 against 3.36 expected. Only the issue's first proposed fix cures it.
- [DRModels.jl#943](https://github.com/itchyshin/DRModels.jl/issues/943#issuecomment-6226381849): no TMB-convention Laplace for ZOB, Tweedie, CumulativeLogit or BetaBinomial `(1 | g)`. Measures the GHQ-vs-Laplace gaps and attributes them fully to coefficients.
- [DRModels.jl#1092](https://github.com/itchyshin/DRModels.jl/issues/1092#issuecomment-6226384174): `simulate()` b = 0 versus drmTMB's marginal default, a mode drmTMB lacks. Edited once to correct my own misstatement about `re.form = ~0`.
- [DRModels.jl#1104](https://github.com/itchyshin/DRModels.jl/issues/1104#issuecomment-6226392101): TruncNB2 `fitted()` is the untruncated mean, which PR #1100's rewrite does not cover, plus the LogNormal twin numbers.

## Considered and not filed

- **No quantile prediction API in DRModels.jl.** Not documented as existing, so it is a feature gap; at most a ledger row. The refuter recommended not filing.
- **Cross-engine Wald SEs agree only to about 1e-6 relative** while coefficients agree to 1e-11. drmTMB's `vcov` comes from TMB `sdreport`'s finite-difference Hessian (step 1e-3); DRModels.jl's is exact (ForwardDiff). Inverting a central difference reproduces R's SEs to ≤ 3e-10 (`julia/21_vcov_check.jl`). This is a precision note: **use about a 1e-5 relative bar for cross-engine SE parity, not 1e-8.**
- **#1550** (`%||%` on R < 4.4): reproduced, but lane t5 already documented it from this environment.
- **Performance observation (outside t6):** DRModels.jl `Tweedie()` + `(1 | g)` took 535 s against drmTMB's 11 s, from one run, 1 thread, 21-node adaptive GHQ. Worth a look by the performance lane; not filed from here.

## Coverage gaps (not recorded as PASS)

- **Julia, cells not run:** `skew_normal_ri` and `truncated_nbinom2_ri` (refused, #1122).
- **Julia, CumulativeLogit:** P1–P3, P5, P7 and P9/P10 are not evaluable (#1121). Its parity is coefficient-level only (1.1e-11).
- **P10 at a shared integrator:** possible only for gaussian, lognormal, student, binomial and poisson `ri`. The other 7 `ri` cells compare GHQ with Laplace.
- **Bridge:** no `ri` cell was admitted. The Gaussian `(1 | g)` bridge parity was measured only on a numeric-only formula (exact: coefficients 0, logLik 0). Bridge P8 is impossible (#1570).
- **Not in scope:** bivariate families, `zi`/`hu` routes, offsets and structured (phylo/spatial) effects. The log-σ soft clamp never bound in these data, so clamp behaviour in `predict()` is untested.
- **Replication:** one dataset per cell. Near-bar P8 z values were replicated with other seeds and nsim = 20 000 and did not recur: R nbinom2_fixed −2.0/−2.1, tweedie_fixed 2.7/2.2, lognormal_fixed var −2.9 (10-seed mean −0.59 ± 0.35).
- **t1 family list:** unverified (see Scope 1).

## Reproduce

```sh
Rscript sweep-oct16/t6/R/00_make_data.R            # data + cells.csv
Rscript sweep-oct16/t6/R/10_harness_r.R            # R P1-P8   -> results/r_*
julia --project=<env with DRModels at the pin, CSV, DataFrames, JSON, CategoricalArrays> sweep-oct16/t6/julia/10_harness_jl.jl   # Julia P1-P8 -> results/jl_*
julia --project=<same> sweep-oct16/t6/julia/20_parity.jl                                  # P9/P10 (needs results/jl_fits/*.jls; regenerated by 10_harness_jl.jl, not committed)
DRMODELS_JL_PATH=<DRModels.jl> Rscript sweep-oct16/t6/R/30_bridge.R                       # P11 (R < 4.4: #1550 shim inside)
Rscript sweep-oct16/t6/R/90_receipt_matrix.R       # the matrix above
```

Each filed claim has a standalone script in `repro/` and its fresh-run log in `logs/repro_*.log`. The triage record is `results/triage_wf1.json`; the verification record is `results/verify_wf2.json`.

Team note: Shannon speaking. Workflow agents acted as the R and Julia test engineers (Curie), the parity and bridge auditors (Ada, Fisher) and an adversarial refuter (Rose). No subagents are running now.
