# After Task: Count Structured Mu Q1 First Slice

## Goal

Finish the inherited Team A first slice for ordinary Poisson and NB2 q=1
structured count `mu` effects. The implemented claim is: ordinary
non-zero-inflated Poisson and NB2 models can now fit one unlabelled q=1
structured `mu` intercept from `phylo()`, `spatial()`, `animal()`, or
`relmat()` on the log-mean scale.

## Implemented

- `drm_build_poisson_spec()` and `drm_build_nbinom2_spec()` now extract
  `phylo()`, `spatial()`, `animal()`, and `relmat()` count-side `mu` terms and
  select at most one structured term per fit.
- `validate_count_structured_mu_term()` keeps the first slice narrow: ordinary
  count models only, no zero-inflation, no ordinary-plus-structured `mu` mixture,
  no labels, and no structured slopes.
- `validate_nbinom2_sigma_random_terms()` now treats structured `mu` terms like
  ordinary `mu` random effects for the joint `mu`/`sigma` first-gate boundary.
- `tests/testthat/test-count-structured-mu.R` adds deterministic Poisson and
  NB2 recovery checks for `spatial()`, `animal()`, and `relmat()`, plus
  unsupported-neighbor checks.
- Public status text was synchronized across README, NEWS, ROADMAP, formula
  grammar, likelihood notes, family registry, validation-debt and readiness
  maps, known limitations, and user-facing vignettes.

## Mathematical Contract

For the accepted count structured path, the linear predictor is

```text
eta_mu_i = offset_i + X_mu[i, ] beta_mu + a_level[i]
a ~ Normal(0, sd_structured^2 A_structured)
```

where `A_structured` is supplied by the tree, coordinate precision,
animal-model matrix, or user-supplied relatedness matrix. The count likelihood
stays Poisson or NB2, and NB2 `sigma` stays fixed-effect unless the separate
ordinary grouped `sigma ~ ... + (1 | id)` route is used. This slice reuses the
existing TMB structured-effect ABI (`u_phylo`, `log_sd_phylo`, `Q_phylo`) and
does not change likelihood parameterization.

## Files Changed

- Code: `R/drmTMB.R`, `R/methods.R`
- Tests: `tests/testthat/test-count-structured-mu.R`,
  `tests/testthat/test-nongaussian-structured-boundary.R`,
  `tests/testthat/test-poisson-mean.R`
- User and design docs: `README.md`, `NEWS.md`, `ROADMAP.md`,
  `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/36-cpp-modularization-source-map.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/59-structural-slope-and-non-gaussian-map.md`,
  `docs/design/79-supported-nongaussian-evidence-goal.md`,
  `docs/dev-log/known-limitations.md`, `docs/dev-log/team-improvements.md`,
  `vignettes/count-nbinom2.Rmd`, `vignettes/distribution-families.Rmd`,
  `vignettes/formula-grammar.Rmd`, `vignettes/implementation-map.Rmd`,
  `vignettes/model-map.Rmd`, and `vignettes/source-map.Rmd`

## Checks Run

```sh
air format R/drmTMB.R R/methods.R tests/testthat/test-count-structured-mu.R tests/testthat/test-nongaussian-structured-boundary.R tests/testthat/test-poisson-mean.R
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); cat('load_all ok\n')"
Rscript --vanilla -e "devtools::test(filter = '^(count-structured-mu|nongaussian-structured-boundary|poisson-mean)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(count-structured-mu|phase18-poisson-phylo-q1|phase18-nbinom2-phylo-q1|nbinom2-location-scale|poisson-mean|nongaussian-structured-boundary)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::check()"
git diff --check
```

Results:

- Focused, adjacent, and full `devtools::test()` passes completed.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site(preview = FALSE)` passed after the final docs edits.
- `devtools::document()` produced only unrelated generated roxygen churn, which
  was reverted; no `.Rd` or `DESCRIPTION` changes are retained.
- `devtools::check()` passed with 0 errors, 0 warnings, and 0 notes in
  6 minutes 40.6 seconds.
- `git diff --check` was clean.

## Tests Of The Tests

The new test file checks both recovery and failure paths. It fits Poisson and
NB2 models for `spatial()`, `animal()`, and `relmat()` and checks convergence,
positive-definite Hessian status, fixed effects, `sdpars()`, marker-specific
`ranef()` blocks, response-scale predictions, direct `profile_targets()` rows,
and `check_drm()` diagnostics. It also rejects structured slopes, labelled
structured count terms, ordinary-plus-structured mixtures, zero-inflated
structured count models, simultaneous structured types, and NB2 structured
`sigma` neighbors.

## Consistency Audit

Source and rendered-site scans used these patterns:

```sh
rg -n -e 'spatial/animal/`relmat\(\)` count structure' -e 'spatial/animal/`relmat\(\)` count routes' -e 'spatial/animal/`relmat\(\)` parity' -e 'non-Gaussian spatial/animal/`relmat\(\)` effects remain planned' -e 'ordinary Poisson/NB2 q=1 phylogenetic `mu` routes' -e 'outside ordinary NB2 `sigma` intercepts and ordinary Poisson/NB2 q=1 phylogenetic' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**'
rg -n -e 'spatial/animal/`relmat\(\)` count structure' -e 'spatial/animal/`relmat\(\)` count routes' -e 'spatial/animal/`relmat\(\)` parity' -e 'non-Gaussian spatial/animal/`relmat\(\)` effects remain planned' -e 'ordinary Poisson/NB2 q=1 phylogenetic `mu` routes' -e 'outside ordinary NB2 `sigma` intercepts and ordinary Poisson/NB2 q=1 phylogenetic' pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/count-nbinom2.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/implementation-map.html pkgdown-site/articles/model-map.html pkgdown-site/articles/source-map.html pkgdown-site/news/index.html
```

Current docs and rendered current pages were synchronized. Remaining source hits
are historical phylo-only design notes for earlier slices and were left intact
because they record the state at the time they were written.

## GitHub Issue Maintenance

Open issue searches:

- `gh issue list --search "count structured" --state open --json number,title,url,labels --limit 20`
- `gh issue list --search "non-Gaussian structured" --state open --json number,title,url,labels --limit 20`
- `gh issue list --search "spatial animal relmat count" --state open --json number,title,url,labels --limit 20`

Related broad ledgers were #33, #58, #59, #128, and #147. None was a precise
owner for this narrow q=1 count structured source-test slice, so no duplicate
issue or issue comment was added before PR creation.

## What Did Not Go Smoothly

The inherited branch had implementation and docs but no current check-log entry
or after-task report. Several current source-map/status surfaces still said the
count structured route was phylo-only. Also, `devtools::document()` ran with the
local roxygen version and generated unrelated Rd/link churn; that output was
removed before the final validation state.

## Team Learning

- Ada should create the check-log entry before a long branch switch or remote
  handoff so the next agent does not have to infer the active lane from a dirty
  diff.
- Rose should scan current rendered pages and current source maps separately
  from historical design notes.
- Grace should treat `devtools::document()` output carefully when the repo's
  configured roxygen version differs from the local version.
- The stale-scan and roxygen-churn lessons were recorded in
  `docs/dev-log/team-improvements.md`.

## Known Limitations

This is a q=1 source-tested first slice. It does not add structured count
slopes, labelled q=2/q=4 count covariance, simultaneous structured count types,
zero-inflated structured count effects, NB2 structured `sigma`, bivariate or
mixed-response count models, or formal operating-characteristic parity for
spatial, animal, and `relmat()` count routes.

## Next Actions

Open the focused PR, watch GitHub Actions, and keep the next autonomous slice
blocked until this PR has reviewable CI evidence. The likely follow-up after CI
is a small Phase 18 evidence slice that writes opt-in smoke/grid artifacts for
spatial, animal, and `relmat()` q=1 count routes without promoting them to
formal recovery parity.
