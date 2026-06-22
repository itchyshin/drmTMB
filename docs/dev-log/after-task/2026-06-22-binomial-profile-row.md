# After Task: Binomial Profile Row

## 1. Goal

Bank slice S043 by recording target-scoped binomial profile status without
promoting profile intervals.

## 2. Implemented

- Added a focused binomial test showing that fixed-effect `mu` profile targets
  are visible, direct, and profile-ready.
- Kept `confint(method = "profile")` guarded so callers must request explicit
  target names.
- Recorded the current explicit low-budget `fixef:mu:x` profile outcome as a
  structured `profile_failed` / `nonfinite_interval` row.
- Added `docs/dev-log/dashboard/binomial-profile-status.tsv` and validator,
  dashboard-copy, and dashboard README wiring.
- Added `docs/design/196-binomial-profile-row.md`.

## 3a. Decisions and Rejected Alternatives

The slice records the current low-budget explicit profile result as failure
status rather than treating profile-target readiness as interval readiness.
Default `confint(method = "profile")` remains guarded by explicit `parm`
requirements so the method does not guess targets for users.

## 4. Files Touched

- `tests/testthat/test-binomial-response.R`
- `docs/dev-log/dashboard/binomial-profile-status.tsv`
- `docs/dev-log/dashboard/finish-100-slices.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/196-binomial-profile-row.md`
- `docs/dev-log/after-task/2026-06-22-binomial-profile-row.md`
- `docs/dev-log/check-log.md`
- `tools/start-mission-control.sh`
- `tools/validate-mission-control.py`

## 5. Checks Run

The focused binomial test, dashboard JSON parsing, mission-control validation,
and whitespace check passed:

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "binomial-response", reporter = "summary")'
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/sweep.json
tools/validate-mission-control.py
git diff --check
```

`tools/validate-mission-control.py` reported 3
`binomial-profile-status.tsv` rows.

## 6. Tests of the Tests

The new test exercises a failure path as well as the ready target path:
`confint(method = "profile")` must reject missing explicit targets, while an
explicit low-budget target must return a structured
`profile_failed`/`nonfinite_interval` row.

## 7a. Issue Ledger

No GitHub issue was edited. The row stays inside local mission-control evidence
for the current 100-slice run.

## 8. Consistency Audit

The dashboard validator now requires the profile-status TSV schema, allowed
status vocabulary, local evidence links, and no unsupported AI-REML promotion
phrasing. The dashboard copy script includes the new TSV.

## 9. What Did Not Go Smoothly

The first attempt at this slice had stale test-file context after the restart,
so the test insertion was redone against the current file.

## 10. Known Residuals

The explicit profile smoke intentionally records a failed interval endpoint.
Binomial profile intervals need a broader non-boundary feasibility grid and
coverage accounting before any public interval claim.

S043 records target visibility and failure-status evidence only. It does not
promote binomial profile intervals, evaluate coverage, add random effects,
relax Julia bridge gates, claim non-Gaussian REML, expose public
`engine_control`, or touch Ayumi-facing text.

## 11. Team Learning

Profile-target readiness and profile-interval readiness are different claims.
Dashboard rows should keep target discovery, default-call guards, explicit
failure status, and interval-promotion state as separate columns.
