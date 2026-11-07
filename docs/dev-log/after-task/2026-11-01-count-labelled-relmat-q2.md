# After-task: labelled relmat q2 with coefficient SDs for Poisson and NB2

Date: 2026-11-01. Lane: codex/general-sd-regression (PR 1663).

## Question

`relmat(1 + x | p | id, K = K)` with one SD formula per coefficient was refused
for Poisson and NB2 while the unlabelled form was admitted. Does the label mean
something different here?

## Finding

In this package a covariance label marks a block shared across distributional
parameters or responses. Inside a single `mu` formula there is nothing to
share with, but the label still changes the model: the unlabelled structured
q2 block has two independent unit-scale latent fields, and the labelled block
adds one cross-coefficient correlation `rho`, so the latent prior is R kron K
with R = [1 rho; rho 1]. The NB2 `animal()` route already works this way
(`cor(mu:(Intercept),mu:x | p | id)`, report symbol `rho_phylo`). The labelled
form is therefore not an alias of the unlabelled fit; it is a nesting model, and
no cross-dpar sharing is needed. The engine already supported it, so the change
is a gate change only.

## What changed

- `R/drmTMB.R`, Poisson builder: `allow_poisson_structured_q2_sd` now accepts a
  labelled block when the provider is `relmat`.
- `R/drmTMB.R`, NB2 builder: `allow_nb2_structured_q2_sd` and the labelled
  intercept-slope type list for `validate_count_structured_mu_term` now include
  `relmat` next to `animal` when SD formulas are present.
- `docs/design/01-formula-grammar.md`: the structured count q2 row now says
  what is admitted and what stays refused.
- New `tests/testthat/test-count-labelled-relmat-q2-sd.R`.

## Tests (new file)

Fixture: 36 groups of 16, non-unit-diagonal `K`, shuffled factor levels, `K`
supplied in a different shuffled order, true rho 0.8, two group-level SD
predictors. Tolerances fixed before the first run.

- Dense Laplace oracle (plain R, independent kernel, prior R kron K, fitted
  rho) at 1e-4 absolute, Poisson and NB2, two seeds each.
- Six emulated bugs each move the oracle by more than 1 log-likelihood unit:
  swapped SD formulas, shifted levels, unaligned K, one SD for both fields,
  rho dropped, rho sign flipped.
- Correlation reported under the labelled name, equal to the engine report,
  nested above the unlabelled fit, absent from the unlabelled fit; label name
  arbitrary; `Q` and `K` agree at 1e-4.
- Constant-SD reduction: oracle at 1e-4 for both families, and equality with
  the plain labelled Poisson block at 1e-5 (the plain labelled NB2 relmat block
  stays refused, so NB2 has no plain comparator).
- Group SD predictions match the fitted surfaces; conditional `simulate()`.
- Refusals with message patterns: one SD formula only, ordinary term beside the
  block, zero inflation, plain labelled NB2 relmat, labelled phylo for Poisson
  and NB2.

Result on Totoro (cores 16-19): 104 expectations pass, 0 fail, 0 error.

## Existing pins that must change (not edited in the lane copy)

Four assertions pinned the old refusal and now fail, as expected:

- `tests/testthat/test-count-structured-q2-more-providers-sd.R` lines 367 and
  372 (Poisson and NB2 labelled relmat).
- `tests/testthat/test-poisson-structured-q2-sd-regression.R` line 245.
- `tests/testthat/test-nbinom2-structured-q2-sd-regression.R` line 290.

All three files carry evidence receipts, so they were left alone. A separate
patch, `batch19-count-labelled-relmat-q2-pin-tests.patch`, swaps each pin to a
still-refused route (labelled spatial with SD formulas, labelled relmat with
`zi ~ 1`, plain labelled NB2 relmat) without deleting or loosening any
assertion. With it applied the three files pass (165, 45 and 75 expectations).
The coordinator must refresh their receipts if the patch is applied.

## Not covered

No Julia parity, no interval calibration, one DGP family, no recovery study
beyond a fixed-seed band. Labelled Poisson `animal()`, labelled phylo and
spatial, and labelled blocks across `mu` and `sigma` were not touched. The NB2
generic refusal text still names only `animal(1 + x | id)`; it was left as is.
