# After Task: Profile Budgets and Structured Sigma Parity

## Goal

Handle the current Bergmann-report follow-up lane without touching the other
active worktree: wire profile parallelism and a profile budget guard, verify and
fix phylogenetic bootstrap refits, fit univariate Gaussian residual-scale
structured intercepts for `phylo()`, `spatial()`, `animal()`, and `relmat()`,
and close the smaller documentation, benchmark, and extractor follow-ups.

## Implemented

- `confint(method = "profile")` now forwards `parallel` and `workers` through
  direct-target and `newdata` profile loops.
- `confint()` now has `profile_maxit`, passed to `TMB::tmbprofile()` as
  `maxit`, with a guard against also supplying `maxit` in `...`.
- `bf()` / `drm_formula()` now retain the caller environment, so bootstrap
  refits can find local structured objects such as `tree`, `coords`, `Ainv`,
  and `Q`.
- Univariate Gaussian `sigma ~ phylo(1 | ...)`, `sigma ~ spatial(1 | ...)`,
  `sigma ~ animal(1 | ...)`, and `sigma ~ relmat(1 | ...)` now fit
  residual-scale structured intercepts. Matching intercept-only `mu`/`sigma`
  structured terms estimate one latent structured correlation.
- Bivariate `sigma()` now returns a roundable classed list.
- `bench/large-phylo-location.R` now has a real `(1 | cell_id)` benchmark
  scenario.
- `vignettes/convergence.Rmd` now uses `standard_errors_finite` instead of the
  stale `fixed_se_finite` wording.
- The rebased branch also qualifies `stats::qnorm()` and `stats::qchisq()` in
  `plot_corpairs_eye_row()` and ignores `.git` in `.Rbuildignore`, clearing the
  local `R CMD check` notes found during final validation.

## Mathematical Contract

For a matching univariate structured location-scale block,

```text
mu_i = X_mu[i, ] beta_mu + s_mu[group_i]
log(sigma_i) = X_sigma[i, ] beta_sigma + s_sigma[group_i]
```

The two latent fields share the same structured precision and estimate one
latent `mu`-`sigma` correlation. Sigma-only structured intercepts use only the
second equation and have no correlation parameter. Residual-scale structured
slopes and direct-SD formulas combined with structured `sigma` remain planned.

## Files Changed

Core implementation changed `R/bf.R`, `R/drmTMB.R`, `R/profile.R`,
`R/methods.R`, `R/formula-markers.R`, and `src/drmTMB.cpp`. Final check hygiene
changed `.Rbuildignore` and `R/plot-corpairs.R`. Tests changed the profile,
phylogenetic, spatial, animal/relmat, bivariate Gaussian, phylo utility, and
Gaussian location-scale shards. Documentation updates covered `README.md`,
`ROADMAP.md`, `NEWS.md`, selected design docs, selected vignettes, generated man
pages, and `docs/dev-log/check-log.md`.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = '^profile-targets$')"
Rscript -e "devtools::test(filter = '^(biv-gaussian|phylo-utils|phylo-gaussian|spatial-gaussian|animal-relmat-gaussian)$')"
Rscript bench/large-phylo-location.R --rows 40 --species 4 --structured none --cell-random-effect true --cell-random-effect-cells 5 --eval-max 100 --iter-max 100 --memory-light true
Rscript -e "devtools::test(filter = '^gaussian-location-scale$')"
air format tests/testthat/test-profile-targets.R
Rscript -e "devtools::test(filter = '^profile-targets$')"
Rscript -e "devtools::test()"
git diff --check
git fetch origin
git rebase origin/main
Rscript -e "devtools::test(filter = '^profile-targets$')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test(filter = '^plot-corpairs$')"
Rscript -e "devtools::check(args = '--no-manual', error_on = 'never')"
```

Outcomes:

- `devtools::document()` regenerated the expected namespace and man pages.
- Final profile shard: 563 passed, 0 failed, 0 warnings, 0 skips. This covers
  profile parallelism and budgets plus bootstrap refits for ordinary
  `mu`/`sigma` random effects, phylogenetic SD targets, bivariate phylogenetic
  q=2 SD targets, and direct structured location-scale SD targets for
  `phylo()`, `spatial()`, `animal()`, and `relmat()`.
- Structured/extractor shard: 1,271 passed, 0 failed, 0 warnings, 0 skips.
- Gaussian location-scale shard: 80 passed, 0 failed, 0 warnings, 0 skips.
- Full `devtools::test()`: 6,166 passed, 0 failed, 0 warnings, 0 skips.
- Benchmark smoke: convergence 0 with a five-level `cell_id` random intercept.
- `git diff --check` was clean.
- After rebasing onto `origin/main` at `1c241759`, the profile-target shard
  passed again with 563 assertions, `pkgdown::check_pkgdown()` found no
  problems, the `plot-corpairs` shard passed with 45 assertions, and
  `devtools::check(args = "--no-manual")` completed with 0 errors, 0 warnings,
  and 0 notes.

## Tests Of The Tests

The new phylogenetic bootstrap tests failed before the formula-environment fix:
both scalar and bivariate q=2 phylogenetic bootstrap rows reported
`bootstrap_unavailable` with 0 successful refits. After `drm_formula()` retained
the caller environment, those tests passed with 2/2 successful refits. The
expanded bootstrap matrix also refits direct location-scale SD targets for
ordinary random effects, `spatial()`, `animal()`, and `relmat()` with 2/2
successful refits. The full suite also caught an obsolete unsupported-syntax
expectation for `sigma ~ spatial(1 | ...)`; that test now checks the
still-unsupported residual-scale structured-slope form.

## Consistency Audit

Current-facing status inventories were synchronized in `README.md`, `ROADMAP.md`,
`NEWS.md`, `docs/design/01-formula-grammar.md`,
`docs/design/03-likelihoods.md`, `docs/design/12-profile-likelihood-cis.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`, and the model-map,
formula-grammar, source-map, phylogenetic-spatial, implementation-map, and
structural-dependence vignettes.

The stale-wording scan was:

```sh
rg -n 'standalone spatial `sigma`|phylogenetic or spatial effects in `sigma`|spatial scale terms|standalone spatial scale|standalone structured `sigma`|standalone `sigma` relatedness|standalone `sigma`,|spatial-sigma-only routes|standalone phylogenetic `sigma`|spatial `sigma`, spatial q=4|sigma relatedness models|standalone scale models' README.md ROADMAP.md NEWS.md docs/design vignettes R tests --glob '!docs/dev-log/**' -S
```

It found one historical NEWS entry under the released 0.1.3 section. That entry
was left as historical chronology; the current development bullets and
current-facing docs now record the fitted intercept-only structured `sigma`
boundary.

## GitHub Issue Maintenance

`gh issue list --limit 20 --search "phylo bootstrap profile sigma spatial animal relmat"`
found issue #147, "Implement animal() and relmat() known-relatedness structured
effects". I did not comment or close it from this isolated local branch because
the user asked not to overlap with another conversation; the after-task report
and check-log leave the local evidence for the eventual PR or issue update.

## What Did Not Go Smoothly

The main bug was not in the bootstrap percentile calculation. It was that
`drm_formula()` did not retain the caller environment, so a bootstrap refit made
after the fitting call returned could no longer find local structured objects.
The benchmark script exposed the same formula-construction assumption because it
was passing evaluated formulas through `bf()`.

## Team Learning

Ada should treat structured-effect refits as an environment-retention test, not
only a numerical refit test. Boole should include local-object formulas in future
formula-grammar tests. Rose should keep old release notes separate from
current-facing capability inventories during stale-wording scans.

## Known Limitations

- The original Ayumi field artifacts were not present in this clean worktree, so
  6.11 is verified here with small local structured-dependency bootstrap smokes
  rather than rerunning those field examples.
- Residual-scale structured slopes, direct-SD formulas combined with structured
  `sigma`, mesh/SPDE, predictor-dependent structured `corpair()` routes, and
  broad non-Gaussian structured effects remain planned.
- The new univariate `mu`/`sigma` structured-correlation smoke tests are wiring
  and convergence tests, not full recovery or operating-characteristic grids.

## Next Actions

- Use this branch as a focused PR rather than mixing it with the rendered figure
  QA branch.
- Add field-example bootstrap evidence if the original Ayumi data artifacts are
  restored to the workspace.
- Add ADEMP/recovery grids before advertising broad performance for structured
  residual-scale effects.
