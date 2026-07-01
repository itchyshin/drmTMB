# After Task: Q-Series Host Access Gate Sync

## Goal

Make the Q-Series widget and validator treat host access as a compute-routing
gate, not as inference or support evidence.

## Implemented

- Added `structured-re-q-series-host-access-recheck.tsv` as a first-class
  dashboard sidecar with five host rows: Totoro, FIIA, Nibi, Rorqual, and Fir.
- Added a host-access table and stat card to the Q-Series widget build `r153`.
- Updated the next-campaign queue so Nibi/Rorqual reachability is not a
  substitute for Totoro/FIIA smoke without a Fisher/Rose/Grace
  smoke-substitution contract.
- Updated Gaussian low-q row-selection, q1 `mu` dry-run, q1 `mu` smoke-contract,
  q2 intercept contract, q2-plus-q2 contract, local-smoke summaries,
  support-cell `next_gate` text, status-audit text, README dashboard notes, the
  dry-run runner, mission-control validator, and focused tests.
- Promoted no row and changed no `fit_status`, `interval_status`, or
  `coverage_status`.

## Mathematical Contract

No estimand, likelihood, interval rule, or coverage denominator changed. This is
a routing and status-boundary sync only: host reachability can permit a future
smoke only after the row contract accepts that host, and cannot by itself supply
interval, coverage, `inference_ready`, or `supported` evidence.

## Files Changed

- `docs/dev-log/dashboard/structured-re-q-series-host-access-recheck.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-dry-run.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-intercept-interval-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-local-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- Matching dashboard artifact mirrors under `docs/dev-log/simulation-artifacts/`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file
  tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 10 next-campaign rows, and 5 host-access recheck
  rows.
- `cmp` checks passed for row-selection, q1 `mu` dry-run, q2 intercept local
  smoke, and q2-plus-q2 local smoke dashboard/artifact mirrors.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 8645 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## Tests Of The Tests

The new host-access test first failed because it expected `checked_at` as a
`Date` while the project TSV reader returns character columns. After fixing the
test expectation, the focused contract suite passed. Mission-control validation
also failed before the neighboring q1/q2 host-gate text was synchronized, which
confirmed the validator was exercising the intended drift boundary.

## Consistency Audit

- Stale live-surface scan:
  `rg -n "fir is reachable but has no drmTMB checkout|fir checkout|fir_no_drmtmb|live host checkout|resolve Totoro/FIIA host access|host access or checkout|fir reachable with no drmTMB checkout" docs/dev-log/dashboard tools tests/testthat README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd`
  returned no matches after cleanup.
- Positive host-gate scan confirmed `smoke-substitution contract` appears in
  the README, widget, validator, focused test, next-campaign queue,
  row-selection, q1 `mu` dry-run, q2 contracts, and local-smoke summaries.
- No formula grammar, equations, likelihood parameterization, examples,
  vignettes, NEWS, ROADMAP, or pkgdown navigation changed.

## GitHub Issue Maintenance

`gh issue list --search "Q-Series OR qseries OR structured RE host smoke" --limit
20 --json number,title,state,url` returned no matching open issue in this
checkout, so no issue was opened or commented.

## What Did Not Go Smoothly

- The first TSV rewrite coerced formatted numeric fields in the q1 `mu` dry-run
  summary from `1.0000` / `0.000000` to `1` / `0`; mission-control caught this
  and the table was rewritten with character-safe reads.
- The initial stale-wording pass found old host text in neighboring live TSVs,
  not just the new sidecar, so the cleanup expanded to support cells, status
  audit rows, local-smoke summaries, and the dry-run runner.

## Team Learning

Rose's sweep was necessary: host reachability is a tempting shortcut, so it
needs a validated sidecar plus stale-wording scans. Grace's reproducibility
boundary is now explicit: Nibi/Rorqual are reachable, but they are not approved
substitutes until Fisher/Rose/Grace accept a substitution contract.

## Known Limitations

- This does not run any new smoke, denominator, interval, coverage, or HPC job.
- Totoro still needs interactive/key access, FIIA still needs an alias or host
  name, and Fir still lacks a checked qseries root.
- Nibi/Rorqual reachability is only a routing fact. It promotes no row and does
  not change `interval_status`, `coverage_status`, `inference_ready`, or
  `supported`.

## Next Actions

Write a Fisher/Rose/Grace smoke-substitution contract if Nibi or Rorqual should
replace the intended Totoro/FIIA smoke host. Otherwise restore Totoro/FIIA access
and run the exact reviewed q1/q2 smoke targets with all attempted rows retained.
