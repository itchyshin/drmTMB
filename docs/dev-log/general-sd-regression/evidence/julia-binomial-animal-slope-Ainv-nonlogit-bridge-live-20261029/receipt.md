# Evidence receipt: Binomial animal-slope SD bridge with Ainv

## Claim

The R-to-Julia bridge fits one complete-data Binomial animal-slope-only SD regression with supplied `Ainv` under probit and cloglog, matching the existing native TMB route for point recovery, likelihood, and fitted group-SD predictions.

## Synthetic model

The independent fixture uses 80 animals and 32 observations per animal. The slope covariate varies by observation; the SD predictor is assigned once per animal. It generates the latent slope covariance as `D A D` and supplies `Ainv = solve(A)` to both fitted engines. The model is `y ~ x + animal(0 + x | id, Ainv = Ainv)` with `sd(id, level = "animal") ~ z`. Each link uses a fixed seed.

## Source identity

- drmTMB HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`; working-tree source hashes are in `source-manifest.sha256`.
- DRM.jl HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`; working-tree source hashes are in `source-manifest.sha256`.
- Test log: `test.log`; SHA-256 `1b8a0278f83e577e7f7991b119313f5267e0c5444f004e561d496c2f0d402cb1`.

Both source worktrees were dirty. The manifest therefore identifies the exact source bytes used with these HEADs; the HEADs alone do not identify the candidate state.

## Command and result

```sh
PATH="/Users/z3437171/.juliaup/bin:$PATH" \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
Rscript -e 'devtools::load_all(".", quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R", reporter="summary")'
```

The command exited successfully on macOS with Julia 1.10.0. Three live bridge test cases passed, including the animal-slope `Ainv` fit under both probit and cloglog. The slope assertions check convergence, finite and correctly named SD coefficients, log-SD slope within 0.5 of truth, TMB/Julia log-likelihood agreement within 0.1, and group-SD prediction agreement. The same run also checked neighboring animal-intercept `A` and relmat-intercept routes under both links.

## Boundaries

This is synthetic point-fit and output-agreement evidence for one animal slope-only route. It does not establish interval calibration, coverage, pedigree input, animal intercept-plus-slope correlated blocks, mixed animal-plus-IID models, missing-data support, or broad Julia parity. Required rows remain unreviewed; the evidence ledger does not promote support.
