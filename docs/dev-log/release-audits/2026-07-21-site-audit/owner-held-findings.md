# Owner-held findings

## `bivariate-coscale` — resolved after ownership transfer

- **Owner:** Codex (transferred by Shinichi on 2026-07-21)
- **Source:** `vignettes/bivariate-coscale.Rmd:422-425`
- **Severity:** P1 public-claim defect
- **Finding:** the page correctly says that predictor-dependent `rho12`
  intervals are computed but not coverage-certified, then calls the constant
  `rho12 ~ 1` profile interval “the certified reporting target.” The capability
  ledger has no committed CI-coverage simulation for the constant fixed-effect
  `rho12` cell. The referent must be repaired without removing the correct
  regression-interval hedge.
- **Disposition:** repaired in `vignettes/bivariate-coscale.Rmd`. The constant
  interval is now described as finite and reportable but not coverage-certified;
  the distinct predictor-dependent `newdata` caveat remains unchanged.

The page is no longer owner-held.
