# 2026-10-22: Gamma shared spatial-kernel SD comparison

The focused `gamma-spatial-sd-regression` filter completed with no failed
assertions and one live R-to-Julia fit. The comparison feeds the same named,
unit-diagonal covariance matrix to native TMB and the Julia bridge through
`relmat(1 | site)` and `sd(site, level = "relmat") ~ z`. This checks one Gamma
structured-intercept point comparison using a spatially derived kernel; it
does not establish parity for the coordinate `spatial()` marker. JuliaCall
logged a startup dependency-extension warning even though the test process
exited successfully. Details:
`docs/dev-log/after-task/2026-10-22-gamma-spatial-shared-k-parity.md`.
