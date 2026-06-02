# After Task: phylo_interaction First Slice

## Goal

Close issue #447 with one fitted two-phylogeny pair-effect route, without
turning it into a broad bipartite-model wrapper. The implemented claim is:
`phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)` fits
one q=1 pair-level structured `mu` field for univariate Gaussian, ordinary
Poisson, and ordinary NB2 models.

## Implemented

`phylo_interaction()` is exported and documented as a formula marker. The parser
requires intercept-only random-effect syntax, two simple partner variables
joined by `:`, and named `tree1`/`tree2` arguments. The model builder evaluates
both trees, creates augmented phylogenetic precisions for the observed partner
levels, and builds the pair precision with a sparse Kronecker product.

The fitted field reuses the existing structured `u_phylo`, `Q_phylo`, and
`log_sd_phylo` machinery. It appears under `sdpars$mu`, is available through
`ranef(fit, "phylo_interaction_mu")`, and is listed by `profile_targets()` as a
direct structured-SD target.

## Mathematical Contract

For observation `i` with partner levels `a_i` and `b_i`, the first slice is:

```text
eta_mu_i = X_mu[i, ] beta_mu + z[a_i, b_i]
vec(z) ~ Normal(0, sd_pair^2 (A_partner2 kron A_partner1))
```

The implementation uses the inverse form:

```text
Q_pair = Q_partner2 kron Q_partner1
log|Q_pair| = n_partner2 * log|Q_partner1| + n_partner1 * log|Q_partner2|
```

This is not yet an additive decomposition with separate partner main
phylogenies plus a pair interaction.

## Files Changed

- `R/formula-markers.R`
- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/gaussian-aggregation.R`
- `R/profile.R`
- `tests/testthat/test-phylo-interaction.R`
- `tests/testthat/test-package-skeleton.R`
- `NAMESPACE`
- `man/phylo_interaction.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-models.Rmd`
- `vignettes/structural-dependence.Rmd`
- `vignettes/bipartite-phylogenetic-interactions.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

The final check-log entry records the exact commands. The relevant outcomes
were:

- `air format` completed on code, tests, docs, article, and after-task files.
- Source and test parse checks passed.
- Focused `phylo-interaction` and `package-skeleton` tests passed before and
  after `devtools::document()`.
- `devtools::document()` generated `man/phylo_interaction.Rd` and updated
  `NAMESPACE`; unrelated local roxygen churn was removed.
- The two-tree article code parsed and rendered.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(lazy = TRUE, preview = FALSE)` built the reference page,
  article, article index, NEWS page, and search index.
- Rendered pkgdown scans found the new article, reference page, Reference
  index entry, linked structural articles, and NEWS entry for #447.
- Stale-wording and boundary scans found no missing-data lane terms, old
  Hadfield shorthand, or old ordinary Poisson-only structured message in the
  touched source/status files. Planned-boundary terms appeared only where they
  were explicitly documented as not fitted.
- `git diff --check` passed.
- `devtools::check(args = c("--no-manual"), error_on = "never")` completed in
  7m 11s with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The new test file fits Gaussian, Poisson, and NB2 models with
`phylo_interaction()`; checks the structured type, partner variables, direct SD
row, `ranef()` key, and `profile_targets()` TMB parameter; and verifies that
link-scale predictions include the structured contribution. A separate builder
test checks the sparse Kronecker precision dimension and observation-node
alignment. Parser tests cover missing random-effect syntax, non-intercept
slopes, missing `partner1:partner2` syntax, and missing `tree1`/`tree2`.

The profile-target check guards a regression where
`phylo_interaction(1 | plant:pollinator)` could fit but fail to advertise the
direct `log_sd_phylo` profiling route.

## Consistency Audit

The status inventory was synchronized across `README.md`, `ROADMAP.md`,
`NEWS.md`, `docs/dev-log/known-limitations.md`,
`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
`vignettes/formula-grammar.Rmd`, the structural-dependence and phylogenetic
articles, and `_pkgdown.yml`.

The scan patterns used for the final audit are recorded in the check log. They
separate fitted Gaussian/Poisson/NB2 pair-level support from planned additive
partner main phylogenies, binary/Bernoulli incidence, pair slopes, labelled
count covariance, and simultaneous structured layers.

## GitHub Issue Maintenance

Issue #447 is the narrow tracker for this slice. The pull request for this work
should include `Closes #447`.

## What Did Not Go Smoothly

This work had to be split from a dirty main worktree that also contained
missing-data files and post-fit accessor work. The clean branch deliberately
kept only the `phylo_interaction()` slice and left missing-data work to the
separate missing-data thread.

## Team Learning

- Boole: keep `phylo_interaction()` as the memorable high-level marker and
  `relmat()` as the lower-level precision escape hatch.
- Gauss: reuse the existing sparse structured-effect likelihood route instead
  of adding a new TMB branch.
- Curie: when docs claim Gaussian, Poisson, and NB2 support, the focused test
  file must fit all three.
- Rose: pair-level phylogenetic dependence and missing-data design are separate
  lanes.

## Known Limitations

This slice fits only one q=1 pair-level structured field. It does not fit
separate partner main phylogenies plus the interaction in the same model. It
does not support binary/Bernoulli incidence models, structured pair slopes,
labelled count covariance, zero-inflated structured effects, `sigma` structured
count effects, or simultaneous structured layers. Exact ordinary
`(1 | ID1:ID2)` parser sugar remains a small future grammar task; use a
precomputed `pair_id` column now.

## Next Actions

1. Add ordinary colon-group parser support if the project wants
   `(1 | ID1:ID2)` to work directly instead of requiring `pair_id`.
2. Design the additive bipartite route:
   `phylo(1 | partner1) + phylo(1 | partner2) + phylo_interaction(...)`.
3. Keep binary incidence models separate until a Bernoulli/binomial family
   design and recovery tests exist.
