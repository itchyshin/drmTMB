# After Task: Beta-binomial animal matrix-input SD regression

## 1. Goal

Test whether the existing native Beta-binomial animal direct-SD route also works with supplied covariance `A` and precision `Ainv`, and document the result without broadening the claim beyond the tested providers.

## 2. Implemented

Added synthetic fits using a covariance matrix and its precision, with both matrices jointly permuted relative to the factor order. The test checks convergence, recovery of the SD slope, group-named SD predictions and likelihood agreement with the pedigree-input fit. Both provider fits pass. No production code change was needed; the existing builder and structured likelihood already admit the two matrix forms.

The tested model retains `log(tau_g) = alpha_0 + alpha_1 z_g` and covariance `D A D` for the animal location effect. The `Ainv` fit supplies the corresponding inverse relationship matrix. This extends provider evidence for the same q1 Beta-binomial `mu` intercept, complete responses and fixed `sigma`.

## 3a. Decisions and Rejected Alternatives

The supplied matrices use the same synthetic DGP and are permuted by matching row and column labels. This checks label-based mapping as well as provider equivalence. The capability denominator and its claim fields are unchanged. Julia parity and interval calibration remain outside this provider-input check.

## 4. Files Touched

- `tests/testthat/test-beta-binomial-animal-pedigree-sd-regression.R`.
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/known-limitations.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`, `docs/dev-log/general-sd-regression/inventory.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`.
- `.unlazy/general-sd-regression/GATES.md`, `LOOP/lanes/general-sd-regression/checkpoint.md`, `docs/dev-log/check-log.md`, and this report.

## 5. Checks Run

- Focused test command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-binomial-animal-pedigree-sd-regression", reporter = "summary")'`. It passed after correcting the test's local pedigree binding; the first attempt had a parser setup error because a formula argument used `fx$pedigree` instead of a named object.
- The broader Beta-binomial test filter `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^(beta-binomial|beta-binomial-sd-integration|beta-binomial-sd-slope-integration|beta-binomial-sd-slope|beta-binomial-animal-pedigree-sd-regression)$", reporter = "summary")'` was stopped after exceeding the two-minute estimate. The new animal-provider test and 10 preceding assertions passed; no test failure was observed before interrupt. The stopped run provides no full-filter result.
- Current-source render command `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/predictor-dependent-random-sd.Rmd", output_file = "/private/tmp/predictor-dependent-random-sd-beta-binomial-animal-matrix-final.html", quiet = TRUE)'` passed with only the existing Pandoc `--mathjax` deprecation warning.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'pkgdown::check_pkgdown()'` passed with existing Pandoc `--mathml` deprecation warnings. The previous whole-site build stopped when the sandbox could not resolve CRAN; see the preceding slice's check-log entry.
- `gh issue list --state open --search '"beta-binomial" "animal" in:title,body' --json number,title,url` returned only issue #1243, about reciprocal companion links between R and Julia tutorials. That issue remains unchanged.
- The after-task structure check passed (`TRUE`). `slop_check.py` reported 0 findings across 729 words, with no em dashes. Scoped `git diff --check` passed on the tracked files changed in this slice.

## 6. Tests of the Tests

The test uses real fitted models, not mocks. It reverses both matrix dimensions together while preserving dimnames, compares both matrix likelihoods with the pedigree likelihood, checks the generating SD slope, and compares predicted SDs with the fitted coefficient formula for observed animal labels. Its first failure was a formula-construction error, which was fixed before evaluating provider behavior.

## 7a. Issue Ledger

The open-issue search returned issue #1243, about reciprocal companion links between R and Julia tutorials. Its scope is tutorial navigation; it was left unchanged. No issue was opened, commented on, or closed.

## 8. Consistency Audit

Current formula and likelihood references, the random-effect-scale guide, formula-grammar table, predictor-dependent-SD tutorial, adapter map, inventory, known limitations, roadmap and NEWS now distinguish the three tested animal inputs from remaining providers and engines. Julia parity, other structured providers and interval calibration remain open. The full 19,118-row universe is unchanged.

Exact status-inventory search:

```sh
rg -n -i 'A/Ainv|supplied covariance|precision input|Beta-binomial.*animal|animal.*Beta-binomial' README.md NEWS.md _pkgdown.yml docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/18-random-effect-scale-models.md docs/dev-log/known-limitations.md docs/dev-log/internal-roadmap.md docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md docs/dev-log/general-sd-regression/inventory.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd
```

README status and `_pkgdown.yml` navigation were checked; neither required a change for the provider addition.

## 9. What Did Not Go Smoothly

The initial test run stopped in formula parsing because the fixture passed a data-frame expression where the parser requires a named pedigree object. Binding the pedigree locally fixed the test setup. The provider fits then passed without production changes.

## 10. Known Residuals

This evidence covers only native TMB, complete Beta-binomial responses, one q1 animal `mu` intercept and fixed `sigma`. It does not establish other animal encodings, other structured effects, Julia parity, profile/bootstrap routing, interval calibration or full public-output consistency. G3, G4 and G6 receive partial evidence only and remain open.

## 11. Team Learning

When a provider accepts labeled matrices, deliberately permute both dimensions and compare the fitted likelihood with the equivalent provider route. This catches silent dependence on input order while retaining the user-facing labels.

## 12. Cross-Product Coverage

Covers: native R/TMB Beta-binomial q1 animal `mu` intercept direct-SD fits using pedigree, covariance `A`, and precision `Ainv` inputs, with synthetic point recovery, group-SD predictions and matrix-likelihood comparison under a joint label permutation.

Does NOT cover: Julia, other response families, other structured providers, animal slopes, other random-effect targets, profile/bootstrap behavior, interval calibration, or completion of the general SD-regression goal.
