# After Task: Native ordinary NB2 mean--scale covariance prerequisite

## Goal

Add the smallest native TMB route needed for the 0.7.1 R--Julia parity arc:
one labelled ordinary NB2 random-intercept pair shared by `mu` and `sigma`.

## Implemented

`bf(count ~ x + (1 | p | id), sigma ~ z + (1 | p | id))` now fits one
complete-data, non-zero-inflated ordinary NB2 intercept pair. The parser
refuses slopes, multiple or unmatched labels, structured terms, missing-data
integration, and zero inflation. Existing one-sided labelled-term refusals
remain on their former validation paths.

## Mathematical Contract

For group `j`, the native branch uses independent standard-normal latents
`u_j` and `v_j`, and sets the scale-side latent effect to
`rho * u_j + sqrt(1 - rho^2) * v_j`, where
`rho = 0.999999 * tanh(eta_cor_mu_sigma)`. Both latent priors remain
unweighted; observation weights, when used by the established NB2 likelihood,
affect only response densities. `sigma` stays on its log-predictor scale and
NB2 size remains `1 / sigma^2`.

## Files Changed

- `R/drmTMB.R` admits and wires the one-pair NB2 route.
- `src/drmTMB.cpp` applies the conditional scale latent effect in the NB2
  branch and reports its transformed correlation.
- `tests/testthat/test-nbinom2-location-scale.R` supplies a fixed-seed data
  fixture and checks parser, report, transform, extractor, and target behavior.
- `README.md`, `vignettes/formula-grammar.Rmd`,
  `docs/design/01-formula-grammar.md`, `docs/design/04-random-effects.md`,
  `docs/design/143-phase-18-structured-workflow-registry.md`, and
  `docs/dev-log/known-limitations.md` state the narrow boundary.

## Checks Run

The focused NB2 suite passed after the final implementation. The combined
NB2, covariance-registry, and profile-target suites passed in 34.2 seconds.
Exact commands and test-of-test history are in
`docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-native-coupled-nb2.md`.

## Tests Of The Tests

The test first failed against the old NB2 refusal. A first native patch exposed
a non-positive-definite Hessian because its correlation parameter had no NB2
objective path. The final assertions compare the transformed outer parameter,
the TMB report, and independently reconstructed sigma modes, not merely fit
class or convergence.

## Consistency Audit

The status-inventory scan covered `README.md`, the internal roadmap, `NEWS.md`,
the known-limitations ledger, formula grammar design and vignette, and pkgdown
configuration. It found stale NB2-only wording in the README, vignette,
limitations ledger, and workflow registry; these files now distinguish the
one-pair parity route from broader labelled count covariance. Historical NEWS
items and roadmap history were left intact.

## GitHub Issue Maintenance

Open issue #1260 is the existing integrator-mismatch umbrella. It was inspected
but not commented on: this native prerequisite has no cross-engine receipt yet,
so a status update would overstate technical closure. No duplicate issue was
opened.

## What Did Not Go Smoothly

The C++ template contains visually similar scale-random-effect blocks. The
first patch landed in a neighbouring family branch, producing a zero NB2
correlation gradient. The deterministic Hessian assertion caught that error
before any bridge fixture was created.

## Team Learning

For multi-family TMB templates, use a family-unique nearby marker when patching
and check the resulting diff's `model_type` location before compiling. A fitted
outer parameter is not evidence that it reaches the requested likelihood.

## Known Limitations

This is native, source-level plumbing only. It neither proves R--Julia parity
nor adds a general NB2 mean--scale covariance capability, profiles, or coverage
evidence. The Julia scalar `:Laplace` work is committed separately; the bridge,
same-target inference receipts, matrix regeneration, cost probe, and the
approval-gated 500-seed campaign remain ahead.

## Next Actions

Build the R-to-Julia coupled NB2 fixture and bridge refusal controls against
the pinned DRM.jl scalar-Laplace commit. Then classify all shared outer targets
before regenerating the parity matrix. Do not start the coverage campaign until
the measured cost probe has been reviewed and explicitly approved.
