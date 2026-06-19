# After-task: post-Big-4 companion gate refresh

## Purpose

Refresh mission-control and finish-plan wording after PR #634 banked the native
R/TMB Big 4 numerical-guard diagnostics on `main`. The next work should move to
direct DRM.jl evidence and then Julia-via-R registry/parity evidence without
turning the native diagnostic artifacts into bridge, release, coverage, power,
or recovery claims.

## Changes

- Updated `docs/dev-log/dashboard/status.json` and
  `docs/dev-log/dashboard/sweep.json` with a post-#634 active-work message.
- Updated `docs/design/168-r-julia-finish-capability-matrix.md` so the
  dashboard row and ADEMP/comparator row name the next companion gates.
- Updated `docs/design/157-capability-completion-worklist.md` with the
  immediate work-order pivot: direct DRM.jl evidence first from a clean
  DRM.jl worktree, then Julia-via-R registry/parity evidence in `drmTMB`.

## Evidence

- Local repo before edits: clean at
  `ae42e467ecda485413d969d5d11a95cfe2fca0c3`.
- `tools/start-mission-control.sh --background` refreshed the served checkout
  metadata before edits to detached `ae42e467` with `dirty = false`.
- DRM.jl `origin/main` was observed at
  `9bdea6564661e1d9eb454ed3c6d2d9398522f74f`.
- The saved DRM.jl checkout was dirty on `shannon/ayumi-integration`, so the
  direct-Julia implementation surface should be a fresh worktree.
- After the source edits, dashboard JSON parsing passed,
  `tools/validate-mission-control.py` reported `25/68 banked_or_verified`,
  `1 active`, `17 matrix rows`, `11 finish rows`, `15 Julia gate rows`, and
  `9 Julia capability rows`, and `git diff --check` passed.
- `pkgdown::check_pkgdown()` reported no problems.
- The served mission-control copy at `http://127.0.0.1:8765/` refreshed to
  `2026-06-19 15:15 MDT` on branch
  `codex/post-big4-companion-gate-refresh`, head `ae42e467`, with metrics
  25 verified, 1 active, 0 blocked, and 1 deferred.
- Ada's PR review caught one stale dashboard ADEMP/comparator row that still
  pointed at the q8 endpoint-status note; that row now points at this
  companion-gate refresh and keeps direct DRM.jl and Julia-via-R parity planned.

## Boundary

This is a planning and mission-control refresh only. It does not add model
capability, direct DRM.jl parity, Julia-via-R parity, q2/q4/q8 promotion,
coverage, power, recovery accuracy, release readiness, CRAN readiness,
non-Gaussian REML/AI-REML, or selectable Julia `engine_control`.
