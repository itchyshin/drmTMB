# After Task: Staggered Docs And Structured-Effect Grammar

## Goal

Use a staggered team workflow to improve public documentation before the next
implementation phase, and make the planned phylogenetic and spatial grammar
consistent with the mathematical target.

## Implemented

- Separated implemented and planned examples in the README and getting-started
  vignette.
- Added an explicit convention that `Normal(a, b)` uses variance as the second
  argument.
- Added equation and R-syntax pairings for one location model with several
  scale quantities: residual `sigma`, `sd(population)`, and `sd(site)`.
- Added a runnable `sd(population) ~ habitat` tutorial example.
- Defined "coscale" as the residual covariance structure represented by
  `rho12` in the bivariate Gaussian seed.
- Moved planned phylogenetic syntax to
  `phylo(1 | species, tree = tree)`, requiring an ultrametric tree with branch
  lengths.
- Moved planned spatial syntax to
  `spatial(1 | site, coords = coords)`, with structured slopes later.
- Updated pkgdown reference grouping so `gr()`, `phylo()`, and `spatial()` are
  clearly planned structured-effect markers.

## Mathematical Contract

The current implemented Gaussian models remain unchanged:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + random effects
log(sigma_i) = X_sigma[i, ] beta_sigma + optional residual-scale random effects
```

For multiple random-effect scale formulas:

```text
mu_i = X_mu[i, ] beta_mu + b_j[i] + c_k[i]
b_j = sd_mu_population,j u_j
c_k = sd_mu_site,k r_k
log(sd_mu_population,j) = W_population[j, ] alpha
log(sd_mu_site,k) = W_site[k, ] kappa
```

For planned phylogeny:

```text
phylo(1 | species, tree = tree)
a_aug ~ MVN(0, sigma_phylo^2 S)
Q_aug = S^{-1} / sigma_phylo^2
a_species = P_tip a_aug
```

The public `phylo()` API should require an ultrametric tree with branch
lengths; dense tip covariance belongs to internal comparator tests or lower
level structured-covariance paths, not the main public phylogeny API.

For planned spatial structure:

```text
spatial(1 | site, coords = coords)
z_space ~ GMRF(Q_spde)
```

## Files Changed

- `README.md`
- `_pkgdown.yml`
- `R/formula-markers.R`
- `man/gr.Rd`
- `man/phylo.Rd`
- `man/spatial.Rd`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/meta-analysis.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/08-meta-analysis.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/11-reference-programme.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); ..."` for the new
  `sd(population) ~ habitat` example.
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` stale-wording scans for inconsistent Normal notation, `Cphy`,
  `phylo(species)`, old spatial placeholders, `O'Dea-style`, and
  `biological data`.
- `git diff --check`

Outcomes:

- tutorial example converged and returned positive predicted
  `sd(population)` values;
- full test suite: 403 passed, 0 failed;
- pkgdown check: no problems found;
- pkgdown site: built successfully;
- package check with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors, 0 warnings,
  0 notes;
- stale-wording scans: no matches for the searched hazards;
- whitespace check: passed.

## Tests Of The Tests

This was mostly a documentation and design task, so no new formal test file was
added. The new tutorial example was executed directly and checked for
convergence, sign of the group-scale coefficient, and positive predictions.
Curie's simulation-testing plan is recorded as the gate for the next
phylogenetic implementation task.

## Consistency Audit

- Pat's user audit drove the README split, Normal notation correction, and
  `sd(group)` runnable example.
- Jason's source map drove the A-inverse/SPDE source-map notes and the warning
  not to copy gllvmTMB's high-dimensional API grid.
- Curie's testing plan drove the next phylogenetic gate: parser tests,
  sparse-vs-dense algebra tests, and one small simulation recovery test.
- User feedback corrected public phylogenetic syntax: `phylo()` should take an
  ultrametric tree with branch lengths, not just a dense `Cphy` matrix.
- User feedback aligned spatial syntax with phylogenetic syntax.

## What Did Not Go Smoothly

- The first draft of planned phylogenetic syntax allowed public
  `cor = Cphy`, which was too permissive and would have encouraged users to
  bypass the tree-based A-inverse path.
- The older documentation used `Normal(mu, sqrt(v + sigma^2))`, mixing SD and
  variance conventions. This is now corrected.
- The README had planned bivariate syntax too close to implemented syntax.

## Team Learning

- Staggered parallel work is useful when roles do not edit the same files:
  Pat can audit current docs, Jason can scout source design, and Curie can plan
  tests while Ada integrates.
- Public grammar should expose scientific objects, not just computational
  conveniences. For phylogeny, the scientific object is an ultrametric
  branch-length tree.
- Phylogenetic and spatial dependence can share structured random-effect
  syntax while keeping distinct speed paths internally.

## Known Limitations

- No new phylogenetic or spatial likelihood code was implemented.
- `phylo()` and `spatial()` remain planned markers.
- The next implementation phase still needs parser support, tree validation,
  sparse A-inverse construction, TMB prior evaluation, and simulation tests.

## Next Actions

1. Implement parser validation for planned `phylo(1 | species, tree = tree)` in
   univariate Gaussian `mu`.
2. Add a small internal tree-to-sparse-precision path following the Hadfield
   and Nakagawa construction, with provenance notes before any code reuse.
3. Add dense comparator tests for tiny trees and one CRAN-safe simulation
   recovery test.
4. Only after that, consider spatial `spatial(1 | site, coords = coords)` with
   mesh/SPDE plumbing.
