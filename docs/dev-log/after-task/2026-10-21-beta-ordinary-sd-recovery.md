# After Task: Beta Ordinary SD Recovery Smoke

## 1. Goal

Add a quick independent recovery smoke for the already-admitted native Beta ordinary random-intercept and independent random-slope SD routes, and make the source map describe their current scope accurately.

## 2. Implemented

Two deterministic synthetic fits now check that Beta ordinary intercept and independent-slope SD regressions recover a nonzero group-level log-SD trend and predict the SD surface in group-label order. The source map now distinguishes Beta and skew-normal intercept-plus-slope adapters from the intercept-only Gamma and Student-t adapters.

## 3a. Decisions and Rejected Alternatives

For group `g`, each test draws a single random coefficient with standard deviation `exp(alpha0 + alpha1 * z_g)`. The location predictor uses a logit link, and conditional responses are drawn independently from a Beta distribution with precision `1 / sigma^2`. The intercept fixture uses `b_g` in the intercept; the slope fixture uses `b_g * x`, with `x` varying within group and `z_g` constant within group.

The smoke is limited to already-admitted native adapters. It adds recovery evidence without changing the likelihood, formula grammar, or user-facing API. No simulation campaign or coverage claim is part of this slice.

## 4. Files Touched

- `tests/testthat/test-beta-sd-regression.R`: added small-group intercept and independent-slope recovery smoke tests.
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`: corrected the family summary sentence to match the existing Beta and skew-normal independent-slope routes.
- `docs/dev-log/check-log.md` and `docs/dev-log/check-log.d/2026-10-21-beta-ordinary-sd-recovery.md`: recorded focused test evidence.

## 5. Checks Run

- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-beta-sd-regression.R", reporter = "summary")'`: passed all 26 expectations, including the new intercept and slope fits.
- The same source-loaded session ran `test-beta-sd-integration.R` and `test-beta-sd-slope-integration.R`: both files completed with exit code 0 and no failures. These include existing public-output, save/reload, constant-SD, independent-quadrature, and wrong-SD-map checks.
- `git diff --check` passed for the source-map change; the test file was parsed and executed by the focused R run.
- Live Julia tests did not run in these commands.

## 6. Tests of the Tests

The new fixtures draw random effects and Beta responses directly from the stated data-generating model; they do not simulate from the fitted package model. The existing slope integration test also compares the fitted marginal likelihood with independent per-group quadrature and checks a reversed-SD-map negative control. `NOT_CRAN=true` was required because a first isolated invocation skipped the recovery test through `skip_on_cran()`.

## 8. Consistency Audit

The runtime formula selectors, the adapter-map table, and the formula-grammar row all describe Beta ordinary intercept and one independent numeric slope SD route. The adapter-map summary sentence had lagged behind its own table and is corrected. No public API or likelihood parameterization changed. The relevant status scan was:

```sh
rg -n 'Beta.*ordinary|ordinary.*Beta|Beta.*independent.*slope' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd
```

## 7a. Issue Ledger

Open-issue searches for predictor-dependent SDs and Beta `sd(group)` terms found no issue tracking this small-group native recovery smoke. The surfaced documentation issue #1488 concerns definitions and reader order; the test-sweep issue #1463 covers separate historical datasets. Neither needs an update for this test-only change.

## 9. What Did Not Go Smoothly

The first `test_file()` invocation skipped the new fit because `skip_on_cran()` did not see a development run. The explicit `NOT_CRAN=true` rerun executed both new fits and passed.

## 11. Team Learning

When a focused test file contains `skip_on_cran()`, set `NOT_CRAN=true` explicitly for local source-loaded execution and confirm that the recovery expectation ran rather than relying on the absence of a failure.

## 10. Known Residuals

This adds native TMB point-recovery smoke only. It does not add Julia parity, interval calibration, profile or bootstrap refits, or evidence for structured Beta effects. The wider general SD programme remains open.

## 12. Cross-Product Coverage

This change covers the native TMB `mu` endpoint with ordinary Beta random-intercept and independent numeric-slope providers, using point-recovery and group-keyed prediction checks. It does NOT cover Julia, animal or phylogenetic providers, correlated blocks, profile or bootstrap refits, calibrated intervals, or coverage. Continue the family-by-effect inventory. Before editing shared builders or TMB likelihood code, resolve the active Gaussian animal-SD lease and review the relevant branch diffs. The Julia paired lane remains under a foreign ownership warning and was not edited.
