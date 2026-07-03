# After Task: Q-Series Tranche 99 q1 mu one-slope spatial DRAC allocation install-load proof

## Goal

Bank the Tranche 99 q1 `mu` one-slope spatial-only DRAC allocation install/load
proof before any repeat model job. The claim is narrow: one Slurm job was
submitted, allocated, and failed before module load; no package install, package
load, model, denominator, coverage, or status movement occurred.

## Implemented

Added
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche99-spatial-drac-allocation-install-load-proof.tsv`
with 8 decision rows. Fetched Rorqual artifacts under
`docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche99-spatial-drac-allocation-install-load-proof/`,
including host provenance, Slurm stderr/stdout, `sacct` output, the staged
sbatch packet, packet hash, and a compact terminal-review note. Appended SC439
member-board rows and moved the q1 `mu` one-slope queue primary evidence to T99.

## Mathematical Contract

No formula, estimand, covariance structure, likelihood, or interval rule changed.
The direct-SD target identity remains `sd_mu_intercept` and `sd_mu_x` for the
spatial q1 `mu` one-slope cell. T99 is not fit evidence, interval evidence,
admission evidence, coverage evidence, or support evidence.

## Files Changed

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche99-spatial-drac-allocation-install-load-proof.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

- Parsed the T99 sidecar, q1 `mu` one-slope queue, and member-discussions TSVs:
  9 T99 TSV lines including header, 45 columns, no bad-width rows; queue rows
  have 14 columns and member rows have 12 columns.
- Extracted dashboard JavaScript from `docs/dev-log/dashboard/index.html` and
  ran `node --check /tmp/drmtmb-mission-control-index-r293.js`; passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py` passed and reported 8 T99 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'Sys.setenv(OMP_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1"); devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'` passed with
  `DONE` after stale queue string expectations were corrected from T99 to T100.
- Support-cell invariant scan reported `104 96 8 0 0 0 0`: 104 Q-Series cells,
  96 non-ordinary structured-provider cells, 8 interval+coverage
  `inference_ready` rows, 0 authority `supported` rows, 0 structured
  `supported` rows, 0 q4 coverage-ready rows, and 0 q4 coverage-authorized
  rows.
- `git diff --check` passed.
- `tools/check-after-task.R` is not present in this checkout, so the named
  after-task checker could not be run.

## Tests Of The Tests

The focused conversion-contract test now reads the T99 TSV, checks the expected
8 decision IDs, validates linked artifacts, verifies Slurm job `15094722` failed
with `FAILED 1:0`, confirms the `SKIP_CC_CVMFS` pre-module failure signature,
and checks that SC439 includes Rose/Fisher/Gauss/Noether/Grace blocking claims.
The validator separately enforces the same row-level contract.

## Consistency Audit

Mission Control build `r293` renders a T99 summary card, table, ledger entry, and
TSV loader. The dashboard README, completion map, queue, member board, validator,
tests, and check log all state the same boundary: no package install, no
`R CMD INSTALL`, no `library(drmTMB)`, no model, no denominator, no coverage,
and no support status movement.

## GitHub Issue Maintenance

No GitHub issue action was needed. This tranche updates local dashboard and
development-log evidence only; it does not change public APIs, formula grammar,
package code, pkgdown, README, NEWS, or support-cell statuses.

## What Did Not Go Smoothly

The first remote staging attempt failed before submitting because an unquoted
heredoc expanded an R `$package` expression while writing the sbatch script. The
corrected packet submitted job `15094722`, which then failed before module load
because `set -u` was active while sourcing the DRAC CVMFS profile and the profile
referenced unset `SKIP_CC_CVMFS`.

## Team Learning

Grace's next guard is concrete: T100 must patch/review the shell-profile source
order or define `SKIP_CC_CVMFS` safely before any repeat allocation. Rose and
Fisher keep T99 out of fit, denominator, admission, coverage, and support claims.

## Known Limitations

T99 does not make `drmTMB` loadable on Rorqual. It does not prove that `cli`,
`RcppEigen`, or `TMB` can be installed inside the run-local library. The q1 `mu`
one-slope spatial support cell remains `point_fit/planned/planned`.

## Next Actions

Checkpoint before any compute. Tranche 100 may only be a no-compute
shell-profile guard/packet review: patch the sbatch packet to avoid `set -u`
before sourcing the DRAC CVMFS profile or define `SKIP_CC_CVMFS` safely, then
run syntax, hash, and provenance checks. Stop before any repeat allocation,
package install, `R CMD INSTALL`, `library(drmTMB)`, smoke runner, model formula,
model fit, retained denominator, coverage, top-up, or status movement.
