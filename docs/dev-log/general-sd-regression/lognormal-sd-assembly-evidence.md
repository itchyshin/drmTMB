# Lognormal direct-SD assembly test checkpoint

This is an intentional source-only RED checkpoint for the first lognormal SD leaf: complete data, one ordinary unlabelled random intercept in `mu`, one `sd(id)` regression, and a fixed-effect residual `sigma` regression. It does not run a model fit, simulation, TMB objective, or compiled test.

Added `tests/testthat/test-lognormal-sd-assembly.R` covering builder-to-TMB scale-design metadata, default and explicit `dpar="mu"`/intercept selectors, an intercept-only `sd(id) ~ 1` formula, group-constant scale covariate validation, preservation of `sigma ~ z`, and fail-closed fences for a sigma random intercept, a phylogenetic mean term, and a binary missing-predictor `mi()` term. The fixture is deterministic and positive-valued.

Before running, estimated the source-only check at under 10 seconds. Command:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  Rscript tools/general-sd-regression/run-source-tests.R \
  tests/testthat/test-lognormal-sd-assembly.R
```

It completed in about 2.5 seconds. The primary assembly, explicit selector, constant-formula, and group-constancy test cases all fail at the current `drm_build_lognormal_ls_spec()` guard (`R/drmTMB.R:5405-5409`): “Random-effect scale formulae are not implemented for `lognormal()` models yet.” This is the expected RED result. The prohibited-combination test passes because that same broad guard rejects every direct-SD formula before the specific sigma-RE, structured-effect, and `mi()` combinations are reached; those assertions must be rerun after ordinary lognormal SD admission is implemented to establish the narrower fences.

The initial RED output is retained at `docs/dev-log/general-sd-regression/evidence/lognormal-20261017/lognormal-sd-assembly-red-initial.log`. After the parent added the native lognormal route, I corrected the `beta_sigma` map assertion to accept the ordinary unlisted/free-parameter representation and tightened the three negative controls to their specific current fence messages. The source-only assembly runner then passed and printed `SOURCE_ASSEMBLY_PASS`; its retained output is `docs/dev-log/general-sd-regression/evidence/lognormal-20261017/source-assembly.log`. That verifies R assembly only, not compiled behavior.

Added `tests/testthat/test-lognormal-sd-integration.R` for the isolated compiled run. It uses the independent fixed-seed DGP and exact marginal oracle to check one seeded coefficient-recovery fixture, fitted likelihood, a wrong-group-covariate negative control, target labels, profile intervals, save/reload, prediction, fresh random-effect draw variances, two marginal simulations, two bootstrap refits, and reduction of `sd(id) ~ 1` to the ordinary random-intercept model. Totoro's compiled integration log reports 24 passing expectations against the installed package at `/home/snakagaw/hsq_work/drmtmb-general-sd-lognormal-20261017-02/library/drmTMB`; the source archive was SHA-256 `bad56b4bf70e56972bc1fde2a10a578690789ccca6159e131e09e54176870ffa`. The current test and helper are byte-identical to their archive members: SHA-256 `0134f1237d8a09167ecfb23fbcc3818806c2af34143fb78b95d270c8eb2aa9ee` and `57286d91c8bec5fb9216bacdccca491f39dae5dca4439f9018e6c3884eb9cb6e`, respectively. This closes the pending compiled rerun for the fresh-effect variance-ratio assertion. The retained output is `evidence/lognormal-20261017/compiled-integration-totoro.log`; no new fits were launched in this turn.

Targeted `git diff --check` passes for the changed owned files. No production source was changed by this task.
