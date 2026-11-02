# 2026-10-22: Tweedie Julia SD-regression bridge

The Julia bridge admits one complete-data Tweedie `mu` random intercept or
one independent numeric slope with a matching SD formula, fixed-effect
`sigma` predictors, and intercept-only `nu`; random effects on `sigma` or
`nu` are excluded. The focused Julia bridge filter passed 37 expectations,
including the categorical-slope refusal, and ran both live same-data
comparisons against native TMB. This used drmTMB candidate HEAD `425bee815`
and paired Julia candidate HEAD `70dbf564e`; both worktrees were dirty. Native
Tweedie SD integration passed 27 expectations. Structured/correlated effects,
other endpoints, and interval calibration remain outside this slice. See the after-task report at
`docs/dev-log/after-task/2026-10-22-tweedie-julia-sd-bridge.md`.
