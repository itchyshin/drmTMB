# Spatial q2 Confidence Eye joint calibration contract

**Date:** 2026-08-03  
**Branch base:** `b8fd1863d7207e2c728348bee760c125d38ac088` (PR #893 merge)  
**Surface:** dense coordinate-spatial, bivariate Gaussian, q2 location intercept, `REML = TRUE`  
**Status:** frozen pre-implementation contract; Noether and Fisher approval required before code or compute

## Decision

Finite profile endpoints do not establish calibrated uncertainty. The spatial
q2 article may gain a Confidence Eye only when the same prospective campaign
shows acceptable all-attempt 95% profile coverage for all three latent targets
at one common information floor:

```text
sd_spatial1, sd_spatial2, rho_spatial
```

A campaign result is evidence-complete whether the verdict is `PASS` or
`HOLD`. `PASS` permits the bounded article uncertainty claim only at the tested
passing rungs M `(36 sites, 3 each)` and H `(36 sites, 8 each)`, with M named
as the lowest tested jointly passing rung. It does not authorize interpolation
or extrapolation to another information configuration. `HOLD` preserves the
point-only article and records every failed attempt without retry substitution.

## Reconciliation ledger

| Label | Item | Binding disposition |
| --- | --- | --- |
| DONE | PR #893 | Fixed-kappa mesh point recovery landed without changing the dense `coords =` route. Mesh uncertainty remains outside this arc. |
| DONE | Dense spatial q2 point evidence | `mc-0199` and `mc-0672` have exact-cell point recovery. The single-fixture profile receipts establish endpoint feasibility for the two SD targets only. |
| OWED | Joint calibration | Prospectively calibrate both latent SDs and latent spatial correlation together, retaining every dataset attempt in every target denominator. |
| OWED | Common information floor | Select the lowest rung at which all three targets pass and all higher rungs pass; otherwise return `HOLD`. |
| OWED | Evidence packet | Preserve task ledger, raw target outcomes, failure taxonomy, hashes, environment, source SHA, scheduler receipts, reconciled summaries, and final claim decision. |
| RETRACTED | Endpoint sufficiency | A finite interval, an estimate inside one interval, or one successful low-rung fixture does not support an uncertainty claim. |
| RETRACTED | Target-wise cherry-picking | No target may receive its own favorable floor, and successful reruns may not replace failed attempts. |
| RETRACTED | Comparator rescue | Wald and bootstrap diagnostics cannot change a failing profile verdict. |
| PROTECTED | Dense route | Existing `spatial(..., coords = coords)` behavior, kernel construction, profile target names, and point-recovery evidence are not rewritten by this arc. |
| PROTECTED | Article boundary | The article remains point-only unless the joint gate passes and the passing render clears Florence review. |
| PROTECTED | Negative space | Mesh intervals, range estimation, slopes, q4+, non-Gaussian models, spatial `sigma`, derived observed correlations, geometry robustness, and `supported` tier are deferred. |

## Five-row symbolic alignment

For paired observation `i` at site `s(i)`, let

\[
\begin{aligned}
y_{1i} &= x_{1i}^\top\beta_1 + a_{1,s(i)} + \epsilon_{1i},\\
y_{2i} &= x_{2i}^\top\beta_2 + a_{2,s(i)} + \epsilon_{2i},\\
\begin{bmatrix}a_1\\a_2\end{bmatrix}
&\sim N\!\left(0,G\otimes K_{sp}\right),\\
\begin{bmatrix}\epsilon_1\\\epsilon_2\end{bmatrix}
&\sim N\!\left(0,R\otimes I\right),
\end{aligned}
\]

where `K_sp` is the existing fixed coordinate kernel and

\[
G=\begin{bmatrix}
\tau_1^2 & \rho_{sp}\tau_1\tau_2\\
\rho_{sp}\tau_1\tau_2 & \tau_2^2
\end{bmatrix},\qquad
R=\begin{bmatrix}
\sigma_1^2 & \rho_{12}\sigma_1\sigma_2\\
\rho_{12}\sigma_1\sigma_2 & \sigma_2^2
\end{bmatrix}.
\]

| Row | Symbol and role | Frozen R/profile identity | Truth | Gate role |
| --- | --- | --- | --- | --- |
| 1 | `tau1 = sd_spatial1` | `sd:mu:mu1:spatial(1 | p | site)` | `0.55` | claim target |
| 2 | `tau2 = sd_spatial2` | `sd:mu:mu2:spatial(1 | p | site)` | `0.55` | claim target |
| 3 | `rho_sp = rho_spatial` | `cor:spatial:cor(mu1:(Intercept),mu2:(Intercept) | p | site)` | `0.45` | claim target |
| 4 | `sigma1`, `sigma2` | constant estimated `sigma1 = ~ 1`, `sigma2 = ~ 1` | `0.18`, `0.20` | fitted nuisance; no interval claim |
| 5 | `rho12` | constant estimated `rho12 = ~ 1` | `-0.10` | fitted residual nuisance; never a proxy for row 3 |

The covariance cross-block is
`rho_sp * tau1 * tau2 * Z K_sp Z' + rho12 * sigma1 * sigma2 * I`.
This identity is the fail-closed check against exchanging latent and residual
correlations.

These are five reporting rows comprising six scalar covariance parameters.
Only rows 1–3 are profile-gated latent claim targets; rows 4–5 are fitted
nuisance parameters. Rows 1–3 are gated on public response scales:
`tau_r = exp(lambda_r)` and
`rho_sp = 0.999999 * tanh(eta_sp)`. The profile fixes the corresponding direct
internal TMB coordinate and back-transforms endpoints before comparing with
truth. This is a likelihood reparameterization: add no transformation
Jacobian and do not alter the REML objective, constants, or unit weights. Each
raw outcome records `tmb_parameter`, `index`, `scale`, and `transformation`.

## Frozen data-generating process

The campaign reuses the production coordinate-kernel construction and the
validated Phase-18 draw equations, but it must not call
`phase18_fit_spatial_q2()`, which fits ML. It must generate distinct covariates
`x1` and `x2`, fit `mu1 = y1 ~ x1 + spatial(...)` and
`mu2 = y2 ~ x2 + spatial(...)`, and set `REML = TRUE`. The distinct covariates
are a deliberate stacking-error control.

Freeze the fixed-effect truths as
`beta_mu1 = c("(Intercept)" = 0.35, x1 = 0.25)` and
`beta_mu2 = c("(Intercept)" = -0.20, x2 = -0.30)`. The five reporting rows
above comprise six scalar covariance parameters. Use complete paired
responses, unit weights, the baseline `ring` geometry from
`phase18_spatial_q2_coords()`, first-observed factor/site order, the existing
Euclidean exponential kernel, production diagonal jitter `1e-6`, and no
estimated range. Fit the exact q2 REML model:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
    mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = dat,
  REML = TRUE
)
```

The three information rungs are ordered, not factorial:

| Rung | `n_site` | `n_each` | Paired observations | Purpose |
| --- | ---: | ---: | ---: | --- |
| L | 12 | 3 | 36 | low-information boundary |
| M | 36 | 3 | 108 | more independent spatial units |
| H | 36 | 8 | 288 | more within-site residual separation |

No alternative geometry, truth, start, optimizer, or rung may be introduced
after results are visible.

Every dataset receipt records `coords_sha256`, `K_sp_sha256`, site order,
kernel condition number, applied jitter, and whether the production Cholesky
fallback fired. The baseline contract requires `jitter = 1e-6` and
`fallback_fired = FALSE`; a mismatch is a provenance failure and all three
target outcomes are non-covering.

## Seed ledger and execution stages

Rung indices are `L = 1`, `M = 2`, `H = 3`.

```text
smoke seed(r, j) = 260803000 + 1000*r + j, j = 1,...,20
full  seed(r, j) = 260900000 + 1000*r + j, j = 1,...,500
```

The smoke is 20 datasets per rung and is infrastructure-only. It may stop the
full launch for a runner, provenance, resource, or systematic profile defect,
but it cannot change the contract or count toward the 500-dataset campaign.
The full campaign contains exactly 1,500 dataset attempts and 4,500 target
outcomes. Compute runs as a DRAC job array, never on a login node or GitHub
Actions.

The smoke submission is fenced to `--array=1-60%60`. A compute-node setup job
first verifies and extracts the source archive, checks its embedded source-SHA
attestation, and installs that exact source into a new per-packet R library.
The smoke array has an `afterok` dependency on setup and executes only the
verified extracted runner. No full-stage submission wrapper exists before the
reconciled smoke receipt and its separate packet review.

## Per-attempt outcome contract

Each dataset is attempted exactly once under its ledger seed. Each of the three
target rows receives one terminal outcome even when the fit fails before
profiling. Required raw fields include:

```text
source_sha, packet_sha256, stage, rung, replicate, seed, n_site, n_each,
target, truth, estimate, lower, upper, covered, finite_interval,
tmb_parameter, index, scale, transformation, objective,
fit_convergence, pdHess, fit_warning, profile_status, profile_boundary,
profile_clamp_limited, elapsed_seconds, failure_class, failure_message
```

Define `point_fit_valid` as `fit_convergence == 0`, `pdHess == TRUE`, finite
objective and target estimates, and all three target estimates interior to
their guarded parameter spaces. Profile only a point-fit-valid dataset.
Terminal failure classes are `dgp_failure`, `provenance_failure`, `fit_error`,
`fit_nonconvergence`, `fit_pdhess_false`, `fit_nonfinite`,
`fit_target_boundary`, `profile_not_run_pointfit_invalid`, `profile_error`,
`profile_nonfinite`, `profile_boundary`, and `profile_clamp_limited`. A dataset
that fails before profiling still emits all three target rows; each receives
`profile_not_run_pointfit_invalid` plus the underlying fit failure detail,
`finite_interval = FALSE`, and `covered = FALSE` in the 500-attempt
denominator. A warning is retained verbatim but is not itself a failure when
the fit and profile satisfy every frozen condition. Any terminal failure,
missing row, duplicate seed, malformed interval, boundary-limited interval,
clamp-limited interval, or non-finite value is `covered = FALSE`. There is no
retry substitution.

## Joint gate and common floor

For target `t` and rung `r`, with exactly `N = 500` attempted datasets,

\[
\widehat C_{tr}=\frac{1}{500}\sum_{j=1}^{500}
I\{L_{trj}\le\theta_t\le U_{trj}\},
\qquad
\widehat F_{tr}=\frac{1}{500}\sum_{j=1}^{500}I\{L,U\text{ finite and valid}\}.
\]

The target-rung row passes only when all conditions hold:

```text
attempts == 500
unique seeds == 500
coverage in [0.925, 0.975]
finite valid interval rate >= 0.95
no provenance, schema, duplicate, or missing-row defect
```

Report the observed nominal-binomial Monte Carlo standard error
`sqrt(rate * (1 - rate) / denominator)` for all aggregate rates, including
coverage, finite interval, valid point fit, convergence, warning, and each
failure class. Also report diagnostic-only conditional finite-profile coverage
with its explicit `n_finite` denominator and MCSE. Report a Wilson interval for
each proportion for transparency. The `[0.925, 0.975]` rule is an observed
all-attempt operating-characteristic gate, not a confidence interval proving
true coverage lies in that range. MCSEs, Wilson intervals, and conditional
coverage are descriptive and are not additional gates.

A rung passes jointly only when all three target rows pass. The common floor is
the lowest jointly passing rung for which every higher rung also passes. If no
such rung exists, the campaign verdict is `HOLD`.

## Comparators

The profile interval is the featured and sole gating interval. A same-dataset
Wald/delta interval is recorded as a non-gating diagnostic. A plain parametric
bootstrap may be run only as a separately labelled diagnostic packet with its
own seeds and denominator; it cannot replace a profile failure, enter the
profile denominator, alter the common floor, or rescue `HOLD`.

## Provenance and reconciliation

The submitted packet freezes the source SHA and SHA-256 hashes of the contract,
runner, reconciler, task ledger, and SLURM script. Every task writes to a unique
path and records scheduler job/array IDs. Reconciliation fails closed on source
or packet mismatch, an unexpected seed, a duplicate or absent target row, an
incorrect attempt count, or an output produced outside the frozen packet.
Raw failures remain immutable; summaries are regenerated from raw rows.

## Review and publication gates

1. Noether and Fisher approve this contract before implementation or compute.
2. Mechanical tests and a deterministic local one-dataset probe establish only
   runner correctness, never coverage.
3. Grace approves the hashed DRAC packet before the smoke launch.
4. The 20/rung smoke clears infrastructure before the 500/rung launch.
5. One D-43 panel reviews the reconciled evidence and proposed claim.
6. Only a `PASS` campaign may add the bounded Confidence Eye to the article;
   Florence reviews that passing render before merge.
7. A `HOLD` campaign merges the complete negative evidence and leaves the
   article point-only.

## Compute authority

Shinichi explicitly authorized the DRAC array, the 20/rung smoke, and completion
of the full arc in this task on 2026-08-02. This is bounded advance authority
for the frozen packet only. Fisher/Noether/Grace approval validates the design
and packet but does not create compute authority.

The full 1,500-dataset launch is conditionally pre-authorized after a clean
smoke receipt when all of the following hold: no contract or source change, no
systematic fit/profile/provenance defect, projected array wall time no more than
12 hours, and projected consumption no more than 2,000 CPU-hours. The smoke
receipt must record measured task-time quantiles, peak memory, projected array
wall time at the submitted concurrency, and projected CPU-hours. Exceeding any
bound, changing the packet, or observing a systematic defect stops the launch
for fresh explicit authorization.

## Claim boundary

At maximum, `PASS` supports 95% profile uncertainty for the exact dense
coordinate-spatial Gaussian q2 REML intercept cell, under the baseline ring
geometry, at the two tested rungs M `(36 sites, 3 each)` and H
`(36 sites, 8 each)` only. M is the lowest tested jointly passing rung; L
`(12 sites, 3 each)` failed, and no untested larger, intermediate, or
alternative information configuration is covered. It does not support mesh
intervals, spatial range estimation, slopes, q4+, non-Gaussian families,
spatial scale models, derived observed correlations, geometry robustness, or
the `supported` tier.
