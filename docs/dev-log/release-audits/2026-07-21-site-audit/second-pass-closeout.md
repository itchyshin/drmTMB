# Second-pass reader-article closeout

## Scope

This pass reopened every authored pkgdown article after the earlier reader-surface
audit. It did not treat a prior closeout as evidence: each page was reread
against its current source and rebuilt locally. All 35 current article sources
are covered, including `bivariate-coscale`, whose ownership transferred to the
Codex lane during this pass.

## Repairs

- `vignettes/meta-analysis.Rmd` now calls `meta_V()` implemented and
  source-tested but ledger-unregistered, without assigning an evidence tier or
  interval-coverage claim.
- `vignettes/bivariate-coscale.Rmd` now states that both predictor-dependent
  and constant `rho12` profile intervals are computed/reportable but not
  coverage-certified. The source no longer calls the constant interval a
  certified reporting target.

The per-article evidence and disposition are in `article-scorecard-second-pass.md`.

## Verification

- `pkgdown::build_site(pkg = ".")` completed after the article scorecard.
- `pkgdown::check_pkgdown(pkg = ".")`: no problems found.
- `tools::checkRd()` parsed all 68 Rd topics.
- Render inventory: 36 article HTML pages and 98 reference HTML pages.
- Git worktree clean at closeout.

## Boundary

This closeout establishes reader-surface consistency and repaired public claim
wording. It does not create new simulation, recovery, coverage, performance,
or CRAN/platform evidence.
