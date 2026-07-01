# Q2 animal correlation fixed-8 SR150 pregrid

This directory records the fixed-8 animal q2 correlation pregrid:

```sh
unset GSWEEP_N_GROUPS
R_PROFILE_USER=/dev/null NOT_CRAN=true \
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 \
Rscript --no-init-file tools/run-structured-re-q2-slope-coverage-grid.R \
  --holdout=animal_cor --n_rep=150 --seed_start=733101 --n_each=20 \
  --bootstrap=0 \
  --out_dir=docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-pregrid-local
```

Result:

- 150/150 fits
- 149/150 convergence
- 150/150 `pdHess`
- 1 retained boundary/convergence flag, seed `733197`
- 150/150 finite Wald intervals
- 150/150 finite endpoint-profile intervals
- Wald coverage 132/150 = 0.8800, lower/upper misses 4/14
- Profile coverage 133/150 = 0.8867, lower/upper misses 4/13

This is retained-denominator pregrid evidence only. It is not MCSE-qualified
coverage, not interval readiness, and not a Q-Series status promotion.
