# After-task: Poisson and NB2 structured SD regression with missing responses

Date: 2026-11-02. Lane: codex/general-sd-regression (batch 21).

## Gap

`miss_control(response = "include")` was refused for every Poisson and NB2
structured SD route, for example
`bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z)` with some `y`
NA. The refusals were builder guards, not likelihood limits.

## What the likelihood does

The Poisson (`model_type == 6`) and NB2 (`model_type == 7`) C++ branches skip
only the response density of a row whose `observed_y` is 0. The latent
structured field (`u_phylo`) gets its Gaussian prior for every node regardless
of which rows are observed, and the node set is built in R from all kept rows,
including rows with an NA response. So masking removes likelihood terms and
leaves the prior intact.

A group whose responses are all NA keeps its node under the prior. Because that
node is a prior-only block of a Gaussian field it integrates out exactly, so
the include fit also equals the complete-case fit that never saw the group.
This was measured, not assumed: on every route (relmat, animal, phylo,
spatial, for both families) the include and complete-case log-likelihoods
agree to about 1e-12 with two groups fully NA, and the include fit matches a
dense Laplace oracle that keeps the prior term for every node. For the spatial
route the complete-case fit needs the coordinate table restricted to the
remaining ids, which the new test does.

## What changed

- `R/drmTMB.R`, Poisson: the structured SD gate now admits include when the
  model has exactly one unlabelled structured intercept (relmat, animal, phylo
  or spatial), one `sd(group, level = ...)` formula, no ordinary `sd()`, and no
  `zi`.
- `R/drmTMB.R`, NB2: the early include gate no longer refuses structured SD on
  its own. A new gate, placed right after the structured term is selected,
  applies the same one-structured-intercept rule and keeps the existing
  "requires complete data" message and a short hint.
- Roxygen and `man/drmTMB.Rd` for the `missing` argument mention the new
  routes. Design documents were not changed.
- New `tests/testthat/test-count-structured-sd-missing-include.R`.

## Tests added

For each family (Poisson, NB2) and each route (relmat with a permuted
non-unit-scale `K`, animal with `A`, phylo with a tree, spatial with shuffled
coordinates), 24 groups of 8 rows, about 20 percent NA, group levels in an
order different from the covariance order:

1. Include logLik equals the complete-case logLik to 1e-8, with matching mu and
   SD coefficients, `nobs` equal to the observed count, and logLik equal to an
   independent dense Laplace oracle (observed rows only) to 1e-6 relative.
   Emulated bugs move the oracle by more than 0.05: NA scored as an observed
   zero, and the SD surface attached to the wrong groups.
2. NA rows get finite mu predictions and every group has a finite positive SD
   prediction.
3. Two groups entirely NA: logLik equals the oracle that keeps the prior term
   for all nodes (1e-6), equals the complete-case fit (1e-8), and the
   NA-as-zero bug still moves the oracle.

A final test pins the fences with message patterns, for both families:
slope-only structured SD, intercept plus slope (q2), ordinary plus structured
(iid) SD, and zero-inflated structured SD all stay refused with include, and an
include build of the admitted shape succeeds. Without include the default
drop policy is unchanged.

Tolerances were fixed before the first run and none was loosened. The oracle
is written in the test file and shares no code with the engine; phylo and
spatial covariances come from two internal helpers whose alignment is
exercised by the deliberate order mismatch (disclosed in the file header).

## Not admitted, and why

- Ordinary plus structured (iid) SD routes with include. The likelihood would
  be fine, but admitting them contradicts three pins in receipted test files
  (`test-poisson-iid-structured-sd-regression.R` line 341,
  `test-nbinom2-batch5-sd-regression.R` line 394,
  `test-structured-sd-q-ainv-quickwins.R` line 517), each of which expects
  include to be refused. Editing receipted files was avoided. To admit this
  route later, relax `poisson_iid_structured` and `nb2_iid_structured`
  (drop `!include_missing_response`), move the three pins to a still-refused
  shape, and refresh their receipts.
- Slope-only and q2 structured routes. They are pinned as refused in the
  receipted `test-structured-sd-nonunit-k-and-missing.R` and
  `test-count-structured-q2-more-providers-sd.R`, which are untouched and pass.
- Zero-inflated structured include, `mi()` plus include, labelled blocks.

## Existing tests edited

- `tests/testthat/test-nb2-gamma-sd-missing-include.R` (not in the receipted
  `test_path` column): the NB2 structured pin used the now-admitted relmat
  intercept shape. It now uses the still-refused slope-only shape for NB2 and
  keeps the intercept shape for Gamma. No assertion was deleted or loosened.
- `inst/extdata/env-skip-census.tsv` regenerated (two rows for the new file).
- No receipted test file was edited.

## Results (Totoro, cores 0-3, NOT_CRAN=true, passed/failed/error/skipped)

- New `test-count-structured-sd-missing-include.R`: 219/0/0/0.
- `test-nb2-gamma-sd-missing-include.R`: 114/0/0/0 after the pin move.
- Receipted neighbours, all 0 failed: `test-structured-sd-nonunit-k-and-missing.R`
  53, `test-count-structured-q2-more-providers-sd.R` 165,
  `test-poisson-iid-structured-sd-regression.R` 170,
  `test-nbinom2-batch5-sd-regression.R` 150,
  `test-structured-sd-q-ainv-quickwins.R` 92,
  `test-poisson-structured-q2-sd-regression.R` 45,
  `test-nbinom2-structured-q2-sd-regression.R` 75.
- Other neighbours, all 0 failed: poisson-sd-missing-include 37,
  poisson-sd-assembly 45, poisson-slope-sd-assembly 22,
  missing-response-poisson 29, missing-response-nbinom2 27, poisson-phylo 6,
  nbinom2-phylo 4, poisson-relmat 19, poisson-animal 11, poisson-spatial 42,
  nbinom2-animal 16, nbinom2-relmat-spatial-intercept 34,
  sd-regression-g4-semantics 210, structured-sd-targets 16,
  missing-data-capability-gate 11, missing-response-family-gate 2,
  env-skip-census 5.

## Not covered

Synthetic data only, 24 groups. No recovery or coverage campaign, no Julia
engine route, no informative missingness (missing responses are treated as
ignorable given the predictors). Design documents and the capability table
still describe these routes as complete-response only and need a docs sync by
the coordinator.
