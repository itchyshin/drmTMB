# 2026-10-20: Zero-One Beta SD Regression Julia Bridge

The focused Zero-one Beta SD-regression slice now has a live R-to-Julia
synthetic fit. Julia direct tests passed 14/14, and the existing Julia
Zero-one Beta recovery test passed 6/6. The live bridge test passed route
admission, both engine fits, coefficient checks, fitted and new-data SD
prediction, and save/reload assertions. The native filtered suite passed its
assembly and independent groupwise integration tests; its live Julia test
skipped because `DRM_JL_PATH` was unset for that run.
`pkgdown::check_pkgdown()` found no problems; Pandoc emitted existing
`--mathml` deprecation warnings.

Exact live bridge command:

```sh
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRMTMB_JULIA_TESTS=true \
Rscript -e 'devtools::test(filter="julia-zero-one-beta-sd", reporter="summary")'
```

The first bridge attempt stopped during JuliaCall setup because the sandbox
could not create a pidfile in the user's Julia depot. Retrying with the needed
depot write access completed successfully. This work does not establish
interval-coverage calibration. The Julia feature remains in its separate
candidate worktree pending integration. Full scope and limits are recorded in
`docs/dev-log/after-task/2026-10-20-zero-one-beta-sd-julia-bridge.md`.
