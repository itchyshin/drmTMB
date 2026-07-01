# After Task: Q-Series Substitute-Smoke Review Sync

## Goal

Record the already-imported Nibi substitute smokes as reviewed smoke-only
evidence and move their linked Gaussian low-q rows to retained-denominator or
calibration design, without promoting any Q-Series support cell.

## Implemented

- Closed the q1 `mu` intercept, q2 `mu1+mu2` intercept, and phylo q2-plus-q2
  intercept Nibi `n=5` smoke imports as Fisher/Rose-reviewed host/fixture
  evidence only.
- Updated nine Gaussian low-q row-selection rows to
  `nibi_rorqual_substitution_smoke_reviewed` with
  `retained_denominator_design_required`.
- Synced the smoke-substitution contract, next-campaign queue, row-selection
  ledger, support-cell rows, low-q status audit, validator, focused tests, and
  dashboard README so the next gate is an exact row-specific
  retained-denominator or calibration design.
- Reconciled the predecessor q1 `mu`, q2 intercept, and q2-plus-q2 contract
  sidecars so they no longer present substitute-host review as pending. The
  local dry-run and local-smoke sidecars remain historical artifact mirrors.
- Preserved all linked support cells at `point_fit/planned/planned`; no
  interval, coverage, `inference_ready`, or `supported` status changed.
- Bumped the dashboard build to `r158`.

## Mathematical Contract

No estimand, likelihood, formula grammar, interval correction, small-sample
rule, or denominator policy changed. The only claim is routing/evidence status:
the imported Nibi `n=5` artifacts are reviewed smoke evidence, not coverage or
support evidence.

## Files Changed

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-nibi-smoke-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-intercept-nibi-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-nibi-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-smoke-substitution-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 23 Gaussian low-q row-selection rows, 4 q1
  `mu` Nibi smoke rows, 12 q2 intercept Nibi smoke rows, and 6 q2-plus-q2 Nibi
  smoke rows.
- Embedded dashboard script syntax check via extracted `<script>` and
  `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- `git diff --check` on the touched dashboard, validator, focused-test, and
  reviewed-smoke TSV files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 8819 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## Tests Of The Tests

The focused conversion-contract test now asserts the reviewed smoke statuses,
reviewed sidecar paths, retained-denominator design run mode, and no-promotion
claim boundaries. Earlier contract-sync work showed this suite fails when the
required host-route and denominator-block phrases drift, so this rerun is a
real guard against silently treating smoke as coverage.

## Consistency Audit

- The support-cell table still has 104 rows.
- Exactly five rows have both `interval_status = inference_ready` and
  `coverage_status = inference_ready`.
- No row has `authority_status = supported`.
- Nine Gaussian low-q row-selection rows are now
  `nibi_rorqual_substitution_smoke_reviewed`.
- The current q1 `mu`, q2 intercept, and q2-plus-q2 contract sidecars now use
  reviewed-smoke contract statuses rather than old Totoro/FIIA smoke-ready
  statuses; the local-smoke sidecars are left as artifact mirrors.
- Stale wording scan:
  `rg -n "substitute-host artifacts pass Fisher/Rose review|blocked until Fisher/Rose review the substitute-host artifact|Fisher/Rose review of the host artifact" docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-*.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`
  returned no matches.
- The q2-plus-q2 sigma1/sigma2 direct-correlation profile failure remains
  visible and blocks denominator design until repaired or explicitly explained.

## GitHub Issue Maintenance

`gh issue list --search "Q-Series Nibi substitute smoke OR qseries smoke substitution OR retained denominator" --limit 20 --json number,title,state,url`
returned the broad open tracker `#59` only. No issue comment was added because
this sync is internal dashboard evidence hygiene and makes no public status
promotion.

## What Did Not Go Smoothly

- The existing contract-sync after-task report was still accurate for its time
  but ended with "run one substitute smoke" as next action. This report
  supersedes that next-action state rather than rewriting historical notes.
- The first consistency pass tried to rewrite local-smoke sidecars, but mission
  control correctly rejected that because those TSVs mirror historical
  artifacts. The fix was to restore those mirrors and put current-state wording
  only in the contract sidecars.
- The support-cell TSV does not have a single `support_status` column; the audit
  therefore checks `interval_status`, `coverage_status`, and `authority_status`
  separately.

## Team Learning

Rose's useful guard here is to split host access, smoke review, denominator
design, interval readiness, and support authority into separate fields. Grace's
cluster-access evidence should never be allowed to stand in for Fisher's
coverage evidence.

## Known Limitations

- This does not run a denominator grid.
- This does not promote any support cell.
- This does not resolve q1 sigma, matched `mu+sigma`, q2 slopes, q2-plus-q2
  sigma-correlation failure, q4/q8, non-Gaussian intervals, REML, AI-REML, or
  bridge support.

## Next Actions

Write the first exact retained-denominator or calibration contract from the
reviewed smoke rows. It must name one `cell_id`, one target set, interval
channel, MCSE gate, one-sided miss rule, host, seeds, artifact-retention policy,
blocked neighbours, and stop rules before any Nibi/Rorqual/DRAC denominator
work starts.
