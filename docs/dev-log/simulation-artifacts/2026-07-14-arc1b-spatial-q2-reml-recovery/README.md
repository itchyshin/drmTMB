# Arc 1b-S1 spatial q2 REML recovery artifact

This directory contains the predeclared retained-denominator recovery campaign
for the exact matched labelled bivariate-Gaussian spatial q2 location-intercept
cell under native-TMB REML.

- Host: Totoro (`totoro.biology.ualberta.ca`)
- Source commit: `20966bc54712d83c5faafcd5cbfc265759675a7f`
- Source runner SHA-256:
  `acf7ab9b68293b071634ab26ae34927fe12a3b49baf4106d73551cca2dc09a4f`
- Master seed: `2026071403`
- Design: 200 replicates for each of 6 cells
  (`n_site = 16, 32, 64` crossed with `n_each = 3, 6`)
- Parallelism: 32 forked workers, `OPENBLAS_NUM_THREADS=1`,
  `OMP_NUM_THREADS=1`, `MKL_NUM_THREADS=1`

Command:

```sh
R_ENVIRON_USER=/dev/null \
R_LIBS_USER="$HOME/drmtmb_work/arc1b-s1-lib:$HOME/R/lib" \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
R_PROFILE_USER=/dev/null \
Rscript --no-init-file tools/run-arc1b-spatial-q2-reml-recovery.R \
  --n-rep=200 --cores=32 \
  --out-dir=$HOME/drmtmb_work/arc1b-s1-campaign
```

## Retained-denominator result

- attempted: 1,200
- fit objects returned: 1,200
- optimizer convergence code zero: 1,200
- `pdHess = TRUE`: 1,198
- target-boundary attempts: 9
- retained optimizer warnings: 2 attempts recorded `NaNs produced`; both
  returned fit objects with convergence code zero and remain in the denominator
- duplicate `cell_id`/`replicate` keys: 0

The high-information cells (`n_site >= 32`, `n_each = 6`) had 100%
convergence and 100% `pdHess`. In the highest-information cell
(`n_site = 64`, `n_each = 6`), biases were -0.01095 for spatial SD 1,
-0.00882 for spatial SD 2, and +0.00773 for the spatial correlation. Their
RMSE values decreased from the corresponding 32-site cell. All predeclared
recovery gates in
`docs/dev-log/2026-07-14-arc1b-s1-recovery-design.md` passed.

This evidence supports `point_fit_recovery` only. It is not interval,
coverage, `inference_ready_with_caveats`, or `supported` evidence.
