# After Task: relmat Use-Case Clarification

Date: 2026-05-22

## Task Goal

Clarify when `relmat()` is useful by giving concrete examples for covariance,
correlation, and precision inputs, and by separating latent group-level
known-matrix structure from observation-level known sampling covariance.

This was a documentation-only task. It did not change formula parsing,
likelihoods, the TMB ABI, tests, or fitted behaviour.

## Team Roles

- Ada kept the change scoped to public docs and closeout records.
- Boole checked syntax and marker boundaries.
- Fisher checked the latent random-effect equation and the separation from
  `meta_V(V = V)`.
- Pat checked whether the examples answer a reader's "when would I use this?"
  question.
- Grace rebuilt roxygen and pkgdown artifacts.
- Rose checked issue overlap and stale wording.

No spawned subagents were running; these are standing review perspectives.

## Files Created Or Changed

- `R/formula-markers.R`
- `man/relmat.Rd`
- `vignettes/relmat-known-matrices.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-22-relmat-use-cases.md`

## Checks Run

```sh
air format R/formula-markers.R vignettes/relmat-known-matrices.Rmd
Rscript -e "devtools::document()"
Rscript -e "pkgdown::build_reference()"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('relmat-known-matrices', new_process = FALSE, quiet = TRUE)"
rg -n 'When is|Choosing|Two concrete examples|Genomic or marker-based|graph, network, river|correlation matrix with diagonal 1|known sampling covariance|fit_grm\$sdpars\$mu' vignettes/relmat-known-matrices.Rmd man/relmat.Rd pkgdown-site/articles/relmat-known-matrices.html pkgdown-site/reference/relmat.html -S
Rscript -e "devtools::test(filter = 'package-skeleton|animal-relmat-gaussian|check-drm', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
git diff --check
gh issue list --search "relmat known matrix K Q covariance precision" --limit 20
```

Outcomes:

- Focused tests passed.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed.
- `git diff --check` passed.

## Consistency Audit

The relmat article now gives the latent model equation:

```text
u_id ~ N(0, sd_relmat^2 K)
u_id ~ N(0, sd_relmat^2 Q^-1)
```

The article and reference page now say `relmat()` is for latent group-level
structure. Known sampling covariance for observed estimates remains
`meta_V(V = V)`. Pedigree, tree, and coordinate-spatial matrices remain routed
through `animal()`, `phylo()`, and `spatial()` when those names describe the
scientific structure better.

## Tests Of The Tests

The focused test run covered package-skeleton parser expectations,
animal/relmat fitted Gaussian routes, and `check_drm()` diagnostics. This did
not add a new fitted route, so no new numerical test was required.

## What Did Not Go Smoothly

The old page was technically accurate but too abstract. The repair was to add
examples before mechanics: genomic relationship matrix as `K`, and a
river/network precision matrix as `Q`.

## GitHub Issue Maintenance

`gh issue list --search "relmat known matrix K Q covariance precision" --limit 20`
found #147 and #31 as broader open ledgers. This clarification does not close
either issue because it does not complete animal/relmat feature work or the
whole tutorial upgrade path.

## Known Limitations And Next Actions

- `relmat()` remains Gaussian-only for the fitted structured routes.
- Standalone `sigma`, multiple slopes, slope correlations, non-Gaussian
  relatedness effects, and predictor-dependent `corpair()` regressions remain
  planned.
- The article now gives use cases, but later examples should use real data or a
  small reproducible simulated object if this page becomes a teaching tutorial
  rather than a route map.
