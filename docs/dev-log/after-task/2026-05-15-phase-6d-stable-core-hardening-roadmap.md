# Phase 6d stable-core validation and engine-hardening roadmap

Date: 2026-05-15

## Goal

Record the audit-response lane as a concrete roadmap phase so `drmTMB` can keep
its stable supported surface honest before expanding too far into new families,
spatial claims, or high-dimensional random-effect structures.

## What changed

- Added Phase 6d to `ROADMAP.md` as "Stable-Core Validation and Engine
  Hardening".
- Created GitHub issue #38 for the Phase 6d tracking lane.
- Split the audit response into Slices 77-84:
  stable-core feature matrix, validation-debt register, failure-safe
  `sdreport()` handling, optimizer/start/map design, dense-covariance and
  large-data guards, count-kernel audit, C++ modularization source map, and a
  final Phase 6d gate.

## Standing-review notes

- Ada: keep Slice 55 as the next implementation slice; Phase 6d is now a
  recorded later lane, not an excuse to interrupt the current profile-CI work.
- Boole: the feature matrix and validation register must separate fitted,
  parsed-but-rejected, experimental, and planned syntax.
- Gauss and Noether: optimizer and modularization work should be designed before
  implementation, because the TMB report/sdreport state must stay tied to the
  selected optimum.
- Fisher: profile-CI readiness, boundary behavior, and unavailable-interval
  status are part of the validation debt, not optional polish.
- Pat and Darwin: the stable-core matrix should be readable by applied ecology,
  evolution, and environmental-science users.
- Grace: Phase 6d should close only with targeted tests, pkgdown checks, and
  GitHub Actions evidence.
- Rose: the audit criticisms are now traceable in the roadmap rather than left
  as conversation-only advice.

## Checks

To be run with the roadmap update:

- `air format ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-phase-6d-stable-core-hardening-roadmap.md`
- `pkgdown::build_site()`
- `pkgdown::check_pkgdown()`
- `git diff --check`

## Known limitations

- This task records Phase 6d and opens its tracking issue; it does not implement
  `sdreport()` controls, optimizer fallbacks, multi-starts, count-kernel changes,
  or C++ modularization.
- Phase 6d is intentionally placed after the current Phase 6, 6b, and 6c lanes
  so the active profile-likelihood work can continue.
