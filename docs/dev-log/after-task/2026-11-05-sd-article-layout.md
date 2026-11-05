# SD article layout repair

## 1. Goal

Keep the article equations and navigation readable across screen widths.

## 2. Implemented

Split four model displays into aligned lines and compact the navigation at intermediate widths. The distributions and parameter definitions remain the same.

## 3a. Decisions and Rejected Alternatives

Keep the version note on wide displays. On narrower desktop displays, retain the ordinary package version and hide the additional note to leave room for navigation.

## 4. Files Touched

The SD article, pkgdown stylesheet, this report and the check-log fragment.

## 5. Checks Run

The article rebuilt with the current source loaded in process. Chromium renders at 390, 768, 1050, 1365 and 1920 CSS pixels were inspected or measured. The 1050-pixel viewport corresponds to a 1365-pixel display at 130% scaling; this is a layout simulation. Published-page verification is pending deployment.

## 6. Tests of the Tests

The original published article visibly placed the Gamma equation over the sidebar. The local phone render initially overflowed on two earlier equations, which were then split as well.

## 7a. Issue Ledger

No numerical issue or model-support claim is changed by this repair.

## 8. Consistency Audit

The Bernoulli logit, Poisson log-mean, related-group covariance construction and Gamma shape and rate retain the original parameterization.

## 9. What Did Not Go Smoothly

The first article build used a stale installed package in a child process and failed. Loading the current source and building in process succeeded.

## 10. Known Residuals

Public deployment and actual browser-zoom controls have not yet been verified at this pre-merge checkpoint.

## 11. Team Learning

A successful site build and HTTP response do not verify layout. Inspect the displayed equations and navigation at narrow widths before claiming a visual pass.

## 12. Cross-Product Coverage

This change affects the R pkgdown article and shared navigation styling. It does not alter the Julia guide or model implementations.
