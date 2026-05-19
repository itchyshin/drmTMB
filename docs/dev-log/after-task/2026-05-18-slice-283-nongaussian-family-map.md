# After Task: Slice 283 Non-Gaussian Family Map

## Goal

List every current public family route with its distributional parameters,
links, shape or coscale slot, fitted random-effect allowance, and local
test-evidence state before the next count, proportion, shape, ordinal, and
mixed-response hardening slices.

## Implemented

`docs/design/02-family-registry.md` now has a Slice 283 family-and-evidence
map. It covers Gaussian, Student-t, lognormal, Gamma, beta, beta-binomial,
Poisson, zero-inflated Poisson, NB2, zero-inflated NB2, truncated NB2, hurdle
NB2, cumulative-logit ordinal, all-Gaussian bivariate, and planned
skew-normal/Tweedie rows. The map is explicitly an audit, not new grammar.

The slice also corrected stale status wording:

- beta-binomial is fixed-effect only, with `mu`, `sigma`, `zoi`, and `coi`
  random effects still blocked;
- Poisson and NB2 ordinary non-zero-inflated `mu` random intercepts and
  independent numeric slopes are the fitted non-Gaussian random-effect paths;
- bivariate Gaussian fits have selected labelled random-intercept covariance
  blocks, while bivariate random slopes remain planned;
- current source-map, tutorial-style, and family-chooser prose now lead with
  preferred `meta_V(V = V)` and keep `meta_known_V(V = V)` as a compatibility
  alias.

## Mathematical Contract

No likelihood, formula grammar, or TMB parameterization changed. The audited
contract is that one-response non-Gaussian families keep fixed-effect
distributional-parameter formulas unless a row explicitly names a fitted
ordinary `mu` random-effect route. The only current non-Gaussian mixed-model
routes are non-zero-inflated Poisson and NB2 `mu` random intercepts and
independent numeric slopes. `rho12` remains the all-Gaussian bivariate
residual coscale, not a group, phylogenetic, spatial, animal, or `relmat()`
correlation.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/02-family-registry.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/source-map.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/distribution-families.Rmd`
- `air format docs/design/21-tutorial-style.md`
- `air format vignettes/source-map.Rmd`
- `Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/distribution-families.Rmd", output_dir = tempfile("distribution-families-render-"), quiet = FALSE)'`
- `Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/source-map.Rmd", output_dir = tempfile("source-map-render-"), quiet = FALSE)'`
- `Rscript -e "devtools::test(filter = 'family-link-contract|poisson-mean|nbinom2-location-scale|beta-binomial', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|phase18-nbinom2-mu-random-effect', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`, twice after the final source-map edit; both runs reported no problems.
- `git diff --check`

## Tests Of The Tests

No new executable tests were added because this slice only audits and
synchronizes documentation. The targeted test pass still exercised the
evidence named in the map: family-link helpers, beta-binomial fixed-effect
behaviour and malformed inputs, Poisson and NB2 ordinary `mu` random effects,
and the Phase 18 Poisson/NB2 smoke surfaces with Wald/profile evidence rows.

## Consistency Audit

Exact searches used:

```sh
rg -n 'beta-binomial.*ordinary|beta_binomial\(\).*ordinary|beta-binomial.*random intercept|beta-binomial.*independent numeric|Bivariate random effects are planned but not implemented|Meta-analysis: Gaussian regression with `meta_known_V\(V = V\)`|meta-analysis.*with `meta_known_V\(V = V\)`' docs/design vignettes README.md ROADMAP.md NEWS.md
rg -n 'meta_known_V\(V = V\).*remains the route|`meta_known_V\(V = V\)` in one bivariate|with `meta_known_V\(V = V\)`$' vignettes/source-map.Rmd docs/design vignettes README.md ROADMAP.md NEWS.md
rg -n 'family map|Family and parameter map|Slice 283|beta-binomial|Poisson/NB2|meta_V\(V = V\)|meta_known_V\(V = V\)|fixed-effect only|random intercepts plus independent slopes|random-effect allowance|test evidence' README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/21-tutorial-style.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/formula-grammar.Rmd vignettes/distribution-families.Rmd vignettes/source-map.Rmd _pkgdown.yml
```

The remaining `meta_known_V(V = V)` hits are compatibility-alias wording,
historical NEWS/ROADMAP entries, or formula-grammar rows that deliberately
document the alias. No current source-map, family-chooser, or tutorial-style
sentence now leads with `meta_known_V()` as the preferred route.

## What Did Not Go Smoothly

The first stale-wording scan used backticks inside a double-quoted shell
pattern, which triggered shell command substitution before `rg` ran. I reran
the scans with single-quoted patterns and recorded the corrected patterns
above.

The audit also found two more useful stale notes than expected: the
source-map article still led with `meta_known_V()` for both univariate and
bivariate known sampling covariance, and the tutorial-style note used the old
spelling. Those were updated and re-rendered.

## Team Learning

Ada kept the slice documentation-only. Pat and Darwin pushed the map toward a
reader-facing answer to "can I fit this now?" Fisher and Curie kept test
evidence tied to named files rather than generic claims. Grace required the
vignette renders and pkgdown pass after each source-map change. Rose caught
the stale beta-binomial random-effect claim and the remaining `meta_known_V()`
lead wording.

## Known Limitations

This slice adds no likelihood, parser route, random-effect allowance, interval
method, simulation grid, or pkgdown navigation item. It does not make
beta-binomial, zero-inflated, hurdle, ordinal, shape, structured
non-Gaussian, or mixed-response bivariate random effects fitted.

## Next Actions

- Slice 284 should use the map as the source checklist for count-model
  hardening across Poisson, NB2, zero-inflated, truncated, and hurdle count
  surfaces.
- Slice 285 should reuse the same evidence columns for beta, beta-binomial,
  zero-one-inflation, and denominator-aware proportion paths.
- Future family additions should update this map at the same time as the
  likelihood, tests, examples, NEWS, roadmap, and after-task report.
