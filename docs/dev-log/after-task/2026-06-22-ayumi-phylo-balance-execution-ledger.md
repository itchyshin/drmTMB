# After Task: Ayumi Phylo Balance Execution Ledger

## 1. Goal

Start implementing the Ayumi phylo-balance 100-slice plan by banking the
rehydration and semantics waves as validator-owned mission-control state.

## 2. Implemented

Added an Ayumi-specific 100-slice ledger, vocabulary table, and tracker table.
The first 20 slices now record the current issue-access boundary, internal
tracker split, forbidden wording, route vocabulary, reply gate, and
reader-facing balance summary before any new public Ayumi reply is drafted.

## 3a. Decisions and Rejected Alternatives

The direct Ayumi issue still cannot be read from this session, so the tracker
table records it as inaccessible instead of quoting it. Internal tracker
comments report that a prior reply was posted on 2026-06-15, but this run
treats that as tracker evidence only because the reply text is not directly
readable here.

The ledger was kept separate from `finish-100-slices.tsv`. The existing
finish-run ledger is still the R/Julia capability finish lane; the new Ayumi
ledger is the balance-and-reply arc.

## 4. Files Touched

- `docs/design/197-ayumi-phylo-balance-research-100-slices.md`
- `docs/dev-log/after-task/2026-06-22-ayumi-phylo-balance-execution-ledger.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/dashboard/ayumi-phylo-balance-trackers.tsv`
- `docs/dev-log/dashboard/ayumi-phylo-balance-vocabulary.tsv`
- `tools/start-mission-control.sh`
- `tools/validate-mission-control.py`

## 5. Checks Run

The dashboard JSON, mission-control validator, and whitespace check passed:

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/drm-status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/drm-sweep.json
tools/validate-mission-control.py
git diff --check
```

`tools/validate-mission-control.py` reported 100 Ayumi balance-slice rows, 8
Ayumi balance vocabulary rows, and 6 Ayumi balance tracker rows.

## 6. Tests of the Tests

The new guard is `tools/validate-mission-control.py`. It now checks that the
Ayumi ledger has exactly 100 ordered `A001`-style rows, ten rows per wave,
known statuses, banked-row evidence, required vocabulary terms, and required
tracker rows for the external Ayumi issue plus `drmTMB#555`, `drmTMB#570`,
`DRM.jl#291`, and `DRM.jl#293`.

## 7a. Issue Ledger

Read live tracker state for:

- `https://github.com/itchyshin/drmTMB/issues/555`
- `https://github.com/itchyshin/drmTMB/issues/570`
- `https://github.com/itchyshin/DRM.jl/issues/291`
- `https://github.com/itchyshin/DRM.jl/issues/293`

Attempted to read `https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/2`;
it remained inaccessible from this session. No issue was edited, drafted, or
commented on.

## 8. Consistency Audit

The new vocabulary table keeps native ML balance, partial native REML,
experimental bridge support, diagnostic point fits, MAP wording, and Ayumi
reply readiness separate. The dashboard README and start script were updated
so the new TSVs are discoverable and copied into the served dashboard.

## 9. What Did Not Go Smoothly

The surprising part was the tracker evidence that an earlier Ayumi reply
exists, while the external thread remains unreadable here. That forced a
stronger access-boundary row so future work does not quote unread text.

## 10. Known Residuals

A021-A100 remain queued. Before any public reply, a session with issue access
must read the current Ayumi thread directly or the maintainer must supply the
exact latest text.

## 11. Team Learning

The balance question needs a validator-owned vocabulary, not just a prose
promise. The package can honestly say native ML balance and native REML
asymmetry at the same time only if every row names route, estimator, and
inference status.
