# Evidence receipt: Julia Binomial animal q2 pedigree bridge

Date: 2026-10-29

## Question

Can the existing Binomial animal intercept-plus-slope SD route consume a pedigree through the R-to-Julia bridge while preserving observed-animal ordering and coefficient-specific outputs?

## Result

Yes, for the tested synthetic candidate. For logit, probit, and cloglog, the bridge converted the pedigree to an additive relationship covariance and passed its observed-animal submatrix in first-seen order. Native TMB and Julia converged; their likelihoods, two coefficient-specific SD designs, and group-SD predictions met the test tolerances. Julia marginal simulation returned binary observations of the expected length.

The change in this slice is a new recovery test. No model or bridge source changed for this q2 route because the current candidate already supported it through the pedigree-to-covariance path.

## Reproduction

```sh
PATH="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH" JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-binomial-animal-q2-pedigree.R", reporter = "summary")'
```

The saved console log reports a passing live JuliaCall bridge test. The fixed-seed fixture uses 72 observed offspring in 12 full-sib families, 32 observations per group, a numeric random slope, and separate group-level SD predictors for intercept and slope. It includes three Binomial links.

## Source pins

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`
- Exact current source, test, and console hashes: `source-manifest.sha256`

## Limits

This is one synthetic q2 pedigree fixture per link, one intercept, one numeric slope, complete responses, and candidate R/Julia source. It is point-recovery and workflow evidence only. It does not establish interval calibration, coverage, all animal layouts, other providers, broad family support, or release readiness. The required-row inventory and review status are unchanged.
