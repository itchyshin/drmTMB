# Q-Series Tranche 110 q1 mu one-slope spatial DRAC module-list executable proof

## 1. Goal

Run the checkpointed Tranche 110 proof from the T109 contract: one
allocation-safe no-model Rorqual job that proves the corrected plain module-list
route and R/Rscript executables, then stops before package install, package
load, model execution, retained denominator, coverage, or support-cell movement.

## 2. Implemented

Submitted exactly one Rorqual Slurm job, `15104831`, using the T109 packet
contract. The job allocated `rc32601`, completed with exit `0:0`, captured the
raw plain `module list` with `r/4.4.0`, and resolved both `R` and `Rscript` to
R 4.4.0 CVMFS paths.

Mission Control build `r304`, the queue row, member discussions, validator,
focused tests, dashboard README, completion map, and check log now all point to
T110 as a terminal module-list/executable proof and route the next gate to
Tranche 111 no-compute terminal decision review.

## 3a. Decisions and Rejected Alternatives

The economical decision was to stop immediately after the module-list and
executable guards. Package install, `R CMD INSTALL`, `library(drmTMB)`, smoke
runner execution, and any model formula were rejected for T110 because this
tranche was only designed to prove the DRAC module/executable route.

No second T110 job was submitted. The first short polls saw `PENDING`, but a
fresh poll before ledger writing showed the same job had completed; terminal
artifacts were fetched from that job only.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche110-spatial-drac-module-list-executable-terminal-proof.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche110-spatial-drac-module-list-executable-proof/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-q-series-tranche110-q1-mu-one-slope-spatial-drac-module-list-executable-proof.md`

Pre-existing modified runner files and AGENTS/CLAUDE files were not edited for
this tranche.

## 5. Checks Run

- `bash -n docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche110-spatial-drac-module-list-executable-proof/q1-mu-slope-spatial-t110-module-list-executable-proof.sbatch` passed.
- T110 local and remote packet hashes matched
  `59f5d4734f6347db86015c0c00090e833ef8cac7cc7f04cafe0ad6397912095d`.
- Rorqual `sacct` reported job `15104831` as `COMPLETED|0:0|00:00:02|rc32601`.
- Fetched terminal artifacts contain `module_load`, `loaded_module_guard`, and
  `executable_guard` as `passed`; package install, `R CMD INSTALL`, and
  `library_drmTMB` are `not_attempted`; model execution is `not_run`; denominator
  is `not_created`.
- Final validator, focused tests, support invariant, JavaScript syntax check,
  served-version check, after-task checker, `git diff --check`, and checkpoint
  commands are recorded in `docs/dev-log/check-log.md` for this tranche.

## 6. Tests of the Tests

The validator now fails if the T110 sidecar is missing, has the wrong row count
or fields, points at missing artifacts, changes support-cell status, omits the
exact job/allocation evidence, or treats the proof as install, package-load,
fit, retained-denominator, coverage, `inference_ready`, or `supported`
evidence.

The focused test reads the T110 sidecar, fetched module list, R/Rscript probe,
terminal status, queue row, and Rose/Fisher/Gauss/Noether/Grace member rows.

## 7a. Issue Ledger

- Fixed: T109 was an unexecuted packet contract. T110 proves that the corrected
  plain module-list route works on a Rorqual allocation and that R/Rscript are
  available after the guard.
- Deferred: package install, `R CMD INSTALL`, package load, model fit, retained
  denominator, coverage, top-up, and support-cell movement remain unauthorized.
- Deferred: source SHA remains inherited from the accepted staged source path
  because the remote source copy has no Git head.

## 8. Consistency Audit

Rose audit: T110 is module-list/executable proof only. It is not
dependency-install success, not package-load success, not fit evidence, not
denominator evidence, not admission evidence, not coverage evidence, not
`inference_ready`, not `supported`, not a tier claim, and not public support.

The support-cell invariant remains unchanged at `104 96 8 0 0 0 0`. The q1
`mu` one-slope spatial row remains `point_fit/planned/planned`, and no q4
coverage or support boundary moved.

## 9. What Did Not Go Smoothly

The first remote tar command tried to archive the tarball while creating it, so
`tar` returned a file-changed warning. I recreated the archive while excluding
the tarball itself and fetched the terminal artifacts successfully.

## 10. Known Residuals

T111 is required before any package-install/load proof. T110 does not prove
that dependencies install, that `drmTMB` loads, that a smoke runner works, that
any model fits, or that any retained denominator can be counted.

The worktree still contains pre-existing modified files outside this tranche,
including protected runner files under user review; those were left untouched.

## 11. Team Learning

Small proofs should stop as soon as they answer the narrow question. T110
answered only "does the corrected module and executable route work on Rorqual?"
and the next honest unit is a no-compute terminal decision review before any
package-load step.
