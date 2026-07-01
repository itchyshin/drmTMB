# After Task: Q-Series q2 Repair Smoke Totoro Review

## 1. Goal

Run the retained-denominator q2 repair-smoke contract on Totoro as a bounded,
host-separated diagnostic slice, then import and review the results without
promoting any Q-Series row.

## 2. Implemented

This promotes exactly no Q-Series row. The five repair-contract cells ran on
Totoro as five concurrent single-threaded R jobs:
`phylo`, `spatial`, `animal`, and `relmat` q2 `mu1+mu2` intercept cells with
32 replicates each, plus the phylo q2_plus_q2 intercept cell with 16
replicates. The dispatch importer wrote
`structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv`, and the
Fisher/Rose/Grace review wrote
`structured-re-q2-retained-denominator-repair-smoke-review.tsv`.

The result is diagnostic-only. Four q2 intercept cells had complete fit,
`pdHess`, Wald-finite, and profile-finite counts, but their smoke MCSEs remain
above 0.01 and miss patterns still require review. The phylo q2_plus_q2
intercept cell had profile finiteness loss: minimum profile-finite count 14/16.
All five rows remain `point_fit/planned/planned`.

## 3a. Decisions and Rejected Alternatives

The smoke used Totoro rather than DRAC because the contract allowed a small
repair smoke on Totoro after source/root checks, and Totoro had an existing
ControlMaster connection. I rejected broad SR475/SR1000 top-up because the
repair smoke did not define or pass a new interval-repair route. I also rejected
mixing Totoro results into existing Nibi/Rorqual denominators; these artifacts
are host-stamped Totoro diagnostics only.

The first Totoro attempt failed because the default R library did not expose
`TMB`. The second failed because the source snapshot still had a macOS-built
`src/drmTMB.so`. I cleaned Totoro compiled objects, verified a Linux-side
`devtools::load_all()` rebuild, pinned
`R_LIBS=/home/snakagaw/drmtmb-qseries/20260630-totoro-standby-77b634eda91b/rlib`,
and reran the same five-cell contract.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-manifest-local/`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-totoro-parallel/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-q-series-q2-repair-smoke-totoro-review.md`

## 5. Checks Run

- Totoro dry run:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q2-retained-denominator-repair-smoke.R --dry-run=true --write-dashboard=false --host-class=totoro_q2_repair_parallel_smoke --host-name=totoro --output-root=docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-totoro-parallel --overwrite=true`.
- Totoro dependency check with pinned library: `library(TMB)` and
  `library(RcppEigen)` loaded under R 4.5.3.
- Totoro Linux rebuild check:
  `R_PROFILE_USER=/dev/null R_LIBS=/home/snakagaw/drmtmb-qseries/20260630-totoro-standby-77b634eda91b/rlib NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::load_all(".", quiet = TRUE)'`: passed.
- Totoro five-cell parallel smoke: passed after the Linux rebuild; logs show
  four q2 intercept summaries plus the q2_plus_q2 summary were written.
- `pgrep -af "run-structured-re-q2|q2-retained-denominator-repair"` after the
  run: no matching runner remained.
- Local import:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R --manifest=docs/dev-log/simulation-artifacts/2026-06-30-q2-retained-denominator-repair-smoke-totoro-parallel/structured-re-q2-retained-denominator-repair-smoke-command.tsv --output=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv --overwrite=true --require-artifacts=true`: passed.
- Local review:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R --dispatch=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv --output=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv --sync-dashboard=true --overwrite=true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- Required section-header check for this after-task report: passed with
  `after_task_headers_ok`. The hub mentions `tools/check-after-task.R`, but that
  script is not present in this repository.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 10206 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.

## 6. Tests of the Tests

The smoke exposed two real infrastructure failures before any scientific result:
missing `TMB` on Totoro's default `.libPaths()` and an invalid macOS shared
object in the source snapshot. The subsequent `devtools::load_all()` check
would have failed if the Linux rebuild had not replaced the stale object. The
dispatch summarizer was run with `--require-artifacts=true`, so missing
per-cell artifacts would have failed the import instead of becoming
manifest-only rows.

## 7a. Issue Ledger

No GitHub issues or PR comments were changed in this slice. The local issue
ledger outcome is: q2 repair smoke ran, but all five cells remain blocked from
top-up and status edits until a named interval-repair route exists and passes
this same small smoke contract.

## 8. Consistency Audit

Mission control, the dispatch sidecar, review sidecar, support-cell table,
next-campaign queue, and dashboard build now agree that the Totoro smoke is
diagnostic-only. The support-cell rows still say
`do_not_promote_keep_point_fit_planned_planned`, and the claim boundaries
forbid `interval_status`, `coverage_status`, `inference_ready`, `supported`,
q2 inheritance, q4/q8, non-Gaussian intervals, REML, AI-REML, bridge support,
and public support.

## 9. What Did Not Go Smoothly

The Totoro source snapshot was parse-ready but not compute-ready. It needed the
standby R library path for `TMB` and `RcppEigen`, and it needed stale compiled
macOS objects removed before Linux could load the package. The runner also
recorded failed `git rev-parse` output because the Totoro snapshot excludes
`.git`; I replaced those `git-sha.txt` files with the local source SHA
`77b634eda91b0173926557ce5c4a3d20853fb215` and wrote a Totoro module/library
note.

## 10. Known Residuals

The q2 repair smoke did not repair the interval route. Four q2 intercept cells
are finite but MCSE-limited at n=32 and still show upper-miss pressure; the
phylo q2_plus_q2 intercept cell has profile finiteness loss. These are not
coverage denominators and must not be used for promotion. A full
`devtools::check()` was not rerun for this slice.

## 11. Team Learning

Parse-ready remote snapshots are not compute-ready. For Totoro, clean compiled
objects and run a one-line `devtools::load_all()` with the intended `R_LIBS`
before launching any parallel smoke. For no-queue hosts, cell-level
parallelism is the right first acceleration when each cell writes a separate
artifact root.
