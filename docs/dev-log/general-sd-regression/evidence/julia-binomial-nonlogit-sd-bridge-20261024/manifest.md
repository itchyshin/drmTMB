# Julia Binomial non-logit SD bridge evidence

Test command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
DRMTMB_JULIA_TESTS=true \
DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
PATH='/Users/z3437171/.juliaup/bin':$PATH \
Rscript -e 'devtools::test(filter = "julia-binomial-sd-links-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

The command exited 0. The focused test reported 26 passing expectations: six
R-side family/route checks and 20 expectations after Julia startup, including
the probit and complementary log-log TMB/Julia fits. The generic footer says
“0 live tests ran” despite Julia startup and the 20 post-startup expectations;
do not use that counter as evidence that the live test was skipped.

The paired DRM.jl unit test command
`julia --project=. test/test_binomial_bridge_links.jl` exited 0 with 4/4
assertions passing. R parsing and scoped `git diff --check` exited 0.

SHA-256 source snapshot:

| File | SHA-256 |
|---|---|
| `R/julia-bridge.R` | `8deee2ded13c35f15d9a11a2274f8e7b80ee1e2ed62db6e94b9503816baaad70` |
| `tests/testthat/test-julia-binomial-sd-links-bridge.R` | `7c859e9c6696f2db25ae1a625e6fc1374ae8d53c51f87e5e6c4ea4b430fd6650` |
| `NEWS.md` | `2f3e40ebb3e1c450ce9fe6ecf0f1e60ddf03a8a6099425aa70129397a57f4ef6` |
| `vignettes/julia-engine.Rmd` | `ca8b5f0b9b940b72143e7e6ded01189c5914046d01b268c7368c786280be92f0` |
| `vignettes/formula-grammar.Rmd` | `94af1bd3802a2cdaceaabcc7a0a62f9ae9ba4b50c69b0606272bdbb0317626a2` |
| paired `src/bridge.jl` | `5dce57b711cabd3b21b836f74d1affa247f2ed8d40b4320b5966491051a9ef60` |
| paired `test/test_binomial_bridge_links.jl` | `1a44a8dabc743e75a712ea41eba696798b3b0da439d9ffd44f13e44db57dfea2` |

This is fixed-seed point-recovery evidence. The TMB and DRM.jl fits use
different integration approximations, and this check does not test confidence
interval coverage.
