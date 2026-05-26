# After Task: Phylogenetic Direct-SD and Corpair Combination

## Goal

Allow the fitted bivariate Gaussian q=2 phylogenetic direct-SD route to combine
response-specific phylogenetic SD surfaces with a predictor-dependent
phylogenetic `corpair()` regression:

```r
bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1,
  sd1(species, level = "phylogenetic") ~ z_species,
  sd2(species, level = "phylogenetic") ~ z_species,
  corpair(species, level = "phylogenetic", block = "p",
    from = "mu1", to = "mu2"
  ) ~ z_species
)
```

The same slice migrates new user-facing examples from `sd_phylo*()` to
`sd*(_, level = "phylogenetic")` while keeping the old names as deprecated
compatibility aliases.

## Implemented

- Added parser support for `level = "phylogenetic"` on `sd()`, `sd1()`, and
  `sd2()` direct-SD formula left-hand sides.
- Deprecated `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` during formula
  parsing while preserving their fitted likelihood route.
- Removed the previous builder guard that rejected phylogenetic `corpair()`
  regression beside bivariate phylogenetic direct-SD formulas.
- Updated the TMB bivariate phylogenetic q=2 branch so species-specific
  direct-SD values multiply the same two-field `corpair()` loading transform
  used for predictor-dependent phylogenetic correlations.
- Updated `ranef()`-side transformation code so extracted bivariate
  phylogenetic random effects use the same direct-SD plus `corpair()` transform
  as the likelihood.
- Kept `level = "spatial"`, `level = "animal"`, and `level = "relmat"` direct-SD
  formulas as planned-but-not-implemented parser routes.
- Updated formula grammar, likelihood, direct-SD, correlation-pair, readiness,
  source-map, roadmap, NEWS, reference, and phylogenetic tutorial prose.

## Mathematical Contract

For each observed species `l`, the direct-SD formulas define
`tau1_l = exp(W1_l alpha1)` and `tau2_l = exp(W2_l alpha2)`. The
phylogenetic `corpair()` formula defines
`rho_l = 0.999999 * tanh(Wrho_l gamma)`. Two independent unit tree fields
`z1` and `z2` are transformed as

```text
a1_l = tau1_l * (sqrt((1 + rho_l) / 2) * z1_l +
                  sqrt((1 - rho_l) / 2) * z2_l)
a2_l = tau2_l * (sqrt((1 + rho_l) / 2) * z1_l -
                  sqrt((1 - rho_l) / 2) * z2_l)
```

This gives a positive-definite same-species loading contract for the fitted
q=2 location-location route. It is still Family B direct-SD modelling of
phylogenetic location effects, not residual `sigma1`/`sigma2`, not residual
`rho12`, and not a q=4 location-scale covariance model.

## Files Changed

This lane owns changes in:

- `R/drmTMB.R`
- `R/parse-formula.R`
- `R/random-effect-scale-formulas.R`
- `R/methods.R`
- `R/check.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-check-drm.R`
- `tests/testthat/test-control.R`
- `tests/testthat/test-profile-targets.R`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `vignettes/phylogenetic-models.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `vignettes/which-scale.Rmd`
- generated Rd files for the touched roxygen topics.

The branch also had pre-existing dirty NB2 Phase 18, logo, and simulation
artifact work. Those files were not reverted; overlapping status docs were
edited only where this direct-SD/correlation wording needed synchronization.

## Checks Run

```sh
air format R/drmTMB.R R/parse-formula.R R/random-effect-scale-formulas.R R/methods.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-biv-gaussian.R tests/testthat/test-check-drm.R tests/testthat/test-control.R tests/testthat/test-profile-targets.R README.md ROADMAP.md NEWS.md docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md docs/design/20-coscale-correlation-pairs.md vignettes/which-scale.Rmd vignettes/phylogenetic-spatial.Rmd
air format R/check.R docs/design/46-pre-simulation-readiness-matrix.md docs/design/59-structural-slope-and-non-gaussian-map.md
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'phylo-gaussian', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'profile-targets|biv-gaussian|check-drm|control', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale|gaussian-location-scale', reporter = 'summary')"
Rscript -e "devtools::test(filter = 'phylo-gaussian|profile-targets|biv-gaussian|check-drm|control|gaussian-random-effect-scale|gaussian-location-scale', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site(preview = FALSE)"
rg -n 'Do not combine phylogenetic .*corpair.*sd_phylo|current implemented.*sd_phylo|sd_phylo\(species\) ~|sd_phylo1\(species\) ~|sd_phylo2\(species\) ~|direct `sd_phylo|`sd_phylo\(species\)` \| Implemented|direct `sd_phylo\*\(\)`' README.md ROADMAP.md NEWS.md docs/design vignettes R man pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html pkgdown-site/articles pkgdown-site/reference -g '!*.json'
rg -n 'sd\(species, level = "phylogenetic"\)|sd1\(species, level = "phylogenetic"\)|sd2\(species, level = "phylogenetic"\)|deprecated `sd_phylo|deprecated compatibility|compatibility alias' R/check.R man/check_drm.Rd docs/design/46-pre-simulation-readiness-matrix.md docs/design/59-structural-slope-and-non-gaussian-map.md pkgdown-site/reference/check_drm.html pkgdown-site/ROADMAP.html pkgdown-site/articles/phylogenetic-models.html
gh issue list --repo itchyshin/drmTMB --state open --search "sd_phylo corpair" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "direct-SD corpair" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "level phylogenetic sd" --limit 20 --json number,title,state,url,labels
git diff --check
Rscript -e "devtools::check(error_on = 'never')"
```

- The focused phylogenetic, profile-target, bivariate, diagnostic, control, and
  Gaussian direct-SD/location-scale tests passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(preview = FALSE)` completed and rebuilt the changed
  reference and article pages.
- `git diff --check` was clean.
- `devtools::check(error_on = "never")` completed in 5m35.3s with 0 errors,
  0 warnings, and 0 notes.

## Tests Of The Tests

The new combined-model test simulates species-specific `tau1`, `tau2`, and
`rho_phylo` surfaces, fits the direct-SD plus `corpair()` route, checks
optimizer convergence and a small maximum gradient, verifies the expected
coefficient directions, checks positive fitted SD surfaces, and verifies that
`summary()$covariance` points to the direct-SD median rows. A separate
deprecated-spelling fit test now proves `sd_phylo(species)` remains a fitted
alias, not merely a parser warning.

## Consistency Audit

The status pages now separate four states:

- preferred fitted syntax: `sd(..., level = "phylogenetic")`,
  `sd1(..., level = "phylogenetic")`, and
  `sd2(..., level = "phylogenetic")`;
- deprecated compatibility spellings: `sd_phylo()`, `sd_phylo1()`, and
  `sd_phylo2()`;
- the newly fitted bivariate q=2 combination with phylogenetic `corpair()`;
- still-planned neighbours: q=4 predictor-dependent phylogenetic correlation,
  direct-SD formulas with structured `sigma`, spatial/animal/`relmat`
  direct-SD levels, and non-Gaussian structured direct-SD routes.

The stale-wording scan still finds old spelling examples only when they are
explicitly described as deprecated compatibility. It found no remaining source
or rendered claim that users should prefer `sd_phylo*()` as the current primary
interface, and no remaining guard text saying phylogenetic `corpair()` cannot
combine with bivariate direct-SD surfaces.

## GitHub Issue Maintenance

Open-issue searches for `sd_phylo corpair`, `direct-SD corpair`, and
`level phylogenetic sd` surfaced broad issues #31, #5, #147, and #58, but no
single direct issue for this exact syntax/likelihood combination. I did not
comment on or close a broad issue from this dirty local branch; the repository
check-log and this after-task report record the implemented slice.

## What Did Not Go Smoothly

The first deprecated-alias fit test assigned the return value of
`expect_warning()` to `form`, so `drmTMB()` received an expectation object rather
than a `bf()` formula. The failing focused test caught the mistake immediately.
The test now assigns inside `expect_warning()`, and the lesson is recorded in
`docs/dev-log/team-improvements.md`.

## Team Learning

Ada kept the slice anchored to the checkpoint goal rather than the adjacent NB2
work. Boole checked the `sd*(_, level = "phylogenetic")` grammar and reserved
future levels. Gauss and Noether checked that the R-side random-effect
transform matches the C++ likelihood transform. Fisher checked the recovery
test target and boundary wording. Pat checked that deprecated spellings still
tell users what to use next. Grace ran focused tests, pkgdown, and full
`devtools::check()`. Rose added the stale-wording and compatibility-test
process note. These were role perspectives, not spawned agents.

## Known Limitations

This does not implement spatial, animal-model, or `relmat()` direct-SD
surfaces. It does not implement predictor-dependent q=4 phylogenetic
location-scale or scale-scale correlations. It does not allow direct-SD
formulas to target residual-scale structured effects. It does not change the
non-Gaussian structured direct-SD boundary.

## Next Actions

The next narrow modelling slice should either run a recovery grid for this
combined bivariate phylogenetic q=2 route, or open the corresponding
level-based direct-SD design for the next structured source only after its
likelihood, parser boundaries, documentation, and simulation tests are scoped.
