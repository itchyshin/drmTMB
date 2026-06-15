# After Task: R-First Mission-Control Rerank

## Goal

Make the dashboard and finish matrix reflect the updated operating order:
complete the native `drmTMB` R/TMB support-status path first, then use Julia as
the acceleration/parity lane. This prevents Ayumi-style q4 workflows from being
framed as Julia-only while the native path can already provide point-estimate,
target-inventory, rejection, and profile-status evidence.

## Implemented

- Updated `docs/dev-log/dashboard/status.json`:
  - Phase 2 now tracks bridge truth and the merged #556 R-side Julia REML
    requested/effective estimator status slice.
  - Phase 3 is now the active native R/TMB point-estimate and CI-status lane.
  - The dashboard records #552/#553 as banked native q4 ML profile-status
    evidence and #557/#559 as banked native REML/harness work after their
    macOS, Ubuntu, and Windows checks passed.
- Updated `docs/dev-log/dashboard/sweep.json` so the live overlay names the
  R-first work.
- Updated `docs/design/168-r-julia-finish-capability-matrix.md` so the first
  work order prioritizes `drmTMB#555` before broader bridge-gate and Julia
  speed slices.
- Updated `docs/dev-log/check-log.md` with the validation commands for this
  rerank.

## Verification

```sh
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json
sh -n tools/start-mission-control.sh
git diff --check
sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/status.json
```

The shell health checks and `curl` reads saw the updated R-first dashboard at
`http://127.0.0.1:8765/`; after #557/#558/#559 merged, the validator returned
`mission_control_ok: 14/64 banked_or_verified, 3 active, 16 matrix rows`. The
Codex in-app browser connector returned a localhost navigation failure even
while `curl` succeeded, so that browser check is recorded as a connector
limitation rather than dashboard evidence.

## Claim Boundary

This is a status and planning rerank, not a model-capability change. Native
`engine = "tmb"` is still not a full REML fallback for the bivariate q4
phylogenetic location-scale model. Julia speed work remains active, but it
should not be the only route users can inspect.
