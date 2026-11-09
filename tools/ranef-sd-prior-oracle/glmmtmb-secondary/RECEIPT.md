# Secondary glmmTMB comparison

The installed `glmmTMB` 1.1.14 was compared with the frozen independent oracle for the approved Gaussian mean random-intercept SD-prior slice. This is a secondary cross-engine comparison; it does not replace the independent dense derivation, full package checks, or inference validation.

## Matching contract

The installed `glmmTMB` prior help defines Gamma parameters as mean and shape on the natural SD scale. For oracle shape `a` and rate `b`, the matched call uses `gamma(a / b, a)` with `class = "ranef_sd"` and `coef = "g"`. The model is `y ~ x + (1 | g)`, `dispformula = ~x`, Gaussian family, with the same nine frozen rows and groups. The five coordinates are mean intercept and slope, Gaussian dispersion intercept and slope, and log random-intercept SD. Direct point comparisons verify that glmmTMB's dispersion coordinates match the oracle's log residual SD coordinates in this model. The comparison evaluates the normalized penalized objective; `logLik.glmmTMB()` on this prior fit also includes its penalty and is not used as an unpenalized data-likelihood estimate here.

## Results

Command from this directory: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /usr/bin/time -p Rscript compare.R > compare.log 2>&1`. The rerun against the adjacent committed oracle exited 0 in 1.45 seconds and printed `GLMMTMB_ORACLE_COMPARISON_PASS`.

- Across 30 interior points, the maximum relative objective error was 1.45e-15, maximum absolute gradient error was 6.22e-15, and maximum componentwise scaled full-Hessian error was 1.16e-9. The Hessian was a Richardson extrapolation of glmmTMB's TMB automatic-differentiation gradient using numDeriv defaults: initial `d = eps = 1e-4`, four levels and factor two; each nonzero-coordinate step starts at `abs(d*x)`.
- All six original glmmTMB `nlminb` fits reported convergence 0. A BFGS refinement and numerical-Newton score polish were applied and recorded; all refined scores were at most 6.20e-13 and objective errors at most 7.11e-15.
- Only the three oracle fits with both successful refinement and numerical eligibility were compared by parameters; the maximum error was 2.76e-14. The three oracle refinements reporting precision loss were compared by objective and score only. No global optimality or recovery claim is made.
- Exact pointwise and fit-level outputs, warning text, initial optimizer messages, and status flags are in `point-results.csv` and `fit-results.csv`.

## Provenance

`compare.log` records R 4.6.0, macOS aarch64, glmmTMB 1.1.14, TMB 1.9.21, numDeriv 2016.8-1.1 and other loaded versions. The glmmTMB binary SHA-256 was `8efd2fb4ccec944c66541a44c1ce95d78ce9e1dfde2175b01761f0e633f35955`; its installed DESCRIPTION SHA-256 was `919b899db9f41dc8c954430779ff0d8ea2d0f4fd89726e11b704d24f6d98d38f`. This identifies the installed binary and metadata, not its complete source history.

Frozen oracle SHA-256: `fixture.json` `01b27cca962c4cda5c8b0f4edb39a91204c6b979a002d34df8934997136dba13`; `expected.json` `3103ae0cb20c9afad79ea5f25cf144d3c5410decca47b32c4abd6d53848d7a30`; `expected_noninteger.json` `b40f23b97a16f14959dd068549a6b211ad847eb463d99b8e1789bd1dda02c824`; `fitted_optima.json` `c7536c9d37090cd022a6275d27de277bc6b33af50c336d459b2a3b8fa2a24bbc`. The comparison script SHA-256 is `9fe65e41447d3e26a8388f0e7b68cf1bc046912587d652f997c4bfbd51862c60`.
