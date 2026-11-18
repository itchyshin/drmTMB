# Label-boundary negative control

This control compares the current Poisson assembly fence with the builder from the earlier frozen capsule, without changing package source or running a fit.

The capsule `/private/tmp/drmtmb-poisson-label-20261017.tar.gz` has SHA-256 `2cab4d8f1ff25fd5d9ac6294dd0dae450e71143c90aa07c333a468f27d1204a4`. I extracted only its `drmTMB/R/drmTMB.R` member to `old-source/R/drmTMB.R`; that file's SHA-256 is `9e66eed5fb72246872bfa9592c87c124e0e2090e4fcad5d00f54831e90d77bf7`.

With the current source and tests, `Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-poisson-sd-assembly.R` passes: 38 expectations, `SOURCE_ASSEMBLY_PASS`. The assembly suite includes two negative cases for labelled intercepts combined with (1) a structured partner and (2) response-missing inclusion.

Then `Rscript docs/dev-log/general-sd-regression/evidence/poisson-label-20261017/fence-negative-control/run-old-builder-control.R` sourced all current R files and helpers into an isolated test environment, overrode the builder with the complete extracted old `R/drmTMB.R`, and ran the same current test file. Exactly those two expectations failed, both because the old builder returned without throwing; the remaining expectations passed. This is the expected RED control showing that the new fences detect the prior over-admission. Logs are `current-green.log` and `frozen-old-red.log`; the latter's R process exits normally because testthat was asked to collect both failures.

This is source-level assembly evidence only. No compiled package, likelihood fit, or change to the package's R source was involved.
