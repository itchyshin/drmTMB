# Mission-Control Standing-Team Validator Refresh

Date: 2026-06-17

## Goal

Keep the mission-control finish-board widget aligned with the canonical
standing review names from `AGENTS.md`. The dashboard already had the r7
finish-board renderer, Julia gate tables, and validator, but it still allowed
`Hopper` as a team/owner name. That made the widget easier to drift away from
the standing team contract.

## What Changed

- Removed `Hopper` from `docs/dev-log/dashboard/status.json`.
- Reassigned bridge-gate ownership to `Boole + Emmy + Grace`.
- Reassigned missing-values ownership to `Curie + Fisher + Rose`.
- Replaced the docs-review checklist member `Hopper` with `Pat`.
- Tightened `tools/validate-mission-control.py`:
  - team cards must contain only standing review names;
  - phase owners must contain only standing review names;
  - finish-board owners must contain only standing review names;
  - activity/evidence rows may still name system actors such as `Codex`,
    `GitHub`, `Dashboard`, `Issue ledger`, and `Status matrix`.

## Checks

```sh
python3 tools/validate-mission-control.py
```

passed:

```text
mission_control_ok: 20/68 banked_or_verified, 4 active, 17 matrix rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows
```

```sh
rg -n 'Hopper|Karpinski' docs/dev-log/dashboard/status.json tools/validate-mission-control.py docs/dev-log/dashboard/README.md docs/design/168-r-julia-finish-capability-matrix.md || true
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 -m py_compile tools/validate-mission-control.py
```

also passed.

The served dashboard was refreshed with:

```sh
sh tools/start-mission-control.sh --background
```

Browser DOM verification passed at both 1280 px and 390 px widths: the page
rendered 11 finish-board cards, 13 standing team names, the #569 and #544 rows,
the bridge-gate and Julia capability sections, and no `Hopper` or `Karpinski`
text. Both widths reported no horizontal overflow.

Screenshot capture from the in-app browser timed out, and standalone Playwright
was not installed in this worktree. No screenshot artifact is claimed for this
slice.

## Boundary

This task changes only dashboard governance and validation. It does not change
R package runtime code, likelihoods, `src/drmTMB.cpp`, Julia bridge gates,
Ayumi/Model A work, DRM.jl code, or any release/readiness claim.
