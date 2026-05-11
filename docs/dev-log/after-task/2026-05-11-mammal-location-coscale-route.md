# Mammal Location-Coscale Route

## Task Goal

Capture the mammal body mass and litter-size protocol as a concrete
`drmTMB` route without claiming that the full bivariate phylogenetic
location-scale model is already runnable.

## Files Changed

- `docs/design/29-mammal-location-coscale-route.md`: added the protocol-to-
  package map, current implementation boundary, correlation naming rules, and
  staged implementation route.
- `docs/design/15-location-coscale-phylogenetic-extension.md`: pointed the
  existing mammal example to the new route note.
- `ROADMAP.md`: linked Phase 11 bivariate covariance work to the mammal route.
- `docs/dev-log/check-log.md`: recorded the checks for this documentation
  slice.

## Checks Run

- `pdftotext /Users/z3437171/Downloads/Mammalian_location_co_scale_trade_offs.pdf - | rg -n "Objective|Model|Stage|location-scale|phylogenetic|non-phylogenetic|rho|correlation|lifestyle|sigma|residual|MCMCglmm|Stan|Upham|50|posterior|H\\^?2|heritability|scale" -C 2`: confirmed the three protocol objectives, covariance targets, lifestyle-specific covariance plan, and 50-tree posterior-pooling language.
- `gh issue view 5 --repo itchyshin/drmTMB --json number,title,body,comments,url`: confirmed issue #5 already frames covariance blocks as the long-term individual-difference endpoint and that PR #11 is only a documentation clarity slice.
- `rg -n "docs/design|design/28|design/20|location-coscale|double-hierarchical" README.md ROADMAP.md _pkgdown.yml docs vignettes`: checked the local design-link pattern before adding the new route reference.
- `rg -n "phylo\\(" R/drmTMB.R R/parse-formula.R tests/testthat/test-phylo-gaussian.R vignettes/phylogenetic-spatial.Rmd docs/design/01-formula-grammar.md`: confirmed the implemented boundary for univariate `phylo(1 | species, tree = tree)` in `mu` and planned structured extensions.
- `air format ROADMAP.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/29-mammal-location-coscale-route.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-mammal-location-coscale-route.md`: completed.
- `git diff --check`: clean.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|phylo-gaussian|corpairs')"`: 168 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `rg -n "Mammal Location-Coscale Route|29-mammal-location-coscale-route|mammal body mass|body mass-litter size route|tree-loop|posterior pooling|full model is runnable|full protocol" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests _pkgdown.yml --glob '!docs/dev-log/after-task/**'`: confirmed the new route is linked only from the roadmap and the existing location-coscale design note, and that the new note keeps posterior pooling outside the implemented maximum-likelihood surface.
- `rg -n "rho ~|meta_gaussian\\(|tau ~|meta_known_V\\([^V]|rho12.*phylogenetic|phylogenetic.*rho12" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests _pkgdown.yml --glob '!docs/dev-log/after-task/**'`: found only intentional guardrails and existing statements that residual `rho12` remains separate from phylogenetic, spatial, or species-level correlations.
- `rg -n "Objective 1|Objective 2|Objective 3|implemented|planned|rho12|rho_a|rho_e|Sigma_a|Sigma_e|sigma1|sigma2" docs/design/29-mammal-location-coscale-route.md`: checked that the new equations, R syntax, status table, and naming rules preserve the implemented-versus-planned boundary.

## Consistency Audit

The new note keeps `rho12` restricted to residual bivariate correlation and
uses level-specific wording for phylogenetic and non-phylogenetic species
correlations. It does not add a new family, change formula grammar, or change
likelihood parameterization.

## Tests Of The Tests

No R tests were added because this is a design and roadmap slice. The important
test for this task is whether the note separates runnable scouting models from
planned covariance models; the route table records that boundary explicitly.

## What Did Not Go Smoothly

The existing repository already mentioned the mammal protocol in the broader
location-coscale design note. The useful work was therefore not another broad
aspirational paragraph, but a narrower protocol-to-milestone map with explicit
"safe use now" and "planned" rows.

## Team Learning And Process Improvements

For paper-driven feature requests, first write the scientific model targets as
named covariance layers, then map each layer to current parser, likelihood,
extractor, and diagnostic status. That prevents residual `rho12` from being
treated as a substitute for phylogenetic or species-level covariance.

## Design-Doc Updates

Added `docs/design/29-mammal-location-coscale-route.md` and linked it from the
existing location-coscale phylogenetic extension note and Phase 11 roadmap.

## Pkgdown And Documentation Updates

No pkgdown navigation change was made because the new file is an internal
design note, not a user-facing article or reference topic.

## Known Limitations And Next Actions

The next implementation slice should be bivariate Gaussian species-level
covariance for `mu1` and `mu2`, with simulation recovery and `corpairs()` rows
that keep species-level mean-mean correlation distinct from residual `rho12`.
The full protocol still needs bivariate phylogenetic covariance,
non-phylogenetic species covariance, phylogenetic scale effects, and a separate
decision about tree-loop sensitivity versus Bayesian posterior pooling.
