# R=999 paired-diagnosis authentication receipt

Date: 2026-07-26
Scope: scalar Gaussian random-intercept RE-SD diagnostic only.

## Source and execution identity

The existing Totoro run used `~/drm_work/a1_coverage.R` with SHA-256
`18439f2d90b0cf31a905f401fa0ba4626b41c8415d8f8fab8b12264711abce1b`, exactly
matching the hash frozen in `launch_r999_subset.sh`.

The run launched 100 ten-replicate shards for each original A1 cell:

| Cell | Groups | Observations/group | True RE SD | Outer attempts | Bootstrap draws |
|---|---:|---:|---:|---:|---:|
| `c01` | 10 | 4 | 0.5 | 1,000 | 999 |
| `c03` | 50 | 4 | 0.5 | 1,000 | 999 |

## Retention and pairing check

Read-only Totoro checks returned:

```text
CSV shards: 200
Detected error logs: 0
Historical R=199 target rows: 2,000
R=999 target rows: 2,000
Merged paired rows: 2,000
Incomplete merged rows: 0
Duplicate (cell_id, seed), R=199: 0
Duplicate (cell_id, seed), R=999: 0
```

The analysis filters only to the prespecified marginal scalar target
`sd:mu:(1 | g)`, then requires a complete, exact 2,000-row paired merge. It
does not drop nonconverged or failed rows to improve coverage; none occurred in
this matched target subset.

## Verdict

The R=999 data pass provenance, shard-completeness, and pairing gates. They are
eligible for the diagnostic comparison in `r999-diagnosis-report.md`; no other
interval conclusion follows from this receipt.
