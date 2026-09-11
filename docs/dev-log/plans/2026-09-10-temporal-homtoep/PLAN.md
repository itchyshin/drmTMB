# P2 child plan — homogeneous temporal Toeplitz

## Status correction — 2026-09-10

T3-7 and T3-7a established that the direct latent-process contract below is
not identifiable when it estimates a free Toeplitz correlation, temporal SD,
and residual SD from one response per series--occasion. It is retained as a
non-public prototype and evidence record, not a promotable provider. The next
action is the explicit choice in `T3-8-REDESIGN-DECISION.md`: an identified
marginal covariance model for ordinary panels, or a replicated latent-process
model. No profile, campaign, documentation, or release gate may treat the
prototype as a completed feature.

## Closure update — 2026-09-10

The identified marginal provider selected by `T3-8-REDESIGN-DECISION.md` is complete
at `ceff79d53`. It fits `y_i ~ N(X_i beta, sigma_T^2 R)` with one total within-series
SD and a valid homogeneous Toeplitz correlation. The original latent provider remains
retained evidence of the identifiability failure and does not qualify the delivered
model. See the executable close gate `T3-12` and
`docs/dev-log/evidence/temporal-homtoep/2026-09-10-p2-closeout.md`.

## Goal

Implement the next **direct temporal** covariance structure after calibrated OU:

```r
fit <- drmTMB(
  bf(y ~ treatment + temporal(1 | id, time = occasion, structure = "homtoep"),
     sigma ~ 1),
  data = dat, family = gaussian(), REML = FALSE
)
```

The delivered model is the identified marginal covariance selected in
`T3-8-REDESIGN-DECISION.md`. The discarded latent process remains below as a
historical record of the identifiability diagnosis. The scientific question remains
whether equally spaced repeated observations require a free lag-by-lag correlation
rather than OU or AR1 exponential decay.

The completed direct temporal OU parent is the prerequisite. The additive phylogenetic-stable plus OU development slice is an optional composition test and does not govern this temporal progression.

## Historical latent-prototype contract (retained)

For every ID on common discrete occasions `k,l`:

\[
y_{ik}=x_{ik}^{T}\beta+a_{ik}+\epsilon_{ik},\quad
\operatorname{Cov}(a_{ik},a_{il})=s_a^2r_{|k-l|},\quad r_0=1,
\quad \epsilon_{ik}\sim N(0,\sigma^2).
\]

`R = Toeplitz(1, r_1, ..., r_{K-1})` must be positive definite. AR1 is nested by `r_d = phi^d`; the diagonal process is nested by `r_d = 0` for `d > 0`. `sd_temporal` is a stationary process SD, never an innovation SD.

Initial scope: univariate Gaussian ML, fixed `mu` predictors and offsets, constant `sigma`, exactly one temporal intercept, no ordinary random intercept, no slopes, no REML, no `newdata`, no forecast, no variance/correlation intervals, and no unequal schedules. A later composition arc may add ordinary or phylogenetic stable intercepts only after this direct provider closes.

## Delivered marginal provider

For each ID, the public model is

\[
y_i \sim N(X_i\beta, \sigma_T^2 R),
\]

where `R` is a positive-definite homogeneous Toeplitz correlation matrix and
`sigma()` reports the total within-series SD. It therefore has no separate iid
residual SD, no temporal conditional mode, and no temporal `sigma` effect. The
delivered provider admits complete common equally spaced integer schedules of three
through twelve occasions, preserves original row order, and supports fixed mean-effect
profile intervals only in the retained qualified panel cells.

## Historical prototype admissions and interface

- `occasion` is finite integer metadata with a common equally spaced schedule in every retained ID; at most 12 levels.
- Validate raw ID/occasion duplicates and metadata before response omission. After omission, reject any ID lacking the complete retained schedule.
- Reject irregular elapsed time and direct readers to OU. Reject aliases such as `toep` and `hom_toep`.
- Report `sd_temporal`, `cor_lag1` through `cor_lag(K-1)`, and `sigma` with clear weak-information and boundary diagnostics.
- Preserve input row order in public output while storing sorted schedule metadata and retained-row mapping.

## Historical S0–S6 delivery slices

| Slice | Owner and model/effort | Owned files | Required evidence |
| --- | --- | --- | --- |
| S0 parameter map | Gauss + Noether, Astra high | comparison memo, `tools/temporal-homtoep-map-*` | Compare partial-autocorrelation recursion, constrained Cholesky and one equivalent differentiable map; choose a map only after valid-R, derivative, reconstruction and dense-agreement tests. Review glmmTMB implementation and documentation as source-map evidence, never as a drop-in port. |
| S1 grammar/layout | Boole, Astra high | formula parser/layout, `test-temporal-homtoep-parser.R` | complete-schedule admission, early errors, shuffled-row reconstruction, raw metadata before omission. |
| S2 native/provider | Gauss, Astra high | `src/drmTMB.cpp`, optimizer plumbing | one native covariance provider, correct normalizers, independent IDs, starts and map transform. |
| S3 oracle/methods | Curie Terra medium + Emmy Terra high | dense helper, methods/simulation/tests | dense V, score/Hessian/modes; labels, fitted/residual/simulation contract, deferred prediction/inference errors. |
| S4 recovery/calibration | Curie Terra medium + Fisher Astra high | fixtures, pilot, assessment runner | AR1, diagonal and non-exponential valid-Toeplitz recovery; timed pilot; frozen campaign only after explicit campaign approval. |
| S5 reader workflow | Pat + Darwin, Terra medium | temporal vignette/design docs | realistic discrete repeated-measures question: does correlation depart from exponential decay? Rendered output explains when to use OU instead. |
| S6 integration | Ada + Rose, Astra high; Noether and Pat independent | ledger, reports, package checks | reverify all artifacts, package check, independent mathematical and reader reviews, exact commit. |

S1–S3 are sequential. S4 and S5 may overlap only after the public interface is frozen. No more than two production children may write concurrently.

## Historical prototype test plan

The dense oracle must independently construct every Toeplitz covariance matrix. Test likelihood, score, two finite-difference Hessian step sizes, conditional modes, input shuffling, multiple IDs, and unequal variance components. Mutation controls must detect invalid correlation maps, compressed schedules, omitted normalizers, cross-ID state sharing, and swapped process/residual scales.

Predeclare recovery cells before results: AR1-generated lags, a non-exponential positive-definite Toeplitz matrix, a valid negative first-lag matrix, and a low-information stress cell. Report coefficient recovery separately from correlation recovery. Interval calibration requires a separate predeclared 95% profile campaign; direct OU coverage cannot transfer.

## Historical compute and closure plan

S0 map stress tests and S1 parser tests are expected below 30 minutes locally. The recovery pilot supplies the campaign estimate. Any campaign above 30 minutes requires its measured plan, target, storage route, thread ceiling, and explicit approval; use DRAC/Fir arrays and Totoro durable mirrors, never login nodes or GitHub Actions.

Historical planning estimate: 35–55 agent-hours plus measured campaign compute. The delivery and closure evidence now supersede this initial execution paragraph.
