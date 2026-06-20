# Non-Gaussian fixed-effect recovery + Wald calibration (500 reps)

Status: **promotion-grade (500 reps/cell).** Rose+Fisher verified 2026-06-20.
Outcome: the "Non-Gaussian models" matrix **point** cell was promoted
`partial -> covered`; the **wald** and **simulation** cells were held (see
"Promotion outcome" below).

Native R/TMB fixed-effect `mu = b0 + b1*x` recovery + Wald-interval coverage for
the implemented one-response non-Gaussian families (poisson, nbinom2, Gamma(log),
lognormal, beta, student). Extends the binomial approach to characterise the
shared "Non-Gaussian models" matrix row. Deterministic: `master_seed = 20260620`
with per-cell and per-rep offsets; `b0 = 0.5`, `b1 = 0.4` on each family's mu
link scale.

## Result (500 reps x n in {300, 600} x 6 families x 2 targets = 12,000 fits)

0 fit/confint errors; `n_ok = 500` every cell; elapsed 289.4 s. Near-unbiased
recovery for every family (largest absolute bias 0.0052, nbinom2 n=300 intercept;
all other cells |bias| <= 0.004); largest RMSE 0.0602. pdHess rate 1.000 for five
families and 0.996 for student n=300 (2/500 fits non-PD, recovering to 1.000 at
n=600). Fisher and Rose each recomputed the per-cell summary from the per-fit CSV
independently and reproduced it exactly.

Wald coverage by family (range over intercept/slope x n in {300, 600}):

| Family    | Wald coverage | max abs bias | pdHess      |
| --------- | ------------- | ------------ | ----------- |
| beta      | 0.950-0.960   | 0.0013       | 1.000       |
| Gamma     | 0.944-0.956   | 0.0006       | 1.000       |
| lognormal | 0.940-0.962   | 0.0016       | 1.000       |
| nbinom2   | 0.932-0.954   | 0.0052       | 1.000       |
| poisson   | 0.938-0.970   | 0.0017       | 1.000       |
| student   | 0.926-0.952   | 0.0040       | 0.996-1.000 |

See `tables/nongaussian-fe-coverage-summary.csv` (per cell) and
`tables/nongaussian-fe-fits.csv` (per fit).

## Promotion outcome (Rose+Fisher verified)

- **point `partial -> covered` (PROMOTED).** Scope: native R/TMB, fixed-effect
  `mu` coefficient recovery, complete data, correctly specified model, for the
  six implemented one-response families. Recovery is clean across all six
  (near-unbiased, 0/12,000 errors, pdHess >= 0.996). Both verifiers agree.
- **wald (HELD partial).** The contract requires every family's Wald coverage in
  ~0.93-0.97. 23/24 cells satisfy this (mean 0.9479), but **student n=300 mu:x =
  0.926** falls below the 0.93 floor (MCSE 0.0117; student n=300 intercept = 0.936
  is marginal). The dip is a small-n finite-sample effect compounded by 2/500
  non-PD fits counted as not-covered; both student n=600 cells recover (0.944,
  0.952). Wald stays partial and student small-n is the flagged off-cell.
- **simulation (HELD partial).** The verifiers split (Fisher promote, Rose hold)
  and the guardrail hold won. This artifact carries no explicit
  simulation-promotion clause (unlike the rho12 artifact, which did), and the
  in-repo binomial row keeps simulation partial despite covered Wald and profile
  cells -- so covered intervals do not auto-carry a simulation promotion. A
  simulation flip would need a separate explicit authorization plus owner
  sign-off.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration/run.R 500
```

## Boundary

Native R/TMB, fixed-effect `mu` only, complete data, correctly specified model.
No recovery/power claim for random or structured effects; no interval claim
beyond fixed-effect mu Wald (and that interval cell remains partial); no
profile/bootstrap, scale/shape-parameter interval, bivariate/mixed, or
Julia-bridge claim; no release/CRAN claim.
