# After-task: Q-Series count recovery widget state

Meta: 2026-06-28 · Codex · branch `codex/qseries-sigma-inference-ready`;
dashboard build `r66`.

## 1. Goal

Make the Q-Series widget reflect the already-banked 80-rep count one-slope
recovery grid without promoting count intervals, coverage, bridge support, or
public support.

## 2. Implemented

The 104-row Q-Series board now has a distinct `recovery_only` state for the
eight Poisson/NB2 q1 `mu` one-slope count cells. The widget joins those cells to
`structured-re-count-slope-recovery-results.tsv` and shows fit_ok counts,
`pdHess` false counts, SD bias/RMSE, and the recovery-only claim boundary.

## 3a. Decisions and Rejected Alternatives

The later 80-rep recovery result is rendered as a sidecar join, while the
earlier fixture and runner contracts stay as historical pre-run artifacts.
This keeps provenance visible without pretending the old dry-run contracts were
the execution result.

Rejected alternatives:

- Do not rewrite the fixture/recovery contract rows to look post-run; the
  validator shows they are intended to preserve the dry-run contract.
- Do not move the count rows out of `interval_status = unsupported` or
  `coverage_status = planned`.
- Do not describe count recovery as bridge parity, REML, AI-REML, q2/q4 count
  covariance, or public support.

## 3b. Mathematical Contract

No likelihood, estimator, formula grammar, or interval method changed. The
statistical contract is descriptive: the count rows have native TMB ML/Laplace
point/extractor evidence plus local 80-rep recovery evidence for convergence
and structured-SD bias/RMSE. This does not create a Wald, profile, bootstrap, or
coverage interval contract.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-28-q-series-count-recovery-widget.md`
- `AGENTS.md`

## 5. Checks Run

- `sed -n '/<script>/,/<\\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -`: passed.
- `python3 tools/validate-mission-control.py`: `mission_control_ok`, including
  104 Q-Series support cells and 8 count-slope recovery-results rows.
- `git diff --check`: passed.
- Stale wording scan:
  `rg -n "Execute the count slope recovery runner contract|count.*recovery.*designed_not_run|recovery_only|structured-re-count-slope-recovery-results" docs/dev-log/dashboard docs/dev-log/check-log.md tools/validate-mission-control.py`.
- Superseded restart/sigma wording scan:
  `rg -n '15 commits, \`9ae75bf1\`|UNPUSHED|push it or it is lost|linked q-series cells keep \`interval_status = planned\`|linked support cells do not move to interval' AGENTS.md docs/dev-log/dashboard/README.md`: no hits.

## 6. Tests of the Tests

No package behaviour test changed. The mission-control validator still protects
the row count, recovery-result schema, linked support-cell coverage status, and
the `r66` build/version sync. The JavaScript syntax check protects the widget
change.

## 7a. Issue Ledger

No issue or PR comment was added. This was a local dashboard/status-ledger
alignment patch inside the existing Q-Series PR stack.

## 8. Consistency Audit

The Q-Series support-cell rows now say that the count recovery grid is banked,
while the historical fixture and runner contracts still describe their original
dry-run/pre-run roles. The dashboard README now explains the separation:
pre-run contracts are provenance, and
`structured-re-count-slope-recovery-results.tsv` is recovery-only evidence.
The restart instructions in `AGENTS.md` no longer tell the next agent that the
small-sample interval arc is unpushed, and the sigma-sidecar README language no
longer contradicts the later phylo/relmat q1 sigma promotion.

## 9. What Did Not Go Smoothly

The first instinct was to rewrite the fixture/recovery contract rows, but the
validator revealed those tables intentionally preserve the dry-run contracts.
The safer move was to keep those historical rows intact and surface the later
recovery result through the widget join.

## 10. Known Residuals

The eight count rows remain `interval_status = unsupported` and
`coverage_status = planned`. The recovery grid is only convergence plus SD
bias/RMSE evidence; it does not prove count interval reliability, q2/q4 count
covariance, REML, AI-REML, bridge support, or public support.

## 11. Team Learning

For Q-Series status work, sidecars should keep their temporal role visible:
pre-run contracts, local smoke shards, recovery grids, and interval/coverage
evidence are separate artifacts even when they refer to the same `cell_id`.

Next action: use this recovery-only display as the basis for the next count
tranche, or return to Gaussian q4 admission if the maintainer wants the high-q
lane first.
