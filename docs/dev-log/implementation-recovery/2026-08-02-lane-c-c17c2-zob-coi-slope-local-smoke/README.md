# C17-C2 local smoke receipt

This one-fit smoke exercised the exact candidate formula

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ x + (0 + x | id))
```

from the authenticated working source recorded in `provenance.tsv`. The fit
completed with convergence code 0, `pdHess = TRUE`, maximum gradient
`0.000875`, a non-boundary random-slope SD, mode correlation `0.629`, and all
predeclared sample-information diagnostics satisfied. The independent
boundary-only `lme4::glmer()` comparator agreed to within `8.6e-05` across the
`coi` intercept, slope, and random-slope SD.

This is a smoke receipt, not recovery evidence and not a capability promotion.
Its purpose is to prove that the runner produces non-empty, interpretable
output before the retained three-rung campaign runs on Totoro.
