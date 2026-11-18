# Native Student-t independent-slope SD regression, 2026-10-18

The native Student-t SD-regression adapter now admits one explicitly selected
ordinary independent location slope for complete-response univariate fits. The
source assembly test passed 25 expectations after first failing at the intended
intercept-only fence. A fresh installed-package integration run passed 30
expectations, including synthetic recovery, an independent slope-loading
Laplace oracle, a wrong-group control, constant-SD equivalence, prediction,
simulation, save/reload, and profile/bootstrap target routing. Knitting the
location-scale vignette executed all chunks; `pkgdown::check_pkgdown()` and
`git diff --check` passed.

This is not interval-calibration evidence. The Julia route is not checked via
the R bridge here. Correlated blocks, structured effects, random `sigma` or
`nu`, missing responses, and imputation remain outside the slice. See
`docs/dev-log/after-task/2026-10-18-native-student-slope-sd.md` and the bounded
gate `.unlazy/general-sd-regression/gates/native-student-slope-sd.md`.
