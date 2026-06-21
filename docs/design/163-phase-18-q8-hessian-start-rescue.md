# Phase 18 Q8 Hessian And Start Rescue

This note records the next q8 individual-difference rescue gate after the
2026-06-08 stress audit. The reader is the contributor deciding whether q8
needs better starts, a different optimizer path, or a different interval
strategy before any coverage or power claim.

## Current Evidence

The fitted surface is the ordinary bivariate Gaussian all-endpoint block:

```r
bf(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 + x | p | id),
  sigma1 = ~ x + (1 + x | p | id),
  sigma2 = ~ x + (1 + x | p | id),
  rho12 = ~ 1
)
```

This model has eight group-level endpoint SDs and 28 group-level endpoint
correlations. Residual `rho12` is a separate residual coscale parameter and
must not be treated as one of the group-level q8 correlations.

The 2026-06-08 q8 stress audit wrote
`docs/dev-log/simulation-artifacts/2026-06-08-q8-stress-audit/`. With
`se = FALSE` and the existing 800-iteration budget, all five manifests
completed, two fits converged, and no failure-ledger rows were written. The low
replication row and both positive and negative residual-`rho12` rows remained
nonconverged or ill-conditioned.

The important correction is that the q8 artifact lane uses `se = FALSE`.
Therefore a `pdHess_rate` of zero in those artifacts means no positive-Hessian
evidence was computed; it is not by itself proof that `TMB::sdreport()` computed
a non-positive-definite Hessian.

## Hessian Probe

The 2026-06-08 Hessian probe reran the two stress rows that had converged with
`se = FALSE`: high latent q8 correlation and weak endpoint SD ratio. It used
`se = TRUE` with the same 800-iteration budget, then repeated the same two rows
with `optimizer_preset = "careful"`.

Artifacts:

- `docs/dev-log/simulation-artifacts/2026-06-08-q8-hessian-probe/`
- `docs/dev-log/simulation-artifacts/2026-06-08-q8-hessian-probe-careful/`
- `docs/dev-log/simulation-artifacts/2026-06-08-q8-hessian-probe-comparison/`

Both `se = TRUE` strategies gave the same qualitative result: 0/2 convergence,
0/2 positive-Hessian fits, warning rows with `NaNs produced`, and
ill-conditioned latent q8 correlation matrices. The high latent-correlation row
had maximum fitted absolute correlation about 0.965 and condition number about
2.38e10. The weak-SD-ratio row had maximum fitted absolute correlation about
0.982 and condition number about 2.60e9.

This is stronger evidence than the earlier `se = FALSE` stress audit. It says
that the two apparently converged point-estimate fits are not ready for
Hessian-based inference when standard errors are requested.

## Staged-Start Gate

A true staged-start q8 rescue should not be hacked inside a simulation script.
The public `drmTMB()` interface still has no `start =` argument, and start-like
control names remain reserved. The local implementation now uses an internal
hook instead: `drm_fit_spec()` fits a prepared specification and
`drm_apply_start_override()` applies named `spec$start` blocks after
`add_covariance_probe_parameter(spec)` and before `TMB::MakeADFun()`.

The q8-specific mapper `drm_qgt2_staged_start_override()` now maps shared fixed
effects by model-matrix column name and q>2 endpoint SDs by member key. It can
also copy common q4-to-q8 correlation starts through a pair-key and
packed-theta reconstruction helper, with shrinkage and positive-definite
regularization before the packed `theta_re_cov` vector is passed to TMB. The
default remains conservative: `copy_theta_re_cov = FALSE` keeps
`theta_re_cov` at the target neutral start unless a diagnostic runner requests
the theta-staged strategy explicitly.

The follow-up start-hook preflight is now recorded in
`docs/design/165-phase-18-q8-start-hook-preflight.md`. It keeps public
start-like control names reserved, records the source tests, and records the
first paired cold-versus-staged pilot.

The staged-start ladder should be:

1. fixed-effect bivariate Gaussian location-scale model;
2. q4 location block for `mu1` and `mu2`;
3. q6 location block if the target has more than one location slope;
4. q8 all-endpoint block with inherited fixed-effect, SD, and correlation
   starts where names match.

Promotion requires paired comparisons on the same seeds: cold q8 start versus
staged q8 start, with convergence, `TMB::sdreport()` status, maximum gradient,
minimum correlation eigenvalue, and condition number reported by diagnostic
preset. The first one-row pilot on low replication (`q8_diag_001`, seed
`20260641`) improved optimizer code from 1 to 0 and improved the minimum q8
correlation eigenvalue from 5.57e-14 to 2.26e-7, but that is not enough to
promote q8 coverage, power, or interval evidence.

## Sample-Size And Theta-Start Pilot

The 2026-06-09 usability pilot wrote
`docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-pilot/`. It reran
the five hard diagnostic rows and added a sample-size ladder with 24 x 6,
48 x 10, and 96 x 12 group-by-repeat designs. Each row compared cold q8,
q4 SD-staged q8, and q4 theta-staged q8 starts; the high latent-correlation
and high sample-size rows also requested `se = TRUE`.

The result is sample-size conditional rather than binary. In the low
sample-size row, cold and SD-staged starts errored with a non-positive leading
minor, while theta-staged q8 fit but still returned optimizer code 1. In the
baseline row, all three starts fit but the q8 correlation matrix remained
near-singular, with minimum eigenvalues around 5.4e-16 to 4.1e-15. In the high
sample-size row, cold and SD-staged `se = TRUE` fits reported `pdHess = TRUE`
and substantially better q8 correlation conditioning: minimum eigenvalues
2.05e-6 and 4.26e-6, and condition numbers 1.27e6 and 6.11e5. Those high-row
fits still returned optimizer code 1 under the 800-iteration budget, so they
are stronger usability evidence, not coverage or power promotion evidence.

Theta-staged starts are therefore a diagnostic option, not the default answer.
They rescued the weak-SD stress row from a cold-start leading-minor error to
optimizer code 0, with minimum q8 correlation eigenvalue 2.83e-7 and condition
number 1.20e7. They also got through one low sample-size row where cold and
SD-staged starts failed. But they worsened some low-replication and
high-correlation rows, and in the high sample-size row theta-staged `se = TRUE`
reported `pdHess = FALSE` where cold and SD-staged fits reported
`pdHess = TRUE`.

## Profile And Bootstrap Fallback Gate

The 2026-06-08 fallback pilot wrote
`docs/dev-log/simulation-artifacts/2026-06-08-q8-profile-bootstrap-fallback-pilot/`.
It reran the five hard diagnostic rows with cold q8 and q4-staged q8 starts,
then ran `se = TRUE` Hessian probes on the weak-SD-ratio and high-correlation
rows.

The profile-target inventory gives the main boundary. Across the five staged
q8 fits, fixed effects, residual `rho12`, and the eight endpoint SDs per fit
were direct targets and `profile_ready = TRUE`. The 28 q8 group-level
correlations per fit were derived `unstructured_corr` rows with
`profile_ready = FALSE` and `profile_note = "derived_unstructured_correlation"`.
That means `rho12` and endpoint SDs can use the direct interval machinery, but
q8 group-level correlations cannot be treated as direct atanh-profile targets.

One endpoint profile interval did work. For the staged low-replication fit,
`confint(..., method = "profile", profile_engine = "endpoint", level = 0.70)`
returned a response-scale interval of 0.239 to 0.359 for
`sd:mu:mu1:(1 + x | p | id):(Intercept)`, with `conf.status = "profile"`.
This is a scalar direct-target success, not a q8-wide interval promotion.

The generic public bootstrap route did not rescue that same staged fit. A
three-replicate smoke for the same direct SD returned
`bootstrap_unavailable`, with 0/3 successful refits and the warning
`NA/NaN function evaluation`. The same public bootstrap route also rejected a
q8 group-level correlation before refitting because derived q8 correlations
are not supported bootstrap targets. A q8 correlation bootstrap would need a
separate developer artifact path that refits models, extracts `corpairs()` or
`corpars$re_cov`, records refit failures, and summarizes the derived statistic;
it is not available through `confint(..., method = "bootstrap")` today.

The 2026-06-09 inference pilot wrote
`docs/dev-log/simulation-artifacts/2026-06-09-q8-usability-inference-pilot/`.
On the weak-SD row, theta-staged q8 reached optimizer code 0 but retained
`pdHess = FALSE`. A direct endpoint-SD profile returned a 70% interval of
0.135 to 0.194 for the first `sd:mu` intercept target, with one
`NA/NaN function evaluation` warning and 71 seconds elapsed. The requested
30-second elapsed limit is only best-effort around native TMB/profile code.
The custom derived-correlation bootstrap wrote 29 draw rows from two requested
refits, but one refit was nonconverged and the other errored with a
non-positive leading minor, so no percentile interval rows were produced.

## Optimizer-Budget Pilot

The 2026-06-09 optimizer-budget pilot wrote
`docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/`.
It reran the high sample-size row (`q8_size_003`, 96 groups x 12 repeats,
seed `20260687`) with `se = TRUE`, the same three starts, and two `nlminb`
budgets: 800 and 1600 evaluations/iterations.

Doubling the budget did not change the fitted pattern on this row. Cold q8 and
q4 SD-staged q8 both returned convergence code 1 with `pdHess = TRUE` under
both budgets. Their q8 correlation diagnostics were unchanged at the printed
precision: cold q8 had minimum eigenvalue 2.05e-6 and condition number 1.27e6,
while SD-staged q8 had minimum eigenvalue 4.26e-6 and condition number
6.11e5. Q4 theta-staged q8 returned convergence code 1 with `pdHess = FALSE`
under both budgets and one `NaNs produced` warning. This pilot says that, for
the high sample-size row already tested, more `nlminb` iterations alone are not
the missing piece.

## Decision

The next q8 task is not a broad recovery or power grid. Q8 remains data-hungry:
larger replication improved Hessian and correlation-conditioning behaviour, but
the paired 800/1600 budget pilot did not turn the high sample-size row into
optimizer convergence code 0. Keep theta-staged starts as a per-row diagnostic
option rather than a default rescue. Direct q8 SD profiles are feasible but
expensive and must stay bounded and selected. Derived q8 correlations now have a
developer bootstrap artifact path, but the first two-refit pilot produced no
interval rows, so derived-correlation intervals remain unpromoted. Q8 remains
fitted and diagnostic-artifact ready, with sample-size-dependent usability
evidence, but not coverage-ready or power-ready.
