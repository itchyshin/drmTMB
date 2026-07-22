# Owner-held findings

## `bivariate-coscale`

- **Owner:** Shinichi
- **Source:** `vignettes/bivariate-coscale.Rmd:422-425`
- **Severity:** P1 public-claim defect
- **Finding:** the page correctly says that predictor-dependent `rho12`
  intervals are computed but not coverage-certified, then calls the constant
  `rho12 ~ 1` profile interval “the certified reporting target.” The capability
  ledger has no committed CI-coverage simulation for the constant fixed-effect
  `rho12` cell. The referent must be repaired without removing the correct
  regression-interval hedge.
- **Required disposition:** change “certified reporting target” to language
  such as “a finite computed reporting interval whose coverage is not
  certified”; preserve the distinction from row-specific `newdata` intervals.

This audit does not edit the owner-held source file.
