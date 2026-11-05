# After task: Poisson animal intercept-plus-slope with coefficient SDs

Date: 2026-11-01. Engine: native TMB only. Julia is not involved and was not run.

## What changed

A Poisson model with one unlabelled animal block, `animal(1 + x | id, A = A)`, can now carry one predictor-dependent SD formula for the intercept field and one for the slope field, for example `sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w` and `sd(id, level = "animal", dpar = "mu", coef = "x") ~ v`. The two latent fields stay independent (no cross-coefficient correlation), each scaled by its own per-group SD.

Edits:

- `R/drmTMB.R`, Poisson builder: the structured SD parser now accepts a two-coefficient animal term (intercept first) when SD formulas are present, requires exactly one formula per coefficient, renames duplicate SD labels by coefficient, and reuses the shared identifiability check (zero slope loading, or identical constant SD designs with a constant loading).
- `R/drmTMB.R`, `make_tmb_data()`: Poisson animal q2 now sets `has_sd_phylo_coef_model` and passes the per-coefficient SD row map.
- `src/drmTMB.cpp`, Poisson block (model type 6): the field scale is read from `phylo_mu_sd_row_coef(i, k)` when the coefficient map is on. The prior is unchanged: `log_sd_phylo` is already fixed at 0 whenever SD formulas exist, so the existing independent-field prior is the unit-scale prior.
- No shared parser code was edited beyond passing the existing `allow_multiple_coefficients` switch.

## Evidence

New file `tests/testthat/test-poisson-structured-q2-sd-regression.R` (45 expectations, 0 failures, run on Totoro):

- Dense Laplace oracle in plain R (unit-scale latent, exact Hessian, damped Newton), at the fitted parameters, three fixed seeds. Agreement tolerance 1e-4 absolute on the log-likelihood, fixed before the first run. The relative-tolerance form of the first draft was replaced by an absolute check.
- Fixture: 36 animals, A has a non-unit diagonal (0.8 to 1.6 scaling) and its rows and columns are shuffled relative to the data level order.
- Emulated bugs (swapped SD formulas, SDs shifted by one level, unaligned A, one SD surface used for both coefficients) each move the oracle by more than 1 log-likelihood unit.
- Constant SD formulas (`~ 1`, `~ 1`) match the formula-free `animal(1 + x | id)` fit (relative tolerance 1e-5).
- Predicted per-group SDs match the coefficients; conditional simulation (`re.form = NULL`) runs. Marginal simulation for a q2 structured block was already unsupported and is not claimed.
- Refusals that stay closed, with message patterns: only one of the two coefficients given an SD formula; labelled `(1 + x | p | id)` with SD formulas; relmat q2 with SD formulas; ordinary `sd()` beside a structured q2 block; zero-inflated model; `missing = miss_control(response = "include")`.

No existing test was edited or removed.

Neighbouring files re-run on Totoro, all with 0 failures, 0 errors: every `test-poisson-*.R` (non-Julia, 21 files besides the new one), `test-zi-poisson*.R` (4 files), `test-phase18-poisson-phylo-q1.R` (77), `test-gamma-animal-q2-correlated-sd.R` (46, shared `make_tmb_data()`), `test-binomial-relmat-q2-sd.R` (98). Key counts: batch5 45, correlated-q2 oracle 14, iid-structured 170, spatial 42, relmat 19, phylo 6.

## Not covered

- Phylo, relmat and spatial q2 with coefficient SDs stay refused (same C++ path would likely serve them; each needs its own provider-specific oracle first).
- Labelled correlated block with SDs (needs a rho oracle like the Gamma labelled route); `animal(1 + x | p | id)` with SDs stays refused.
- Zero-inflated and missing-response variants, ordinary `sd()` beside the block, sigma-endpoint SDs, mesh.
- Julia engine: not run. Whether the Julia bridge accepts this formula was not probed; the existing ordinary-mean fence in the bridge may refuse it independently.
- No recovery, calibration, coverage or Julia parity claim. The oracle checks likelihood evaluation at fitted parameters only. The ledger row for this mechanism is not updated here.
