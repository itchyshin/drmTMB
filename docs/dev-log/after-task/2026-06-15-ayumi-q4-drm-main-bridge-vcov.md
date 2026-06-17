# After-task: Ayumi q4 DRM.jl bridge-vcov fix verified through drmTMB

Date: 2026-06-15

## Purpose

Ayumi's one-pair, 10,440-tip q4 Gaussian phylogenetic location-scale workflow
showed that the Julia route could run for a long time and then fail in a
Julia SVD/LAPACK path. This task separated a real post-fit bridge failure from
the remaining speed and REML-bootstrap work.

## What Changed

DRM.jl #292 merged on main as
`9bdea6564661e1d9eb454ed3c6d2d9398522f74f`.

The sister-package change does three things:

- defaults bivariate Gaussian phylo bridge fits to `q4_vcov = false`;
- preserves ML versus REML in q4 bootstrap refits;
- reports the first failed q4 bootstrap replicate when all refits fail.

The first item is the key bridge fix for drmTMB. The q4 R bridge reports
uncertainty through profile/bootstrap rows over the among-axis SDs. It should
not let the auxiliary finite-difference Wald covariance path kill a fit object
that otherwise returned.

## Evidence

Local drmTMB harness run against merged DRM.jl main:

```sh
DRM_JL_PATH=/tmp/DRM-main-merged \
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-evidence/julia-30-ml-reml-bootstrap-drm-main-292-instantiated \
DRMTMB_AYUMI_Q4_SIZES=30 \
DRMTMB_AYUMI_Q4_ENGINES=julia \
DRMTMB_AYUMI_Q4_REML=false,true \
DRMTMB_AYUMI_Q4_PROFILE=none \
DRMTMB_AYUMI_Q4_BOOTSTRAP=2 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=all_q4 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=20260615 \
Rscript tools/ayumi-q4-status-harness.R
```

The DRM.jl worktree was detached at merged main `9bdea65` and loaded from
`/tmp/DRM-main-merged/src/DRM.jl`.

The harness produced:

- `30|julia|REML_FALSE`: fit returned with `convergence = 0`, elapsed time
  34.71 s.
- ML bootstrap: all four q4 SD rows returned with `bootstrap.n = 2`,
  `bootstrap.failed = 0`, and `2/2 successful refits`.
- `30|julia|REML_TRUE`: point fit returned with `convergence = 0`, elapsed time
  9.70 s.
- REML bootstrap: still failed for the Ayumi small subset, but now reports the
  first reason: too few observed `y1_ayumi`/`y2_ayumi` rows for the bivariate
  q4 mean coefficients.

Issue evidence:

- DRM.jl #291 comment:
  https://github.com/itchyshin/DRM.jl/issues/291#issuecomment-4709927117
- drmTMB #555 comment:
  https://github.com/itchyshin/drmTMB/issues/555#issuecomment-4709931132

## Claim Boundary

This task fixed the q4 bridge-vcov point-fit blocker. It did not solve the
10,440-tip wall-time problem, did not make native `engine = "tmb"` a bivariate
q4 REML fallback, and did not make REML bootstrap ready for Ayumi's full
protocol.

The honest current user-facing statement is:

- Julia q4 ML and REML point fits can return through the R bridge after DRM.jl
  #292.
- ML bootstrap has a small real-data smoke proof.
- REML bootstrap remains active follow-up.
- Native TMB ML remains useful for point-estimate and reduced-model checks, but
  native TMB REML is still not the q4 sigma-phylo fallback.

## Next Slices

1. Run the q4 size ladder without intervals first: 30, 100, 250, 500, 1000,
   then larger only when the preceding cell returns useful rows.
2. Fix or explain the q4 REML bootstrap refit semantics on Ayumi-style data.
3. Keep the speed lane in DRM.jl #291 tied to point estimates, objective,
   convergence, and CI/status evidence.
4. Reply to Ayumi only with the fixed/not-fixed boundary visible.
