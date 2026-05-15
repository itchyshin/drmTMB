# After Task: Phase 5b Slices 48-50 Gaussian Aggregation Fit

## Goal

Finish the Phase 5b Gaussian aggregation lane by moving from the Slice 47
design contract to a fitted, opt-in, tested, documented, benchmark-visible
implementation.

## Implemented

- Added `drm_control(aggregate_gaussian = TRUE)` for the first univariate
  Gaussian fixed-effect sufficient-statistic aggregation path.
- Added `R/gaussian-aggregation.R` with an internal aggregation-key builder,
  input validation, fitted aggregation summaries, TMB-data routing, and an
  independent full-row versus aggregated log-likelihood parity helper.
- Added TMB data fields and a `model_type = 1` Gaussian aggregation branch in
  `src/drmTMB.cpp`.
- Kept post-fit output row-level: TMB receives aggregation cells, but the
  fitted object keeps original-row response vectors and model matrices so
  `predict()`, `fitted()`, and `residuals()` remain one value per original
  model row, including memory-light fits.
- Added `check_drm()` reporting for `gaussian_aggregation`.
- Added benchmark support for `--aggregate-gaussian` and
  `--aggregation-cells`, plus summarizer columns for fitted aggregation cells,
  compression ratio, and largest cell size.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/design/03-likelihoods.md`,
  `docs/design/23-large-data-memory.md`,
  `docs/design/31-gaussian-aggregation-sufficient-statistics.md`,
  `docs/dev-log/known-limitations.md`, `vignettes/large-data.Rmd`,
  benchmark docs, and regenerated roxygen/pkgdown outputs.

## Mathematical Contract

For each aggregation cell `g`, rows share the same processed `mu` and `sigma`
design state after model-row filtering:

```text
mu_g = X_mu_g beta_mu
log(sigma_g) = X_sigma_g beta_sigma
```

The TMB branch adds:

```text
0.5 n_g log(2 pi)
  + n_g log(sigma_g)
  + 0.5 (sum_y2_g - 2 mu_g sum_y_g + n_g mu_g^2) / sigma_g^2
```

to the negative log-likelihood. This matches the independent full-row Gaussian
log-likelihood for unweighted rows.

## Files Changed

- `R/control.R`
- `R/drmTMB.R`
- `R/gaussian-aggregation.R`
- `R/check.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gaussian-aggregation.R`
- `tests/testthat/_snaps/gaussian-aggregation.md`
- `tests/testthat/test-phylo-utils.R`
- `bench/large-phylo-location.R`
- `bench/summarize-results.R`
- `bench/README.md`
- `docs/design/03-likelihoods.md`
- `docs/design/23-large-data-memory.md`
- `docs/design/31-gaussian-aggregation-sufficient-statistics.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/large-data.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- generated `man/check_drm.Rd`, `man/drm_control.Rd`, and local pkgdown site.

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed after one C++ brace
  repair during implementation.
- `Rscript -e 'devtools::test(filter = "gaussian-aggregation")'`: passed,
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 33`.
- `Rscript -e 'devtools::test(filter = "sparse-fixed-effects|phylo-utils")'`:
  passed, `FAIL 0 | WARN 0 | SKIP 0 | PASS 117`.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'e <- new.env(parent = globalenv()); sys.source("bench/large-phylo-location.R", e); args <- e$parse_args(c("--rows", "120", "--species", "8", "--structured", "none", "--aggregate-gaussian", "true", "--aggregation-cells", "12", "--memory-light", "true", "--eval-max", "80", "--iter-max", "80")); res <- e$run_benchmark(args); stopifnot(isTRUE(res$aggregate_gaussian[[1]]), res$aggregation_cells_fitted[[1]] <= 12, is.finite(res$aggregation_compression_ratio[[1]])); cat(res$aggregation_cells_fitted[[1]], res$aggregation_compression_ratio[[1]], "\n")'`:
  passed and printed `12 10`.
- `tmp_csv=$(mktemp /tmp/drmTMB-aggregation-smoke-XXXXXX.csv); Rscript bench/large-phylo-location.R --rows 120 --species 8 --structured none --aggregate-gaussian true --aggregation-cells 12 --memory-light true --eval-max 80 --iter-max 80 --output "$tmp_csv" && Rscript bench/summarize-results.R --input "$tmp_csv"`:
  passed; the summary reported `aggregation_cells = 12` and
  `aggregation_compression = 10`.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd` and `man/drm_control.Rd`.
- `Rscript -e 'pkgdown::build_article("large-data", new_process = FALSE)'`:
  passed.
- `Rscript -e 'pkgdown::build_site()'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript -e 'devtools::check(document = FALSE, args = "--no-manual")'`:
  passed with 0 errors, 0 warnings, and 1 NOTE: unable to verify current time.
- `git diff --check`: passed.
- `rg -n "aggregate_gaussian.*reserved|reserved design name|aggregation.*designed but not implemented|no fitted aggregation control|fitted aggregation.*planned|Gaussian sufficient-statistic aggregation is designed" README.md ROADMAP.md NEWS.md R man docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site --glob '!pkgdown-site/search.json'`:
  returned no matches.

## Tests Of The Tests

- The new helper test compares the aggregated likelihood to an independent
  full-row calculation at fixed coefficients.
- The fitted test compares dense and aggregated fits for `coef()`, `sigma`,
  `logLik()`, `AIC`, `vcov()`, `fitted()`, and `residuals()`.
- The fixture includes a non-intercept `sigma` formula, so `sigma` design rows
  are part of the aggregation key.
- Rejection snapshots cover ordinary random effects, structured effects, known
  sampling covariance, non-unit weights, combined sparse fixed effects,
  non-Gaussian families, and bivariate Gaussian families.
- The memory-light test verifies row-level outputs after data/model-frame/TMB
  object storage is dropped.

## Consistency Audit

The implementation, likelihood design note, aggregation design note, large-data
article, roadmap, known limitations, benchmark README, roxygen docs, NEWS, and
rendered pkgdown pages now agree:

- `aggregate_gaussian = TRUE` is implemented, not merely reserved.
- The fitted scope is narrow: univariate Gaussian fixed-effect rows only.
- Sparse matrices and aggregation remain separate scaling tools.
- The first post-fit policy is original-row output, not cell-level residuals.
- Broader weighted, random-effect, structured, bivariate, and non-Gaussian
  aggregation remain future work.

## What Did Not Go Smoothly

The first C++ edit missed one closing brace around the dense Gaussian branch.
Compiling immediately after the TMB change caught it before tests or docs were
layered on top.

## Team Learning

- Ada should continue using early compile gates after each TMB branch change,
  before adding wider tests or documentation.
- Boole should keep `aggregate_gaussian` explicit and Gaussian-only until a
  broader aggregation contract exists.
- Gauss should keep the aggregated and dense Gaussian objectives in separate
  branches with a direct algebra parity helper.
- Noether should keep the aggregation key tied to processed design matrices,
  not raw data columns.
- Curie should keep fitting parity tests small but cover both `mu` and
  `sigma` design rows.
- Fisher should treat this as exact likelihood compression, not a statistical
  approximation, but still require benchmark evidence before million-row
  claims.
- Pat should point users to `check_drm()` and the benchmark smoke command
  before encouraging large repeated-row fits.
- Grace should keep the benchmark harness schema explicit when adding new
  scaling knobs.
- Rose should continue scanning for old "reserved/not implemented" wording
  after design slices become fitted code.

## Known Limitations

- The fitted path rejects ordinary random effects, direct-SD formulas,
  phylogenetic/spatial structured effects, known sampling covariance,
  bivariate Gaussian models, non-Gaussian families, non-unit likelihood
  weights, and combined sparse fixed effects.
- There is no weighted aggregation path.
- There is no cell-level residual or cell-level fitted-summary method yet.
- The benchmark smoke confirms the harness and compression columns, not
  million-row performance.

## Next Actions

- Push the branch and open the Slice 48-50 PR.
- Let GitHub Actions run the cross-platform release matrix.
- Merge and pull once CI is green.
- Start the next phase from a clean `main`; Phase 5b has no remaining planned
  slices after Slice 50, but broader scaling work continues in later roadmap
  phases.
