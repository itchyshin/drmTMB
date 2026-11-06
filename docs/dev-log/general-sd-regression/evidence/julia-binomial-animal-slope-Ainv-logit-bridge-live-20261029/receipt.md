# Evidence receipt: Binomial animal-slope SD bridge with Ainv under logit

## Claim

The R-to-Julia bridge fits one complete-data Binomial animal slope-only SD regression with supplied `Ainv` under logit and agrees with native TMB on the same synthetic data for point recovery, likelihood, and fitted group-SD predictions.

## Synthetic model

The independent fixture uses 80 animals and 32 observations per animal. The observation-level slope predictor varies within animal; the SD predictor is assigned once per animal. The fixture generates random slopes with covariance `D A D` and passes `Ainv = solve(A)` to each engine. The fitted formula is `y ~ x + animal(0 + x | id, Ainv = Ainv)` with `sd(id, level = "animal") ~ z`. Fixed seeds generate the group predictor, covariate, latent slopes, and Bernoulli responses.

## Source identity

- drmTMB HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`; exact working-tree source hashes are in `source-manifest.sha256`.
- DRM.jl HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`; exact working-tree source hashes are in `source-manifest.sha256`.
- Test log SHA-256: `55dc396332b6765f626e3837906d458ee1508689bc59e31aefa82d1ebe61c9ce`.

Both source worktrees were dirty. The manifest identifies the exact tested source bytes with these HEADs; the HEADs alone do not identify the candidate state.

## Command and result

```sh
PATH="/Users/z3437171/.juliaup/bin:$PATH" \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
Rscript -e 'devtools::test(filter = "julia-binomial-animal-slope-Ainv-logit", reporter = "summary", stop_on_failure = TRUE)'
```

The command exited successfully on macOS with Julia 1.10.0. One live bridge test ran. It checks successful route and `Ainv` payload mapping, convergence, finite named SD coefficients, log-SD slope recovery within 0.5 of truth, log-likelihood agreement within 0.1, group-SD predictions equal to the fitted SD formula, and TMB/Julia group-SD agreement within 0.2.

## Boundaries

This is point-fit and output-agreement evidence for one animal slope-only route with `Ainv` under logit. It does not establish interval calibration, coverage, pedigree input, other animal layouts, mixed effects, missing-data support, or broad Julia parity. The Julia-only fit receipt dated 2026-10-24 remains separate; this receipt adds the native-TMB comparison. Required rows remain unreviewed and no support status is promoted.
