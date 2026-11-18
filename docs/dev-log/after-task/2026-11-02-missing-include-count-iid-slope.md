# After-task: Poisson and NB2 ordinary-plus-structured and structured slope-only SD with missing responses

Date: 2026-11-02. Lane: codex/general-sd-regression (batch 23, private copy, no lane commit).

## Gap

Batch 21 admitted `miss_control(response = "include")` for one structured intercept with its own SD formula, and left two Poisson and NB2 shapes refused:

1. One ordinary intercept plus one structured intercept (relmat, animal or phylo), each with its own SD formula: `y ~ x + relmat(1 | id, K = K) + (1 | site)`, `sd(id, level = "relmat") ~ z_id`, `sd(site) ~ z_site`.
2. A structured slope-only term with its own SD formula: `y ~ x + relmat(0 + x | id, K = K)`, `sd(id, level = "relmat") ~ z`, for relmat (K and Q), animal (A, Ainv, pedigree), phylo and spatial.

Both refusals were builder guards. The Poisson (`model_type` 6) and NB2 (7) C++ branches mask each row's density with `observed_y` and apply the Gaussian prior to every latent node, structured or ordinary, whatever the observed rows are. So the likelihood already supported both shapes.

## Source edits (R/drmTMB.R only; nothing in src/)

- `drm_build_poisson_spec()`: `poisson_iid_structured` no longer contains `!include_missing_response`. `poisson_structured_include_ok` now also accepts a structured slope-only term (relmat, animal, phylo, spatial, unlabelled, no ordinary random term beside it), and accepts an ordinary SD formula when `poisson_iid_structured` holds.
- `drm_build_nbinom2_spec()`: the include gate for structured SD accepts a structured intercept or slope-only term and at most one ordinary SD formula (the slope-only shape allows none), still with no zero inflation and no second structured field. `nb2_iid_structured` no longer contains `!include_missing_response`, so the later iid checks decide the rest. The refusal hint now names the new shapes.

One consequence to know about: an ordinary `sd()` formula beside a structured intercept that has no `sd()` of its own was refused under include only because `nb2_iid_structured` and `poisson_iid_structured` carried the include condition. It is now admitted, because it is the same iid gate. It is tested (relmat, both families, include equals complete-case).

## Evidence (tests/testthat/test-count-iid-slope-sd-missing-include.R, new)

Fixtures: 24 structured groups of 8 rows with the row order and level order shuffled against the covariance order, Toeplitz K with diagonal 1.6 for relmat and animal, `ape::rcoal` tree for phylo, a ring of coordinates for spatial, 12 random site levels for the iid shape, every fifth row set to NA.

- Poisson and NB2, iid with relmat, animal and phylo; slope-only with relmat, animal, phylo and spatial. For each case: include equals complete-case log-likelihood within 1e-8, coefficients (mu, structured SD, site SD) within 1e-5, `nobs` equals observed rows, and the log-likelihood equals an independent dense Laplace oracle within 1e-6 relative. The oracle stacks the structured and site latent vectors, scores observed rows only and keeps every group's prior term.
- Bug sensitivity: scoring NA as an observed zero, and attaching the SD surface to reversed groups, each move the oracle by more than 0.05.
- Whole groups missing (two structured groups all NA): the oracle keeps the empty nodes under the prior, and the fit matches it within 1e-6. The complete-case fit also matches within 1e-8, as marginalisation of a prior-only Gaussian block requires. NA rows and empty groups get finite predictions and every group has an SD.
- Slope-only Q, Ainv and pedigree inputs: include equals complete-case, equals the K or A form fit (1e-5), and equals the oracle. The pedigree has founders only (A is the identity), so it checks plumbing, not inbreeding.
- Ordinary SD beside a plain structured intercept: include equals complete-case.
- Refusal pins with message patterns: zero-inflated iid and slope-only (Poisson "non-inflated model with complete responses", NB2 "complete data"), spatial intercept beside an ordinary SD, an ordinary random effect beside a slope-only structured term, and q2 structured SD.

One pre-declared bar was handled by changing the fixture, not the bar. The reversed-SD sensitivity gap for Poisson relmat iid was 0.02 against the declared 0.05, because the SD slope was small. The iid fixture now uses a structured log-SD slope of 0.9 instead of 0.5. No agreement tolerance changed and no assertion was deleted. Two earlier first-run failures were test-code errors (seed above the integer range, and the SD name filter for `sd(site)`).

## Existing tests edited (none receipted)

- `tests/testthat/test-count-structured-sd-missing-include.R` (batch 21, not in `direct-sd-evidence.tsv`): the slope-only and iid refusal pins were removed, with a comment pointing to the new file.
- `tests/testthat/test-nb2-gamma-sd-missing-include.R` (not receipted): the NB2 structured pin moved from slope-only to the still-refused q2 shape. Gamma keeps its slope-only pin.
- `tests/testthat/test-poisson-sd-missing-include.R` (not receipted): the pin that refused a relmat intercept beside one ordinary random effect (with `sd(site) ~ 1`) now expects the builder to accept it, and the refusal moved to two ordinary random effects beside the structured intercept (38 expectations after, 37 before plus one).
- `inst/extdata/env-skip-census.tsv` regenerated (two rows for the new file).

## Receipted files whose pins must be swapped by the coordinator

Not edited here. The replacement code is in `batch23-missing-include-count-iid-slope-pins.patch`, generated against the lane files:

- `test-structured-sd-nonunit-k-and-missing.R` (slope-only refusal for seven routes becomes `expect_no_error` on the builders plus a zero-inflation refusal).
- `test-poisson-iid-structured-sd-regression.R`, `test-nbinom2-batch5-sd-regression.R`, `test-structured-sd-q-ainv-quickwins.R` (the iid include refusal becomes a builder check that keeps every row).

Their `test_sha256` receipts need refreshing after the swap. `test-count-structured-q2-more-providers-sd.R` also has an include pin (Poisson q2); it is unaffected, and q2 is still refused.

## Not covered

Synthetic data only, one seed per case, no recovery or coverage campaign, no Julia engine route, missing responses treated as ignorable. Spatial iid, ordinary slope beside a structured term, labelled and zero-inflated routes and `mi()` predictors stay refused. The capability table, vignettes, NEWS and `direct-sd-evidence.tsv` were not touched, so the new file has no evidence row yet.
