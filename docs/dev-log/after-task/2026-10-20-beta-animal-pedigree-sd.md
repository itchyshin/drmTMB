# After Task: Beta animal-pedigree SD regression

## 1. Goal

Add one bounded native Beta capability: predictor-dependent latent SD for a q1 animal-model intercept built from a pedigree, with tests and accurate support documentation.

## 2. Implemented

The Beta builder now routes `sd(id, level = "animal") ~ z` through the existing structured-SD parser and design builder. For latent effects `b ~ N(0, D A D)`, the model uses `log(s_i) = alpha_0 + alpha_1 z_i` for observed animals and preserves the supplied pedigree covariance scaling. Unobserved founders remain in the pedigree precision but need no SD predictor row because the observation-level multiplier is applied only to observed nodes. The family `sigma` formula remains fixed-effect-only in this slice.

A deterministic synthetic test checks convergence, recovery of the log-SD slope, predictions indexed by animal, and equivalence between a constant-SD formula and the existing constant-SD model. The direct-SD ledger universe remains unchanged, so this report is the evidence pointer rather than a row-status edit.

## 3a. Decisions and Rejected Alternatives

The first selector-only attempt sent `sd_animal()` to the ordinary random-effect resolver. The test exposed that mismatch. The final change uses the structured target parser, which already validates the provider type, group name, and intercept-only constraint. No likelihood or TMB code change was needed.

The test leaves founders unobserved and verifies that their latent nodes retain the no-observation SD-row sentinel while observed animals receive predictions.

## 4. Files Touched

This slice changes `R/drmTMB.R`, adds `tests/testthat/test-beta-animal-pedigree-sd-regression.R`, and updates the existing structured-target expectation in `tests/testthat/test-beta-phylo-direct-sd.R`. It also updates `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/dev-log/general-sd-regression/inventory.md`, `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/predictor-dependent-random-sd.Rmd`.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-animal-pedigree-sd-regression", reporter = "summary")'`: passed.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-animal-pedigree-sd-regression|beta-phylo-direct-sd|gamma-animal-pedigree-sd-regression", reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with existing Pandoc `--mathml` deprecation warnings.
- `devtools::load_all(".", quiet = TRUE)` followed by rendering `vignettes/predictor-dependent-random-sd.Rmd` to `/private/tmp/predictor-dependent-random-sd.html`: passed. The initial render without `load_all()` used a stale installed package and failed before the new chunk; the worktree-loaded render completed.
- `git diff --check` scoped to the files changed for this slice: passed. A repository-wide diff check separately reports a pre-existing extra blank line at EOF in `tests/testthat/test-binomial-sd-integration.R`; that file was outside this slice and was left untouched.
- Read-only issue search, `gh issue list --state open --search '"Beta animal" in:title,body' --json number,title,url`: no matching open issue.

## 6. Tests of the Tests

The first run failed before fitting because the Beta builder rejected `sd_animal()`. After structured routing, a second run exposed that the shared SD builder incorrectly required design rows for unobserved pedigree founders. The builder now creates SD rows only for observed groups while retaining the founders in the latent precision structure; the fixture observes offspring only. The final fit and neighbouring structured-SD tests pass.

## 7a. Issue Ledger

No matching open GitHub issue was found. No issue was opened, edited, or closed.

## 8. Consistency Audit

The formula, parser, and builder agree on `sd(id, level = "animal") ~ z`. The covariance remains `D A D`; predictor values are constant within each animal and defined for observed animals; unobserved founders keep their latent precision nodes without SD design rows. The docs now describe this as a single native Beta pedigree-intercept point-recovery slice. The exact inventory search used was `rg -n 'Beta.*direct|beta.*direct|Beta.*animal|Beta.*phylo|pedigree.*SD|animal.*direct-SD' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`. No README status entry or pkgdown navigation change was indicated. The shared check log was already modified in this worktree and was not edited.

## 9. What Did Not Go Smoothly

A broad text patch first matched the Gaussian builder. That accidental edit was restored before testing. The first test also confirmed that structured animal SDs cannot use the ordinary random-effect target resolver. The final patch is confined to Beta's structured-SD routing.

## 10. Known Residuals

This is point-recovery and output evidence, not interval or coverage validation. It does not establish Julia parity, pedigree-A scaling across other inputs, A or Ainv animal inputs for Beta, structured slopes, multiple or correlated effects, or broader Beta direct-SD support. The larger general-SD goal remains active.

## 11. Team Learning

When a family has both ordinary and structured SD routes, classify selectors before target resolution and test a structured provider directly. For structured SD predictors, align design rows to observed groups while preserving latent precision nodes that are not observed.

## 12. Cross-Product Coverage

This task does NOT cover Julia, other response families, A/Ainv animal inputs for Beta, other structured providers, random slopes, correlated or multi-endpoint blocks, missing-data combinations, profile or bootstrap behaviour, interval calibration, or coverage. These remain in the active general predictor-dependent random-effect SD goal.
