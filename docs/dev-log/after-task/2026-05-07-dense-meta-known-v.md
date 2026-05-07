# After Task: Dense `meta_known_V()` Gaussian Meta-Analysis

## Goal

Extend Phase 2 so Gaussian meta-analysis can use known sampling covariance
matrices, not only independent known sampling variances.

## Implemented

- `meta_known_V(V = V)` now accepts:
  - a variance vector or data column;
  - a diagonal matrix;
  - a dense block-diagonal matrix;
  - a dense full covariance matrix.
- Matrix `V` is subset by rows and columns after missing-data filtering.
- Full known covariance uses a dense MVN likelihood in `src/drmTMB.cpp`.
- `simulate.drmTMB()` draws Gaussian simulations from the full observation
  covariance when `V` is dense.
- Pearson residuals for dense `V` are Cholesky-whitened residuals.
- The project-local `after-task-audit` skill now records Rose's closing
  checklist.

## Mathematical Contract

Diagonal known sampling variance:

```text
yi_i | mu_i, sigma_i, v_i ~ Normal(mu_i, sqrt(v_i + sigma_i^2))
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
```

Dense known sampling covariance:

```text
y | mu, sigma, V ~ MVN(mu, V + diag(sigma_i^2))
```

The estimated `sigma_i` remains the extra heterogeneity SD. In meta-analysis
language this is often called `tau`, but the package API keeps `sigma` for
consistency with Gaussian distributional regression.

## Files Changed

- `.agents/skills/after-task-audit/SKILL.md`
- `AGENTS.md`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-meta-known-v.R`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/meta-analysis.Rmd`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/08-meta-analysis.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/10-after-task-protocol.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'meta-known-v')"`:
  36 passed, 0 failed.
- `Rscript -e "devtools::test()"`:
  166 passed, 0 failed.
- `Rscript -e "devtools::document()"`:
  completed.
- `Rscript -e "pkgdown::check_pkgdown()"`:
  no problems found.
- `Rscript -e "pkgdown::build_site()"`:
  site built successfully.
- `Rscript -e "devtools::check()"`:
  0 errors, 0 warnings, 0 notes.
- `air format .`:
  not available in this environment.

## Tests Of The Tests

- The full-`V` likelihood test compares `logLik(fit)` with an independent base R
  multivariate normal calculation using `chol()`.
- The missing-data test verifies that full covariance matrices are subset by
  rows and columns, not only by diagonal entries.
- The missing-data test now also covers missing covariance entries in a row that
  is already dropped by model missingness, so retained rows are not over-dropped.
- The invalid-covariance tests check nonsymmetric and negative-variance inputs.
- The random-intercept smoke test verifies dense known `V` still works with an
  already-supported `mu` random intercept.
- The first focused run failed on a misplaced helper and overly strict missing
  variance validation; the corrected tests now pass.

## Consistency Audit

- Active docs now say dense known sampling covariance is implemented.
- Roadmap Phase 2 now says diagonal and dense full known covariance are
  implemented, with sparse storage planned.
- `NEWS.md`, `README.md`, vignettes, likelihood docs, family registry,
  meta-analysis design notes, and known limitations were updated.
- Stale wording remains only in historical after-task notes that were accurate
  at the time they were written.
- Guardrail matches for `meta_gaussian()` and `tau ~` are intentional: they
  prevent adding a separate meta-analysis family or a second public scale name
  without a design decision.
- Williams et al. (2026), "Meta-analysis with the glmmTMB R package", is now
  recorded as a `glmmTMB::equalto()` comparator reference in `REFERENCES.bib`,
  the meta-analysis design note, the testing strategy, and the reference
  programme.

## What Did Not Go Smoothly

- The first focused test run exposed two issues: the independent MVN helper was
  defined after it was used, and missing diagonal known variances were validated
  too early instead of being filtered with the model rows.
- Jason's read-only review caught that full-`V` missingness could over-drop rows
  when an already-excluded row had missing covariance entries, and that some
  Normal notation used variance where the surrounding text expected SD.
- A later smoke test for dense `V` with a `mu` random intercept initially assumed
  `sdpars$mu` was a list with `$sd`; it is currently a named numeric vector.
- The local formatter command `air format .` is not installed in this
  environment, so style checking relied on `git diff --check`, manual review,
  and package checks.

## Team Learning

- Rose's audit loop was valuable enough to become a project-local skill:
  `.agents/skills/after-task-audit/SKILL.md`.
- Future after-task reports should explicitly record what went wrong, what felt
  clumsy, and which team capability should improve next.
- For covariance work, Curie should always add at least one independent
  likelihood calculation and one neighbouring-feature smoke test.
- Emmy should later revisit `sdpars` object structure so tests and extractors
  use a stable, documented representation.

## Known Limitations

- Dense full covariance is not the final speed path for large phylogenetic or
  spatial meta-analysis. Sparse precision/covariance infrastructure remains
  planned.
- Bivariate meta-analysis with known within-study covariance is still future
  work.
- `meta_known_V()` remains unsupported in the bivariate Gaussian prototype.

## Next Actions

1. Add sparse known-covariance infrastructure as the bridge to A-inverse and
   SPDE models.
2. Add more comparator tests against `metafor` for full-`V` meta-analysis when
   the overlapping model is clear and fast enough for routine tests.
3. Add a lightweight `glmmTMB::equalto()` comparator smoke test if the current
   development version is available in CI or local optional tests.
4. Continue Phase 4 work on random slopes and named group-level covariance
   blocks.
