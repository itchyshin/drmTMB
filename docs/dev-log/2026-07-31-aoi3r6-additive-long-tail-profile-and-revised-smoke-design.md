# AOI-3R6 — additive long-tail profile and revised local-smoke design

**Status:** plan only.  This document authorizes neither a fresh seed, a local
run, a DRAC submission, nor any public uncertainty surface.  AOI-2 remains on
HOLD and `vcov()`, `confint()`, standard errors, profiles, and interval claims
remain unavailable for staged Bernoulli x ordinary-NB2 association.

## Question

AOI-3R5 retained one completed additive outer attempt (112.039 seconds at the
supervisor) and one hard timeout (180.021 seconds before an outer result was
written).  What can be learned from those records, and what fail-closed smoke
would distinguish an execution budget from an estimator or sandwich defect?

## Retained observations

| retained attempt | association diagnostic | sandwich diagnostic | elapsed seconds | interpretation allowed |
| --- | --- | --- | ---: | --- |
| R4 additive outer 1 | `boundary_unresolved` | unavailable | 41.776 | boundary diagnostic only |
| R4 additive outer 2 | `interior` | `association_step_unstable` | 90.284 | private derivative diagnostic unavailable |
| R4 additive outer 3 | `interior` | `ok` | 129.944 | one private completed path |
| R4 additive outer 3, inner 1 | not separately promoted | `association_step_unstable` | 113.058 | private derivative diagnostic unavailable |
| R4 additive outer 3, inner 2 | not separately promoted | `ok` | 129.661 | one private completed path |
| R4 additive outer 3, inner 3 | not separately promoted | `ok` | 123.594 | one private completed path |
| R5 additive outer 1 | `interior` | `association_step_unstable` | 112.039 supervisor (109.395 child) | complete child, unavailable private sandwich |
| R5 additive outer 2 | no outer row retained | no outer row retained | 180.021 supervisor | process cap fired before phase identity was recorded |

The R4 paths are incomplete diagnostic evidence and R5 is invalid under the
completeness contract.  They are not pooled, retried silently, or used to make a
point-recovery, covariance, or interval claim.

## What the current records do and do not identify

The completed R4 private sandwich paths take roughly 124--130 seconds at
`n = 720`; R5's 180-second cap therefore has only about 50 seconds of headroom
over the slowest retained successful path.  This supports an **operational**
inference that 180 seconds is too narrow to diagnose the current local runtime
reliably.  It does not support a numerical change, a relaxed scientific
criterion, or a claim that the timeout occurred in the association optimizer.

Static inspection identifies two distinct candidate phases:

1. `drm_pair_fit_eta()` runs the association optimization from three starts and
   computes finite-difference score/curvature diagnostics.
2. A successful association fit enters the private BnB sandwich adapter, which
   loops over all 720 rows.  Each row requests full- and half-step stable
   derivatives of a Bernoulli x NB2 rectangle probability.

The rowwise derivative phase is plausibly expensive, and a late unstable row
can consume substantial time before returning `association_step_unstable`.
That is a static call-path inference, not a timed attribution.  The present
runner writes only an outer checkpoint, so R5 outer 2 cannot be assigned to
either phase.

## Proposed R7A timing/provenance smoke (requires separate approval)

R7A would be a fresh, outer-only local smoke at the existing `n = 720` design.
It is an execution/provenance test, not a calibration study.

- Freeze five fresh seeds: one outer attempt for each approved formula class.
  Do not reuse R1--R5 seeds or pool their outcomes with R7A.
- Retain process isolation for every outer attempt.
- Before running, add private child events and elapsed times for
  `margins_fitted`, `association_fit_complete`, `sandwich_started`, and
  `sandwich_finished` (or a retained terminal sandwich-unavailable event).
- Keep a 300-second hard wall-time per outer attempt.  This is an operational
  proposal: it exceeds the largest retained completed path by more than two
  minutes, while preserving an enforceable fail-closed cap.  It is not an
  optimizer-tolerance change or a statistical accommodation.
- Run **no inner refits** in R7A.  A complete R7A can establish only that the
  phase-timing and retention contract is observable across the formula set.

R7A is invalid if any expected child/supervisor event, phase timestamp,
terminal payload, manifest assertion, or source provenance record is absent.
A timeout remains a retained operational failure.  A terminal private
`unavailable` sandwich is retained as such; it is neither upgraded to success
nor conflated with a missing payload.

## Decision ladder after R7A

1. If R7A is incomplete, retain it and revise the execution design before any
   full-refit work.  No DRAC submission follows.
2. If R7A is complete, review its phase records separately.  Completion alone
   does not validate covariance, standard errors, or calibration.
3. Only a new explicit approval could authorize a fresh, preregistered R7B
   full-refit local smoke.  A DRAC calibration campaign would require another
   approval after that local smoke, with all-attempt denominators and
   unavailable outcomes fixed in advance.

## Approval text for the next bounded action

> Authorize AOI-3R7A: implement phase timing/retention and run a fresh
> five-outer timing/provenance local smoke at `n = 720` with a 300-second hard
> cap per outer; no inner refits, no DRAC, and no public uncertainty.
