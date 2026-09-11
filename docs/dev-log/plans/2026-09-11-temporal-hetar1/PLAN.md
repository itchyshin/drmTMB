# P3 child plan — heterogeneous temporal AR1

## Status

**Prepared 2026-09-11 from `c22c18cd279961eba50bae304ccf239d1919515f`.** P2 homogeneous Toeplitz is integrated and its local gates reverify. This document is the P3 child receipt and acceptance design. It authorizes no source-code change until `T4-0` records direct approval of this plan and its source fingerprint.

## Purpose and scientific question

`hetar1` asks whether persistent within-series deviations have the same AR1 correlation across occasions but **different temporal-process SDs** at those occasions. It is appropriate for complete, regularly sampled panels when the amount of temporal variability plausibly changes across the season, life stage, or experimental occasion. It does not model a changing residual scale; temporal log-SD is a later, separate arc.

```r
fit <- drmTMB(
  bf(y ~ treatment + temporal(1 | id, time = occasion, structure = "hetar1"),
     sigma ~ 1),
  data = dat, family = gaussian(), REML = FALSE
)
```

## Statistical contract

For ID `i` and common ordered integer occasion `k`:

\[
y_{ik}=x_{ik}^{T}\beta+a_{ik}+\epsilon_{ik},\qquad
\epsilon_{ik}\sim N(0,\sigma^2),
\]
\[
\operatorname{Cov}(a_{ik},a_{il})=s_k s_l \phi^{|k-l|},
\quad s_k>0,\quad -1<\phi<1.
\]

Equivalently, \(V_i=D R(\phi)D+\sigma^2I\), where \(D=\operatorname{diag}(s_1,\ldots,s_K)\). `s_k` is a process SD, not an innovation SD and not the observation-level residual SD. IDs are independent. The model uses its Gaussian marginal likelihood; its dense `V_i` is the independent oracle.

The provider must admit exactly one temporal intercept, fixed mean predictors and offsets, univariate Gaussian ML, constant `sigma ~ 1`, and no ordinary, phylogenetic, spatial or scale-side random-effect combination. It keeps original output row order while storing a sorted common schedule.

## Admission, identification and public behaviour

Validate finite integer `time`, non-missing ID/time metadata and duplicate ID--occasion keys before response omission. After the package's ordinary listwise omission, every retained ID must have the same complete equally spaced schedule of 3 through 12 levels, with support at every level. Reject irregular elapsed time, partial schedules, aliases and an `sd` formula; direct irregular time to OU.

The conditions are a supported-design rule, not an identification guarantee. Emit diagnostics for level-specific process SDs at the boundary, persistence near either boundary, a non-positive-definite observed-information matrix, conflicting starts, and weak support at a level. Do not silently collapse near-equal SDs to homogeneous AR1.

Report `phi`, labelled `sd_temporal[occasion]`, and `sigma`. Support fitted values, residuals, simulation, `VarCorr`, structured metadata and the established fixed-mean `vcov()` / Wald interval surface only when its information diagnostic is valid. Defer variance/persistence intervals, `newdata`, forecasting, REML and all scale-side temporal terms.

## Required reductions and mutations

- Equal `s_k` must reproduce the existing latent AR1 marginal covariance with residual sigma.
- `phi = 0` must give independent occasion-specific temporal variances plus residual variance.
- A near-zero `s_k` is a diagnostic boundary case, never missing data.
- Mutations must be detected for missing left/right `D` factors, one global SD substituted for level SDs, compressed or reordered level labels, a shared process across IDs, omitted normalizers, and swapped process/residual SDs.

## Slices, ownership and effort

| Slice | Owner/lens | Files owned | Acceptance result |
| --- | --- | --- | --- |
| S0 source/map | Ada + Noether, Astra high | this plan, fingerprint, `T4-*` ledger | exact parent/source pin; formula and likelihood contract agree; glmmTMB is recorded as a comparison source, not copied code. |
| S1 grammar/layout | Boole, Terra medium | `R/temporal.R`, parser tests | canonical `hetar1`; common schedule, labels and early errors work. |
| S2 native likelihood | Gauss, Astra high | `src/drmTMB.cpp`, fitting plumbing | differentiated D-R-D Gaussian marginal likelihood, two starts and diagnostics. |
| S3 methods/oracle | Curie + Emmy, Terra medium/high | dense helper, methods, simulation, tests | independent `V`, score/Hessian, output labels, simulation and fixed-mean covariance checks. |
| S4 interval feasibility | Fisher + Curie, Astra/Terra high/medium | frozen fixtures, pilot runner, retained outputs | at most 24 fixtures, all starts/failures retained; finite fixed-mean Wald intervals assessed without coverage claim. |
| S5 reader workflow | Pat + Darwin, Terra medium | vignette and design docs | rendered applied example says when heterogeneity is useful and when OU/temporal scale is the right question. |
| S6 integration | Ada + Rose; Noether/Pat independent | gates, reports, check log | reverify, package check, reviews, closeout and local commit. |

S1 → S3 are sequential. S4 and S5 may overlap after the public API is frozen. No more than two production writers may run concurrently. Estimated local deterministic work is 12–18 agent-hours. Before any run expected to exceed 30 minutes, execute a five-seed pilot, record elapsed time/memory/output completeness, then obtain a separate compute authorization. No coverage campaign is part of P3.

## Interval-feasibility evidence

The frozen panel has at most 24 data sets, each using both \(\phi=-0.3\) and \(+0.3\) starts. Its primary layouts are 80 IDs × 8 levels with monotone SDs and \(\phi=0.5\), 80 × 12 with a U-shaped SD pattern and \(\phi=0.8\), and 80 × 8 with unequal SDs and \(\phi=-0.5\). The one stress layout is 20 × 6 with a sparse high-variance occasion. Seeds, all starts, selected objective, convergence/Hessian diagnostics, interval availability, estimates, widths, warnings and runtime are immutable outputs.

A finite Wald interval is evidence only that the declared full observed-information calculation succeeded for that fixture. It is **interval feasibility**, not coverage, calibrated standard errors, or general inference readiness. Failed intervals remain in the denominator and are described rather than removed. The previously failed P1 G13 coverage rows remain historical evidence in the parent programme; P3 does not replace or reinterpret them.

## Completion boundary

P3 closes only after each runnable gate emits its exact receipt, the source fingerprint still matches the estimator tested, the public docs render locally, independent Noether and Pat reviews address their findings, and the after-task report records what P3 does not cover. No remote campaign, push, release, external message or temporal-scale implementation is included.
