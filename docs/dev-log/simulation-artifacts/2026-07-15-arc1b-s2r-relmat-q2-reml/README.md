# Arc 1b-S2R relmat q2 REML recovery evidence

This directory retains the complete predeclared recovery campaign for the one
newly admitted model: a bivariate Gaussian, location-only, matching labelled
`relmat(1 | p | id, K = K)` intercept in `mu1` and `mu2`, constant residual
parameters, complete pairs, unit weights, and native-TMB `REML = TRUE`.

## Provenance

- Base commit: `d210439187f2a49922de8bcf8c183d164d7bd0dc` (merged PR #783).
- Branch source was transferred from the isolated local worktree to the
  isolated Totoro checkout
  `/home/snakagaw/drmtmb_work/arc1b-s2r-relmat-q2-reml`.
- Package library: `/home/snakagaw/drmtmb_work/arc1b-s2r-lib`.
- Package version verified immediately before both smokes and the campaign:
  `drmTMB 0.6.0.9000`.
- Compute host: Totoro, R 4.5.3 on Ubuntu 24.04.4 LTS, 32 workers, with
  `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, and `MKL_NUM_THREADS=1`.
- Runner: `tools/run-arc1b-s2r-relmat-q2-reml-recovery.R`.
- Master seed: `2026071503`; replicate seed is
  `master_seed + 100000 * cell_number + replicate`.
- Matrix: named dense covariance with
  `K[i,j] = 0.4^abs(i-j)` and levels `id_001`, ..., `id_g` in response and
  matrix order. `matrix-digests.tsv` authenticates every matrix dimension.
- The local and Totoro SHA-256 values matched for the admission source, runner,
  and every copied campaign output before this README was written.

The campaign command was:

```sh
R_LIBS=/home/snakagaw/drmtmb_work/arc1b-s2r-lib \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 \
R_PROFILE_USER=/dev/null Rscript --no-init-file \
  tools/run-arc1b-s2r-relmat-q2-reml-recovery.R \
  --n-rep=400 --cores=32 --master-seed=2026071503 \
  --out-dir=/home/snakagaw/drmtmb_work/arc1b-s2r-results-20260715
```

An initial remote smoke accidentally resolved the server's old default
`drmTMB_0.1.4` because `R_LIBS_USER` was ignored. That run was discarded before
the campaign. The corrected smoke explicitly used the absolute `R_LIBS` path,
reported package version `0.6.0.9000`, and completed all six fits with
convergence 0 and `pdHess = TRUE`. The fixed campaign used the same absolute
library path.

## Retained denominator and result

All 2,400 predeclared attempts are uniquely present in `raw-attempts.tsv`; all
2,400 fits succeeded with optimizer convergence 0 and `pdHess = TRUE`. The only
flagged rows were two `g=16, m=3` structured-correlation boundary estimates;
they remain in both the raw denominator and `failure-ledger.tsv`.

Every row in `gates.tsv` is PASS. In the `g=64, m=6` cell, absolute bias was
0.00496 for `tau1`, 0.00363 for `tau2`, and 0.00088 for `rho_K`. From `g=32`
to `g=64` at `m=6`, RMSE decreased by 0.02334, 0.01701, and 0.05660,
respectively; each decrease passes the independently bootstrapped
`RMSE64 <= RMSE32 + SE_delta` gate.

This supports only the exact ledger cells at `point_fit_recovery`. It does not
support `Q`, slopes or q4+, scale-side structure, extra random-effect layers,
missing or weighted pairs, non-Gaussian families, intervals, or coverage.

## Files

- `design.tsv`: all frozen cell, replicate, and seed keys.
- `raw-attempts.tsv`: every retained fit attempt and estimate.
- `summary.tsv`: attempt-based rates and conditional bias/RMSE with MCSEs.
- `rmse-difference.tsv`: independently bootstrapped RMSE-difference gate.
- `gates.tsv`: executable predeclared promotion decisions.
- `failure-ledger.tsv`: all warning, convergence, Hessian, or boundary flags.
- `matrix-digests.tsv`: deterministic supplied-`K` identity and ordering.
- `session-info.txt`: R, platform, BLAS, LAPACK, locale, and time-zone record.
- `SHA256SUMS`: source and evidence hashes.
