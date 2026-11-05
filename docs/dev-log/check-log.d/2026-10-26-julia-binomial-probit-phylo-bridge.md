# Check Log: Probit phylogenetic Bernoulli SD bridge

Date: 2026-10-26

Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

Command:

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
/usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd")'
```

Result: PASS, 61 expectations, 0 testthat failures, 0 testthat warnings, 0 skips. Two live Julia bridge tests ran in 118.5 seconds on Julia 1.10.0. Julia emitted a numerical warning for two nearly singular Hessian coordinates in the probit phylogenetic fit (`rcond = 4.6681524208092426e-11`); their Wald standard errors are not trustworthy. Trailing testthat progress padding was trimmed from the saved console output. Console SHA-256: `a756a0717cb280805265d5b2c1b57ea6e892c713817f50cc6635ee7ef3a4450a`.

Source SHA-256: `R/julia-bridge.R` `d3240442ad139222bfe84e2cff055349b820d09f4d45071f62ab783de627c967`; test `tests/testthat/test-julia-binomial-phylo-sd.R` `001996362052b626ce3f3b768ac400525a3c19ebe72bc853203934d6c334dec3`; paired `DRM.jl/src/inference.jl` `bc9592479f22a50a2c46efcb7bac09c120d1b0c64eda8254aa04a64026419c0d`.

Consistency search:

```sh
rg -n -i 'probit|phylogenetic|non-logit' NEWS.md docs/design/18-random-effect-scale-models.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd
```

Counts were NEWS 147, random-effect-scale design 29, roadmap 167, limitations 54, formula-grammar design 58, formula-grammar vignette 29, and Julia-engine vignette 27 matching lines. Public docs remain with the separate documentation-audit lane. The SD inventory now marks the old pre-retry failure as historical and records this focused result. GitHub search for an open issue on the same route returned no matches.

Scope: one synthetic probit Bernoulli phylogenetic random-intercept route with predictor-dependent SD. This does not establish interval calibration, broad provider parity, or full-suite status.
