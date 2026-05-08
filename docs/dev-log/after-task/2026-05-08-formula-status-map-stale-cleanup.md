# After Task: Formula Status Map And Stale Cleanup

## Goal

Make the public formula grammar docs easier to trust by showing which syntax is
implemented now, which syntax is reserved, and which syntax remains planned.

## Implemented

- Added a current-status map to `vignettes/formula-grammar.Rmd`.
- Added planned-only comments to visible phylogenetic slope, spatial, and
  bivariate random-effect examples.
- Changed active design notes that still described intercept-only
  `phylo(1 | species, tree = tree)` as future.
- Clarified that random-intercept meta-regression and
  `meta_known_V(V = V)` plus intercept-only phylogenetic `mu` have tests, while
  `sd(group)` scale models in known-covariance meta-analysis still need
  explicit validation.
- Updated `drmTMB()` roxygen and regenerated `man/drmTMB.Rd`.

## Mathematical Contract

No likelihood changed. The documented current implemented contracts remain:

```text
y_i ~ Normal(mu_i, sigma_i^2)
log(sigma_i) = X_sigma[i, ] beta_sigma
```

for Gaussian location-scale models,

```text
y ~ MVN(mu, V + diag(sigma_i^2))
```

for known-covariance Gaussian meta-analysis, and

```text
a_species ~ MVN(0, sigma_phylo^2 A)
mu_i = X_mu[i, ] beta_mu + a_species[i]
```

for the intercept-only phylogenetic location effect. The docs now label these
as implemented and keep spatial fields and phylogenetic slopes as planned.

## Files Changed

- `R/drmTMB.R`
- `R/formula-markers.R`
- `man/drmTMB.Rd`
- `man/spatial.Rd`
- `README.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/08-meta-analysis.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/dev-log/check-log.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-status grep over `README.md`, `vignettes`, `docs/design`, `R`, and
  `man`.

## Tests Of The Tests

This was a documentation/status task, so no new test file was added. The
existing full suite remained green with 483 passing tests, including the
likelihood-comparator tests for `meta_known_V(V = V)` and intercept-only
phylogenetic `mu`.

## Consistency Audit

- The formula grammar article now starts with a status map.
- The `which-scale` vignette no longer says all phylogenetic structured effects
  are future.
- The phylogenetic/spatial speed design note separates implemented univariate
  phylogenetic syntax from planned spatial and bivariate extensions.
- The meta-analysis design note separates implemented random-intercept and
  phylogenetic meta-analysis combinations from still-unvalidated random-effect
  scale combinations.
- The `drmTMB()` help page now mentions `meta_known_V(V = V)`.
- `pkgdown::check_pkgdown()` found no missing reference entries.
- Remaining stale-status grep hits were manually checked and were appropriate
  planned-feature or roadmap wording, not current-support contradictions.

## What Did Not Go Smoothly

One first patch attempt missed the exact vignette context because the file had
already changed. The fix was to re-read the local context with `sed` and apply
smaller patches.

## Team Learning

Pat's user-test review showed that planned examples need inline comments,
because users copy code blocks faster than they read surrounding paragraphs.
Rose's systems audit showed that status drift is now the main docs risk as
features move quickly from roadmap to implementation.

The team process should keep adding a stale-status grep to close-out work:

```sh
rg -n "planned|not implemented|future|Reserved|roadmap|Current planned" README.md vignettes docs/design R man | rg "phylo\\(1 \\||meta_known_V|sd\\(group\\)|mvbind|rho12|spatial|A-inverse|random-intercept meta"
```

## Known Limitations

- Spatial fields are still planned, not fitted.
- Phylogenetic slopes, phylogenetic `sigma`, and bivariate structured
  phylogenetic effects remain planned.
- `mvbind()` shorthand and mixed bivariate response families remain planned.
- Historical after-task notes and changelog entries may accurately describe
  older states and should not be mechanically rewritten.

## Next Actions

1. Commit and push this docs consistency pass.
2. Continue with either dense full-`V` plus phylo comparator tests or
   prediction semantics for phylogenetic/random-effect models.
3. Add the stale-status grep to the after-task habit for every feature that
   changes implementation status.
