# Check log: Gamma animal intercept and slope SD targets

Command:

```sh
PATH="/Users/z3437171/.juliaup/bin:$PATH" \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
Rscript -e 'devtools::test(filter = "gamma-animal-q2-cross-engine-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit 0, 19 expectations passed, one live Julia bridge fit, 40.4 seconds. The fixture checks separate Gamma animal-intercept and numeric-slope SD targets, truth direction and native recovery, same-data TMB/Julia estimates and log likelihood, target-specific predictions and stored outputs, and save/reload.

Native candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`.
Julia candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`.
Test SHA-256: `1d676f4b12acc3f1e2d73ed3f79107433dba9189343d0615d457a4a510572458`.

This is one fixture-specific recovery/output check with a unit-diagonal relatedness matrix. It does not establish interval calibration, general provider/kernel behavior, correlated intercept-slope support, or a closed capability-universe row.

The after-task structural validator passed. It reported that the 13-file acceptance ledger is not runnable in this checkout because Node or `gate-check` is missing, so that validator reports gate state as unknown. The report prose linter passed with zero findings. A whole-worktree `git diff --check` found an unrelated blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`; this file was not changed in this slice.
