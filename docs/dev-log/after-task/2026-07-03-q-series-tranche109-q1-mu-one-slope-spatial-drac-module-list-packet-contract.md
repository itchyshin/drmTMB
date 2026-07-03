# Q-Series Tranche 109 q1 mu one-slope spatial DRAC module-list packet contract

## 1. Goal

Bank the Tranche 109 no-compute packet contract after the Tranche 108
module-list syntax review. The goal was to fix the packet contract shape before
spending another allocation, while keeping the q1 `mu` one-slope spatial support
cell at `point_fit/planned/planned`.

## 2. Implemented

Added a 10-row Mission Control sidecar for T109 and two local packet artifacts:
the contract summary and an unexecuted shell snippet. The snippet replaces the
bad `module list -t` capture with plain `module list`, requires `r/4.4.0` in
the captured module list, probes `command -v R` and `command -v Rscript`, and
stops before package install, `R CMD INSTALL`, `library(drmTMB)`, any smoke
runner, and any model fit.

Mission Control build `r303`, the queue row, member discussions, validator,
focused tests, dashboard README, completion map, and check log now all point to
T109 as banked evidence and route the next gate to checkpointed Tranche 110
only.

## 3a. Decisions and Rejected Alternatives

The economical decision was to write a packet contract only. A repeat
`sbatch`/`salloc` allocation was rejected because the existing evidence showed a
packet syntax error, not a model or package route result.

The contract deliberately stops before package install and package load even if
`R` and `Rscript` are found. That keeps T110 narrow: one allocation-safe
module-list/executable proof, not a dependency-install proof and not a model
smoke.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche109-spatial-drac-module-list-packet-contract.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche109-spatial-drac-module-list-packet-contract/t109-module-list-packet-contract.txt`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche109-spatial-drac-module-list-packet-contract/t109-module-list-guard-snippet.sh`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-q-series-tranche109-q1-mu-one-slope-spatial-drac-module-list-packet-contract.md`

Pre-existing modified runner files and AGENTS/CLAUDE files were not edited for
this tranche.

## 5. Checks Run

- `bash -n docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche109-spatial-drac-module-list-packet-contract/t109-module-list-guard-snippet.sh` passed.
- TSV width scan passed for the T109 sidecar, next-campaign queue, and member
  discussions.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py` passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"` passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py` passed and reported 10 T109 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'Sys.setenv(OMP_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1",MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'` passed with `DONE`.
- Support-cell invariant scan reported `104 96 8 0 0 0 0`.
- `node --check /tmp/drmtmb-mission-control-index-r303.js` passed.
- `curl -fsS http://127.0.0.1:49716/version.txt` reported `r303`.
- After-task structure checker passed for this report.
- `git diff --check` passed.
- `tools/codex-checkpoint.R` wrote
  `docs/dev-log/recovery-checkpoints/2026-07-03-025027-codex-checkpoint.md`
  with Tranche 110 as the next gate.

## 6. Tests of the Tests

The validator now fails if Mission Control omits the T109 sidecar, if the
sidecar has the wrong row count or fields, if a T109 row claims denominator,
coverage, promotion, or support-cell movement, or if the T109 snippet contains
an executable `module list -t` command.

The focused test now reads the T109 sidecar, verifies the corrected plain
module-list snippet, checks the unchanged support cell, checks the live queue
T110 gate, and checks Rose/Fisher/Gauss/Noether/Grace blocking member rows.

## 7a. Issue Ledger

- Fixed: T108 identified that `module list -t` was interpreted as a match
  filter. T109 banks the corrected contract using plain `module list`.
- Deferred: no executable host proof has been run. T110 must checkpoint first
  and may only prove module-list/executable availability.
- Deferred: package install, package load, model fit, retained denominator,
  coverage, top-up, and support-cell movement remain unauthorized.

## 8. Consistency Audit

Rose audit: T109 is no-compute packet contract evidence only. It is not
module-load success, not loaded-`r/4.4.0` proof, not R/Rscript proof, not
dependency-install success, not package-load success, not fit evidence, not
denominator evidence, not admission evidence, not coverage evidence, not
`inference_ready`, not `supported`, not a tier claim, and not public support.

The support-cell invariant remains unchanged at `104 96 8 0 0 0 0`. The q1
`mu` one-slope spatial row remains `point_fit/planned/planned`, and no q4
coverage or support boundary moved.

## 9. What Did Not Go Smoothly

The validator and test surfaces are now large enough that small text changes can
miss one live-queue assertion. A scan caught one multiline expectation still
pointing at T109, and it was updated to the checkpointed T110 gate.

## 10. Known Residuals

T110 is still required before any renewed allocation evidence exists. T109 does
not prove that DRAC loads `r/4.4.0`, that `R` or `Rscript` exist after module
load, that package dependencies install, that `drmTMB` loads, or that any model
fits.

The worktree also contains pre-existing modified files outside this tranche,
including protected runner files under user review; those were left untouched.

## 11. Team Learning

For route failures, bank the cheapest falsifiable contract before rerunning.
Here the honest next unit is not "try the smoke again"; it is "prove the module
list and executable guards with one no-model allocation, then stop."
