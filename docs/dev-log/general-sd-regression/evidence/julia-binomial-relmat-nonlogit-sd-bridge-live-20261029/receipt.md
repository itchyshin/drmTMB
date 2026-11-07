# Evidence receipt: Julia Binomial relmat SD bridge under probit and cloglog

## Claim

One q1 Binomial related-matrix random intercept with a matching predictor-dependent SD formula fits through both native TMB and the paired Julia development bridge under probit and complementary log-log. The focused checks compare both engines on each same synthetic dataset.

## Synthetic design

Each link uses an independent fixed seed, 64 groups, 24 observations per group, a named AR(1) covariance matrix `K`, and a group-level normal SD predictor. The generating log-SD slope is 0.55. Each fit checks convergence, positive and non-negligible slope recovery, cross-engine coefficient and log-likelihood agreement, and name-aligned group-SD predictions against the DGP.

## Source identity

- drmTMB HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl HEAD `70dbf564eb670144c63c08f61ea099084d95add2`; both candidate worktrees were dirty.
- Exact tested source hashes are in `source-manifest.json`.
- Test SHA-256: `31c583b0d463ecfa7eb4d3a816fd64a2c66f7382a0c641e692bf1adbd8ec5804`.
- Saved console log SHA-256: `5bc9212e6d1f42b4dd28ed23c391e74c4ec197433a410db104e73478b94f1d30`.

## Command and result

```sh
PATH="/Users/z3437171/.juliaup/bin:$PATH" DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
Rscript -e 'devtools::test(filter = "julia-binomial-relmat-nonlogit-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

The command exited 0 on macOS with Julia 1.10.0. The focused live test passed 22 expectations across probit and cloglog. The exact console output is in `test.log`.

## Boundaries

This is fixed-seed point-recovery and output-agreement evidence for one relmat intercept shape under two links. It does not establish interval calibration, coverage, relmat slopes, other structured providers, support in the shared/released DRM.jl source, or broad Julia parity. The evidence rows remain unreviewed and no capability status is promoted.
