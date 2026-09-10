# S0 map decision — homogeneous temporal Toeplitz

## Decision

Use the **reflection-coefficient (partial-autocorrelation) map**.  For a
schedule with `K` common occasions, optimise unconstrained
`eta_1, ..., eta_(K-1)` and set `kappa_m = tanh(eta_m)`.  The inverse
Levinson recursion maps the `kappa_m` values to
`r_0 = 1, r_1, ..., r_(K-1)`.  It then constructs
`R = Toeplitz(r_0, ..., r_(K-1))`.

For recursion step `m`, with the order `m - 1` predictor coefficients
`a` and innovation variance `v`, use

\[
r_m = \sum_{j=1}^{m-1} a_j r_{m-j} + \kappa_m v,
\qquad
 a^{(m)}_j = a^{(m-1)}_j - \kappa_m a^{(m-1)}_{m-j},
\qquad v^{(m)} = v^{(m-1)}(1-\kappa_m^2).
\]

Every finite `eta` has `|kappa_m| < 1`; therefore the resulting finite
Toeplitz correlation matrix is strictly positive definite.  The inverse
recursion recovers `eta` from a valid lag sequence.  The map uses only
smooth elementary operations and finite loops, so the same recursion can
be evaluated on the TMB automatic-differentiation tape in S2.  It needs no
projection, retry, or post-hoc positive-definiteness repair.

`sd_temporal` remains separate: the native covariance will be
`sd_temporal^2 * R + sigma^2 * I`.

## Why the two alternatives were rejected

| Map | Positive definite | Toeplitz by construction | Decision |
| --- | --- | --- | --- |
| Reflection coefficients plus inverse Levinson | Yes | Yes | Chosen. |
| Generic unconstrained Cholesky, then correlation normalisation | Yes | No | Reject: it gives a general correlation matrix and does not enforce common lag correlations. |
| One independently squashed parameter for each lag | No | Yes | Reject: each lag can lie in `(-1, 1)` while the full Toeplitz matrix is indefinite. |

The official glmmTMB covariance vignette lists homogeneous Toeplitz among
its supported structures, and its native implementation transforms each
lag parameter individually before filling Toeplitz diagonals.  That is
useful source-map evidence, but it is not a safe drop-in map for this
provider because direct per-lag bounds do not establish positive
definiteness for every proposed `R`.

Sources consulted 2026-09-10:

- [glmmTMB covariance-structures vignette](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html)
- [glmmTMB native covariance implementation](https://github.com/glmmTMB/glmmTMB/blob/master/glmmTMB/src/glmmTMB.cpp)

## Retained numerical evidence

`tools/temporal-homtoep-map-study.R` and its test file use 480 deterministic
random maps: 40 draws for every `K = 1, ..., 12`, seed `20260910`.

- Smallest observed eigenvalue: `5.735652e-13`, positive but intentionally
  close to the parameter-space boundary.
- Reconstruction recovers a five-lag `eta` vector within `1e-10`.
- Central-difference Jacobians at steps `1e-6` and `1e-5` differ by at most
  `8.881795e-11`.
- The independently bounded-lag counterexample has minimum eigenvalue
  `-0.6641006`.
- The generic-Cholesky counterexample has Toeplitz-diagonal deviation
  `0.5384139`.

The `1e-13` random-stress threshold is a floating-point acceptance floor,
not a new statistical boundary.  The provider must later warn about weak
information and near-boundary fitted correlations; S0 does not claim that
all such parameters are well identified.

## What S0 does and does not authorize

T3-2 closes the parameter-map choice.  It authorizes S1 grammar and layout
work.  It does not authorize native likelihood code, recovery evidence,
profile intervals, a compute campaign, or claims about model calibration.
