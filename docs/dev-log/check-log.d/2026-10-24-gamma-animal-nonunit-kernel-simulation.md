# Check log: Julia Gamma animal SD simulation with non-unit kernel

- Command: `PATH="/Users/z3437171/.juliaup/bin:$PATH" DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-animal-q2-nonunit-kernel-simulation", reporter = "summary", stop_on_failure = TRUE)'`
- Result: PASS; one live Julia bridge fit, seven expectations, exit code 0. Runtime was about 34 seconds, including Julia startup.
- Console: [`test-console.log`](evidence/gamma-animal-nonunit-kernel-simulation-20261024/test-console.log); SHA-256 `702dc1ced1207b67ffa246c77eedd045ad7187fb4b9dcdd0f7c25e6198f38d3b`.
- Test and simulator source hashes: [`source-manifest.md`](evidence/gamma-animal-nonunit-kernel-simulation-20261024/source-manifest.md).
- `git diff --check -- R/julia-simulate.R tests/testthat/test-gamma-animal-q2-nonunit-kernel-simulation.R`: PASS.
- Scope: exact seeded marginal simulation under a supplied non-unit-diagonal animal covariance; no calibration, no new likelihood implementation, and no broad provider or cross-engine claim.
