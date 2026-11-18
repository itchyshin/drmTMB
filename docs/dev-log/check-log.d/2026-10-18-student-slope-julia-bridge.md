# Student-t SD regression through the Julia bridge, 2026-10-18

The bridge now admits one ordinary Student-t location intercept or one
independent numeric location slope when the single `sd()` target matches the
random-effect group and coefficient, and `sigma` and `nu` remain fixed
intercepts. Source-assembly tests passed 9 admission expectations with the two
live fits skipped as expected. The live focused suite passed 32 assertions
across intercept and slope comparisons in 74.1 seconds, with zero failures,
warnings, or skips. Same-data coefficient and group/row prediction checks
passed; the slope fit retained save/reload outputs. The existing Julia bridge
filter passed 208 assertions (two existing `beta()` deprecation warnings and
three expected live skips), and `pkgdown::check_pkgdown()` found no problems.

This is one synthetic point-parity cell per target, not interval calibration.
Correlated and structured targets, random `sigma` or `nu`, missing responses,
imputation, and broader family/backend parity remain open. See
`docs/dev-log/after-task/2026-10-18-student-slope-julia-bridge.md` and the
bounded gate `.unlazy/general-sd-regression/gates/student-slope-julia-bridge.md`.
