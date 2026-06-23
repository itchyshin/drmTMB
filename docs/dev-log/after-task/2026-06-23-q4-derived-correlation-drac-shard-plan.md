# Q4 Derived-Correlation DRAC Shard Plan

## 1. Goal

Bank r57 as a race-safe DRAC/totoro execution plan for the ADEMP-sized q4
derived-correlation delta grid, without running the calibrated grid or moving
SR150.

The simulation plan follows the ADEMP framing of Morris, White, and Crowther
(2019) and the MCSE/reporting discipline of Williams et al. (2024). The current
slice is infrastructure only: it prepares execution layout before any
calibrated coverage wording can be considered.

## 2. Implemented

- Added optional shard controls to the resumable q4 derived-correlation runner:
  `--n-shards`, `--shard-index`, `--manifest-dir`, `--manifest-file`,
  `--run-log-dir`, and `--run-log-file`.
- Kept the default r56 runner behavior unchanged for the already-banked totoro
  pilot.
- Added the dry-run script
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-drac-shard-plan.R`.
- Generated
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-drac-shard-plan.tsv`.
- Added the dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv`.
- Wired the sidecar into the mission-control widget, validator, focused R
  contract test, dashboard README, status JSON, sweep JSON, and build marker
  `r57`.

## 3a. Decisions and Rejected Alternatives

The plan uses nine CPU worker labels: `drac01` through `drac08` plus `totoro`.
These are scheduling labels, not confirmed hostnames. Replace them with concrete
DRAC hostnames only after the user logs in or confirms which DRAC machines are
available.

The plan assigns seed-scale cells by round-robin cell index rather than one
large contiguous block per host. This spreads scale levels across workers and
keeps shard sizes balanced: one shard has 112 cells and eight shards have 111
cells.

The plan rejects a shared run log. Each shard writes a private cell directory,
manifest, and run log under
`q4-derived-correlation-delta-grid-drac-shards/shard_XX/`. Aggregation happens
only after all shard manifests exist.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-drac-shard-plan.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-drac-shard-plan.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-drac-shard-plan.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-075606-codex-checkpoint.md`

## 5. Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-drac-shard-plan.R`
  passed and wrote the 9-shard dry-run plan.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` passed.
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `Rscript tools/codex-checkpoint.R --goal "r57 q4 derived-correlation DRAC shard plan" --next "Run a two-shard rehearsal using private shard roots, aggregate outputs, verify unique cell IDs and denominator MCSE fields, then keep SR150 blocked until calibrated evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-075606-codex-checkpoint.md`.

Full validator and focused R test checks are recorded in the current
check-log entry for this slice.

## 6. Tests of the Tests

The validator and focused R test now require:

- eight dashboard sidecar rows;
- nine shard-plan artifact rows;
- worker labels `drac01` through `drac08` plus `totoro`;
- 1000 total seed-scale cells and 6000 total target rows;
- shard cell counts `112;111;111;111;111;111;111;111;111`;
- private per-shard output roots, manifests, and run logs;
- runner commands carrying `--n-shards=9`, `--cell-limit=1000`,
  `--force=false`, private manifest paths, and private run-log paths;
- coverage and failure-rate MCSE planning values of 0.009747;
- explicit blocking of q4 interval reliability, interval coverage, q4 REML,
  AI-REML, HSquared transfer, and broad bridge support claims.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150.

## 8. Consistency Audit

SR150 remains blocked. The r57 plan does not run the calibrated grid, estimate
coverage, promote interval reliability, promote q4 REML, promote HSquared
AI-REML, promote broad bridge support, stage a commit, open a PR, or prepare an
Ayumi-facing reply.

The HSquared AI-REML lane is explicitly study-first. Before any future AI-REML
transfer work, read the HSquared source and evidence, then create a separate
claim boundary and validation plan. Do not mix that study with this q4
derived-correlation grid.

## 9. What Did Not Go Smoothly

A custom two-shard smoke invocation of the dry-run script temporarily overwrote
the default plan artifact. The default 9-shard plan was regenerated immediately,
and the script's aggregate-gate text was corrected so custom dry runs report
their own cell and target-row counts.

## 10. Known Residuals

The next rung is a two-shard rehearsal, not the full calibrated grid. That
rehearsal should run one small DRAC/totoro split, aggregate private shard
outputs, verify unique cell IDs and denominator retention, and rerun without
force to confirm skip behavior before the 9-shard ADEMP grid is dispatched.

## 11. Team Learning

Curie and Grace should treat remote simulation scaling as a three-step ladder:
single-host resumability, two-shard aggregate rehearsal, then full worker
dispatch. Fisher and Rose should keep SR150 blocked until observed MCSE and
denominator evidence, not planned MCSE, exists.

## References

Morris, T. P., White, I. R., & Crowther, M. J. (2019). Using simulation studies
to evaluate statistical methods. *Statistics in Medicine*, 38, 2074-2102.

Williams, M. N., et al. (2024). Transparent reporting items for simulation
studies evaluating statistical methods. *Methods in Ecology and Evolution*, 15,
1926-1939.
