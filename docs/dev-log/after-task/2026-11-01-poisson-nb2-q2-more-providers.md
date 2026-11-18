# After-task report: Poisson and NB2 structured q2 SD regression, more providers

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression (branch codex/general-sd-regression, base b6629f435).

## What changed

Earlier today Poisson and NB2 structured intercept-plus-slope (q2) models with one SD formula per coefficient were admitted for the animal provider only. This slice admits three more providers for both families: relmat (supplied K or supplied Q), phylo (tree) and spatial (fixed-range coordinate kernel). The labelled covariance form (`relmat(1 + x | p | id)` and so on) stays closed for these providers.

No new engine layer was needed. The C++ q2 branches already take the group precision from `Q_phylo` and do not depend on the provider type. The restriction was only in R, in three places in `R/drmTMB.R`:

1. `drm_build_poisson_spec`: the `allow_poisson_structured_q2_sd` flag now accepts animal, relmat, phylo and spatial (unlabelled only, as before).
2. `drm_build_nbinom2_spec`: the `allow_nb2_structured_q2_sd` flag accepts the same providers. Animal keeps its labelled form. The other three require an unlabelled term.
3. `make_tmb_data`: the gate that sets `has_sd_phylo_coef_model` and `phylo_mu_sd_row_coef` listed only animal for Poisson and NB2.

The third place matters. With only the first two edits the models built and fitted, but the per-row coefficient SD map was left empty, so the SD formulas were silently ignored. The oracle test caught this (log-likelihood off by 1.6 to 4.8 units, and a C++ error for NB2). That is the emulated-bug sensitivity result in practice, not only in the synthetic perturbations.

## Tests

New file `tests/testthat/test-count-structured-q2-more-providers-sd.R`, 165 expectations, covering both families and all three providers.

Oracle: a dense Laplace marginal likelihood in plain R at the fitted parameters, with a dense kernel built in the test file (never the package precision or log-determinant), `dpois` or `dnbinom` data terms and analytic dense Hessians. Kernels are built independently: relmat uses a non-unit diagonal D C D kernel; phylo uses a random coalescent tree with the covariance divided by the tree height, checked against the package's tip covariance; spatial uses exp(-d / median distance) plus 1e-6 on the diagonal. Factor levels of `id`, kernel order and tree tip order are all shuffled against one another, so alignment is by name.

Tolerances were fixed before the first run and not changed: 1e-4 absolute for oracle agreement, 1e-5 for the constant-SD log-likelihood equivalence, 1 log-likelihood unit for each emulated bug (swapped SD formulas, shifted group SDs, unaligned kernel, one SD used for both coefficients). One fixture change was made after the first run: the true SD effects on the log scale were raised from 0.5 to 0.8 and the data enlarged (36 groups, 16 repeats), because the first fixture gave fitted SD surfaces too flat for the emulated bugs to be detectable. The thresholds themselves did not move.

Other checks in the file: relmat K and Q inputs and reversed SD formula order give the same log-likelihood; constant SD formulas match the formula-free fit for every provider and family; per-coefficient SD predictions and `simulate(re.form = NULL)`; refusal checks with message patterns (one SD formula missing, labelled block, ordinary random effect beside the block, zero inflation, missing responses included).

Two existing refusal pins relied on unlabelled relmat q2 with SDs being closed. Both were swapped to a still-refused route (labelled relmat q2 with SDs), with the message pattern for that route, in `test-poisson-structured-q2-sd-regression.R` and `test-nbinom2-structured-q2-sd-regression.R`. No assertion was deleted and no tolerance changed.

## Results

Each file was run on its own on the Mac with one R process at a time (passed, failed, errors, skipped):

- test-count-structured-q2-more-providers-sd.R (new): 165, 0, 0, 0
- test-poisson-structured-q2-sd-regression.R: 45, 0, 0, 0
- test-nbinom2-structured-q2-sd-regression.R: 75, 0, 0, 0
- test-count-structured-mu.R: 533, 0, 0, 0
- test-nongaussian-structured-boundary.R: 81, 0, 0, 0
- test-nbinom2-correlated-q2-sd.R: 12, 0, 0, 0
- test-poisson-correlated-q2-sd.R: 13, 0, 0, 0
- test-poisson-correlated-q2-sd-oracle.R: 14, 0, 0, 0
- test-structured-re-conversion-contracts.R: 22234, 0, 0, 0
- test-coefficient-labels.R: 122, 0, 0, 5 (the five skips are existing)
- test-nbinom2-sigma-structured-recovery.R: 6, 0, 0, 0
- test-mesh-contract.R: 48, 0, 0, 0

The full test suite and `devtools::check()` were not run.

## What this does not cover

- This is a likelihood-evaluation check at fitted parameters. It is not a recovery, calibration, coverage or Julia-parity claim.
- Mesh (SPDE) spatial q2 with coefficient SDs is not tested here. The coordinate-kernel spatial route is the one tested.
- Labelled (correlated) NB2 or Poisson q2 for relmat, phylo and spatial remains closed.
- Zero-inflated, ordinary random effect beside the block, and missing-response-included variants remain refused.
- Julia engine routes for these provider and family combinations were not touched.
- Design documents and the capability map were not updated in this slice.
