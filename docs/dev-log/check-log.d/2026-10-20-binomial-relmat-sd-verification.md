# Native Binomial relmat SD verification

On the current `codex/general-sd-regression` worktree, the existing
`binomial-relmat-sd` test passed 22 checks in 18.5 seconds with zero failures,
warnings, or skips. The fixed-seed case covers recovery of the two log-SD
coefficients, group-level SD predictions, random-effect scaling, marginal
simulation, save/reload prediction, and constant-SD equivalence. The filter
ran no live Julia tests.

The predictor-dependent SD tutorial now includes an independent synthetic
Bernoulli `relmat()` intercept example. Rendering from `devtools::load_all()`
passed to `/private/tmp/predictor-dependent-random-sd-check-20261020-binom-relmat.html`;
Pandoc emitted only its existing `--mathjax` deprecation warning.

The paired DRM.jl audit found no matching Binomial `relmat()` SD route. Its
candidate tree is dirty and the DRM task is actively working on CMR, so no
DRM.jl files were edited. A source-owner and handoff question was sent to that
active task. This is native support evidence only, not Julia parity or
interval calibration.
