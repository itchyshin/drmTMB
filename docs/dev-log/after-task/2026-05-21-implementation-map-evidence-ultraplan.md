# After Task: Implementation Map Evidence Ultraplan

## Goal

Implement the documentation and evidence-map plan without opening new
likelihood surfaces: make the pkgdown maps, validation ledger, source map,
roxygen docs, roadmap, check log, and team process agree on random intercepts,
random slopes, q, interval status, simulation evidence, and fitted-versus-
planned boundaries.

## Implemented

The implementation map now has a source-of-truth hierarchy, evidence
dimensions, simulation tiers, interval tiers, and a current capability table
that separates fitted support from inference support. The model map now starts
with scientific question, fitted syntax, interpretation, and planned neighbour.
The source map now names the coordinate-spatial q=2 and q=4 source/test/doc
route explicitly.

The validation-debt register now splits spatial univariate `mu`, spatial q=2,
spatial q=4, animal `mu`, animal q=2/q=4, `relmat()` `mu`, and `relmat()`
q=2/q=4 rows. Spatial q4 is marked as fitted extractor/diagnostic smoke, not
formal operating-characteristic or coverage evidence. q=4 correlations remain
derived-unavailable for intervals.

## Mathematical Contract

No likelihood, formula grammar, or fitted parameterization changed. The fitted
claim remains:

```text
constant coordinate-spatial q=4 =
  structured intercept endpoints for mu1, mu2, sigma1, sigma2
  with four endpoint SDs and six derived latent correlations.
```

That is not a bivariate spatial slope model, not standalone spatial `sigma`,
not spatial `corpair()` regression, and not non-Gaussian structured
dependence. Direct profile-ready means a target can be attempted; it does not
mean profile-proven in every dataset.

## Files Changed

- `R/check.R`, `R/methods.R`, `man/check_drm.Rd`, `man/corpairs.Rd`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `vignettes/implementation-map.Rmd`, `vignettes/model-map.Rmd`,
  `vignettes/source-map.Rmd`
- `docs/design/02-family-registry.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/37-worked-example-inventory.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/56-phase-18-spatial-q2-ademp.md`,
  `docs/design/65-implementation-map-slices-341-355.md`
- `docs/dev-log/team-improvements.md`

## Checks Run

```sh
air format R/check.R R/methods.R README.md NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/design/37-worked-example-inventory.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/56-phase-18-spatial-q2-ademp.md docs/design/65-implementation-map-slices-341-355.md docs/dev-log/team-improvements.md vignettes/implementation-map.Rmd vignettes/model-map.Rmd vignettes/source-map.Rmd
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'check-drm|corpairs|profile-targets|spatial-gaussian', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "devtools::check()"
rg -n 'How to read the project maps|Current capability and evidence map|Smoke/artifact only|q=4 spatial correlations are derived-only|extractor/diagnostic smoke|The map hierarchy is' pkgdown-site/articles/implementation-map.html pkgdown-site/articles/model-map.html pkgdown-site/articles/source-map.html pkgdown-site/reference/corpairs.html pkgdown-site/reference/check_drm.html pkgdown-site/ROADMAP.html pkgdown-site/index.html -S
rg -n 'behind that q=2 gate|spatial q4.*stay|spatial q=4.*stay|q4 spatial blocks|spatial q=4 blocks remain planned|spatial q4.*planned but not implemented' README.md ROADMAP.md docs/design vignettes R tests/testthat pkgdown-site/articles pkgdown-site/reference pkgdown-site/ROADMAP.html pkgdown-site/index.html -S
gh issue list --search "implementation map OR spatial q4 OR validation debt OR source map" --limit 20
```

Results: targeted tests and the full `devtools::test(reporter = "summary")`
suite passed, `git diff --check` passed, `pkgdown::check_pkgdown()` reported no
problems, `pkgdown::build_site()` completed, and `devtools::check()` passed in
4m53s with 0 errors, 0 warnings, and 0 notes. Rendered scans found the new map
hierarchy and evidence-tier wording. The stale-current-status scan returned no
hits in current docs or rendered current pages; older NEWS entries that were
true for previous releases were left historical.

## Tests Of The Tests

This was a documentation/evidence reconciliation slice. The targeted tests were
not expected to fail before the edit, but they protect the roxygen-described
surfaces: `check_drm()`, `corpairs()`, `profile_targets()`, and
coordinate-spatial Gaussian fits still run after documentation regeneration.

## Consistency Audit

Ada kept the slice to maps, ledgers, and documentation. Boole checked that no
new syntax was implied. Gauss and Noether kept q=4 spatial as an intercept-only
Gaussian location-scale block. Fisher separated Wald, direct profile,
profile-proven, derived-unavailable, and private bootstrap evidence. Curie kept
simulation admission distinct from smoke artifacts. Pat and Darwin moved the
model map toward question-first user routing. Emmy restored extractor/API
accountability for `corpairs()`, `summary()$covariance`, `profile_targets()`,
`check_drm()`, `ranef()`, `sdpars`, and `corpars`. Grace verified pkgdown.
Rose patched stale q2-gate wording and recorded the authority-hierarchy process
improvement.

## GitHub Issue Maintenance

`gh issue list --search "implementation map OR spatial q4 OR validation debt OR source map" --limit 20`
found existing open issues including #5, #31, #33, #57, #61, and #147. No new
issue was opened because this slice reconciles current docs and ledgers rather
than starting a new implementation lane. Future modelling work should continue
under #5 for covariance blocks, #33 for random slopes, and #147 for
animal/`relmat()` relatedness.

## What Did Not Go Smoothly

The first stale wording scan showed why exact phrase scans are too brittle:
the problem was not only "planned but not implemented", but wording like
"behind that q=2 gate". The team-improvement log now records evidence tiers
and map authority as a process rule.

## Team Learning

Map pages should not become slice diaries. Keep the public pages focused on
choosing and interpreting fitted routes, and keep the long historical sequence
in ROADMAP and design ledgers. Every fitted first slice should carry an
evidence tier so users can tell whether a row is routine, smoke-only,
interval-heavy, diagnostic, or planned.

## Known Limitations

This slice does not add q=4 recovery grids, derived q=4 intervals, generic
`sd*()` syntax, p8/q8 endpoints, non-Gaussian structured dependence, `zi`/`hu`
random effects, or new examples beyond map/source/ledger routing.

## Next Actions

The next implementation slice should choose between generic `sd*()` direct-SD
pre-code work, p8/q8 endpoint planning, or the Poisson q1 structured `mu`
intercept gate. Spatial q4 should receive a q=4-specific DGP and recovery
artifact before it is promoted beyond extractor/diagnostic smoke.
