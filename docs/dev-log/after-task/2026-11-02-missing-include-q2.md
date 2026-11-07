# After-task: q2 SD regression with missing responses

Date: 2026-11-02. Lane: codex/general-sd-regression (batch 23).

## Gap

`miss_control(response = "include")` was untested or refused for the
intercept-plus-slope (q2) routes that carry one SD formula per coefficient.

## What was probed

- Gaussian ordinary correlated q2, `y ~ x + (1 + x | id)` with
  `sd(id, coef = "(Intercept)")` and `sd(id, coef = "x")`: already accepted under
  include. No source change. It was untested, so this batch adds the oracle test.
- Poisson animal q2: refused by a builder gate (complete responses required).
- NB2 animal q2, unlabelled and labelled: refused by the early include gate.
- Gamma animal q2, unlabelled and labelled: refused by the Gamma include gate.
- Poisson labelled animal q2 with SDs is refused for a structural reason that
  has nothing to do with include ("one structured coefficient"). Unchanged.

## What the likelihood does

The Gaussian, Poisson (model_type 6), NB2 (7) and Gamma (5) branches guard each
row's response density with `observed_y`. The q2 latent prior (independent
fields, or R kron A when labelled) is a separate term over all nodes and does
not depend on y. So masking removes likelihood terms and leaves the prior
intact, and a group with no observed row keeps its nodes under the prior. No
C++ change was needed.

## What changed

- `R/drmTMB.R`: three gates widened, each to the animal intercept-plus-slope
  block with exactly two coefficient SD formulas, no ordinary `sd()` and no
  zero inflation. Poisson: `poisson_structured_include_ok` also accepts it.
  NB2: the early include gate also accepts it. Gamma: new
  `gamma_include_structured_q2_sd`. Roxygen and `man/drmTMB.Rd` for `missing`
  mention the route.
- New `tests/testthat/test-q2-sd-missing-include.R`.
- `inst/extdata/env-skip-census.tsv` regenerated (one row for the new file).

## Tests added

Six cases: Gaussian, Poisson, NB2 unlabelled and labelled, Gamma unlabelled and
labelled. 24 groups of 8 rows, about 20 percent NA, data order the reverse of
the covariance order, non-unit-scale A.

1. No group wholly missing: include logLik equals the complete-case logLik to
   1e-8, coefficients to 1e-6, and the independent oracle to 1e-6 relative.
   Gaussian oracle is the exact per-group marginal on observed rows. Count and
   Gamma oracle is a dense Laplace marginal over the 2G latent vector with
   prior R kron A, scored on observed rows. Emulated bugs move the oracle by
   more than 0.05 (NA scored as an observed 1, and the two SD surfaces swapped).
2. NA rows get finite mu predictions and every group has finite positive SDs.
3. Two groups wholly NA: logLik equals the prior-keeping oracle (1e-6) and the
   complete-case fit (1e-8).
4. Fences pinned with message patterns under include: Poisson relmat q2,
   zero-inflated Poisson animal q2, Poisson labelled animal q2, NB2 relmat q2,
   NB2 zero-inflated animal q2, Gamma relmat q2, Gamma one-sided animal SD.
   The default drop policy is unchanged.

No tolerance was loosened and no assertion was deleted.

## Receipted file edited (unavoidable)

`tests/testthat/test-poisson-structured-q2-sd-regression.R`
(in `direct-sd-evidence.tsv`). Its last expectation pinned Poisson animal q2
with include as refused, which is exactly the route admitted here. The pin now
uses the still-refused Poisson relmat q2 shape with the same message pattern,
and a comment points to the new file. Nothing else in that file changed. Its
receipt (sha256 and result summary) needs refreshing by the coordinator. All
other receipted neighbours are untouched.

## Results (Totoro, cores 8-11, NOT_CRAN=true, passed/failed/error/skipped)

- New `test-q2-sd-missing-include.R`: 158/0/0/0.
- Edited `test-poisson-structured-q2-sd-regression.R`: 45/0/0/0.
- Neighbours, all 0 failed: nbinom2-structured-q2 75,
  count-structured-q2-more-providers 165, nb2-gamma-sd-missing-include 114,
  count-structured-sd-missing-include 219, binomial-gamma-sd-missing-include
  241, poisson-sd-missing-include 37, gamma-animal-q2-correlated 56,
  gaussian-correlated-q2 17, structured-sd-nonunit-k-and-missing 53,
  poisson-iid-structured 170, nbinom2-batch5 150, structured-sd-q-ainv-quickwins
  92, env-skip-census 5, missing-data-capability-gate 11,
  missing-response-family-gate 2, gamma-structured-slope-sd 87,
  gamma-iid-structured 114, missing-response-poisson 29,
  missing-response-nbinom2 27, nbinom2-correlated-q2 12.

## Not admitted

Relmat, phylo and spatial q2 under include (pinned as refused in receipted
files), q2 with ordinary `sd()` beside it, zero inflation, `mi()` plus include,
Poisson labelled animal q2 (structurally refused).

## Not covered

Synthetic data and one seed per case. No recovery or coverage campaign, no
Julia engine route, no informative missingness. Design documents, NEWS and the
capability table were not updated and still describe these routes as
complete-response only.
