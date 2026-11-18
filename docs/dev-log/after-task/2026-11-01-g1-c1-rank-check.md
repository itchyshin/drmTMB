## 1. Goal

G1 review condition C1 (`docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`, section 2, risk 1): the general SD builders had no rank or size check on the group-level SD design, so `sd(id) ~ w1 + w2 + w3` with three groups, or two collinear group-level predictors, reached the optimiser and surfaced only as a singular Hessian.

## 2. Implemented

- New helper `check_sd_design_rank(X, dpar, group_name)` in `R/drmTMB.R`, placed before `validate_sd_mu_group_constant()`. It aborts with `cli::cli_abort()` when `nrow(X) < ncol(X)` ("more columns than groups") or when `qr(X)$rank < ncol(X)` ("rank deficient"). Both messages name the SD target (`dpar`, for example `sd(id)` or `sd_phylo(species)`), the grouping column, and the group count. The rank message lists the aliased columns taken from the QR pivot (the columns after the first `rank` pivots). A design with as many groups as columns and full rank is allowed, as the condition states "at least as many".
- Called once in `build_sd_mu_structure()` after `model.matrix()` and once in `build_sd_phylo_structure()` after `model.matrix()`. Sigma-side SD blocks (`sd_sigma` in the call sites) go through `build_sd_mu_structure()`, so they are covered by the same call. No other builder of an SD design exists (`grep` for `build_sd_` finds only these two definitions).
- Design note: `docs/design/18-random-effect-scale-models.md`, a paragraph after the within-group constancy rule.

## 3. Decisions

- I avoided cli pluralisation markers. The first draft used `{?s}` with several quantities in one string and cli raised "Multiple quantities for pluralization" at run time, so the messages use `group(s)` and `column(s)`.
- The size check runs before the rank check, because with fewer groups than columns the design is always rank deficient and the size message is the clearer one.
- For structured routes the group count is the number of observed provider levels (`R/drmTMB.R` structured builder, `sd_group_levels`), as the review said. The check does not count the kernel size.
- Not done, by design: the near-aliasing risk for q2 (review risk 2) is not detectable from the SD design alone. The note says rank is necessary and not sufficient.

## 4. Files Touched

- `R/drmTMB.R` (helper plus two call lines)
- `tests/testthat/test-sd-design-rank-check.R` (new)
- `docs/design/18-random-effect-scale-models.md`
- this note (new)

## 5. Checks Run

Tests, in `tests/testthat/test-sd-design-rank-check.R`: ordinary route (Beta, `drm_build_beta_ls_spec()`, `sd(id)`) and structured route (Beta `phylo()`, `sd(species, level = "phylogenetic")`), each with a collinear design (`z2 = 2 * z`, `z_dup = 3 * z_species`; the message must name the aliased column and the target) and an over-parameterised design (3 groups, 4 columns; message must name the target). A positive control confirms 3 groups with 2 columns is still accepted. Tolerances: none, all assertions are error-message matches.

Run on the private copy with `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true`, `pkgload::load_all()` then `testthat::test_file()`, one R process at a time. Counts (passed / failed / error / skipped), 19 files across Gaussian, Beta, Gamma, NB2, Binomial, lognormal and cumulative-logit routes, ordinary, animal, phylo, sigma-side and q2:

- test-sd-design-rank-check.R 10/0/0/0 (new)
- test-beta-sd-regression.R 26, test-beta-phylo-direct-sd.R 44, test-gaussian-animal-sd-regression.R 27, test-gaussian-sd-slope-regression.R 13
- test-gamma-sd-regression.R 17, test-gamma-phylo-sd-regression.R 15, test-nbinom2-animal-sd-regression.R 16, test-binomial-animal-sd-regression.R 12
- test-lognormal-sd-assembly.R 24, test-cumulative-logit-sd-regression.R 14, test-gaussian-sigma-sd-regression.R 15, test-gaussian-structured-q2-sd.R 64
- test-gamma-mu-sigma-joint-sd.R 26, test-structured-sd-nonunit-k-and-missing.R 53, test-gaussian-sigma-structured-sd.R 92, test-gamma-sigma-sd-regression.R 23
- test-gamma-animal-q2-correlated-sd.R 46, test-binomial-correlated-sd.R 102

Every file reported 0 failures, 0 errors, 0 skips. No admitted fixture tripped the new check. Not run: the other roughly 240 SD test files and the full suite.
