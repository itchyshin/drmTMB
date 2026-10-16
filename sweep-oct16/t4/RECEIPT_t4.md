# RECEIPT — sweep-oct16 / t4: edge-case grid (drmTMB vs DRModels.jl)

**Lane:** t4 (edge-case grid) of the 2026-10-16 test sweep.
**Run:** 2026-10-16, cloud session only (not the shared box).
**Pins:** drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` (0.7.1); DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` (0.7.2).
**Branch / PR:** drmTMB `claude/blissful-turing-r8xyyd`, draft PR [itchyshin/drmTMB#1552](https://github.com/itchyshin/drmTMB/pull/1552). No package code was changed.

## 1. Bottom line

Of the 15 cells (50 datasets each, 750 datasets per engine), both engines pass the bar in 5: Gaussian n = 12 and 20, and Poisson n = 8, 12 and 20. In every other cell at least one engine fails some part of the bar.

**Silent wrong answers (`converged = TRUE`, no warning, but the answer is wrong or the MLE does not exist):**

| Cell | drmTMB | DRModels.jl |
|---|---|---|
| Complete binomial separation | 50/50 | 0 |
| Low-mean Poisson n = 8 (all-zero y, or positives only at an extreme x) | 13/14 | 9/14 |
| Gaussian location-scale n = 8 (local maximum, ridge stop, or unbounded likelihood) | 8/50 | 3/50 |
| Student on Gaussian data (logLik above the Gaussian supremum; boundary unflagged) | 6/50 | 0 |

**False alarms (correct answer reported as `converged = FALSE`):**

| Cell | drmTMB | DRModels.jl |
|---|---|---|
| NB2 on Poisson data (known: #1535 R, #1072 J) | 33 | 1 |
| Beta phi = 1e4 | 3 | 0 |
| Student on Gaussian data | 7 | 8 |
| (1 \| g) at the zero-variance boundary | 0 | 22 |
| Near-collinear sigma design | 50 | 0 |
| Gaussian n = 8 | 0 | 3 |

**Misleading but signalled:** DRModels.jl reports the exactly aliased sigma design as converged on all 50 datasets. It gives finite pseudo-inverse SEs for the unidentified coefficients, and its warning blames a "variance/dispersion boundary".

**Twin flag agreement (`is_converged`, R vs Julia):** 513 of 750 datasets agree; 237 disagree. The per-cell breakdown is in §4.

Issues filed and comments posted are listed in §5.

## 2. Environment

The network policy blocked CRAN, r-universe, julialang.org and the Julia package server, so the toolchains came from other sources:

- **R:**
  - R 4.3.3 (Ubuntu 24.04.5 `r-base-core`).
  - TMB 1.9.10, Matrix 1.6-5 and RcppEigen 0.3.4.0.0, from the Ubuntu archive (`r-cran-*`).
  - drmTMB installed with `R CMD INSTALL` from the pinned checkout.
- **Julia:**
  - Julia 1.12.7, conda-forge build (via micromamba).
  - DRModels.jl dependencies instantiated from GitHub (`JULIA_PKG_SERVER=""`), with the pinned checkout as the project.
  - 1 thread, 2 BLAS threads.
- **Machine:** x86_64 Linux, 4 vCPU (Xeon 2.1 GHz).
- **Differences from the shared box:** these versions differ from the box's R 4.6.1 / TMB 1.9.25 / Matrix 1.7-x. Where an issue depends on numerical noise (the Beta false-convergence rate), the TMB version is stated.
- **Provenance files:** `results/fits_drmTMB_sessionInfo.txt` and `results/fits_DRModels_versioninfo.txt`. The second records `DRModels git HEAD: f71b2923…`.

## 3. Design

### Cells (k = 1..15)

| k | cell | DGP | model (both engines) |
|---|---|---|---|
| 1-3 | gauss_n8 / n12 / n20 | x ~ N(0,1); y = 1 + 0.5x + exp(-0.4 + 0.3x)·ε | `y ~ x, sigma ~ x`, Gaussian |
| 4-6 | pois_n8 / n12 / n20 | y ~ Pois(exp(0.5 + 0.5x)) | `y ~ x`, Poisson |
| 7 | bin_complete | n = 50, y = 1{x > 0} | `y ~ x`, binomial / Binomial |
| 8 | bin_quasi | as k = 7, then 10 ties at x = 0 with mixed y | as k = 7 |
| 9 | nb2_poisdata | n = 100, y ~ Pois(exp(1 + 0.5x)) | `y ~ x, sigma ~ 1`, nbinom2 / NegBinomial2 |
| 10 | beta_phi1e4 | n = 100, y ~ Beta(μφ, (1-μ)φ), μ = plogis(0.5x), φ = 1e4 | `y ~ x, sigma ~ 1`, beta_family / Beta |
| 11 | student_gaussdata | n = 100, y = 1 + 0.5x + N(0,1) | `y ~ x, sigma ~ 1, nu ~ 1`, student / Student |
| 12 | re_sd1e-4 | G = 20, m = 5; b_g ~ N(0, 1e-4²); y = 1 + 0.5x + b_g + N(0,1) | `y ~ x + (1\|g), sigma ~ 1`, Gaussian |
| 13 | collin_sigma_exact | as k = 1-3 with n = 100; z = 2x + 1 | `y ~ x, sigma ~ x + z` |
| 14 | collin_sigma_near | as k = 13 but z = x + 1e-6·N(0,1) | `y ~ x, sigma ~ x + z` |
| 15 | pois_n8_lowmean (supplementary) | n = 8, y ~ Pois(exp(-1.5 + 0.5x)) | `y ~ x`, Poisson |

- **Cell 15** was added after cells 4-6 produced no all-zero sample. It covers the all-zero and extreme-x cases of tiny-n Poisson that the API probes had hit.
- **Collinear sigma design:** cell 13 uses an affine alias (z = 2x + 1) rather than #1470's literal duplicate column.

### Seeds and data

- Nominal seed for cell k, replicate r (1..50): `20261016400 + 100·(k−1) + (r−1)`. All seeds are ≥ 20261016400 and all are distinct.
- R's `set.seed()` rejects values above `.Machine$integer.max`, so R is seeded with `seed %% 2^31`. This is the same convention as lane t2 (PR #1549) and is injective here. RNG: Mersenne-Twister / Inversion / Rejection.
- Data are generated once in R (`t4_gen_data.R`) and written with `write.csv`. Both engines read the same CSVs.
- `data_md5.txt` holds the md5 of every one of the 750 CSVs. Regeneration was checked to be byte-identical.
- Only datasets cited in issues are committed: cells 7, 8, 10 and 15 so far, plus any added later.

### Engine-independent reference (`t4_reference.R`, base R only)

- **Multi-start optimum of the exact likelihood:** BFGS from 41 starts, then Nelder-Mead and BFGS polish. Used for the Gaussian location-scale, Beta (`dbeta`), Student (`dt`), Gaussian random intercept (closed-form marginal) and the near-collinear design (fitted in well-conditioned coordinates and mapped back).
- **`glm` for Poisson.** MLE existence follows the Santos Silva & Tenreyro (2010) condition: all-zero y, or positives only at an extreme x.
- **Exact suprema at boundaries:**
  - NB2 at the Poisson limit: Poisson `glm`. The NB2 log-density uses an O(1) form; R's `dnbinom` drifts by about 1e-5 at size ≈ 1e10.
  - Student at ν → ∞: the Gaussian ML fit.
  - Random-intercept variance at zero: the `lm` ML fit.
- **Binomial separation:** supremum 0 for complete separation; the saturated tie-block likelihood for quasi-complete separation.
- **Gaussian location-scale at tiny n (`t4_unbounded_check.R`):** an analytic test of whether the likelihood is bounded. A likelihood spike needs σ → 0 at an observation the mean fits exactly. With log σ linear in x this can only happen at an extreme x_k.
  - Put the spike at x_k, let the mean also interpolate a partner point j, and set log σ(x) = −c + s·|x − x_k|. As c → ∞, the log-likelihood grows like c × slope, where slope = 1 + (1 − d_j/D) + Σ_{i∉{k,j}} (1 − d_i/D) and D is the nearest non-interpolated distance.
  - The likelihood is unbounded iff the maximum slope over k ∈ {argmin x, argmax x} and over j is > 0.
  - A numerical ray check agrees on 149 of 150 datasets. The one disagreement is r49, whose slope is 2.3e-4, a growth too slow for the ray check to resolve.
  - Unbounded datasets at n = 8: r06, r19 and r49. None at n = 12 or 20.

### Regimes

| regime | datasets |
|---|---|
| interior MLE | 486 |
| boundary MLE | 97 (NB2 Poisson limit 32, Student ν → ∞ 36, random-effect SD → 0 29) |
| MLE does not exist | 117 (separation 100, Poisson 14, unbounded Gaussian 3) |
| aliased design | 50 |

### Classification (`t4_analyse.R`)

- **Signals.**
  - drmTMB: `is_converged()`, `convergence_status()`, fit-time warnings, and the warning rows of `check_drm()`.
  - DRModels.jl: `is_converged(fit)`, fit-time `@warn` records (captured with `Test.TestLogger`), and `check_drm(fit).ok`.
- **Tolerances.** A logLik deficit against the reference greater than 1e-4 counts as a wrong optimum. A logLik above an exact supremum by more than 1e-6 counts as a wrong likelihood.
- **Verdicts.** `SILENT_*` means `converged = TRUE` with no fit-time warning and a wrong answer, or a non-existent MLE, or an unflagged boundary. `FALSE_ALARM` means `converged = FALSE` at the correct optimum.
- **Twin agreement.** "Flag agree" compares `is_converged()` across the two engines. "Signal agree" compares (error, non-convergence or warning) across the two engines.

## 4. Results

### Pass bar per cell

S = silent wrong, FA = false alarm. Full tables, including the reference regimes and the R−J logLik differences, are in `results/summary.md`. Per-fit rows are in `results/classified.csv` and `results/cross_engine.csv`.

| cell | drmTMB | DRModels.jl | flags agree | signals agree |
|---|---|---|---|---|
| gauss_n8 | **FAIL** (S 8) | **FAIL** (S 3, FA 3) | 43/50 | 43/50 |
| gauss_n12 | pass | pass | 50/50 | 50/50 |
| gauss_n20 | pass | pass | 50/50 | 50/50 |
| pois_n8 | pass | pass | 50/50 | 50/50 |
| pois_n12 | pass | pass | 50/50 | 50/50 |
| pois_n20 | pass | pass | 50/50 | 50/50 |
| pois_n8_lowmean | **FAIL** (S 13 of 14 non-existent) | **FAIL** (S 9 of 14) | 49/50 | 46/50 |
| bin_complete | **FAIL** (S 50) | pass (warns; SE Inf) | 50/50 (both TRUE) | 0/50 |
| bin_quasi | pass (degenerate) | pass (warns) | 0/50 | 50/50 |
| nb2_poisdata | FA 33 (known #1535) | FA 1 (known #1072) | 18/50 | 49/50 |
| beta_phi1e4 | FA 3 | pass | 47/50 | 47/50 |
| student_gaussdata | **FAIL** (S 6, FA 7, logLik above supremum but flagged 23) | FA 8 | 28/50 | 44/50 |
| re_sd1e-4 | pass ("boundary" status; no fit-time warning) | FA 22 | 28/50 | 21/50 |
| collin_sigma_exact | pass (degenerate, rank-deficiency row) | converged + misleading warning, 50 | 0/50 | 50/50 |
| collin_sigma_near | FA 50 (degenerate at the true MLE) | pass (warns) | 0/50 | 50/50 |

### Notes on reading the table

- **gauss_n8 (both engines).** The 9 drmTMB deficits fall into three mechanisms:
  - Unbounded likelihood (r06, r19, r49). drmTMB reports converged; DRModels.jl flags all three.
  - A genuine second mode (r05, r09, r28). Both engines converge to the same local maximum, 0.67–2.37 nats below the global one.
  - Ridge stops (r04, r30, r31). drmTMB stops 0.57–8.2 nats short with converged = TRUE. DRModels.jl reaches the maximum on r04 and r31 but calls it not converged (also on r29).
  - n = 12 and n = 20 are clean in both engines.
- **student_gaussdata.** 27 of 50 drmTMB logLiks exceed the exact Gaussian supremum, by up to 1.02e40; four of these fits are `converged` with no warning. DRModels.jl reaches the Gaussian limit exactly. Its SE for ν at that limit is about 1e-19, not Inf (known #969).
- **re_sd1e-4.** drmTMB flags all 29 boundary fits through `convergence_status() = "boundary"`, with converged = TRUE. DRModels.jl reports converged = FALSE on 22 of the 29 because its absolute gradient tolerance (1e-8) is missed by 3e-8 to 4e-7. It gives a pseudo-inverse SE of about 1e-17 for log SD_g.
- **collin_sigma_near.** Both engines reach the true MLE, which has g1 ≈ −g2 ≈ 1e4–1e5 and honest SEs of about 7e4. drmTMB calls this `degenerate` (`weakly_identified_fixed_effects`); DRModels.jl calls it converged and warns. This is a difference in flag semantics, not a defect in either engine.
- **Determinism.** Re-running the whole pipeline from scratch reproduced every fit of cells 1–14 exactly in both engines; only the timings differed.
- **Run time.** Median per fit: drmTMB 0.03 s, DRModels.jl 0.4 ms after compilation. Totals: 28 s and 39 s (the Julia total includes 17 s of compilation).

## 5. Findings: issues filed and comments posted

Each finding was reproduced minimally from the CSVs at both pins, then checked by an adversarial verifier that tried to refute it, traced the root cause to file:line and searched for duplicates in open and closed issues and PRs of both repos. Every new issue was also checked by an independent skeptic. The repro scripts and their outputs are in `repro/<finding>/`.

| # | finding | action | link |
|---|---|---|---|
| F8a | drmTMB `poisson()`: no MLE (all-zero y; positives only at an extreme x), yet "converged", no warning, `check_drm` ok | **new issue** | [itchyshin/drmTMB#1553](https://github.com/itchyshin/drmTMB/issues/1553) |
| F8b | DRModels.jl Poisson: no existence screen; all-zero y returns the start value `log(eps())` after 0 iterations as converged | **new issue** | [itchyshin/DRModels.jl#1109](https://github.com/itchyshin/DRModels.jl/issues/1109) |
| F2 | drmTMB Beta φ = 1e4: false convergence on 3/50 grid fits and 29/500 extra fits. lgamma cancellation, amplified ~30× by CppAD tape optimisation; fixed by draft #1547 | comment | [itchyshin/drmTMB#1548 (comment)](https://github.com/itchyshin/drmTMB/issues/1548#issuecomment-6224309858) |
| F3 | drmTMB complete separation silent 50/50 at ca3ddef (`min(SE)` fallback blind spot); #1442 fixes the R side; Julia `is_converged` stays true | comment | [itchyshin/drmTMB#1270 (comment)](https://github.com/itchyshin/drmTMB/issues/1270#issuecomment-6224317984) |
| F1 | DRModels.jl aliased sigma design | _pending_ | |
| F4 | drmTMB Student logLik above the Gaussian supremum | _pending_ | |
| F5 | tiny-n Gaussian (both engines) | _pending_ | |
| F6 | DRModels.jl random-effect boundary flag and SE | _pending_ | |
| F7 | twin `is_converged` semantics | _pending_ | |

Known issues not re-filed, with the grid evidence that bears on each:

- drmTMB #1535 (NB2 Poisson limit, false alarm 33/50).
- DRModels.jl #1072 (1/50).
- drmTMB #1470 (at ca3ddef the exactly aliased sigma design is now `degenerate` in 50/50, so not converged; there is still no fit-time warning and no alias handling).
- drmTMB #1469 (tiny n; see F5).
- drmTMB #1496.
- DRModels.jl #983, #1069 and #1088 (not exercised by this grid's cells).

## 6. Limitations

- **Sample size.** 50 datasets per cell, so a rate of 0/50 has a 95% upper bound of about 6%.
- **Tolerances.** The 1e-4 nats deficit tolerance and the 1e-6 supremum tolerance are judgement calls. Every flagged case was checked by hand or by a verifier.
- **Toolchain.** R 4.3.3 / TMB 1.9.10 rather than the box toolchain. Behaviour driven by numerical noise (Beta, Student) may differ in rate on TMB 1.9.25.
- **"Signal" is narrow.** It counts only fit-time warnings and the convergence flag. drmTMB's `check_drm()` / `convergence_status()` information appears only when the user asks for it; it is reported as "diag only" in `results/classified.csv`.
- **Julia `check_drm` and boundaries.** Julia's `check_drm()` emits `@info` on every call and may `@warn`. It was captured separately and was not counted as a fit-time signal.
- **The reference is a multi-start optimiser,** not a certificate. On interior cells it was never beaten by either engine by more than 1e-6.

## 7. Files

- **Code:** `t4_gen_data.R`, `t4_reference.R`, `t4_unbounded_check.R`, `t4_fit_drmTMB.R`, `t4_fit_DRModels.jl`, `t4_analyse.R`, `run_all.sh`.
  - Run from the drmTMB checkout root with `DRMODELS=<path> JULIA=<julia> ./sweep-oct16/t4/run_all.sh`.
- **Data:** `data/index.csv`, `data_md5.txt`, and the cited `data/*.csv`.
- **Results:** `results/` holds the reference, the per-engine fits, the classification, the cross-engine table, `summary.md`, `sessionInfo`/`versioninfo`, and `gauss_unbounded.csv`.
- **Repros:** `repro/<finding>/` holds the minimal repro scripts and their outputs.
