# After Task: Slice 91 Structural-Dependence Reader Route

## Goal

Turn `vignettes/phylogenetic-spatial.Rmd` into a clearer structural-dependence
route: phylogeny first, coordinate spatial dependence second, and
phylogeny-plus-spatial as the planned third endpoint. Keep the fitted/planned
boundary explicit because `drmTMB()` currently rejects simultaneous `phylo()`
and `spatial()` terms in the same `mu` formula.

## Implemented

- Renamed the article and pkgdown navigation label from "Structured
  dependence" to "Structural dependence".
- Added a top-level reader route with the three intended layers:
  phylogeny, spatial, and phylogeny plus spatial.
- Added a conceptual Gaussian equation for a trait such as `heat_tolerance`
  with location predictors, residual-scale predictors, a phylogenetic field,
  and a spatial field:
  `a ~ MVN(0, sigma_phylo^2 A)` and
  `s ~ MVN(0, sigma_space^2 M)`.
- Defined the response, fixed-effect predictors, `A`, `M`,
  `sigma_phylo`, `sigma_space`, and the residual-scale model in words before
  sending readers to syntax.
- Added a route table that marks the first two routes as fitted and the
  combined `phylo()` plus `spatial()` route as planned.
- Added planned combined syntax as a labelled non-runnable example so readers
  can see the intended API without mistaking it for implemented support.
- Updated the coordinate-spatial section so it is the second structural route,
  not an isolated late-page example.
- Updated the final residual-`rho12` distinction so structural covariance
  summaries remain separate from residual response coupling.
- Updated the worked-example inventory to queue the local Methods in Ecology
  and Evolution location-scale heteroscedasticity paper as a future source for
  count and proportion examples after the Gaussian material is stable.

## Mathematical Contract

No parser, likelihood, TMB, extractor, or test surface changed. The tutorial
now teaches the planned endpoint without claiming it is fitted:

```text
current route 1: phylo(1 | species, tree = tree)
current route 2: spatial(1 | site, coords = coords)
planned route 3: phylo(1 | species, tree = tree) + spatial(1 | site, coords = coords)
```

The conceptual combined model is additive in the location predictor:

```text
mu_i = x_i beta_mu + a_species[i] + s_site[i]
a ~ MVN(0, sigma_phylo^2 A)
s ~ MVN(0, sigma_space^2 M)
log(sigma_i) = z_i beta_sigma
```

The report and vignette keep the current implementation boundary aligned with
`R/drmTMB.R`: simultaneous `phylo()` plus `spatial()` in `mu` remains rejected
until multiple structural layers have their own identifiability checks.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-91-structural-dependence-route.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/37-worked-example-inventory.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd vignettes/drmTMB.Rmd _pkgdown.yml`:
  passed.
- `git diff --check`: passed.
- `git diff -- NEWS.md ROADMAP.md _pkgdown.yml docs/design/37-worked-example-inventory.md vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd | LC_ALL=C rg -n '[^\\x00-\\x7F]' || true`:
  returned no matches.
- `pkgdown::build_site()`: passed; rendered
  `articles/phylogenetic-spatial.html`, `articles/model-map.html`,
  `articles/index.html`, `ROADMAP.html`, and `news/index.html`.
- `pkgdown::check_pkgdown()`: passed with "No problems found."
- `rg -n 'Structural dependence|three-step structural-dependence ladder|Phylogeny \\+ spatial|Planned, not fitted yet|simultaneous \`phylo\\(\\)\` plus \`spatial\\(\\)\`|Methods in Ecology and Evolution location-scale paper|phylogeny-plus-spatial' ...`:
  confirmed source and rendered-site evidence for the renamed article, route
  table, planned combined endpoint, NEWS, roadmap, and queued non-Gaussian
  paper source.
- `rg -n 'Only one structured \`mu\` effect|contains both|multiple structured layers|multiple structural \`mu\` layers|simultaneous \`phylo\\(\\)\` plus \`spatial\\(\\)\`' ...`:
  confirmed the code-side rejection message and the tutorial-side planned
  boundary both remain visible.
- `pdfinfo "/Users/z3437171/Desktop/Methods Ecol Evol - 2025 - Nakagawa - Location scale models in ecology and evolution Heteroscedasticity in continuous .pdf"`:
  confirmed the local Methods in Ecology and Evolution paper metadata before
  queuing it for later count/proportion tutorial examples.
- `pdftotext ... | rg -n -i "count|proportion|binomial|Poisson|negative binomial|beta|heteroscedastic|example|aggress|life"`:
  inspected enough of the paper to record count and proportion tutorial
  candidates such as fledgling counts, soil invertebrate abundance, parasite
  counts, and bounded or binomial proportions.

## Tests Of The Tests

No new testthat tests were added because Slice 91 is a tutorial/navigation
change only. The key behavioural check is a consistency check rather than a
new model test: the vignette says the combined `phylo()` plus `spatial()` route
is planned, and `R/drmTMB.R` still contains the rejection path for models that
try to fit both structural layers in the same `mu` formula.

## Consistency Audit

- Ada: the slice stays narrow and closes the reader-route gap without changing
  formulas, likelihoods, or release scope.
- Boole: syntax examples use current `rho12`, `phylo()`, `spatial()`, and
  `corpairs()` vocabulary; the combined syntax is explicitly marked planned.
- Noether: the symbolic equation, route table, and status table agree: `A`
  is the tree-derived covariance, `M` is the coordinate-spatial covariance,
  and `sigma_phylo` plus `sigma_space` are structural SDs, not residual
  `sigma`.
- Darwin: the route now answers recognisable biology: heat tolerance may carry
  phylogenetic species similarity, coordinate site similarity, or both.
- Fisher: the combined model remains future work because it needs
  identifiability checks before two structural `mu` layers can be estimated
  together.
- Pat: the article gives a reader a route through the long page before the
  detailed phylogenetic and spatial examples begin.
- Grace: pkgdown build/check passed and the navigation label now renders as
  "Structural dependence".
- Rose: the non-Gaussian Methods in Ecology and Evolution paper is queued in
  the inventory for later examples rather than being pulled into this PR.

## What Did Not Go Smoothly

One targeted `rg` validation command initially used double quotes around a
pattern containing backticks, which let the shell try to execute `phylo()` and
`spatial()`. The scan was rerun with single quotes and passed cleanly.

## Team Learning

Boole should avoid backticks inside double-quoted shell patterns during
validation. Ada should keep using planned non-runnable code blocks when the
scientific endpoint is important but the fitter intentionally rejects the
syntax.

## Known Limitations

Slice 91 does not implement simultaneous phylogenetic and spatial structural
layers. It does not add mesh/SPDE fitting, bivariate spatial covariance, spatial
`corpair()` regressions, phylogenetic slopes, or non-Gaussian tutorials. The
Methods in Ecology and Evolution heteroscedasticity paper is queued for later
count and proportion examples after the Gaussian tutorial section and Phase 92
gate are closed.

## Next Actions

1. Open and merge the Slice 91 PR after GitHub Actions pass.
2. Run Slice 92 as the tutorial maturation gate: stale-status scan, pkgdown
   check, Rose audit, and phase note.
3. After the Gaussian tutorial gate, start the non-Gaussian tutorial queue one
   surface at a time, using the Methods in Ecology and Evolution paper for
   count and proportion examples.
