# After Task: Ayumi Literature And Docs A081-A090

## 1. Goal

Bank the literature/docs wave so the Ayumi balance story is grounded in the
public location-scale motivation, local identifiability evidence, and current
drmTMB/DRM.jl route boundaries.

## 2. Implemented

Added `docs/design/204-ayumi-literature-docs-summary.md`, synchronized README,
formula grammar, known limitations, check-log, dashboard JSON, and banked
A081-A090 in the Ayumi 100-slice ledger.

## 3a. Decisions and Rejected Alternatives

I did not add a new public vignette or pkgdown navigation entry. The current
need is a local reply/stub plan, not a public tutorial surface. I also did not
expand the literature search into a broad review; the necessary citations are
already the PLSM, PC-prior, and penalized variance-component anchors used by
docs 170-173.

## 4. Files Touched

- `README.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/known-limitations.md`
- `docs/design/204-ayumi-literature-docs-summary.md`
- `docs/dev-log/after-task/2026-06-22-ayumi-literature-docs-summary.md`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/design/197-ayumi-phylo-balance-research-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## 5. Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/drm-status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/drm-sweep.json
tools/validate-mission-control.py
git diff --check
```

The validator was run before this docs wave and passed after A071-A080. The
final validator for A081-A090 is recorded in the main check log after these
edits.

## 6. Tests of the Tests

This wave is prose and dashboard state. The dashboard validator catches missing
or nonexistent evidence for banked A081-A090 rows; the stale-wording scans in
the final closeout will check for forbidden REML, bridge, and interval claims.

## 7a. Issue Ledger

No external issue was updated. The Ayumi issue URL remained inaccessible from
this session, so the note uses the user's quoted concern and public tutorial
context rather than quoting the issue.

## 8. Consistency Audit

The docs wave checked the public tutorial, docs 170-173, README current
boundaries, formula grammar, and known limitations. The resulting prose keeps
native ML balance, native REML asymmetry, direct DRM.jl machinery, and R bridge
promotion as separate claims.

## 9. What Did Not Go Smoothly

The external GitHub issue still could not be read here. The public tutorial was
available, and it was enough to ground the location-scale motivation without
using inaccessible issue text.

## 10. Known Residuals

No public vignette was added. No issue reply was drafted or posted. Literature
claims remain scoped to motivation and vocabulary; they are not validation for
drmTMB q4 intervals.

## 11. Team Learning

When a user asks whether support is "balanced", answer separately for syntax,
point fit, estimator, inference, data design, and bridge parity. The word
"balanced" alone hides too much.
