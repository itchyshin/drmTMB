# After Task: Capability Completion Worklist

## Goal

As the first block of a "close out the planned capabilities before the big power
simulation" push, establish the spec-level readiness for every remaining
capability.

## Finding

The specification work is essentially already complete in the repository. Every
remaining capability already has a design gate or ADEMP sheet (skew-normal:
docs 123/127/128/132; random slopes: 44/59/144-152; structured slopes: 54/55/58;
large-data: 23; cross-dpar boundary: 45; double-hierarchical endpoint map: 28),
and `docs/design/46-pre-simulation-readiness-matrix.md` maintains a detailed,
current fitted-versus-planned matrix. Writing further gates would duplicate
existing design and add bloat.

## What Was Missing

A single dependency-ordered index from today's fitted surface to the full
capability set, naming the exact parser/likelihood site, test contract, and
simulation lane for each remaining slice — so a local-R/TMB session can work top
to bottom without rediscovering the design.

## Implemented

- Added `docs/design/157-capability-completion-worklist.md`: the remaining
  implementation slices in dependency order, grouped as Tier A
  (individual-difference covariance endpoint: scale slopes -> same-response
  location-scale slopes -> q8), Tier B (structured slopes), Tier C
  (skew-normal), Tier D (random effects in `rho12`), Tier E (large-data), and
  Tier F (mixed-response bivariate, research-scoped). Each item cites its gate
  and known code site.
- Pointed `ROADMAP.md` at the worklist and the readiness matrix.

## Scope

Index/sequencing only. No new capability is claimed as fitted, and no fitted
status changes. The implementation slices themselves need a TMB build/test loop
and so are out of scope for the cloud sandbox (network policy blocks the R
package repositories); they are listed to make the local session turnkey.

## Issues Touched (informational)

Provides the consolidated path for #3 (skew-normal), #4 (large-data),
#5 (covariance blocks), #33 (random slopes), and #147 (animal/relmat). These
remain open pending local implementation.

## Checks Run

Documentation-only block: no R code, tests, or fitted status changed, so no
package checks were run (and local R has no dependencies available here).
