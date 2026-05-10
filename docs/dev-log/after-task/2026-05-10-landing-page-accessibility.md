# Landing Page Accessibility Pass

Date: 2026-05-10

Reader: an applied ecology, evolution, or environmental-science user arriving
at the pkgdown home page and deciding where to start.

## Goal

Make the landing page a short orientation page rather than a combined tutorial,
family registry, formula guide, and roadmap. The page should answer three
questions quickly: what `drmTMB` is for, whether it can fit the user's broad
model type, and which article to open next.

## Review Input

Pat reviewed the home page from the new-user perspective. The main finding was
that the previous README introduced too many parameters, families, equations,
and planned features before giving the reader a concrete path. The recommended
structure was one overview, one Gaussian location-scale example, a compact
capability table, article links, and brief limitations.

## Changes

- Rewrote `README.md` from a reference-style catalogue into a 94-line landing
  page.
- Kept one symbolic-equation/R-syntax pairing: the Gaussian location-scale
  model `drm_formula(y ~ x1, sigma ~ x1)`.
- Replaced long family-by-family prose with a compact table keyed by user
  questions, response type, main syntax, and the next article to read.
- Linked users outward to getting started, response-family choice, scale
  interpretation, model checking, bivariate `rho12`, meta-analysis, and
  phylogenetic/spatial articles.
- Kept current boundaries visible: one/two responses only, non-Gaussian random
  effects mostly planned, residual `rho12` is not group-level covariance, and
  double-hierarchical individual-difference covariance remains planned work.
- Preserved the public `sigma` convention and explained that variance-facing
  summaries should use derived `sigma^2`.

## Validation

- `Rscript -e "pkgdown::build_site()"`: passed and rendered the shorter
  `pkgdown-site/index.html`.
- `Rscript -e "pkgdown::build_home()"`: passed after the final table-syntax
  polish.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- Rendered HTML was inspected for the main anchors, article links, and the
  displayed `phylo(1 | species, tree = tree)` syntax.

## Remaining Limitations

This was a content-accessibility and information-architecture pass, not a full
screen-reader or keyboard-navigation audit. A future visual QA pass should
inspect the published page in desktop and mobile viewports after deployment.
