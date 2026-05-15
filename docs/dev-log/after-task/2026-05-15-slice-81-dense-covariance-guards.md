# After Task: Slice 81 Dense Covariance And Large-Data Guards

## Goal

Make dense known sampling covariance visibly small-to-moderate rather than an
implicit large-data promise.

## Implemented

- `check_drm()` now reports full-matrix `meta_known_V(V = V)` fits as
  `known_sampling_covariance` notes.
- The dense known-covariance row now includes retained dimension, dense storage,
  density, approximate R object size, rank, and conditioning.
- Dense `V` messages distinguish ordinary dense matrices, low-density
  block-structured matrices, and rank or conditioning concerns.
- README, model-map, meta-analysis, large-data, source-map, known-limitations,
  and validation-debt docs now describe dense known covariance as a
  small-to-moderate route until sparse or block-sparse storage has evidence.
- `ROADMAP.md` marks Slice 81 complete, and `NEWS.md` records the user-facing
  diagnostic change.

## Mathematical Contract

The likelihood did not change. For diagonal known sampling variance, the
univariate Gaussian likelihood remains

```text
y_i ~ Normal(mu_i, v_i + sigma_i^2).
```

For full known covariance, it remains

```text
y ~ MVN(mu, V + diag(sigma_i^2)).
```

The Slice 81 change is diagnostic and interpretive: when `V` is a retained
dense matrix, users see that storage scale before treating the fit as a
large-data workflow.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `tests/testthat/test-control.R`
- `README.md`
- `vignettes/model-map.Rmd`
- `vignettes/meta-analysis.Rmd`
- `vignettes/large-data.Rmd`
- `vignettes/source-map.Rmd`
- `docs/design/08-meta-analysis.md`
- `docs/design/23-large-data-memory.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/known-limitations.md`
- `ROADMAP.md`
- `NEWS.md`
- `man/check_drm.Rd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/check.R tests/testthat/test-check-drm.R tests/testthat/test-control.R README.md vignettes/model-map.Rmd vignettes/meta-analysis.Rmd vignettes/large-data.Rmd vignettes/source-map.Rmd docs/design/08-meta-analysis.md docs/design/23-large-data-memory.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md ROADMAP.md NEWS.md`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "check-drm|control|meta-known-v|biv-gaussian", reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::document()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(reporter = "summary")'`
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`
- `git diff --check`
- Source and rendered wording scans for dense known-covariance guardrails and
  stale scalability claims.

All tests and checks passed. `devtools::check()` passed with 0 errors, 0
warnings, and 0 notes.

## Tests Of The Tests

The dense known-covariance diagnostic test now checks that a full matrix
produces `status = "note"` and reports `storage=dense`, `density=`, `size_mb=`,
rank, and sparse or block-sparse guardrail wording. The memory-light bivariate
known-`V` test checks the same dense-storage row after fitted data, model
frames, and the TMB object have been dropped.

## Consistency Audit

The source and rendered docs now agree that dense full known covariance is
implemented, but not a broad large-data path. The validation-debt register keeps
sparse and block-sparse `V` as open debt. The large-data article separates
dense known covariance from sparse fixed-effect matrices and Gaussian
aggregation.

## What Did Not Go Smoothly

The first targeted test update asserted `attr(check_drm(fit), "ok")` for a
small bivariate memory-light known-`V` fit. That fit already has an unrelated
near-boundary residual `rho12` warning, so the assertion was too broad. The
test now checks the intended `known_sampling_covariance` row directly.

## Team Learning

- Ada kept Slice 81 as a guardrail slice rather than starting sparse `V`.
- Gauss and Noether kept the likelihood contract unchanged.
- Pat made the reader-facing language explicit: dense means dense.
- Grace verified pkgdown and full package checks.
- Rose closed the loop by checking rendered wording and the validation-debt
  register.

## Known Limitations

- Sparse and block-sparse known sampling covariance are still not implemented.
- The diagnostic reports approximate dense R object size, not peak memory used
  during model construction or TMB evaluation.
- Dense `V` notes do not estimate whether a particular user's machine can fit a
  larger model; they only expose the storage boundary.

## Next Actions

- Continue to Slice 82: count likelihood kernel audit.
- Keep sparse or block-sparse known covariance as debt until there is code,
  tests, diagnostics, docs, benchmarks, and after-task evidence.
