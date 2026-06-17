# After-task: Julia q4 phylocov target estimates

Date: 2026-06-15

## Purpose

Ayumi's q4 Julia status ladder exposed a misleading R-side target inventory:
`profile_targets()` named the four bivariate phylogenetic SD targets, but the
reported estimates were hard-coded `0.5` placeholders. That made the dashboard
and harness evidence look cleaner than the bridge contract actually was.

## What Changed

`drm_julia_profile_targets_biv()` now reconstructs the stored q4 among-axis
phylogenetic covariance `Sigma_a` with `drm_julia_phylocov_matrix()` and reports
the fitted axis SDs as `sqrt(diag(Sigma_a))` for:

- `sd:mu1:phylo(...)`
- `sd:mu2:phylo(...)`
- `sd:sigma1:phylo(...)`
- `sd:sigma2:phylo(...)`

If the q4 `phylocov` block is absent or non-finite, the bridge now returns no
profile targets rather than inventing a fitted estimate.

The synthetic bivariate Julia confint fixture now carries a known q4
`phylocov` log-Cholesky block and asserts the public target estimates and link
estimates match that covariance.

## Evidence

Focused local tests:

```sh
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-biv-confint.R"); testthat::test_file("tests/testthat/test-julia-phylo-q4-corpairs.R")'
Rscript --vanilla -e 'devtools::test(filter = "julia-biv-confint|julia-phylo-q4-corpairs")'
Rscript --vanilla -e 'devtools::test()'
air format R/julia-bridge.R tests/testthat/test-julia-biv-confint.R
git diff --check
```

The package-style filtered test passed with 60 expectations. The full
`devtools::test()` suite passed with 10,946 expectations, 5 skips, 0 failures,
and 0 warnings in 1319.4 s. The skips were existing guarded Julia/cross-family
availability or known-bug skips, not this patch.

Ayumi-bundle Julia 1.12.6 smoke:

```sh
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/DRM.jl" \
JULIA_HOME="/Users/z3437171/.julia/juliaup/julia-1.12.6+0.aarch64.apple.darwin14/Julia-1.12.app/Contents/Resources/julia/bin" \
JULIA_NUM_THREADS=4 \
OPENBLAS_NUM_THREADS=1 \
OMP_NUM_THREADS=1 \
DRMTMB_AYUMI_Q4_RDS=/tmp/ayumi-ls-ecogeo/for_test/birds_tarsus_beak_10440.rds \
DRMTMB_AYUMI_Q4_SIZES=30 \
DRMTMB_AYUMI_Q4_ENGINES=julia \
DRMTMB_AYUMI_Q4_REML=false \
DRMTMB_AYUMI_Q4_PROFILE=none \
DRMTMB_AYUMI_Q4_BOOTSTRAP=2 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=all_q4 \
DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=20260615 \
DRMTMB_AYUMI_Q4_TIME_LIMIT=300 \
DRMTMB_AYUMI_Q4_OUT=/tmp/drmtmb-ayumi-evidence/julia-30-ml-bootstrap-allq4-phylocov-targets \
Rscript --vanilla tools/ayumi-q4-status-harness.R
```

The 30-tip Julia ML fit returned with `convergence = 0`,
`fit_diagnostic_status = "fit_returned_converged_pdhess_false"`,
`logLik = 30.979053`, and elapsed fit time 50.28 s.

The repaired target table reported fitted q4 SD estimates:

- `sd:mu1 = 0.015125`
- `sd:mu2 = 1.046819`
- `sd:sigma1 = 4.372916`
- `sd:sigma2 = 1.448649`

The admitted all-q4 bootstrap smoke returned four rows with
`bootstrap.n = 2`, `bootstrap.failed = 0`, and
`profile.message = "2/2 successful refits"` in 11.62 s after the point fit.

## Claim Boundary

This is not a 10,440-tip speed result and not calibrated bootstrap inference.
`B = 2` only proves that the admitted all-q4 bootstrap plumbing returns rows on
a 30-tip Ayumi subset after the target-estimate repair.

The intentionally unsupported single-target q4 bootstrap attempt still rejects
early. Bivariate q4 Julia profile/bootstrap intervals currently operate on all
four axes together.

Native `engine = "tmb"` remains a useful ML point/reduced-model diagnostic path,
but it is not yet a full REML fallback for Ayumi's bivariate q4 sigma-phylo
model.

## Next Slices

1. Merge this R-side target-estimate repair and re-run the dashboard validation
   from public main.
2. Keep the next Ayumi benchmark as a size ladder with no intervals first, then
   all-q4 bootstrap only when point fits return useful objective/status rows.
3. Keep AI-REML wording restricted to exact Gaussian REML/MME design work; do
   not describe the current q4 Julia route as AI-REML.
