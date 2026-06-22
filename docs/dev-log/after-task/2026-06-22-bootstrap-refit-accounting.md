# After Task: Bootstrap Refit Accounting

## Goal

Bank S027 by standardizing bootstrap refit-count and failure-reason accounting
without making an interval-coverage claim.

## Implemented

Added `docs/dev-log/dashboard/bootstrap-refit-accounting.tsv` with seven rows:
public direct variance components, scalar phylogenetic SD, structured
location-scale direct targets, native q4 30-tip all-axis smoke, native q4
100-tip careful and robust negative smokes, and the Julia q4 30-tip bridge
smoke. The rows separate requested refits, successful refits, failed refits,
failure-reason visibility, diagnostic status, and interval-claim status.

Updated the mission-control validator and start script so the table is checked
and served with the dashboard.

## Checks Run

```sh
tools/validate-mission-control.py
git diff --check
```

Result: mission-control validation passed with the bootstrap accounting table.
`git diff --check` was clean.

## Consistency Audit

This is an accounting slice. It does not run new bootstrap jobs, change
bootstrap algorithms, claim interval coverage, promote native q4 uncertainty,
change model behavior, change bridge support, use non-Gaussian REML wording,
change HSquared AI-REML status, or draft Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use S028 to link q2 and q4 target tables without collapsing their support or
uncertainty statuses.
