# RECEIPT t2: simulation recovery, Gaussian location-scale (sweep 2026-10-16)

**Reader:** Engine A (sweep coordinator), and the maintainers of drmTMB and DRModels.jl. This receipt records what was run, the pass-bar verdict, and the findings filed.

| item | value |
|---|---|
| lane | t2, simulation recovery of the Gaussian location-scale model |
| drmTMB | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` (0.7.1), installed from a clean worktree; `drm_provenance()` reports `git_dirty = FALSE` |
| DRModels.jl | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` (0.7.2), `Pkg.develop`ed from a clean checkout |
| where | Claude Code cloud session container (Ubuntu 24.04, 4 vCPU), not the shared box |
| date | 2026-10-16 |
| primary run | 9 cells × 500 reps × 2 engines = 9,000 fits |
| confirmatory run | 6 gate cells × 2,000 fresh reps × 2 engines = 24,000 fits. This goes beyond the lane spec; see "Verdict" |
| PR | itchyshin/drmTMB#1549 (branch `claude/intelligent-euler-h4b2is`) |

## Verdict

**By the letter of the pass bar (primary 500 reps): FAIL.** The failures are in Wald coverage in 5 of the 28 gate rows (n ≥ 200) and in the converged rate of the two n = 50 random-effect cells. Relative bias passes everywhere it is gated.

**What the failures mean.** No gate-cell failure is an engine defect. On every shared dataset the two engines fit the same likelihood to the same optimum:
- |ΔlogLik| ≤ 2e-11 and |Δ estimate| ≤ 4e-10 on all 15,000 shared datasets at n ≥ 200 (3,000 primary + 12,000 confirmatory);
- standard errors equal to within 3e-6 relative.

Every n ≥ 200 verdict is therefore identical for drmTMB and DRModels.jl, and a gate failure describes ML Wald inference on this design, not either package. The confirmatory 2,000 reps sort the five primary coverage failures, and expose one primary PASS that is weaker than it looked:

| primary failure (both engines) | reps 1-500 | pooled 2,500 (MCSE) | reading |
|---|---:|---:|---|
| `sigma_intercept`, n = 1000, no RE | 97.2% | 95.60% (0.41) | Monte Carlo noise; does not replicate |
| `sigma_intercept`, n = 1000, G = 20 | 97.6% | 95.24% (0.43) | Monte Carlo noise. This cell shares x, z and ε with the row above by design, so it is the same draw |
| `mu_intercept`, n = 1000, G = 20 | 92.6% | 92.56% (0.52) | **Replicates.** z-Wald under-coverage with 20 groups; t(G − 1) raises it to 94.1%, still about 2 SE short of 95% |
| `sd_g`, n = 1000, G = 20 | 92.6% | 92.40% (0.53) | **Replicates.** Same cause; t(G − 1) plus the log(G/(G − 1)) shift gives 95.2%, and a χ²₁₉ limit predicts the observed 92.4% almost exactly (92.41%) |
| `mu_intercept`, n = 200, no RE | 92.0% | 92.96% (0.51) | **Real, small.** Still FAIL pooled (by 0.04 pp) and about 4 MCSE below nominal 95%; at n = 1000 the same parameter covers 94.88%. Mild finite-sample under-coverage of the ML Wald interval with an estimated variance function (pooled SE/SD = 0.96) |
| `mu_intercept`, n = 200, G = 20 (primary **PASS**) | 94.0% | 93.12% (0.51) | **Weaker than the primary PASS suggests.** Reps 501-2500 alone give 92.90% (a FAIL). Pooled it passes by 0.12 pp. Same G = 20 mechanism as the n = 1000 row |

**The pooled 2,500-rep verdicts are the substantive ones for every cell.** On them, coverage fails in 3 gate rows: n = 200 no-RE mean intercept 92.96%, n = 1000 G = 20 mean intercept 92.56%, and n = 1000 G = 20 sd(g) 92.40%. A fourth row, the n = 200 G = 20 mean intercept at 93.12%, passes by 0.12 pp.

The convergence failures are all at n = 50:
- **n = 50, G = 20, DRModels.jl 493/500.** All 7 misses are sd(g) = 0 boundary MLEs at the same optimum as drmTMB. This is a DRModels.jl classification defect (finding A2, [DRModels.jl#1050](https://github.com/itchyshin/DRModels.jl/issues/1050#issuecomment-6225239469)): of its 14 near-zero sd(g) fits it calls 7 converged and 7 not, with no consistent rule. There is also a policy difference: drmTMB counts `boundary` as converged. Under a consistent "boundary = not converged" rule DRModels.jl would score 486/500 (97.2%); under drmTMB's rule, 500/500.
- **n = 50, G = 50, one row per group.** drmTMB refuses all 500 datasets by design ("only singleton groups"). DRModels.jl fits them: 306 converged, 190 not converged, and 4 crashes (finding B, [DRModels.jl#1114](https://github.com/itchyshin/DRModels.jl/issues/1114)).

The model in this cell identifies sd(g) and σ(z) only through the functional form of `sigma ~ z`, so the cell tests refusal and failure handling, not recovery.

**Bias.** All 28 gate rows pass. The closest is sd(g) at n = 200, G = 20: −4.98% (MCSE 0.80) on 500 reps. On 2,500 reps it is −4.35% (0.36), and −4.18% (0.32) at n = 1000. That is the expected downward ML bias of a variance component estimated from 20 groups: it does not shrink with n at fixed G, and it is −2.1% / −1.7% at G = 50. The σ intercept also shows a small but real ML bias: +2.0% pooled at n = 200 (MCSE 0.20), meaning σ is underestimated by about 1% (0.01 on the log scale). It is inside the bar.

## Findings filed

The DRModels.jl defects (A1, A2, B, C) are confined to the n = 50 cells. The drmTMB items are a calibration gap at n ≥ 200 (D) and a unit-dependent boundary label (E). E was added as evidence to the open twin-contract issue rather than filed separately.

| # | repo | what | where filed |
|---|---|---|---|
| A1 | DRModels.jl | At the sd(g) = 0 boundary, `stderror` for log sd(g) is either `Inf` or a tiny positive pinv residue (about 1e-15 or less); rounding decides which. The residue gives a zero-width Wald interval: 7 of 14 boundary fits at n = 50, G = 20 (4 of them `is_converged = true`) and 184 of 219 at G = 50 (26 converged). The same residue then becomes the profiler's initial step, and `profile_result` reports an unbounded upper limit with `failed = 0` (reps 143 and 253; drmTMB's profile gives 0.52 and 0.43). drmTMB's Wald interval is `(0, Inf)` with `wald_at_boundary` | [DRModels.jl#969 (comment)](https://github.com/itchyshin/DRModels.jl/issues/969#issuecomment-6225228486) |
| A2 | DRModels.jl | `is_converged` at the sd(g) = 0 boundary follows the absolute 1e-8 gradient test (`gaussian_ranef.jl:659`). Six boundary MLEs pass and seven fail, at the same optimum as drmTMB (ΔlogLik ≤ 1.9e-9). On a near-tie, the restart tie-break (`:441-447`) also discards a gradient-converged candidate in 5 of the 7 | [DRModels.jl#1050 (comment)](https://github.com/itchyshin/DRModels.jl/issues/1050#issuecomment-6225239469) |
| B | DRModels.jl | A bare `ArgumentError: matrix contains Infs or NaNs` on 4 of 500 all-singleton datasets. `gaussian_ranef.jl:612` and six other sites were not moved to `_vcov_from_hessian_checked` by the #968 fix | [DRModels.jl#1114 (new)](https://github.com/itchyshin/DRModels.jl/issues/1114) |
| C | DRModels.jl | On all-singleton groups, 14 of the 306 fits reported `is_converged = true` have a collapsed residual scale (fitted σ down to 1e-44). The likelihood is bounded here. Rep 72 sits on a supremum that is never attained (its SEs should be infinite; reported 0.11 and 0.26). Rep 77 is a genuine but degenerate interior MLE whose SEs are understated about 10^7-fold (4.8e-6 against about 112 from the profile curvature) | [DRModels.jl#1059 (comment)](https://github.com/itchyshin/DRModels.jl/issues/1059#issuecomment-6225170717) |
| D | drmTMB (both engines identical) | z-Wald under-coverage of an ordinary `(1 \| g)` SD and the mean intercept at G = 20. `small_sample_df` / `bias_correct` do not reach ordinary `(1 \| g)` SDs; a post-hoc t(G − 1) restores nominal coverage | [drmTMB#1558 (new)](https://github.com/itchyshin/drmTMB/issues/1558) |
| E | drmTMB | The sd(g) boundary label uses an absolute `sd < 1e-4` rule, and the optimiser's stopping point on the flat ridge depends on scale. The same boundary MLE is therefore `boundary`/TRUE, `converged` (rep 445, sd 1.5e-4, log-SE 3e4) or `degenerate`/FALSE depending on the units of y | [drmTMB#1554 (comment)](https://github.com/itchyshin/drmTMB/issues/1554#issuecomment-6225328561) |

**How the findings were verified.** Before anything was posted, each finding went to an independent adversarial verifier. The verifier re-derived every number from the raw fits and the source code and tried to refute the claim. F2 (A2) was checked twice. All five survived as "partially confirmed": the core defect was real, and some numbers or wording needed correcting. Every correction was applied before posting. The main ones:
- **A1:** the residue is positive in exact arithmetic, so removing rounding noise cannot fix it. The profile-interval failure was added after I reproduced it myself.
- **A2:** the restart tie-break was identified as a second mechanism.
- **B:** #1054 also patched three Student-t sites, and about 70 unchecked calls remain.
- **C:** the ridge (rep 72) and degenerate-maximum (rep 77) cases were separated. I re-derived rep 77's SE independently from an exact-likelihood profile in R.
- **D:** the MCSEs and the χ²-limit theory were added; I re-computed the theory values myself.

A separate completeness critic then recomputed every summary number from the raw per-rep CSVs. All of them matched exactly, with a maximum |difference| of 4.4e-15. The critic also challenged the classifications. Its corrections are all incorporated here:
- the fifth primary coverage FAIL;
- pooled verdicts for every cell, rather than only for primary FAILs;
- one-sided miss rates;
- finding E;
- the design disclosures listed under "Deviations".

Each posted body was then read back through the GitHub API and diffed against the local file; the data, code and numbers were byte-identical. The one difference: GitHub strips the trailing attribution footer from issue bodies, but not from comments.

## Design

**Data-generating model.** For each dataset, x_i and z_i are independent N(0, 1), drawn afresh for every rep, and

  y_i = 1 + 0.5 x_i + u_{g[i]} + exp(-0.5 + 0.4 z_i) ε_i,  ε_i ~ N(0, 1),

with u_g ~ N(0, 0.5²) in the random-effect cells and u ≡ 0 in the `none` cells. Group labels are balanced and deterministic, `g = rep_len(1:G, n)`. This gives:
- G = 20: 2–3 rows per group at n = 50, 10 at n = 200, and 50 at n = 1000.
- G = 50: 1, 4 and 20 rows per group at the same three n.

**Fitted models** (ML, each package's defaults):

| engine | no grouping term | with `(1 \| g)` |
|---|---|---|
| drmTMB | `drmTMB(bf(y ~ x, sigma ~ z), data = d)` | `drmTMB(bf(y ~ x + (1 \| g), sigma ~ z), data = d)` |
| DRModels.jl | `drm(bf(@formula(y ~ x), @formula(sigma ~ z)), Gaussian(); data = d)` | `drm(bf(@formula(y ~ x + (1 \| g)), @formula(sigma ~ z)), Gaussian(); data = d)` |

The `(1 | g)` marginal is exactly Gaussian in both engines. drmTMB's Laplace approximation is exact for this model, and DRModels.jl evaluates the closed form through Woodbury and the matrix-determinant lemma. The two engines therefore target the same likelihood.

**Estimands and scales.**
- Relative bias is (mean of the estimates − truth) / truth over converged fits.
  - The mu coefficients and the log-sigma coefficients are assessed on their own scales.
  - sd(g) is assessed on the SD scale.
  - The truth for `sigma_intercept` is −0.5, so a positive relative bias means the estimate is more negative than the truth (σ is underestimated).
- Wald coverage is the share of converged fits whose package-reported 95% Wald interval contains the truth.
  - drmTMB uses `confint(fit, method = "wald")`.
  - DRModels.jl uses `confint(fit; method = :wald)`.
  - Both form estimate ± 1.96·SE on the link scale (log for sd(g)) and back-transform.
  - For an ordinary `(1 | g)` term, drmTMB's default `small_sample_df`/`bias_correct` adjustments do not apply, and every interval here has `conf.status = "wald"` or `"wald_at_boundary"`.
- "Converged" is each package's own trusted accessor, `is_converged(fit)`.
  - drmTMB counts `convergence_status = "boundary"` as converged.
  - DRModels.jl requires the optimiser flag and a non-degenerate residual scale.
- Monte Carlo SEs:
  - relative bias: SD(est) / √m / |truth|;
  - coverage: √(p(1 − p)/m), about 1.0 pp at 500 reps.

**Seeds.** The nominal seed for rep r is 20261016100 + r.
- R's `set.seed()` accepts only 32-bit integers. `set.seed(20261016101)` fails with "supplied seed is not a valid integer".
- The generator therefore seeds R with `(20261016100 + r) %% 2^31`, using Mersenne-Twister, Inversion and Rejection. That is 933663269–933663768 for reps 1–500, which is injective over every rep used here.
- `sweep-oct16/t2/data/seeds.csv` (regenerated by the script) lists both values per rep.

**Common random numbers.** Within a rep, the draw order is x, z, ε, then u. The `none`, `G20` and `G50` cells at the same n therefore share x, z and ε exactly and differ only by u, and the first 20 entries of u are the same in the G = 20 and G = 50 cells. Results for the σ coefficients are thus strongly correlated across the three RE settings at a given n: three cells failing together is one Monte Carlo event, not three. Reps are independent within a cell.

**One dataset, two engines.** Every dataset was generated once in R and written with 17 significant digits; a read-back check confirms the doubles are identical. Both engines fit the same files, which makes the paired cross-engine comparison exact.

## Results

All tables below are generated by `t2_receipt_tables.R` from `summary/` and `summary_confirm/`; no number is transcribed by hand. Per-rep, per-parameter fits for both engines are in `summary/t2_fits_long.csv.gz` (reps 1-500) and `summary_confirm/t2_fits_long.csv.gz` (reps 501-2500).

### Gate cells (n ≥ 200): bias and Wald coverage

The two engines are identical in these cells: the largest difference in relative bias is 2.4e-11, coverage is identical, and the converged counts are equal. One row per cell and parameter therefore stands for both. Verdicts on reps 1-500 are the lane's formal verdict; the pooled 2,500-rep columns are the confirmatory evidence.

| cell | parameter | rel. bias, reps 1-500 (MCSE) | bias verdict | coverage, reps 1-500 (MCSE) | coverage verdict | SE/SD | pooled 2,500: rel. bias | pooled 2,500: coverage (MCSE) | pooled verdict |
|---|---|---:|:---:|---:|:---:|---:|---:|---:|:---:|
| n0200_none | mu_intercept | +0.02% (0.18) | PASS | 92.0% (1.2) | **FAIL** | 0.921 | +0.11% | 92.96% (0.51) | **FAIL** (coverage) |
| n0200_none | mu_x | -0.26% (0.34) | PASS | 94.0% (1.1) | PASS | 0.956 | -0.20% | 94.40% (0.46) | PASS |
| n0200_none | sigma_intercept | +1.43% (0.46) | PASS | 94.2% (1.0) | PASS | 0.968 | +2.05% | 94.84% (0.44) | PASS |
| n0200_none | sigma_z | +1.37% (0.57) | PASS | 94.8% (1.0) | PASS | 1.007 | +1.28% | 95.28% (0.42) | PASS |
| n1000_none | mu_intercept | +0.08% (0.07) | PASS | 95.6% (0.9) | PASS | 1.004 | -0.04% | 94.88% (0.44) | PASS |
| n1000_none | mu_x | +0.06% (0.14) | PASS | 94.6% (1.0) | PASS | 1.044 | -0.05% | 94.84% (0.44) | PASS |
| n1000_none | sigma_intercept | +0.37% (0.19) | PASS | 97.2% (0.7) | **FAIL** | 1.047 | +0.52% | 95.60% (0.41) | PASS |
| n1000_none | sigma_z | +0.24% (0.25) | PASS | 95.0% (1.0) | PASS | 1.002 | +0.16% | 95.60% (0.41) | PASS |
| n0200_G20 | mu_intercept | +0.62% (0.50) | PASS | 94.0% (1.1) | PASS | 1.002 | +0.09% | 93.12% (0.51) | PASS |
| n0200_G20 | mu_x | -0.42% (0.36) | PASS | 94.6% (1.0) | PASS | 0.984 | -0.26% | 94.60% (0.45) | PASS |
| n0200_G20 | sigma_intercept | +1.06% (0.50) | PASS | 93.2% (1.1) | PASS | 0.948 | +1.78% | 94.28% (0.46) | PASS |
| n0200_G20 | sigma_z | +1.11% (0.64) | PASS | 94.8% (1.0) | PASS | 1.010 | +0.86% | 94.28% (0.46) | PASS |
| n0200_G20 | sd_g | -4.98% (0.80) | PASS | 93.2% (1.1) | PASS | 0.873 | -4.35% | 93.56% (0.49) | PASS |
| n1000_G20 | mu_intercept | +0.24% (0.51) | PASS | 92.6% (1.2) | **FAIL** | 0.960 | -0.37% | 92.56% (0.52) | **FAIL** (coverage) |
| n1000_G20 | mu_x | +0.03% (0.14) | PASS | 95.0% (1.0) | PASS | 1.044 | -0.06% | 94.84% (0.44) | PASS |
| n1000_G20 | sigma_intercept | +0.27% (0.19) | PASS | 97.6% (0.7) | **FAIL** | 1.038 | +0.45% | 95.24% (0.43) | PASS |
| n1000_G20 | sigma_z | +0.04% (0.26) | PASS | 95.0% (1.0) | PASS | 1.003 | +0.08% | 95.44% (0.42) | PASS |
| n1000_G20 | sd_g | -3.40% (0.73) | PASS | 92.6% (1.2) | **FAIL** | 0.940 | -4.18% | 92.40% (0.53) | **FAIL** (coverage) |
| n0200_G50 | mu_intercept | +0.07% (0.36) | PASS | 94.0% (1.1) | PASS | 0.984 | +0.04% | 94.56% (0.45) | PASS |
| n0200_G50 | mu_x | -0.40% (0.40) | PASS | 94.0% (1.1) | PASS | 0.966 | -0.27% | 94.16% (0.47) | PASS |
| n0200_G50 | sigma_intercept | +1.95% (0.55) | PASS | 94.2% (1.0) | PASS | 0.954 | +2.08% | 95.00% (0.44) | PASS |
| n0200_G50 | sigma_z | +1.32% (0.74) | PASS | 94.2% (1.0) | PASS | 0.991 | +0.78% | 94.92% (0.44) | PASS |
| n0200_G50 | sd_g | -2.63% (0.60) | PASS | 95.8% (0.9) | PASS | 0.967 | -2.09% | 95.44% (0.42) | PASS |
| n1000_G50 | mu_intercept | +0.29% (0.32) | PASS | 94.6% (1.0) | PASS | 0.989 | -0.22% | 94.40% (0.46) | PASS |
| n1000_G50 | mu_x | +0.05% (0.15) | PASS | 94.4% (1.0) | PASS | 1.020 | -0.03% | 94.40% (0.46) | PASS |
| n1000_G50 | sigma_intercept | +0.26% (0.20) | PASS | 96.6% (0.8) | PASS | 1.039 | +0.42% | 95.60% (0.41) | PASS |
| n1000_G50 | sigma_z | +0.27% (0.27) | PASS | 95.4% (0.9) | PASS | 1.003 | +0.11% | 95.56% (0.41) | PASS |
| n1000_G50 | sd_g | -1.70% (0.48) | PASS | 93.8% (1.1) | PASS | 0.949 | -1.67% | 93.84% (0.48) | PASS |

### Convergence (reps 1-500)

| cell | drmTMB converged | drmTMB status counts | DRModels.jl converged | DRModels.jl status counts | median fit time, s (drmTMB / DRModels.jl) |
|---|---:|---|---:|---|---|
| n0050_none | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.036 / 0.0002 |
| n0200_none | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.039 / 0.0004 |
| n1000_none | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.056 / 0.0019 |
| n0050_G20 | 500 / 500 (100.0%) | boundary:13 converged:487 | 493 / 500 (98.6%) **FAIL** | converged:493 not_converged:7 | 0.095 / 0.0004 |
| n0200_G20 | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.150 / 0.0010 |
| n1000_G20 | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.454 / 0.0044 |
| n0050_G50 | 0 / 500 (0.0%) **FAIL** | error:500 | 306 / 500 (61.2%) **FAIL** | converged:306 error:4 not_converged:190 | 0.020 / 0.0011 |
| n0200_G50 | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.142 / 0.0011 |
| n1000_G50 | 500 / 500 (100.0%) | converged:500 | 500 / 500 (100.0%) | converged:500 | 0.483 / 0.0046 |

All six gate cells also converge 2,000/2,000 in both engines on the confirmatory reps. Fit times are incidental: three R processes and one Julia process shared four vCPUs, so they are not a benchmark.

### n = 50 cells (reported, not gated)

At n = 50 the σ coefficients carry the classical small-sample ML bias. A +7.2% relative bias on the log-σ intercept (truth −0.5) is −0.036 on the log scale, so σ is underestimated by about 3.5%. Wald coverage for that intercept is 90.4%. The two engines' n = 50 rows are not directly comparable. In the G = 20 cell they average over different rep sets (500 for drmTMB, 493 for DRModels.jl); the sets differ only by the 7 boundary fits of finding A2. The near-nominal sd(g) coverage there (98–99%) is not evidence of calibration: it counts the boundary fits whose Wald interval is (0, Inf). **The G = 50 rows for DRModels.jl are not meaningful recovery results.** Its 306 "converged" fits include collapsed-scale and boundary fits (findings A1 and C), which produce the +349% and +170% σ biases and the 73.2% sd(g) coverage. drmTMB has no fits in this cell.

| cell | parameter | engine | converged fits | rel. bias (MCSE) | median rel. bias | coverage (MCSE) |
|---|---|---|---:|---:|---:|---:|
| n0050_none | mu_intercept | DRModels | 500 | -0.09% (0.35) | +0.14% | 92.2% (1.2) |
| n0050_none | mu_intercept | drmTMB | 500 | -0.09% (0.35) | +0.14% | 92.2% (1.2) |
| n0050_none | mu_x | DRModels | 500 | -0.66% (0.68) | -0.93% | 94.2% (1.0) |
| n0050_none | mu_x | drmTMB | 500 | -0.66% (0.68) | -0.93% | 94.2% (1.0) |
| n0050_none | sigma_intercept | DRModels | 500 | +7.16% (0.96) | +6.01% | 90.4% (1.3) |
| n0050_none | sigma_intercept | drmTMB | 500 | +7.16% (0.96) | +6.01% | 90.4% (1.3) |
| n0050_none | sigma_z | DRModels | 500 | +4.31% (1.32) | +4.30% | 93.8% (1.1) |
| n0050_none | sigma_z | drmTMB | 500 | +4.31% (1.32) | +4.30% | 93.8% (1.1) |
| n0050_G20 | mu_intercept | DRModels | 493 | -0.75% (0.64) | -0.69% | 90.7% (1.3) |
| n0050_G20 | mu_intercept | drmTMB | 500 | -0.78% (0.64) | -0.68% | 90.4% (1.3) |
| n0050_G20 | mu_x | DRModels | 493 | -1.02% (0.85) | -1.32% | 94.3% (1.0) |
| n0050_G20 | mu_x | drmTMB | 500 | -0.93% (0.85) | -1.43% | 94.2% (1.0) |
| n0050_G20 | sigma_intercept | DRModels | 493 | +9.24% (1.34) | +7.33% | 92.7% (1.2) |
| n0050_G20 | sigma_intercept | drmTMB | 500 | +8.88% (1.33) | +6.54% | 92.4% (1.2) |
| n0050_G20 | sigma_z | DRModels | 493 | +2.34% (1.86) | +1.70% | 94.1% (1.1) |
| n0050_G20 | sigma_z | drmTMB | 500 | +2.28% (1.84) | +1.90% | 94.0% (1.1) |
| n0050_G20 | sd_g | DRModels | 493 | -7.46% (1.26) | -4.73% | 98.2% (0.6) |
| n0050_G20 | sd_g | drmTMB | 500 | -8.75% (1.33) | -5.18% | 99.0% (0.4) |
| n0050_G50 | mu_intercept | DRModels | 306 | -0.85% (0.62) | -0.78% | 93.8% (1.4) |
| n0050_G50 | mu_x | DRModels | 306 | -1.40% (1.24) | +0.91% | 94.1% (1.3) |
| n0050_G50 | sigma_intercept | DRModels | 306 | +348.68% (84.41) | +58.03% | 92.8% (1.5) |
| n0050_G50 | sigma_z | DRModels | 306 | +170.39% (45.13) | +48.68% | 96.1% (1.1) |
| n0050_G50 | sd_g | DRModels | 306 | -3.77% (2.66) | +7.21% | 73.2% (2.5) |

### Cross-engine agreement on identical datasets

Reps where either engine puts sd(g) below 1e-4 are excluded from the estimate comparison: the log-sd direction is flat there, so the engines stop at different points along it. Their logLik still agrees to 1.9e-9.

| reps | cell | both converged | excluded (sd(g) < 1e-4) | max abs dlogLik | max abs d(link estimate) | SE ratio range |
|---|---|---:|---:|---:|---:|---|
| 1-500 | n0050_none | 500 | 0 | 1.3e-13 | 1.6e-10 | 0.999999 - 1.000002 |
| 1-500 | n0200_none | 500 | 0 | 9.7e-13 | 3.8e-11 | 1.000000 - 1.000002 |
| 1-500 | n1000_none | 500 | 0 | 1.5e-11 | 8.0e-12 | 1.000000 - 1.000002 |
| 1-500 | n0050_G20 | 493 | 7 | 1.0e-09 | 3.8e-09 | 0.999999 - 1.000004 |
| 1-500 | n0200_G20 | 500 | 0 | 1.2e-12 | 3.5e-10 | 1.000000 - 1.000002 |
| 1-500 | n1000_G20 | 500 | 0 | 1.8e-11 | 2.4e-10 | 1.000000 - 1.000001 |
| 1-500 | n0200_G50 | 500 | 0 | 1.5e-12 | 1.7e-10 | 1.000000 - 1.000002 |
| 1-500 | n1000_G50 | 500 | 0 | 1.8e-11 | 1.1e-10 | 1.000000 - 1.000001 |
| 501-2500 | n0200_none | 2000 | 0 | 1.0e-12 | 4.3e-11 | 1.000000 - 1.000003 |
| 501-2500 | n1000_none | 2000 | 0 | 1.8e-11 | 9.3e-12 | 1.000000 - 1.000002 |
| 501-2500 | n0200_G20 | 2000 | 0 | 1.3e-12 | 3.6e-10 | 1.000000 - 1.000002 |
| 501-2500 | n1000_G20 | 2000 | 0 | 1.8e-11 | 2.6e-10 | 1.000000 - 1.000002 |
| 501-2500 | n0200_G50 | 2000 | 0 | 1.7e-12 | 3.4e-10 | 1.000000 - 1.000003 |
| 501-2500 | n1000_G50 | 2000 | 0 | 1.9e-11 | 1.4e-10 | 1.000000 - 1.000001 |

### Post-hoc check of a small-sample Wald recipe (evidence for finding D)

Coverage is recomputed from each engine's stored link-scale estimate and SE, pooled over 2,500 reps; the numbers shown are drmTMB's. DRModels.jl's are identical (`summary/t2_posthoc_t_DRModels.md`). The MCSE at 95% is 0.44 pp.

| cell | target | reps | z interval (reported) | t(G-1) | t(G-1) + log(G/(G-1)) centre shift |
|---|---|---:|---:|---:|---:|
| n0200_G20 | mu_intercept | 2500 | 93.12% | 94.92% | - |
| n1000_G20 | mu_intercept | 2500 | 92.56% | 94.12% | - |
| n0200_G50 | mu_intercept | 2500 | 94.56% | 95.24% | - |
| n1000_G50 | mu_intercept | 2500 | 94.40% | 95.08% | - |
| n0200_G20 | sd_g | 2500 | 93.56% | 95.12% | 95.92% |
| n1000_G20 | sd_g | 2500 | 92.40% | 94.16% | 95.24% |
| n0200_G50 | sd_g | 2500 | 95.44% | 95.96% | 95.68% |
| n1000_G50 | sd_g | 2500 | 93.84% | 94.32% | 95.04% |

## How to read the coverage verdicts

At 500 reps the Monte Carlo SE of a coverage proportion near 95% is 0.97 pp, so the [93%, 97%] band is only ±2.06 MCSE wide. By exact binomial calculation:
- an exactly calibrated interval fails the band with probability 3.0%;
- across 28 gated rows that is 0.85 expected chance failures, and P(at least one) = 58%;
- the bar also has little power. An interval with true coverage of 92.5% passes it with probability 37.5%, and one at 93% with probability 54%.

A single 500-rep PASS is therefore weak evidence of calibration. The σ rows are also correlated across the three RE settings at each n by the common-random-numbers design. The two σ-intercept failures at n = 1000 are one such correlated event, and the confirmatory reps remove them. The G = 20 failures are different: they replicate with 2,000 fresh reps and have a mechanism. A z quantile ignores that a between-group quantity is estimated from 20 groups, and the ML SE of log sd(g) is 6–13% smaller than its sampling SD (SE/SD = 0.87–0.94).

**The two-sided bar hides one-sided misses.** For sd(g) the truth lies above the interval far more often than below:
- 7.12% against 0.48% at n = 1000, G = 20, and 5.76% against 0.68% at n = 200, G = 20;
- still lopsided at G = 50 (4.88% against 1.28% at n = 1000).

The σ intercept misses mostly above too, at every n ≥ 200 (about 2.7–4.2% above against 1.2–1.7% below). Both patterns are ML's downward bias in scale and SD estimates. One-sided bounds for sd(g) are therefore less well calibrated than the two-sided coverage suggests. The full table is `summary/t2_onesided_drmTMB.md`; DRModels.jl's is identical.

## Deviations from the lane spec, and limitations

1. **Seeds.** The nominal seed 20261016100 + rep cannot be passed to R's `set.seed()`. R is seeded with `(20261016100 + rep) %% 2^31`, which is 933663268 + rep and injective over all 2,500 reps used. `seeds.csv`, written by the generator, lists both values. The nominal seed alone therefore does not define the data: regenerating "seed 20261016101" in another language gives different numbers. The R generator, or the committed SHA-256 sums, define them.
2. **Choices the spec left open.**
   - Covariates are x, z ~ N(0, 1), independent and redrawn every rep, so coverage is averaged over random designs, not conditional on one design.
   - The groups are balanced and interleaved, `rep_len(1:G, n)`; unbalanced groups are not tested.
   - Group size m = n/G varies with n at fixed G, so G effects and m effects are confounded.
   - There is a single true-parameter point: sd(g) = 0.5, ICC about 0.4, moderate heteroscedasticity. Nothing here speaks to small sd(g) or values near the boundary.
   - The random effect is a mean intercept only.
3. **Common random numbers.**
   - Within a rep, the `none`, `G20` and `G50` cells at the same n share x, z and ε, and G20's group effects are the first 20 of G50's. Estimates of the shared parameters (`mu_x`, `sigma_intercept`, `sigma_z`) correlate 0.76–0.99 across those cells (0.89–0.99 between `none` and `G20`), so agreement across RE settings is not independent evidence.
   - Across different n the RNG stream is reused in shifted order (for example, n = 200's x is the first 200 of n = 1000's x). The estimates correlate only about 0.02–0.05 there.
4. **The pass bar.**
   - It is two-sided and has low power (see "How to read the coverage verdicts").
   - Relative bias is measured on the SD scale for sd(g) but on the link scale for the σ coefficients, where it is relative to an arbitrary intercept of −0.5.
   - The formal verdict uses reps 1-500 as specified. The pooled 2,500-rep verdicts, reported for every cell, are the substantive ones.
5. **Convergence definitions differ by engine.** drmTMB's `is_converged()` counts `boundary` as converged; DRModels.jl has no boundary status, and its verdict at the boundary is inconsistent (finding A2). The bar's ≥ 99% rule is applied literally, including at n = 50, where the G = 50 cell is weakly identified and drmTMB refuses it by design.
6. **Toolchain.** The session's network policy blocks CRAN and julialang.org.
   - R 4.3.3 packages came from Ubuntu 24.04 apt: TMB 1.9.10, Matrix 1.6-5 and RcppEigen 0.3.4.0.0, older than current CRAN.
   - Julia 1.12.7 is the conda-forge build (unofficial). Packages were resolved from the General registry on GitHub; Optim 1.13.3, ForwardDiff 1.4.6 and LineSearches 7.5.1 are pinned in `env/Manifest_julia.toml`.
   - DRModels.jl was `Pkg.develop`ed by path, so the manifest records a path. The SHA (`f71b292`, clean) is recorded in `env/versioninfo_julia.txt`.
   - drmTMB's link-scale SEs were read through internal helpers (`drm_profile_targets`, `drm_sdreport_cov_fixed`). The intervals came from the public `confint()`.
   - Everything ran on one platform (Linux x86-64). The engines agree to 1e-10 on these builds, but no claim is made about other BLAS/LAPACK builds or OSes.
7. **Timings are incidental.** Several fitters shared four loaded vCPUs, each Julia process charges JIT compilation to its first rep, and the timers cover the fit call only, not `confint()`.
8. **Wald only.** Profile and bootstrap intervals were not swept; the lane asks for Wald. Profile intervals appear only in the finding A1 repro.

## Reproduce

From a checkout of this branch, with drmTMB installed at the pinned SHA and a Julia environment that `Pkg.develop`s DRModels.jl at its pinned SHA:

```sh
cd sweep-oct16/t2
Rscript t2_gen_data.R data                                   # reps 1-500, all 9 cells; writes data/SHA256SUMS
Rscript t2_gen_data.R data_confirm 501 2500 n0200_none,n1000_none,n0200_G20,n1000_G20,n0200_G50,n1000_G50
for c in $(tail -n +2 data/cells.csv | cut -d, -f1 | tr -d '"'); do
  Rscript t2_fit_drmTMB.R data results "$c" 1 500
done
julia --project=<env> t2_fit_DRModels.jl data results n0050_none,n0200_none,n1000_none,n0050_G20,n0200_G20,n1000_G20,n0050_G50,n0200_G50,n1000_G50 1 500
# confirmatory: the same two fitters on data_confirm -> results_confirm with reps 501 2500
Rscript t2_analyse.R results summary
Rscript t2_analyse.R results_confirm summary_confirm
Rscript t2_compare.R summary summary_confirm summary
Rscript t2_posthoc_t.R summary drmTMB results results_confirm
Rscript t2_posthoc_t.R summary DRModels results results_confirm
Rscript t2_onesided.R drmTMB summary results results_confirm
Rscript t2_onesided.R DRModels summary results results_confirm
Rscript t2_receipt_tables.R
```

The regenerated `data/SHA256SUMS` must equal `env/data_SHA256SUMS`; this was checked byte-for-byte after the generator gained its rep-range arguments. The minimal repros for the findings are in `repro/`: `repro_boundary.jl` and `repro_boundary.R` plus their captured outputs, and seven 50-row CSVs, each regenerated from its seed and checked against the sweep data.

## Files

| path | contents |
|---|---|
| `t2_config.R` | truth, cells, seed mapping, data-generating function |
| `t2_gen_data.R` | dataset generator (CSV at 17 significant digits, round-trip checked, SHA-256 sums) |
| `t2_fit_drmTMB.R`, `t2_fit_DRModels.jl` | per-engine fitters (long format, one row per rep × parameter) |
| `t2_analyse.R`, `t2_compare.R`, `t2_posthoc_t.R`, `t2_onesided.R`, `t2_receipt_tables.R` | analysis |
| `summary/`, `summary_confirm/` | per-fit evidence (`t2_fits_long.csv.gz`), summaries, paired agreement, tables |
| `env/` | `sessionInfo()`, `versioninfo()`, the Julia project and manifest, data checksums |
| `repro/` | minimal repro data, scripts and outputs for findings A1, A2, B, C and E |

Raw datasets (`data/`, about 155 MB for reps 1-500) and the per-chunk raw fit files (`results*/`) are not committed; they regenerate from the scripts.
