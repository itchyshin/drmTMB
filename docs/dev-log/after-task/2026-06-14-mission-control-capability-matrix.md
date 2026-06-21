# After Task: Mission-Control Dashboard And Finish Matrix

## Goal

Implement the first backbone slice of the finish plan: a local dashboard, a
canonical capability matrix, and durable evidence for the next bridge-gate
implementation work.

## Implemented

- Added `docs/dev-log/dashboard/index.html` as a static dashboard that reads
  `status.json` and `sweep.json` every eight seconds.
- Added `docs/dev-log/dashboard/status.json`, `sweep.json`, `version.txt`, and
  `README.md`.
- Added `tools/start-mission-control.sh` to sync the dashboard source into
  `/tmp/drm-dashboard` and serve it at `http://127.0.0.1:8765/`.
- Borrowed the `GLLVM.jl` dashboard's Repo Truth pattern so the board shows
  branch, HEAD, and dirty-state context for the twin and sister packages.
- Added `docs/design/168-r-julia-finish-capability-matrix.md`, the first
  finish-plan claim registry for engine support, R bridge support, point
  estimates, CI/status, docs, visuals, simulation, and release gates.
- Updated `docs/dev-log/check-log.md` with exact checks and the GitHub issue
  maintenance result.

## Mathematical Contract

No model likelihood or parameterization changed. The matrix preserves the
existing public terms `sigma`, `rho12`, `sd(group)`, `phylo()`, `spatial()`,
`mu`, and `nu`. It also states that `pdHess = FALSE` blocks Wald promotion but
does not automatically discard a useful point estimate.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/after-task/2026-06-14-mission-control-capability-matrix.md`
- `tools/start-mission-control.sh`

## Checks Run

- `python3 -m json.tool docs/dev-log/dashboard/status.json`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json`
- `sh -n tools/start-mission-control.sh`
- `git diff --check -- docs/dev-log/dashboard/index.html docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/dashboard/version.txt docs/dev-log/dashboard/README.md tools/start-mission-control.sh docs/design/168-r-julia-finish-capability-matrix.md`
- `curl -sS -i http://127.0.0.1:8765/status.json`
- `curl -sS -i http://127.0.0.1:8765/sweep.json`
- Browser verification at `http://127.0.0.1:8765/`

The browser check found the expected H1, four metric cards, six roadmap phases,
six repo cards, and eight matrix rows.

## Tests Of The Tests

This slice added project-memory and dashboard infrastructure, not package
model code. The meaningful failure path is visible in the dashboard and report:
remote issue commenting failed with a GitHub integration permission error, and
the blocker is shown rather than hidden.

## Consistency Audit

Targeted scans used:

```sh
rg -n "AI-REML|rho12|pdHess|engine_control|http://127.0.0.1:8765|unsupported|planned|covered" docs/design/168-r-julia-finish-capability-matrix.md docs/dev-log/dashboard/README.md docs/dev-log/dashboard/status.json
```

The scan confirmed the key claim guards are present: `AI-REML` is restricted to
exact Gaussian REML/MME derivations, `rho12` remains the bivariate residual
correlation name, `pdHess = FALSE` is treated as a Wald-inference warning, and
unsupported or planned rows remain visibly marked.

## GitHub Issue Maintenance

`drmTMB#544` was fetched successfully and remains the active bridge-gate drift
epic. An implementation-start comment was attempted through the GitHub
connector, but the connector returned `403 Resource not accessible by
integration`. The `gh` command is not installed, so no remote issue comment was
posted in this session.

Draft comment for the next GitHub-capable session:

```md
Implementation-start note for the finish-plan backbone.

I am starting with the non-code infrastructure slice so later bridge work is
issue-led instead of scattered:

- add a mission-control dashboard source under `docs/dev-log/dashboard/`,
  served locally at `http://127.0.0.1:8765/` from `/tmp/drm-dashboard`;
- add a canonical master capability matrix design note separating engine
  support, R bridge support, point estimates, CI/status, gradient parity,
  simulations, docs, visuals, and release evidence;
- seed the dashboard with `drmTMB#544` as the first active coding epic and keep
  the current wording boundary: experimental default `DRM.jl` fitting path, not
  selectable Julia algorithms;
- record check-log and after-task evidence for the slice.

This does not relax any gate yet. The next implementation slice should still
be the actual gate-vs-engine audit and CI guard described in this issue.
```

## What Did Not Go Smoothly

The GitHub connector could read the issue but could not write a comment. The
local `gh` fallback was unavailable. A background `nohup` server also exited in
this execution environment, so the dashboard is currently served by a live
foreground server process started from Codex.

## Team Learning

Rose's rule is now visible in the dashboard: unsupported, planned,
experimental, and partial rows stay distinct. Grace's rule is also visible:
the dashboard separates local evidence from remote GitHub issue maintenance.
Jason's cross-team visit also improved the board: the `GLLVM.jl` template's
Repo Truth strip is now part of the `drmTMB` mission-control page.

## Known Limitations

- The dashboard is a status surface, not a package test.
- README, ROADMAP, NEWS, pkgdown, and Documenter do not yet draw
  automatically from the matrix.
- The actual gate-vs-engine CI guard in `drmTMB#544` is still the next coding
  slice.
- Remote issue comments still need a GitHub-capable session.

## Next Actions

1. Implement the `drmTMB#544` gate-vs-engine audit.
2. Add the CI guard that fails when R-side gates drift from DRM.jl capability.
3. Add a shared CI-status vocabulary for Wald, profile, bootstrap, and partial
   interval states.
4. Wire the matrix into README, ROADMAP, NEWS, pkgdown, and the dashboard.
