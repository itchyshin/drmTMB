# Arc 1b-S2R ADEMP recovery design

This design follows Morris, White, and Crowther (2019) and the transparent
simulation-reporting checklist of Williams et al. (2024).

## A — Aims

Primary: determine whether the exact admitted supplied-`K` relmat q2 REML cell
recovers both structured SDs and their correlation as information increases.

Secondary: report residual-parameter and fixed-effect recovery, optimizer and
Hessian behaviour, boundaries, failures, and runtime. A deterministic ML fit
checks that ML and REML use the same model but is not a campaign competitor.

## D — Data-generating mechanism

Use the model, numerical truths, and Cholesky construction in the symbolic-
alignment note. For levels named `id_001`, ..., use exactly
`K[i,j]=0.4^abs(i-j)`. This deterministic named correlation matrix is shared
across replicates and the two `m` values at each `g`. Draw distinct independent
standard-normal `x1` and `x2`, use coefficients `(0.30,0.50)` and
`(-0.20,-0.25)`, and use the frozen residual Cholesky draw. Store `K`, `G`,
`R`, seeds, ordering, and hashes for every cell.

| Factor | Levels |
| --- | --- |
| Relatedness levels `g` | 16, 32, 64 |
| Observations per level `m` | 3, 6 |
| Structured SD/correlation | `tau1=0.80`, `tau2=0.65`, `rho_K=0.35` |
| Residual SD/correlation | `sigma1=0.30`, `sigma2=0.35`, `rho12=-0.20` |
| Representation | supplied covariance `K` only |

Run 400 attempted replicates in each of six cells: exactly 2,400 attempts and
2,400 REML fits. Every attempt stays in the denominator. At a 0.90 success
rate, `MCSE=sqrt(.9*.1/400)=0.015`, so three MCSEs are 0.045, below the 0.05
gap to a 0.95 acceptable rate.

Use master seed `2026071503`. Order cells by increasing `g`, then `m`; with
one-based `cell_number`, define
`seed = master_seed + cell_number*100000 + replicate`. Write and hash the
six-by-400 design table before fitting. One tiny local smoke must produce a
nonempty finite row,
then the first remote result must be inspected before the remaining grid runs.

## E — Estimands

Store replicate truth and estimates for `beta_1`, `beta_2`, `tau_1`, `tau_2`,
`rho_K`, `sigma_1`, `sigma_2`, and `rho12`. The primary targets are `tau_1`,
`tau_2`, and `rho_K`. `K` is fixed known input, not an estimand.

## M — Methods

| Method | Role |
| --- | --- |
| Native TMB REML | implementation under test; one fit per campaign attempt |
| Dense REML | deterministic optimum/displaced-vector oracle only |
| Native TMB ML | deterministic/local same-model comparator only |

No interval method, coverage method, Julia engine, or alternative estimator is
part of the 2,400-fit denominator.

## P — Performance measures and gates

Convergence, `pdHess`, and structured-boundary rates always use all 400
attempts in a cell. Define a structured boundary as either estimated
`tau < 1e-5` or `abs(rho_K) >= 0.98`. Bias and RMSE use only rows with a
finite estimate and optimizer `convergence == 0`; report this contributing
`n` beside every conditional metric. A failed/nonfinite fit remains in all
attempt-based rates and the failure ledger and is never imputed.

Report bias `mean(theta_hat-theta)`, RMSE
`sqrt(mean((theta_hat-theta)^2))`, bias MCSE
`sd(theta_hat-theta)/sqrt(n)`, binomial MCSEs for
convergence/`pdHess`/boundary rates, and elapsed-time summaries. For RMSE MCSE,
use exactly 2,000 nonparametric bootstrap resamples of the contributing error
rows, with seed `2026071599 + 1000*cell_number + parameter_number`.

Promotion to `point_fit_recovery` requires all of the following:

1. 2,400 uniquely keyed attempted rows and exactly one REML fit attempt per row;
2. for `g >= 32, m=6`, at least 95% optimizer convergence and 90% `pdHess`
   over the full attempted denominator;
3. for `g=64, m=6`, absolute bias at most 0.10 for each structured SD and 0.12
   for `rho_K`;
4. at `m=6`, independently bootstrap the `g=32` and `g=64` contributing error
   rows, compute `delta_b = RMSE64_b - RMSE32_b`, set
   `SE_delta = sd(delta_b)`, and require
   `RMSE64 <= RMSE32 + SE_delta` for both structured SDs and `rho_K`; and
5. source, raw, summary, matrix, seed, ordering, and denominator hashes match,
   with no reviewer-detected symbolic or parameter-order error.

Any failed condition is a HOLD. Do not delete failures, rerun selectively, or
move a threshold after inspection.

## Compute contract

Use Totoro by default and DRAC only if Totoro is unavailable. Never use GitHub
Actions. Cap parallelism at 32 workers and set OpenBLAS, OMP, MKL, and related
thread counts to one. Results stay local except for the compact authenticated
artifact committed to the repo.

## Williams 11-item self-audit

| Item | Contract |
| ---: | --- |
| 1 Aims | A section above |
| 2 DGP and replicate justification | D section and MCSE calculation |
| 3 Estimands | E section |
| 4 Methods | M section; repo REML references cited in artifact README |
| 5 Performance measures | P formulas and thresholds |
| 6 Software versions | retained `sessionInfo()` |
| 7 DGP code | tracked runner |
| 8 Performance code | tracked summarizer in runner |
| 9 Worked case | deterministic oracle fixture and reader-facing formula |
| 10 Full table | six-cell compact summary with failures retained |
| 11 MCSE | stored beside every aggregated metric |
