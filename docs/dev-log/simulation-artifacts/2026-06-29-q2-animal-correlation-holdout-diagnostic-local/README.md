# Q2 animal correlation fixed-8 holdout diagnostic

This directory records the clean fixed-8 animal correlation holdout smoke run:

```sh
unset GSWEEP_N_GROUPS
R_PROFILE_USER=/dev/null NOT_CRAN=true \
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 \
Rscript --no-init-file tools/run-structured-re-q2-slope-coverage-grid.R \
  --holdout=animal_cor --n_rep=5 --seed_start=733001 --n_each=20 \
  --bootstrap=0 \
  --out_dir=docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-holdout-diagnostic-local
```

Result: 5/5 fits, 5/5 convergence, 5/5 `pdHess`, 0 boundary flags, and 5/5
finite Wald and endpoint-profile intervals for
`cor:animal:cor(mu1:x,mu2:x | p | id)`.

This is fixed-8 smoke only. It is not g=32 evidence, not coverage evidence,
not MCSE-qualified, and does not promote the linked Q-Series row.
