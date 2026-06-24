# Q4 Derived-Correlation Delta Grid ADEMP Contract

## 1. Goal

Turn the r52 mini-grid into an ADEMP-sized dry-run contract for the next q4
derived-correlation delta grid, with predeclared seed ranges, denominator
fields, boundary-clamp accounting, and MCSE thresholds.

## 2. Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-ademp-dry-run.R`.
- The dry-run requires at least 475 replicates and defaults to 500 replicates,
  seed range 202607500-202607999, and scale levels 0.35 and 0.50.
- Added raw artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-ademp-dry-run.tsv`.
- Added ADEMP design note
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-ademp-design.md`.
- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv`.
- Updated the mission-control validator, focused dashboard contract test,
  dashboard table, dashboard README, status JSON, sweep JSON, version marker,
  executable-evidence ledger, and check-log.

## 3. Mathematical Contract

The r53 dry-run freezes 500 replicate seeds per scale level for the stabilized
q4 Gaussian phylo DGP. With two scale levels and six derived-correlation
targets, the future run has 1000 seed-scale cells and 6000 target rows.

The six targets are `cor_mu1_mu2`, `cor_mu1_sigma1`, `cor_mu1_sigma2`,
`cor_mu2_sigma1`, `cor_mu2_sigma2`, and `cor_sigma1_sigma2`, each with true
value 0.05. The planned interval method is
`wald_delta_finite_difference`, using the same full-vector `theta_phylo`
report reconstruction as r51 and r52.

For nominal 0.95 coverage and 500 replicates per scale-target cell, the
predeclared coverage MCSE is `sqrt(0.95 * 0.05 / 500) = 0.009747`, below the
0.01 gate. The reference failure-rate MCSE at rate 0.05 is also 0.009747.
Failures, nonconvergence, `pdHess = FALSE`, warnings, unavailable intervals,
boundary-clamped rows, and finite rows all remain in the denominator.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-ademp-dry-run.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-ademp-dry-run.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-ademp-design.md`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-ademp-contract.md`

## 5. Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-ademp-dry-run.R --n-rep=500`
  passed and wrote `q4-derived-correlation-delta-grid-ademp-dry-run.tsv`.
- `air format docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-ademp-dry-run.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `python3 - <<'PY' ... compile(...) ... PY` passed for
  `tools/validate-mission-control.py` without writing `__pycache__`.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 964 assertions.
- `python3 tools/validate-mission-control.py` passed with 8 q4
  derived-correlation delta-grid ADEMP contract rows and 54
  executable-evidence rows.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed and served build `r53`; direct fetches passed for `version.txt`,
  `status.json`, `sweep.json`,
  `structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv`, the
  raw dry-run TSV under `docs/dev-log/simulation-artifacts/`, and the ADEMP
  design note under `docs/dev-log/simulation-artifacts/`.
- Final `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests Of The Tests

The focused R test and mission-control validator require eight sidecar rows,
12 dry-run scale-target rows, 500 planned replicates, seed range
202607500-202607999, 1000 planned seed-scale cells, 6000 planned target rows,
the exact six q4 derived-correlation targets at both scale levels, nominal
coverage MCSE 0.009747, failure-rate MCSE at reference rate 0.05 equal to
0.009747, failure/clamp denominator policies, and explicit no-coverage/no-REML
boundary wording.

These tests would fail if the dry-run silently lowered the replicate count,
lost a target or scale level, changed the MCSE gate, dropped failed or clamped
rows from denominator policy, or presented the dry-run as calibrated coverage
evidence.

## 7. Consistency Audit

Scoped searches run:

- `rg -n "delta-grid ADEMP|delta grid ADEMP|q4-derived-correlation-delta-grid-ademp|run-calibrated-grid-delta-ademp|q4_delta_ademp" docs/dev-log/dashboard docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-ademp-dry-run.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-ademp-design.md docs/dev-log/dashboard/README.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The first search found the new dry-run script, raw artifact, ADEMP design,
sidecar, widget, status feeds, validator, focused test, check-log, and
executable-evidence ledger. The second search found boundary wording and
validator/test assertions that reject overclaims.

## 8. GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150, and Ayumi-facing text remains out of
scope until the exact issue text and final reply are approved.

## 9. What Did Not Go Smoothly

The first validator run failed because the new executable-evidence row pointed
to this after-task report before the report existed. Creating the report fixed
the evidence-path dependency; the failure was useful because it confirmed the
dashboard does not accept dangling evidence rows.

A handoff audit also caught that the raw dry-run TSV denominator policy used
an accidental internal space where the sidecar used an underscore. Regenerating
the artifact from the source script fixed the raw evidence before banking this
checkpoint.

## 10. Team Learning

Curie and Fisher now have a dry-run gate that can prevent accidental small-grid
coverage claims. Rose should keep checking that SR150 remains blocked until real
calibrated outputs replace the dry-run rows.

## 11. Known Limitations

This slice does not run the 500-replicate grid. It is an ADEMP-sized dry-run
contract only. It does not estimate calibrated coverage, does not move SR150,
and does not promote q4 interval reliability, q4 REML, AI-REML, broad bridge
support, a commit, PR, or Ayumi reply.

## 12. Next Actions

Implement a resumable per-cell grid runner for the r53 contract, then run a
small resumability smoke before any large replicate campaign.
