# After Task: Q-Series Tranche 7 Relmat Q4 Location Coverage Pregrid Contract

## 1. Goal

Bank the relmat-only q4 location coverage pregrid design after Tranche 6
admitted relmat direct-SD targets for coverage-design discussion, without
executing coverage or moving any support-cell status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche7-relmat-coverage-pregrid-contract.tsv`,
a six-row design-only contract for the exact relmat q4 location direct-SD
targets. The four target rows map to coverage-grid shards 13-16, planned SR150,
`bootstrap = 0`, Totoro/control-master as the primary host route, and DRAC as
fallback after submission-pack review.

The contract links back to Tranche 6 review rows and Tranche 5 host-separated
repeat rows, requires source SHA, dirty-state, host-label, seed-manifest,
exact-command, run-log, and Mission Control provenance before execution, and
keeps Rose, Fisher, and Grace as blocking reviewers.

## 3a. Decisions and Rejected Alternatives

SR150 is a screen only. It is not treated as coverage evidence and cannot meet
the MCSE threshold by itself; that remains reserved for SR475 or a reviewed
top-up. This tranche rejected coverage execution, all-provider reruns, host
denominator pooling, support-cell movement, q4 REML, REML, AI-REML, q8, and
derived-correlation interval claims.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche7-relmat-coverage-pregrid-contract.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche7-relmat-q4-location-coverage-pregrid-contract.md`

## 5. Checks Run

- `python3 - <<'PY' ...`: confirmed the Tranche 7 sidecar has seven lines
  including its header and 33 columns on every row.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}'
  docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js &&
  node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 8 Q-Series inference-evidence summary
  rows, 6 q4 location Tranche 6 relmat-review rows, and 6 q4 location Tranche
  7 relmat-pregrid contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'`: passed after
  tightening the new test to the existing TSV reader and member-board schema.
- `rg -n "Tranche 7.*coverage result|Tranche 7.*inference_ready|relmat q4.*coverage authorized|relmat q4.*supported|q4 location relmat.*supported|q4 location relmat.*inference_ready"
  ... || true`: expected hits only in the new Tranche 7 no-claim boundary text.
- `rg -n "coverage_authorized|promotion_decision[[:space:]]+promote|authority_status[[:space:]]+supported|relmat q4.*is supported|relmat q4.*is inference_ready"
  ... || true`: no positive Tranche 7 claim; only historical
  `0_q4_coverage_authorized` invariant text.

## 6. Tests of the Tests

The new focused test checks the Tranche 7 sidecar schema, row counts, exact
shards, seeds, runner arguments, no-coverage and no-promotion decisions,
required host provenance, Rose/Fisher/Grace member-board rows, and the linked
relmat q4 support cell. The first run failed because the test assumed numeric
types for character TSV fields and used two wrong source-column names; fixing
those assumptions made the test match the actual dashboard contract.

## 7a. Issue Ledger

No GitHub issue action was taken. This tranche is a local Mission Control
design contract and does not change public API, formula grammar, package
support, or user-facing documentation.

## 8. Consistency Audit

Rose: the contract is design-only and does not make a tier or support claim.

Fisher: SR150 is explicitly a screen, not coverage evidence; coverage execution
requires a separate Rose/Fisher/Grace-approved host submission pack.

Grace: the contract requires source SHA, dirty-state, host label, seed
manifest, exact commands, run log, and Mission Control provenance before
execution, and forbids host denominator pooling.

Gauss: failed fits, nonconvergence, `pdHess = FALSE`, nonfinite intervals,
gradient/profile warnings, and boundary information stay in the denominator
policy.

Noether: the scope remains the four direct-SD q4 location targets only; no
derived-correlation interval or q8 target is claimed.

## 9. What Did Not Go Smoothly

The first focused test run failed on test assumptions, not contract data:
`planned_shard` and `seed_start` were read as character fields, Tranche 6 review
rows do not carry a `profile_target` column, and member discussions use
`evidence_path`, not `evidence_url`.

## 10. Known Residuals

- No Tranche 7 coverage job has been authorized or run.
- No Tranche 7 result has been imported.
- No support-cell status changed.
- The next execution gate still needs a host submission pack with exact
  commands, source and host provenance artifacts, and Rose/Fisher/Grace
  approval.

## 11. Team Learning

Coverage design can be banked as a useful campaign step without spending
compute. For Q-Series work, the honest next unit is often a reviewed contract
with stop rules, not a run.

## Next Actions

Prepare the relmat-only q4 location host submission pack for Rose/Fisher/Grace:
exact commands for shards 13-16, source SHA and dirty-state capture, host label,
seed manifest, run-log path, output paths, and stop rules before any execution.
