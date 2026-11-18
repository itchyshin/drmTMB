# After task: NB2 phylogenetic-interaction intercept and slope-only SD regression

Date: 2026-11-01. Engine: native TMB only. Julia is not involved and was not run.

## What changed

An NB2 model with one unlabelled `phylo_interaction(1 | plant:pollinator, tree1, tree2)` intercept, or one `phylo_interaction(0 + x | plant:pollinator, tree1, tree2)` slope-only term, can now carry a predictor-dependent SD formula, for example `sd(pair, level = "phylogenetic_interaction") ~ z_pair`, with `sigma ~ 1`. The SD varies by observed species pair.

Edits, all in `R/drmTMB.R`, NB2 builder (`drm_build_nbinom2_spec`):

- The `phylo_interaction` extractor on `mu` now passes `allow_slope = TRUE`, as the Poisson builder already does.
- `"phylo_interaction"` is added to the slope-only structured `mu` types accepted by `validate_count_structured_mu_term`.
- `"phylo_interaction"` is added to the structured types the NB2 SD-regression guard accepts.

No C++ change was needed. The NB2 structured block already scales the latent field by the per-level SD row map for any structured provider, and the Poisson route already used the same machinery.

Side effect to note: the slope-only guard is not tied to the presence of an SD formula, so a plain NB2 `phylo_interaction(0 + x | ...)` fit without any `sd()` formula now also passes the builder guard. That route has not been given its own oracle here.

## Evidence

New file `tests/testthat/test-nbinom2-phylo-interaction-sd.R` (55 expectations, 0 failures, run on the Mac, one R process):

- Dense Laplace oracle in plain R (damped Newton on the pair latent, exact NB2 information, size = 1 / sigma^2), evaluated at the fitted parameters. Agreement tolerance 1e-4 absolute on the log-likelihood, fixed before the first run, for both the intercept and the slope-only variants.
- Fixture: 8 plants by 4 pollinators (32 pairs, different tree sizes), tip labels shuffled relative to tree numbering, pair rows shuffled. The pair covariance is `kronecker(A2, A1)` with plant fastest. Trees use the package correlation form, so K has a unit diagonal. A non-unit diagonal is not available for phylogenetic providers; this differs from the animal and relmat tests, which do use non-unit K.
- Emulated bugs, each required to move the oracle by more than 0.05 log-likelihood units: wrong loading (x for the intercept, 1 for the slope), a constant mean SD, a swapped Kronecker order, a wrongly scaled K (2K). All were caught.
- Constant-SD (`~ 1`) fit matches the formula-free fit (logLik relative 2e-5, mu coefficients 1e-4); nesting check; row-order invariance 1e-5.
- Predicted pair SDs match the coefficients and the stored `sdpars`; conditional simulation is deterministic given a seed and returns integers; the fit survives an RDS round trip.
- Refusals that stay closed, with message patterns: SD input varying within a pair; pair labels that do not identify observed pairs one-to-one; zero inflation; an ordinary `(1 | plant)` beside the interaction term; a structured `sigma` term; an SD level that does not match the provider.

Tolerances were not changed after the first run. Two test-side corrections were made during development: the unit-diagonal point above (the "unscaled K" emulated bug was vacuous, so it became 2K), and refusal patterns were set to the messages the builder actually raises.

## Not covered

- Intercept-plus-slope (q2) `phylo_interaction` with coefficient SDs, labelled correlated blocks, zero inflation, missing-response and `mi()` variants, ordinary `sd()` beside the field, and sigma-endpoint SDs stay refused.
- Marginal simulation for this route is not claimed.
- Julia engine: not run and not probed.
- No recovery, calibration, coverage or Julia parity claim. The oracle checks likelihood evaluation at fitted parameters only. The ledger row is not updated here.
