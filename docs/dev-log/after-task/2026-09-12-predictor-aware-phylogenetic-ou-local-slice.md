# After-task report: predictor-aware phylogenetic OU local slice

## Goal

Add an explicit OU alternative to the Brownian-motion default for the admitted
univariate Gaussian phylogenetic location intercept, and test the requested
location--scale--direct-SD body-mass form on Ayumi's all-species data without
claiming recovery, intervals, or a general BM-versus-OU preference.

## Implemented

`phylo(..., model = "ou")` is explicit; omitted `model` remains BM. The admitted
route has one Gaussian `mu` phylogenetic intercept, fixed effects in `mu` and
`sigma`, and an optional direct phylogenetic-SD amplitude formula. Its positive
location rate is reported as `decay_phylo` (the compatibility name for
`alpha_mu`). Provider metadata now records a field identifier and an
`alpha_index0`; the compiled template holds `log_decay_phylo` as a vector and
selects the field's rate through that index. The current public route contains
one field at index zero.

The portable Ayumi runner and its fail-closed verifier retain the four-cell
BM/OU by constant/climate-residual-scale ladder, exact source commit and
checksums, model diagnostics, and the explicit claim boundary.

## Mathematical contract

For a positive location-side rate alpha and edge length ell,
`rho = exp(-alpha * ell)` and the stationary root-and-edge tree construction
defines the unit OU correlation. With a direct SD design, the marginal
phylogenetic covariance is `D_gamma C_OU(alpha_mu) D_gamma`; it replaces the
ordinary scalar phylogenetic scale instead of multiplying it. Fixed-effect
`sigma ~ temperature + precipitation` changes independent residual variation
and creates neither a second phylogenetic field nor `alpha_sigma`.

## Files changed

The implementation is in `R/drmTMB.R` and `src/drmTMB.cpp`; the independent
native-oracle and parser guards are in
`tests/testthat/test-phylo-ou-covariance-native.R` and
`tests/testthat/test-phylo-ou-covariance-parser.R`. Reproducibility tools are
`tools/phylo-ou-ayumi-bodymass-ladder.R`,
`tools/verify-phylo-ou-ayumi-bodymass-receipt.R`, and
`tools/phylo-ou-recovery-preflight.R`. Formula, likelihood, reader, and
capability wording was reconciled in the R help, `NEWS.md`, `README.md`,
`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
`docs/dev-log/known-limitations.md`, and the phylogenetic/model-map vignettes.

## Checks run

Focused gates G1--G4 all emitted their required `PHYLO_OU_G*_PASS` markers
after the indexed-vector change. `devtools::document()` passed. The receipt
verifier passed against `/private/tmp/phylo-ou-ayumi-bodymass-ladder-verified`
at Ayumi source commit `6c52a46f67d9d86842ae5476dee828684f64a464` with 10,440
rows/tips and all four REML cells. `git diff --check` passed after the final
documentation and verifier changes.

## Tests of tests

The dense independent covariance oracle compares objective, gradient, and
observed Hessian against the native sparse tree likelihood. Its mutations reject
wrong edge normalization, shared-depth covariance, wrong direct-SD placement,
and an accidental BM substitution. Parser tests reject sigma-side OU rather
than silently sharing `alpha_mu`; BM default/parity tests remain in the focused
suite. The receipt verifier checks schema, current source commit, source
checksums, four required cells, convergence/Hessian status, and `check_drm()`
diagnostic counts.

## Empirical and recovery evidence

The exact Ayumi ladder converged for all cells. BM constant/climate max gradients
were approximately `3.6e-10` and `9.9e-11`; OU constant/climate were `0.0157`
and `0.00121`, with BFGS fallback warnings and alpha estimates near zero. A
12-fit clean-versus-weak simulation preflight retained variable clean alpha
estimates and frequent weak-design non-positive-definite Hessians. These are
negative inference findings, so the public boundary remains local fit/oracle
only.

## Consistency and issue audit

The formula grammar, likelihood design, README, model map, phylogenetic reader
article, NEWS, and limitations consistently distinguish `alpha_mu`, deterministic
residual `sigma`, direct-SD amplitude, and deferred `alpha_sigma`. The public
Ayumi issue list was inspected read-only: issue #12 is the all-species
location-scale-scale specification and issue #2 is the future sigma-side
phylogeny question. Neither was modified.

## What did not go smoothly

The receipt verifier originally checked the stored commit and diagnostics too
weakly; it now verifies the current source HEAD and required diagnostic columns.
The 1,000-tip OU-plus-climate-scale preflight took 55.97 seconds, converged only
after fallback, and had `pdHess = FALSE` with max gradient 5.2566678. Sandbox
restrictions prevented `/usr/bin/time -l` from querying RSS. The source-lane
lease registry was also unavailable for a durable write, although the isolated
worktree and preflight found no active file overlap.

An independent direct process sampler was then denied `ps` access by the same
sandbox and reproduced the numerical fit without an RSS value. This rules out
the two local telemetry paths used here; it does not establish a memory bound.

## Known limitations and open gates

G0 remains open because the lane lease could not be durably persisted. G6 remains
open because no RSS was recorded and the 1,000-tip fit is numerically weak. G9
remains open. The provider indexing is a safe one-field allocation seam, not
multi-field OU support: a future sigma-side field needs distinct provider/data
plumbing, field loops, named extraction/profile targets, `alpha_sigma`, and its
own validation arc. There is no bivariate, missing-response, temporal, slope,
forecast, `newdata`, recovery, interval, coverage, or BM-preference claim.

## Next actions

Do not broaden this slice on the basis of the empirical fit. First obtain a
resource-capable sparse preflight that records RSS, then decide whether the
one-field local-fit/oracle slice should be promoted or remain developer-facing.
The next mathematically distinct arc is sigma-side phylogeny with a separate
`alpha_sigma`; it must not reuse `alpha_mu` implicitly. A retained recovery or
calibration campaign requires a fresh estimate and approval if the preflight
shows it will exceed 30 minutes.
