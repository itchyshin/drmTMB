# After Task: Q-Series High-Q Diagnostic Status Sync

## 1. Goal

Make the 104-row Q-Series board show existing high-q interval diagnostic
evidence as a separate status signal, without promoting q4, q6, q8, REML,
AI-REML, coverage, `inference_ready`, `supported`, bridge support, or public
support.

## 2. Implemented

This promotes exactly no support cell. It changes exactly twelve high-q or
q8-shaped support-cell rows from `interval_status = planned` to
`interval_status = diagnostic_only`, with `coverage_status = planned` retained
for every row:

- four q4 location one-slope rows:
  `qseries_phylo_q4_mu1_mu2_one_slope`,
  `qseries_spatial_q4_mu1_mu2_one_slope`,
  `qseries_animal_q4_mu1_mu2_one_slope`, and
  `qseries_relmat_q4_mu1_mu2_one_slope`;
- four q4 all-four intercept rows:
  `qseries_phylo_q4_all_four_intercept`,
  `qseries_spatial_q4_all_four_intercept`,
  `qseries_animal_q4_all_four_intercept`, and
  `qseries_relmat_q4_all_four_intercept`;
- four q8-shaped all-four one-slope rows:
  `qseries_phylo_q4_all_four_one_slope_planned`,
  `qseries_spatial_q4_all_four_one_slope_planned`,
  `qseries_animal_q4_all_four_one_slope_planned`, and
  `qseries_relmat_q4_all_four_one_slope_planned`.

The qseries table keeps the original fixture evidence URLs and claim
boundaries. The linked high-q audit rows now carry
`linked_interval_status = diagnostic_only` and explain that the interval signal
is diagnostic-only, with no calibrated denominator and no coverage promotion.

## 3a. Decisions and Rejected Alternatives

I first tried moving the master row evidence URLs to the interval diagnostic
sidecars. The validator correctly rejected that as a drift from the fixture
contracts. I narrowed the change so the support-cell table records only the
status signal, while the high-q audit owns the diagnostic explanation.

Rejected alternatives: no q4/q8 interval channel was accepted, no coverage
denominator was admitted, no high-q row was promoted to `inference_ready`, and
the q4/q8 fixture sidecars were not rewritten.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/slurm/count-intercept-topup-rorqual.sbatch`
- `docs/dev-log/dashboard/structured-re-count-intercept-topup-cluster-dispatch.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-high-q-diagnostic-status-sync.md`

## 5. Checks Run

```sh
/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
node --check /tmp/drmtmb-dashboard-script.js
git diff --check
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::check()'
```

Results: `tools/validate-mission-control.py` reported `mission_control_ok`;
dashboard JavaScript syntax passed; `git diff --check` passed; and the focused
`structured-re-conversion-contracts` test passed with 6353 PASS / 0 FAIL /
0 WARN / 0 SKIP. The served dashboard copy reports build `r89`.
`devtools::check()` passed in 11m 8.5s with 0 errors, 0 warnings, and 0 notes.

The 104-row support-cell interval counts are now: 40 `unsupported`, 37
`planned`, 18 `diagnostic_only`, 5 `inference_ready`, and 4
`interval_feasible`. Coverage counts are unchanged: 78 `planned`, 21
`unsupported`, and 5 `inference_ready`.

## 6. Tests of the Tests

The mission-control validator now has an exact
`CERTIFIED_DIAGNOSTIC_INTERVAL_CELLS` allow-list for the twelve q4/q8-shaped
rows. It permits `diagnostic_only` only for `interval_status`; coverage remains
guarded separately and cannot become `inference_ready` for high-q rows. The
focused test mirrors the same allow-list in `.expected_interval()` and keeps
the denominator policy pinned to `fixture_not_coverage`.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work updates local
mission-control evidence on the current Q-Series branch and does not open or
close a public capability claim.

## 8. Consistency Audit

The high-q audit still has 24 rows: eight q4 gate-required rows, five
q8/q8-shaped stability-blocked rows, three high-q diagnostic comparator rows,
and eight high-q planned rows. The row-state audit and support-cell table now
agree on the twelve tried high-q interval diagnostics, while coverage remains
planned and all high-q rows remain non-promoted.

The count-intercept top-up cluster-dispatch ledger was also updated to the
completed Rorqual confirmation, SLURM job `14897050`. This is recovery-only
confirmation evidence: the runner and summary both exited 0, and the fetched
three-row result TSV matches the local top-up sidecar on row identity,
denominators, `pdHess`, near-zero counts, and recovery verdicts.

## 9. What Did Not Go Smoothly

The first Rorqual submission tried to install R dependencies from CRAN and was
blocked by the cluster proxy. The second switched to the module-backed
`r-bundle-bioconductor/3.21` dependency stack but failed in the dependency
logger because `packageVersion()` needed `as.character()`. The third
submission, job `14896924`, got past dependency checking but failed when a
stale local Mach-O build object was copied into the Linux source tree. The
fourth submission, job `14896996`, cleaned source build products and installed
the package, then failed because the recovery runner was launched from the
campaign root while sourcing repo-relative helper files. The fifth submission,
job `14897050`, ran recovery scripts from the repo root and completed.

## 10. Known Residuals

High-q rows are still not inference-ready. q4 coverage remains blocked on
denominator admission, finite direct-SD interval rates, derived-correlation
interval machinery, and Hessian/geometry diagnostics. q8 remains stability
first. The Rorqual count-intercept top-up confirmation is now archived with the
local evidence. The Rorqual confirmation still does not make any non-Gaussian interval, coverage,
`inference_ready`, `supported`, REML, AI-REML, bridge, or public-support claim.

## Next Actions

Use the cluster-confirmed count-intercept rows as recovery-only board evidence.
Design a separate interval route before any non-Gaussian interval, coverage,
`inference_ready`, or `supported` wording.

## 11. Team Learning

For the 104-row board, status fields should carry the newest evidence signal,
but evidence URLs and claim boundaries should stay attached to the sidecar that
owns that contract. The high-q audit is the right place to narrate diagnostic
interval attempts; the support-cell table should expose the status without
pretending the row has calibrated interval reliability.
