# After Task: Mission-Control Dashboard And Finish Matrix

## Goal

Implement the first backbone slice of the finish plan: a local dashboard, a
canonical capability matrix, and durable evidence for the next bridge-gate
implementation work. This slice is infrastructure only; it does not relax any
model gate.

## Implemented

- Added `docs/dev-log/dashboard/index.html` as a static dashboard that reads
  `status.json` and `sweep.json` every eight seconds.
- Added `docs/dev-log/dashboard/status.json`, `sweep.json`, `version.txt`, and
  `README.md`.
- Added `tools/start-mission-control.sh` to validate the dashboard source,
  sync it into `/tmp/drm-dashboard`, copy linked local evidence files, and
  serve it at `http://127.0.0.1:8765/`. The launcher also refreshes the live
  `drmTMB` Repo Truth row from `git` at serve time.
- Added `tools/validate-mission-control.py` as a standard-library validator for
  dashboard drift. It checks version consistency, phase counts, metric counts,
  canonical team names, verified/banked evidence-field presence, covered
  matrix-row evidence-field presence, and dashboard-vs-design matrix row count.
- Added `docs/design/168-r-julia-finish-capability-matrix.md`, the first
  finish-plan claim registry for engine support, R bridge support, point
  estimates, CI/status, docs, visuals, simulation, and release gates.
- Posted an implementation-start note to `drmTMB#544`:
  <https://github.com/itchyshin/drmTMB/issues/544#issuecomment-4703413781>.
- Recorded `drmTMB#547` as the first banked `drmTMB#544` bridge-gate-drift
  slice while keeping the claim narrow: q4 Julia REML option forwarding fixed,
  not speed solved, not full q4 inference validation, and not native TMB REML
  fallback.

## Mathematical Contract

No model likelihood or parameterization changed. The matrix preserves the
existing public terms `sigma`, `rho12`, `sd(group)`, `phylo()`, `spatial()`,
`mu`, and `nu`. It also states that `pdHess = FALSE` blocks Wald promotion but
does not automatically discard a useful point estimate.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/after-task/2026-06-14-mission-control-capability-matrix.md`
- `tools/start-mission-control.sh`
- `tools/validate-mission-control.py`

## Checks Run

- `python3 tools/validate-mission-control.py`
  - `mission_control_ok: 8/60 banked_or_verified, 4 active, 16 matrix rows`
- `python3 -m json.tool docs/dev-log/dashboard/status.json`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json`
- `sh -n tools/start-mission-control.sh`
- `sh tools/start-mission-control.sh --background`
- `curl -fsS http://127.0.0.1:8765/status.json | python3 -m json.tool`
- `curl -fsS http://127.0.0.1:8765/docs/design/168-r-julia-finish-capability-matrix.md`
- In-app browser verification at `http://127.0.0.1:8765/`

The browser check found the expected H1, four metric cards, eleven roadmap
phases, six repo cards, fourteen team entries, and seventeen matrix rows
including the header row.

Rose's follow-up audit corrected two dashboard-truth issues after the first
commit: the live repo-truth strip is now refreshed from `git` at serve time
instead of storing a self-referential commit hash in source JSON, and the
progress label now says "banked or verified slices" instead of "verified rows".

## Tests Of The Tests

The validator fails on the main drift modes exposed by the first dashboard
draft: stale metric counts, stale phase counts, non-canonical team names,
version mismatch between `version.txt` and the HTML `BUILD` constant, missing
evidence fields on verified/banked slices, missing evidence fields on covered
matrix rows, and matrix row-count drift between the dashboard JSON and the
design matrix. It does not prove that external URLs still resolve; that remains
part of the human/CI evidence audit.

## Consistency Audit

Targeted scans and checks used:

```sh
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json
sh -n tools/start-mission-control.sh
curl -fsS http://127.0.0.1:8765/status.json | python3 -m json.tool
curl -fsS http://127.0.0.1:8765/docs/design/168-r-julia-finish-capability-matrix.md
```

The current dashboard keeps unsupported, planned, experimental, partial,
covered, verified, banked, active, queued, blocked, and deferred states
separate. It also records the Ayumi/native-TMB boundary: native
`engine = "tmb"` is not yet a full REML fallback for the bivariate q4
phylogenetic location-scale model.

## GitHub Issue Maintenance

`drmTMB#544` remains the active bridge-gate-drift epic. The mission-control
start note was posted at:

<https://github.com/itchyshin/drmTMB/issues/544#issuecomment-4703413781>

That note says explicitly that this dashboard slice does not relax any
remaining R-side gate. The next coding slice is the requested audit: enumerate
current R bridge rejects, compare them to DRM.jl capability, and add the
gate-vs-engine CI guard.

## What Did Not Go Smoothly

The background server answered during the shell health check, but the Codex
tool environment reaped the background process before the in-app browser could
open it. For live verification in this session, a persistent foreground
`python3 -m http.server` exec session is holding `http://127.0.0.1:8765/` open.
Outside this tool environment, `sh tools/start-mission-control.sh --background`
remains the intended launch command.

## Team Learning

Rose's rule is now executable: the validator catches unsupported or unproven
status drift instead of relying on prose discipline. Grace's rule is also
visible: the dashboard separates local worktree state, GitHub issue evidence,
and release readiness. Jason's cross-team visit improved the board by importing
the `GLLVM.jl` dashboard's Repo Truth pattern without importing its package
claims.

## Known Limitations

- The dashboard is a status surface, not a package test.
- README, ROADMAP, NEWS, pkgdown, and Documenter do not yet draw
  automatically from the matrix.
- The actual gate-vs-engine CI guard in `drmTMB#544` is still the next coding
  slice.
- The dashboard records current repo truth from a local snapshot. It should be
  refreshed whenever the sister repositories move.

## Next Actions

1. Implement the `drmTMB#544` gate-vs-engine audit.
2. Add the CI guard that fails when R-side gates drift from DRM.jl capability.
3. Add a shared CI-status vocabulary for Wald, profile, bootstrap, and partial
   interval states.
4. Wire the matrix into README, ROADMAP, NEWS, pkgdown, and the dashboard.
