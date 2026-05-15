# After Task: Slice 34 Structured-Dependence Productization

## Goal

Make the implemented phylogenetic and coordinate-spatial structured-effect
surface easier to understand from the website, without adding new likelihood
features or claiming that mesh/SPDE, spatial q=4, or spatial correlation
regression are fitted.

## Implemented

- Added a runnable coordinate-spatial example to
  `vignettes/phylogenetic-spatial.Rmd`.
- Showed the three first outputs a user should inspect after the spatial fit:
  `fit_spatial$sdpars$mu`, `ranef(fit_spatial, "spatial_mu")`, and the
  profile-ready `sd:mu:spatial(1 | site)` target.
- Updated the article introduction so phylogenetic and spatial structured
  effects are described as sibling fitted foundations: phylogenetic `mu` /
  bivariate/q4 paths, and coordinate-spatial univariate Gaussian `mu`.
- Updated `vignettes/model-map.Rmd` so the first-page model table includes
  `spatial(1 | site, coords = coords)`, and so the correlation-layer table
  does not call spatial correlations fitted before they exist.
- Updated `docs/design/01-formula-grammar.md` so `coords` is the implemented
  spatial syntax and `mesh` is the planned scalable SPDE/GMRF syntax.
- Updated `README.md` and `ROADMAP.md`; Phase 18 now appears in the roadmap
  release-boundary summary as well as in its own section.
- Rebuilt local pkgdown output for review. `pkgdown-site/` remains ignored, so
  deployment still depends on the GitHub pkgdown workflow after push.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- this after-task report

## Checks Run

- `air format` on the changed source files: passed.
- Spatial example smoke check: passed and printed the expected spatial SD,
  `spatial_mu` random effects, and profile-ready spatial SD target.
- Focused tests:
  `devtools::test(filter = "spatial-gaussian|package-skeleton", reporter =
  "summary")`: passed.
- Targeted article build for `phylogenetic-spatial` and `model-map`: passed.
- Full `pkgdown::build_site()`: passed and refreshed local ROADMAP,
  model-map, and structured-dependence pages.
- `pkgdown::check_pkgdown()`: passed with no problems found.
- Rendered-output scan confirmed Phase 18 and the new spatial-example text in
  `pkgdown-site`.
- Stale wording scan found no remaining claims that `coords` spatial syntax is
  merely planned or rejected.
- `git diff --check`: passed.

## Consistency Audit

Source prose, design grammar, README, model-map, structured-dependence article,
local pkgdown pages, and the check log now agree on the fitted/planned split:
coordinate-spatial `mu` is fitted for univariate Gaussian models; mesh/SPDE,
spatial scale, bivariate spatial covariance, spatial direct-SD, and spatial
`corpair()` regressions remain planned.

## What Did Not Go Smoothly

The public ROADMAP page can make Phase 18 look absent if the reader is on the
deployed site before the latest pkgdown workflow has run, or if they stop above
the Phase 18 heading. The local build does contain Phase 18. The release-boundary
summary now points to it earlier so it is harder to miss.

## Team Learning

- Ada: productization slices still need a real check gate, not just prose
  edits.
- Boole: keep `coords` and `mesh` in one grammar section, but name one as
  fitted and the other as planned.
- Gauss: a tiny article fit is a useful smoke check when a tutorial starts
  executing fitted spatial code.
- Noether: keep covariance, precision, and SD wording separate in examples;
  the spatial SD is not residual `sigma`.
- Darwin: spatial examples need a concrete ecological question later, but this
  slice needed clarity and runnable mechanics first.
- Fisher: profile-ready spatial SD targets can be shown, but uncertainty for
  spatial fields and maps is still future work.
- Pat: readers need to see what to inspect immediately after fitting:
  `sdpars`, `ranef()`, and `profile_targets()`.
- Emmy: article helpers should avoid introducing new exported APIs while still
  making examples reproducible.
- Grace: rebuild the full site for roadmap visibility, because article-only
  builds do not prove `ROADMAP.html` is refreshed.
- Rose: the repeated drift pattern is "spatial planned" wording surviving after
  the first coordinate path became fitted; keep stale-wording scans in every
  spatial slice.

## Known Limitations

- This slice did not add new fitted model classes.
- Local `pkgdown-site/` output is ignored by git; public deployment must come
  from the GitHub pkgdown workflow.
- Phase 18 remains a roadmap/design phase. No visualization helper was added.

## Next Actions

1. Continue to Slice 35: full after-phase audit, release-readiness review, and
   final stale-wording scan.
2. Decide whether the first post-35 spatial implementation should harden
   coordinate diagnostics or start the mesh/SPDE design contract.
3. Keep visualization helper design in Phase 18 separate from spatial feature
   work until the data contract is clear across `predict_parameters()`,
   `marginal_parameters()`, `corpairs()`, and profile intervals.
