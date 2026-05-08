# After Task: Equation Syntax Documentation Alignment

## Goal

Make the public documentation more trustworthy by pairing symbolic equations
with matching R syntax, and by clarifying which formula grammar is implemented,
reserved, or planned.

## Implemented

- Split the overview vignette's first Gaussian example into a fixed-effect
  location-scale model followed by a separate random-effect extension.
- Added the same fixed-effect equation/syntax pairing to the README before the
  random-effect examples.
- Added a `Current Status Map` to `docs/design/01-formula-grammar.md`.
- Clarified planned spatial `coords` versus `mesh` inputs in the
  phylogenetic/spatial vignette and speed design note.
- Tightened `DESCRIPTION` so pkgdown metadata starts with current implemented
  functionality and frames shape, zero inflation, and extra response families
  as staged future work.
- Added a NEWS entry for this documentation alignment.

## Mathematical Contract

The fixed-effect Gaussian example now pairs:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 x1_i
log(sigma_i) = gamma_0 + gamma_1 x1_i
```

with:

```r
drm_formula(y ~ x1, sigma ~ x1)
```

The independent random-effect extension now separately pairs:

```text
mu_ij = beta_0 + beta_1 x1_ij + b_{0j} + b_{1j} x1_ij
b_{0j} ~ Normal(0, sd_mu_id_intercept^2)
b_{1j} ~ Normal(0, sd_mu_id_x1^2)
```

with:

```r
drm_formula(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)
```

The correlated block example now separately uses:

```text
[b_{0j}, b_{1j}]' ~ MVN(0, Sigma_mu_id)
```

with:

```r
drm_formula(y ~ x1 + (1 + x1 | id), sigma ~ x1)
```

## Files Changed

- `DESCRIPTION`
- `NEWS.md`
- `README.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/dev-log/check-log.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `Rscript -e "devtools::test()"`: 518 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `Rscript -e "pkgdown::build_site()"`: site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`: 0 errors, 0 warnings, 0 notes.
- `air format .`: failed because `air` is not installed on this machine.

## Tests Of The Tests

No model-fitting code changed, so no new unit tests were added. The existing
full test suite and `devtools::check()` were still run to make sure the
documentation edits did not break vignettes, examples, package metadata, or
pkgdown generation.

## Consistency Audit

- `pkgdown-site/articles/drmTMB.html` now contains the corrected fixed-effect
  Gaussian equation/syntax pairing.
- `pkgdown-site/articles/phylogenetic-spatial.html` now explains that a spatial
  mesh is a computational scaffold, not a biological sampling unit.
- `pkgdown-site/index.html` metadata now describes the current implementation
  before mentioning future staged families.
- `pkgdown-site/news/index.html` contains the documentation-alignment NEWS
  item.
- Remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails in
  meta-analysis documentation and after-task protocol text.

## What Did Not Go Smoothly

The overview vignette had a subtle but important mismatch: it described a
fixed-effect model but showed syntax with random effects. The fix was to split
the teaching sequence into fixed-effect first, then independent random effects,
then correlated random-effect blocks.

The pkgdown homepage metadata also inherited a broad DESCRIPTION. Tightening
DESCRIPTION required rebuilding the site and rerunning the full package check.

## Team Learning

Noether and Pat's perspectives should be applied together for tutorials:
Noether asks whether the equations and code match exactly; Pat asks whether a
new applied user can tell what question the model answers. Rose's audit then
checks whether the same implemented/reserved/planned status appears across
README, vignettes, design docs, NEWS, and generated pkgdown pages.

## Known Limitations

- This task improved documentation only. It did not implement bivariate random
  effects, spatial SPDE fields, phylogenetic slopes, shape families, or
  zero-inflation families.
- The examples still use compact predictor names such as `x1` in several
  places. Future tutorials should add runnable ecology/evolution examples once
  example datasets are chosen.

## Next Actions

1. Add a dense marginal-likelihood comparator test for the fitted sparse
   phylogenetic path.
2. Continue improving tutorials so each major model has one complete
   equation, R syntax, fitted-output, and interpretation sequence.
3. Start a small spatial-mesh design spike before implementing any SPDE code.
