# C17-C2 ordinary `coi` random-slope recovery

This retained Totoro campaign tests the exact point-fit-only candidate

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ x + (0 + x | id))
```

at committed source `ac86a6429f67b738d9b2e21072b109c9c7681b79`. It used
the frozen seeds `2026081781:2026081784`, 50 observations per group, and the
predeclared `M = 16, 32, 64` ladder. Data were drawn once per cell with no
support-conditioned resampling. The independent boundary-only
`lme4::glmer()` comparator checked the common `coi` intercept, slope, and
random-slope SD.

## Result

The `M = 64` claim rung passed all four fit and population-level recovery
attempts. Mean absolute errors were 0.0117 (`mu` intercept), 0.0102 (`mu`
slope), 0.0277 (`zoi` intercept), 0.0231 (`coi` intercept), 0.1068 (`coi`
slope), and 0.0062 (log `sigma`). Mean relative random-slope SD error was
0.2776. The maximum common-parameter difference from `glmer()` was
`5.89e-4`, within the frozen `1e-3` tolerance.

All four `M = 64` attempts had convergence code 0, `pdHess = TRUE`, maximum
gradient at most 0.01, non-boundary SD estimates, mode correlation above 0.45,
and adequate zero/one/interior counts. One seed (`2026081781`) had a minimum
within-group boundary-row predictor SD of 0.403 rather than 0.5. Its fit and
recovery were nevertheless strong: mode correlation 0.660, `coi` slope error
0.0215, and relative SD error 0.0856. This is retained as a sample-information
warning for conditional group-mode interpretation, not a block on the exact
population-level point-fit claim.

The diagnostic rungs remain descriptive. At `M = 16`, three of four attempts
met the full fit diagnostic because seed `2026081783` had mode correlation
0.340; `M = 32` passed four of four. These results support the predeclared
`M = 64` point-fit scope and do not establish profiles, intervals, coverage,
inference-ready, or supported status.

`provenance.tsv` authenticates the committed source and runner blobs. The
recorded dirty state contains only the preceding smoke and compatibility
output directories; no source file differed from the committed candidate.
