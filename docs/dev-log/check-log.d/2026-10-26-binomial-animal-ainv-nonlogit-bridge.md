# Check log: Binomial probit/cloglog animal SD bridge with Ainv

The focused opt-in live bridge test passed for probit and cloglog. Four native TMB/Julia fits checked convergence, log-SD predictor slope recovery, predicted animal SD agreement, and log-likelihood agreement. JuliaCall used Julia 1.10.0 from the paired candidate at `../general-sd-julia`.

The first live attempt stopped because this testthat version rejects `info=` in `expect_lt()`. I removed those unsupported expectation labels and reran successfully. An earlier invocation without `NOT_CRAN=true` skipped before fitting because of `skip_on_cran()`; it is not counted as a live attempt. The two live outputs follow.

Final successful command:

```sh
NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH="$PWD/../general-sd-julia" JULIA_HOME="$HOME/.juliaup/bin" JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-animal-ainv-nonlogit-sd-bridge.R", reporter = "summary")'
```

```text
ℹ Loading drmTMB
julia-binomial-animal-ainv-nonlogit-sd-bridge: .i Starting Julia (first call in a session takes ~30-60 s; later calls are fast)...
Julia version 1.10.0 at location /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin will be used.
Loading setup script for JuliaCall...
Finish loading setup script for JuliaCall.
  Activating project at `~/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`
...1

══ Failed ══════════════════════════════════════════════════════════════════════
Error in `expect_lt(...)`: unused argument `info`

══ DONE ════════════════════════════════════════════════════════════════════════
Julia bridge: 1 live test ran; bridge glue was exercised in this configuration.
Julia exit.
```

```text
ℹ Loading drmTMB
julia-binomial-animal-ainv-nonlogit-sd-bridge: .i Starting Julia (first call in a session takes ~30-60 s; later calls are fast)...
Julia version 1.10.0 at location /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin will be used.
Loading setup script for JuliaCall...
Finish loading setup script for JuliaCall.
  Activating project at `~/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`
.................

══ DONE ════════════════════════════════════════════════════════════════════════
Julia bridge: 1 live test ran; bridge glue was exercised in this configuration.
Julia exit.
```
