# After Task: Phase 18 Tweedie Fixed-Effect And Skew-Normal Source Map

## Goal

Resume the overnight two-lane Phase 18 work and close one fitted Tweedie lane
plus one design-only shape/skewness lane without turning neighbouring random
effects, structured effects, bivariate routes, zero-inflation aliases, or
hurdle aliases into fitted claims.

## Implemented

The fitted claim is narrow: `tweedie()` now supports one-response fixed-effect
models for non-negative semicontinuous responses with exact zeros and positive
continuous values. The supported syntax is:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The shape lane is not fitted code. It adds
`docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md` as a
source map for a future `skew_normal()` implementation and a boundary test that
keeps `skew_normal()` absent from the namespace.

## Mathematical Contract

The Tweedie route uses:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
nu_i = 1 + plogis(eta_nu_i)
phi_i = sigma_i^2
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The TMB branch evaluates `dtweedie(y_i, mu_i, phi_i, nu_i, true)`, so the
likelihood is not just the mean-variance relationship. `fitted()` returns
`mu`, `sigma()` returns public `sigma`, and comparator work against software
that reports Tweedie dispersion must compare `sigma^2` to `phi`.

## Files Changed

Main implementation files:

- `R/family.R`
- `R/drmTMB.R`
- `R/methods.R`
- `R/predict-parameters.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-tweedie-location-scale.R`
- `tests/testthat/test-skew-normal-boundary.R`
- `tests/testthat/test-family-link-contract.R`

Main documentation and ledger files:

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/design/27-tweedie-family-plan.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/122-tweedie-scale-preflight.md`
- `docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md`
- `docs/design/124-phase-18-overnight-two-lane-slices-1419-1618.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

```sh
air format NEWS.md README.md ROADMAP.md _pkgdown.yml R/drmTMB.R R/family.R R/methods.R R/predict-parameters.R tests/testthat/test-family-link-contract.R tests/testthat/test-tweedie-location-scale.R tests/testthat/test-skew-normal-boundary.R docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/06-distribution-roadmap.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/122-tweedie-scale-preflight.md docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md docs/design/124-phase-18-overnight-two-lane-slices-1419-1618.md docs/design/19-family-link-contract.md docs/design/27-tweedie-family-plan.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd vignettes/source-map.Rmd vignettes/implementation-map.Rmd vignettes/model-map.Rmd vignettes/which-scale.Rmd
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|skew-normal-boundary|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "devtools::check()"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
git diff --check
```

Results:

- Focused tests passed.
- Full package tests passed.
- `pkgdown::check_pkgdown()` reported no problems.
- First `devtools::check()` failed because the skew-normal test tried to read a
  source-tree design document from the installed-package check directory.
- After adding a `skip_if_not(file.exists(source_map))` guard for the design-doc
  text assertion, `devtools::check()` passed with 0 errors, 0 warnings, and
  1 NOTE: `unable to verify current time`.
- `pkgdown::build_site(preview = FALSE)` rendered `reference/tweedie.html` and
  the edited articles.
- `git diff --check` was clean.

Before publishing the branch for follow-on two-team work, the publish gate was
rerun on 2026-05-28:

```sh
git diff --check
gh issue list --repo itchyshin/drmTMB --state open --search "Tweedie OR skew-normal OR skew_normal" --limit 20 --json number,title,state,url,labels
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|skew-normal-boundary|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "devtools::check()"
```

That rerun passed focused tests, full tests, and `pkgdown::check_pkgdown()`.
`devtools::check()` completed in 7m 43.4s with 0 errors, 0 warnings, and
1 NOTE: `unable to verify current time`.

## Tests Of The Tests

The Tweedie tests exercise recovery under ordinary, high-zero, and low-zero
simulated data, compare `fitted()`, `sigma()`, `predict(dpar = "nu")`,
simulation, and Pearson residuals to the documented public scale, and assert
that unsupported random effects, predictor-dependent `nu`, `zi`, `hu`,
`meta_V(V = V)`, `mvbind()`, and `sd(group)` neighbours fail before TMB.

The skew-normal test checks the namespace boundary and the source-map wording
when the source tree is available, while skipping only the source-map text read
under installed-package `R CMD check`.

## Consistency Audit

The source stale scan checked for current text saying Tweedie is still not
fitted:

```sh
rg -n "Tweedie[^\n]*(not fitted|not implemented|future-only|does not currently fit|no Tweedie likelihood|planned, not fitted)|not fitted[^\n]*Tweedie|not implemented[^\n]*Tweedie|does not currently fit Tweedie|No Tweedie likelihood" README.md NEWS.md ROADMAP.md docs/design vignettes R man _pkgdown.yml -g '!*.html'
```

The rendered-site scan repeated the same search under `pkgdown-site` after
`pkgdown::build_site(preview = FALSE)`. Both scans were clean for current
Tweedie status. The rendered positive-evidence scan found `reference/tweedie.html`,
the reference index entry, the distribution-family article, formula grammar,
implementation map, source map, README homepage, NEWS, and ROADMAP entries.

The skew-normal scans checked that the new source map did not claim fitted
support:

```sh
rg -n 'skew_normal\(\).*now fits|skew-normal.*implemented|skew-normal.*fitted route|skew_normal.*Implemented' README.md NEWS.md ROADMAP.md docs/design vignettes tests/testthat R man -g '!*.html'
rg -n 'skew_normal\(\).*now fits|skew-normal.*implemented|skew-normal.*fitted route|skew_normal.*Implemented' pkgdown-site -g '*.html'
```

The only source hit outside the new source map was the intended older
"once implemented" naming guidance in `docs/design/14-gamlss-parameter-names.md`;
the rendered scan was clean.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search "Tweedie OR skew-normal OR skew_normal" --limit 20 --json number,title,state,url,labels`
found:

- #2, "Add Tweedie family for non-negative semicontinuous eco-evo data"
- #3, "Add skew-normal location-scale-shape family"

No duplicate issue was opened. The eventual PR should reference #2 for the
first fitted Tweedie slice and #3 for the skew-normal source-map gate if both
lanes stay together.

## What Did Not Go Smoothly

The first `R CMD check` failure was useful: a test that passes in the source
tree can fail in installed-package checks if it assumes `docs/design` is
installed. Future design-doc boundary tests should either keep the assertion in
source-only validation or skip the source text read when the source map is not
available.

The branch also combines a fitted family lane and a design-only shape lane.
That matches the overnight two-team exercise, but the pull-request boundary
still needs care; small reviewable PRs are preferable if the owner wants these
lanes split.

## Team Learning

- Ada: keep the two-lane story explicit, but make the PR boundary decision
  before publishing.
- Boole: when adding a family, update formula grammar and the reference index in
  the same slice as the constructor.
- Gauss and Noether: TMB likelihood reviews should record the public scale,
  internal scale, inverse link, and simulation scale together.
- Curie: design-doc tests need installed-package behaviour in mind.
- Fisher: deterministic recovery tests are enough for first admission, but not
  enough for coverage claims.
- Pat and Darwin: the fitted user story is biomass, cover, CPUE-like indices,
  and similar non-negative semicontinuous measurements, not generic extra-zero
  modelling.
- Grace: run `devtools::check()` before closeout for new exported families,
  because source-tree tests can miss packaging assumptions.
- Rose: record first-failure evidence instead of smoothing it out of the
  history.

No spawned subagents were running.

## Known Limitations

- Tweedie `nu` is intercept-only in this first slice.
- Tweedie random effects, predictor-dependent `nu`, structured effects,
  bivariate or mixed-response Tweedie, zero-inflation aliases, and hurdle
  aliases remain planned.
- No external comparator test against `glmmTMB::tweedie(link = "log")` has
  landed yet.
- Skew-normal remains design-only; no `skew_normal()` constructor, likelihood,
  extractor, simulation, or comparator path was added.
- The local `devtools::check()` result still has one environmental NOTE:
  `unable to verify current time`.

## Next Actions

1. Decide whether to publish one two-lane PR or split Tweedie fixed-effect
   admission and skew-normal source mapping into separate PRs.
2. If Tweedie stays first, add a small external comparator check against
   `glmmTMB::tweedie(link = "log")` with `sigma^2` compared to `phi`.
3. For skew-normal, keep the next task design-only until the parameterization,
   density comparator, fitted-value semantics, and recovery tests are accepted
   together.
