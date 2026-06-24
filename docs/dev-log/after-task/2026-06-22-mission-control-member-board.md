# After Task: Mission-Control Member Board

## Goal

Restore the local mission-control widget and make member review, discussion,
and the next SC201-SC400 structured random-effect conversion plan visible as
validated dashboard state.

## Implemented

The dashboard launcher now copies every dashboard TSV by pattern, preventing
new ledgers from being omitted from `/tmp/drm-dashboard`. Mission control now
has a member roster, member discussion ledger, wave-assignment ledger, and the
SC201-SC400 conversion-slice ledger. The browser widget renders the member
board, discussion cards, wave assignments, structured sidecar blocker counts,
and all 200 conversion rows.

## Mathematical Contract

This task changed mission-control state only. It did not alter likelihoods,
estimators, formula grammar, or inference calculations. REML and AI-REML
wording remains exact-Gaussian and route-specific; q4 point/extractor status,
bridge smoke, and coverage pilots remain separate from interval coverage,
native q4 REML, and public bridge support.

## Files Changed

- `tools/start-mission-control.sh`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/member-roster.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/member-wave-assignments.tsv`
- `docs/dev-log/dashboard/structured-re-conversion-200-slices.tsv`

## Checks Run

```sh
git status --short --branch
git diff --check
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/status.json >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-balance-matrix.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/member-roster.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/member-discussions.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-conversion-200-slices.tsv >/dev/null
```

Browser verification found 13 member cards, 13 discussion cards, 21 member-wave
rows including the header, 201 conversion-slice rows including the header, the
expected structured sidecar counts, and no console errors.

After SC201-SC220 were banked as infrastructure rows, the served
`structured-re-conversion-200-slices.tsv` reported 20 `banked` rows and 180
`queued` rows.

The recovery checkpoint is
`docs/dev-log/recovery-checkpoints/2026-06-22-163601-codex-checkpoint.md`.

## Tests Of The Tests

The validator now checks that the member roster has all 13 standing reviewers,
that Codex and Claude launchable agent files exist, that discussion rows
reference valid members and SC201-SC400 slices, that wave assignments use the
expected SC ranges, that the conversion ledger has exactly SC201-SC400 with 10
rows per wave, and that the launcher copies all dashboard TSVs.

## Consistency Audit

The headline metric is labelled as legacy finish-board state, and the widget
now shows structured sidecar blockers beside it: SR001-SR100 is 91 banked and
9 blocked; SR101-SR200 is 10 banked, 23 blocked, and 67 queued; SC201-SC220
are banked mission-control/member-board infrastructure rows, while SC221-SC400
remain queued. The dashboard README describes the new member artifacts and the
copy-all-TSV launcher rule.

## GitHub Issue Maintenance

No GitHub issue was changed. The Ayumi reply, posting, and public-action gates
remain blocked until the current issue text is reviewed and the final reply is
explicitly approved.

## What Did Not Go Smoothly

The `--background` launcher started, served the direct probes, and then the
`http.server` process exited under this Codex process environment. I detached a
plain `python3 -m http.server` process from the tool process group and reran
the launcher to refresh `/tmp/drm-dashboard` while that server was listening.
The serving-copy drift is now visible if it returns.

## Team Learning

Member review should be stored in dashboard TSVs, not only chat. The durable
record now includes each member's authority, can-do work, improvement target,
signoff surface, and row-level discussion stance.

## Known Limitations

This task does not bank bridge parity, calibrated coverage, native q4 REML,
non-Gaussian REML, public optimizer controls, or an Ayumi reply. SC201-SC220
are banked infrastructure rows only; SC221-SC400 are queued execution state,
not completed capability evidence. No files were staged or committed.

## Next Actions

Start implementation with SC221-SC230 for vocabulary cleanup, or SC231-SC260
if the team wants to begin the q1 bridge payload and parity contract. Keep
bridge parity, REML, and coverage promotions blocked until their row-specific
gates pass.
