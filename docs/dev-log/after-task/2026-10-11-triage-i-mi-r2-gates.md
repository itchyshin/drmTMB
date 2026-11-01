# 2026-10-11: STEP 2 mi() weight gates (no quadrature rewrite)

Reader: Shinichi deciding #1459, and the Code Reviewer who blocked
`a72d37645` because the #1459 warning was false for every non-Gaussian
`mi()` family.

## Task goal

Keep the Gaussian `mi()` prior unweighted until #1459 is decided, but
warn only on the C++ paths that actually leave the prior unweighted.
Do not change the Beta/Gamma quadrature in this slice.

## What changed

The classed warning `drmTMB_mi_weights_prior_unweighted` is driven by
`drm_mi_prior_path_unweighted()`. That helper is true only when the
first predictor family is `"gaussian"` or a second Gaussian predictor
is enabled. Those are the three unweighted `nll -= dnorm(...)` sites:

- `mi_family == 0` location-scale Gaussian at `src/drmTMB.cpp:1301`
- `has_mi2 == 1` second Gaussian at `:1342`
- `mi_family == 0` nbinom2-response copy at `:4556`

`R/mi-weights.R:3-5` listed the second-predictor and nbinom2 x Gaussian
entries. Both are still unweighted Gaussian priors in the compiled
code. Every other family block from `:1357` multiplies the prior by
`weights(i)` (Dinnage M1). A Beta `mi()` fit with `weights = 2` does
not warn. A Gaussian fit still does.

Weight 0 on an observed Gaussian row now uses
`if (asDouble(weights(i)) > 0)` so the log-density never enters the
AD tape. The pin rebuilds the TMB object after a clean fit, sets
`y[4] = 1e200`, and asserts finite `fn` and `gr` at the sane MLE.
On `main` that case is `fn = NaN` and `gr = -Inf`.

`predict()` / `simulate()` allow `weights = 1` and refuse non-unit
weights. The TMB message no longer names DRModels.jl.

`engine = "julia"` still refuses non-unit weights for every family.
The weights check in `drm_julia_joint_prepare()` now runs before the
family check. A Beta `mi()` call with `weights = 2` is
`drmTMB_julia_mi_weights_unsupported`.

The Dinnage M1 helper re-polishes the weight-2 fit from the unit-weight
MLE, restores the duplicate-row versus weight-2 coefficient compare,
and limits any leftover gap to Gamma with the GH-IS + nlminb-scale
reason.

`.Rlib/` is gitignored. The tracked C17 run-1 folder is restored.
C17 was recertified on this tree (`--label triage-i-mi-r2 --tolerance
1e-10`): `|change| 0.000e+00` on mc-0568 / 0569 / 0576. The runner
temporarily moved run-1 because it hardcodes that path; this commit
puts the folder back.

`src/drm_numeric.h` and `src/drm_response_kernels.h` were not edited.
`R/drmTMB.R` and `R/methods.R` were not edited.

## STEP 1 estimate only (no quadrature code)

Code Reviewer receipt on `a72d37645`: the new 31-node prior-centred
IS is not an `integrate()` match. Beta at `mu` 0.02 / 0.10 with
`sigma = 1` has errors up to 48 and 8.9. Mid-range Beta (`mu` 0.02,
`sd_y` 0.1, `x` 0.5) regressed from `2.6e-5` (old 15-node) to 2.63.
Gamma at CV 0.10 has errors 0.06-0.34; CV >= 1 can hit ~70 log units
or NaN when every term underflows.

### Adaptive rewrite (posterior-mode Gauss-Hermite)

What has to change. Each missing-x row would centre a Gauss-Hermite
grid on the posterior mode of `x`, using a fixed 5 Newton steps on
the log or logit scale (no `CondExp`, so every iterate stays on the
tape). Scale by local curvature, add the response family's own
`log f(y | x)`, drop `log_mass` renormalisation, and abort if a row
underflows to NaN or `-Inf - -Inf`.

Family blocks in `src/drmTMB.cpp`. The Gaussian-response path has 13
`mi_family` blocks from `:1260` (0 gaussian, 1 bernoulli, 2 ordinal,
3 categorical, 4 beta, 10 zero-one-beta, 12 beta-binomial, 5 poisson,
8 nbinom2, 11 truncated_nbinom2, 6 lognormal, 7 gamma, 9 tweedie).
Eight more Bernoulli copies sit on other response `model_type`s
(`:2726`, `:2983`, `:3132`, `:3265`, `:3689`, `:3884`, `:4175`,
`:4286`). The nbinom2-response path repeats gaussian and bernoulli
at `:4544` and `:4577`. Finite-state families (bernoulli, ordinal,
categorical) already sum exactly and do not need Gauss-Hermite.
The continuous quadrature families that would take the rewrite are
Beta, zero-one-Beta interior, Gamma, lognormal, and tweedie. The
count families (poisson, nbinom2, truncated_nbinom2, beta-binomial)
use discrete nodes today; forcing Gauss-Hermite on them is a new
design, not a drop-in centre-and-scale.

New derivatives. Newton needs `d/dx` and `d2/dx2` of
`log prior(x) + log f(y | x)`. `drm_response_log_density` already
returns the response log-likelihood, but not those derivatives in
`x`. Gaussian `y | x` is a quadratic and is cheap. Poisson or Beta
`y | x` needs the chain rule through `mu(x) = eta + beta (x - x0)`.
That helper has to be shared, or each family block will grow its
own Hessian.

Risks. A U-shaped Beta prior (`mu` 0.02, `sigma = 1`) plus an
informative mid-range `y` is a bimodal posterior. Five Newton steps
to one mode, then a local Gauss-Hermite scale, can still miss the
other mode. That is the same region where the current IS regresses
from `2.6e-5` to 2.63. A unimodal Laplace proposal may fail the
stated acceptance (`integrate()` error `< 1e-4` at those U-shaped
points) even after the rewrite. Discrete-`x` families, zero-one-Beta
atoms, a non-positive-definite Hessian, and the AD tape of five
unconditional Newton steps are the other structural risks. Dropping
`log_mass` will expose any leftover missing tail instead of hiding
it. `src/drmTMB.cpp` will change again, so C17 must be recertified.
M1 (`weights(i)` outside the mixture) must stay intact.

Invasiveness. High. The work is a new shared Newton-on-unconstrained-scale
helper, per-family prior gradient/Hessian, response-in-`x` Hessian,
R mirrors, replacement of the tautological mass tests, and design-doc
updates to MD7a / MD7d / MD8b. It touches every missing-x quadrature
loop on the Gaussian-response path and any copied loop on other
response types. It should not edit `src/drm_numeric.h` or
`src/drm_response_kernels.h`.

### Fallback (restore the old 15-node Beta rule)

What has to change. Revert `drm_beta_mi_is_node` and its R mirror to
the pre-#1513 15-node Gauss-Legendre rule. Optionally revert Gamma
to the frozen 20-node Gauss-Laguerre rule as well. Keep every STEP 2
#1459 gate. Add follow-up issues that pin the known `integrate()`
failures instead of claiming a fix.

Invasiveness. Low. Two helpers, their R mirrors, the quadrature
manuals, and NEWS / design wording. No new Newton code. C17 only if
`src/drmTMB.cpp` changes.

Risks. #1476 and #1477 stay open. Mid-range Beta returns to the old
`2.6e-5` error, which is the Code Reviewer's regression example.
Low-CV Gamma on the old Laguerre grid collapses again. Near-zero
Beta mass returns. The fallback is honest documentation, not a
numerical fix.

## Files

- `R/mi-weights.R`, `R/missing-data.R`, `R/julia-joint-missing.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-mi-weights-1459.R`,
  `test-julia-mi-weights.R`, `test-dinnage-audit-m1-families.R`,
  `test-guard-branch-continuity.R`
- `docs/design/03-likelihoods.md`, `docs/design/22-likelihood-weights.md`,
  `NEWS.md`, `.gitignore`
- restored
  `docs/dev-log/implementation-recovery/2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1/`
- new
  `docs/dev-log/implementation-recovery/2026-10-11-triage-i-mi-r2-c17c2-c14-final-source-compatibility/`

## Checks

Focused local after `pkgload::load_all()` (R 4.3.3, TMB 1.9.25):
`test-mi-weights-1459.R` 0 fail / 10 tests; `test-julia-mi-weights.R`
0 fail / 5 tests; `test-guard-branch-continuity.R` 0 fail / 15 tests,
`n_cpp = 32L`; Dinnage M1 families 0 fail / 11 tests. C17
`|change| 0.000e+00`. Full-suite counts are recorded in the check-log
after `test_dir()`.

## Consistency audit

```sh
rg "drm_weight_times_logdens" src R tests docs
rg "drmTMB_mi_weights_prior_unweighted|drm_mi_prior_path_unweighted" R tests
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" NEWS.md docs/design docs/dev-log/after-task
```

The old CondExp helper name remains only in historical check-log
lines. Current code uses the data-level `asDouble` skip.

## Tests of the tests

The warning helper is false for Beta/Gamma families and true for
Gaussian and for Beta-plus-second-predictor. The Gaussian weight-2
"one prior row" test stays Gaussian-only. The `y = 1e200` pin
evaluates `fn`/`gr` at a sane parameter, not after an optimizer
that starts from a poisoned mean of `y`. Julia Beta `weights = 2`
hits the classed refusal before the family check, including through
`drm_julia_joint_prepare(family = beta_family(), weights_missing = FALSE)`.

## What did not go smoothly

Fitting `drmTMB()` from scratch with `y = 1e200` on a weight-0 row
fails because starting values use the raw response. The pin therefore
rebuilds `MakeADFun` after a clean fit. Recertify still hardcodes
the run-1 directory; the folder was moved only for that command and
restored in this commit.

## Left

Do not start the adaptive quadrature rewrite. Do not restore the old
15-node rule in this PR. #1477 / #1476 remain Refs, not Fixes.

Refs #1477
Refs #1476
Refs #1459
