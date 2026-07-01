# After Task: Q-Series Gaussian Mu-Slope Hybrid Boundary Audit

## 1. Goal

Use the repaired endpoint-profile boundary rows to decide the next routing gate
for Gaussian q1 `mu` one-slope rows, without promoting interval or coverage
status.

## 2. Implemented

This promotes exactly no support cell. The four linked Q-Series rows remain
`fit_status = point_fit`, `interval_status = planned`, and
`coverage_status = planned`.

I added `tools/summarize-structured-re-gaussian-mu-slope-hybrid-boundary.R`.
The script overlays the 42 repaired endpoint-profile boundary rows onto the
original SR150 Wald pregrid denominator and writes
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv`.
The widget now loads this sidecar as the current q1 `mu` slope routing audit:
animal stays `mu_slope_pregrid_blocked`, while phylo, relmat, and spatial move
to `topup_required`.

## 3a. Decisions and Rejected Alternatives

I kept the original SR150 pregrid sidecar unchanged. That file records the
default Wald run as executed; the new sidecar is a separate hybrid overlay.

Rejected alternatives: I did not edit the support-cell TSV to
`inference_ready`, because all four rows still have planned interval and
coverage status. I also did not top up animal, because the hybrid denominator
has a target-level hard negative: 132/150 covered, coverage 0.880, and 15 upper
misses.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-mu-slope-hybrid-boundary.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-hybrid-boundary-audit.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-mu-slope-hybrid-boundary.R --overwrite=true
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
git diff --check
air format tools/summarize-structured-re-gaussian-mu-slope-hybrid-boundary.R
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/structured-re-q-series-support-cells.tsv | wc -l
curl -fsS http://127.0.0.1:8765/structured-re-gaussian-mu-slope-hybrid-boundary-audit.tsv
```

Results: the summarizer wrote four hybrid audit rows. The mission-control
validator owns the exact schema, values, support-cell links, and no-promotion
claims for those rows and reported `mission_control_ok`. Dashboard JavaScript
syntax passed, `git diff --check` passed, the focused structured-RE conversion
test passed with 6353 PASS / 0 FAIL / 0 WARN / 0 SKIP, and the served dashboard
reported build `r94` with 104 Q-Series rows.

## 6. Tests of the Tests

The validator fails if the hybrid audit is missing, has the wrong four row ids,
changes linked support-cell interval/coverage status away from `planned`, drops
the no-promotion wording, or changes the animal-vs-top-up split.

## 7a. Issue Ledger

No GitHub issue action was taken. This is local dashboard and evidence-routing
work inside the Q-Series arc.

## 8. Consistency Audit

The hybrid audit splits the rows as follows:

- animal: 132/150 covered, 147/150 usable, coverage 0.880, misses lower=0
  upper=15, widget state `mu_slope_pregrid_blocked`.
- phylo: 284/300 covered, 299/300 usable, coverage 0.947, misses lower=3
  upper=12, widget state `topup_required`.
- relmat: 289/300 covered, 299/300 usable, coverage 0.963, misses lower=2
  upper=8, widget state `topup_required`.
- spatial: 286/300 covered, 300/300 usable, coverage 0.953, misses lower=6
  upper=8, widget state `topup_required`.

The widget, README, validator, and check log all state that this is SR150
routing evidence only, not `inference_ready`.

## 9. What Did Not Go Smoothly

My first scratch denominator calculation used the wrong holdout label for
animal. Recomputing with `denominator_role == "pregrid_target"` corrected the
split and showed that animal is the only hard negative after the hybrid
overlay.

## 10. Known Residuals

Phylo, relmat, and spatial still need a retained-denominator top-up to MCSE
`<= 0.01`, plus a miss-balance audit, before any `inference_ready` discussion.
Animal needs interval-channel work before top-up.

## 11. Team Learning

When a boundary repair changes finite-interval accounting, do not rewrite the
original pregrid. Add a hybrid overlay so the default-run evidence and repaired
denominator routing remain auditable separately.
