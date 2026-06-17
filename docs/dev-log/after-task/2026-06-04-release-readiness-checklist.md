# After Task: 0.2.0 Release-Readiness Checklist

## Goal

Block 3 of the capability close-out push: advance the 0.2.0 release track
(#342) and Phase 20 CRAN gate (#61) as far as possible without a local-R
machine.

## Implemented

- Added `docs/design/159-drmtmb-0-2-0-release-readiness.md`, consolidating the
  #342 and #61 gates into one checklist. Each item is marked done, local-R only,
  or pending, so the owner can see exactly what remains and what needs a machine
  with the package dependencies and CRAN tooling.
- Recorded the gate that release should not begin until the pending capability
  slices (doc 157), Phase 18 recovery/coverage evidence, and Phase 19 comparator
  evidence (doc 158) agree with the docs.
- Specified the missing profile-likelihood and interval demonstration article
  (the #342 demo gate): fitted estimate, likelihood/likelihood-ratio distance,
  interval endpoints, target name, engine/source provenance, coarse-vs-dense
  profiles with timing, and the curve itself — authored as eval-on-build code in
  a local session so `R CMD check`/pkgdown exercise it.

## Scope

Design/checklist only. Did not create `cran-comments.md` (premature before
submission) and did not run any CRAN checks (local-R only; the sandbox network
policy blocks the R repositories). No fitted status or package code changed.

## Checks Run

Documentation-only block.
