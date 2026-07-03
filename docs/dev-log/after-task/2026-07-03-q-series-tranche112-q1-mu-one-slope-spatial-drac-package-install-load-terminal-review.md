# Q-Series Tranche 112 q1 mu one-slope spatial DRAC package-install/load terminal review

## 1. Goal

Run at most one allocation-safe no-model Rorqual package-install/load proof from
the T110-proved module/executable route, then bank the terminal evidence without
touching model execution, denominators, coverage, or support-cell status.

## 2. Implemented

Added the T112 Mission Control sidecar, Slurm packet, staging/submission logs,
final scheduler evidence, fetched Rorqual artifacts, and local terminal-review
summary. T112 submitted one Slurm job, `15105466`, on allocation host `rc32301`.

The job proved the `r/4.4.0` module route and `R`/`Rscript` executable paths,
then failed during dependency installation before `R CMD INSTALL`.

## 3a. Decisions and Rejected Alternatives

The terminal decision is a hold, not a rerun. The next tranche must be a
no-compute dependency/provenance review because the allocation could not access
the CRAN `PACKAGES` index, `cli` remained unavailable, the installer error
branch called `conditionMessage()` on a logical value, and T112 host provenance
reported `source_sha` as `NA`.

A repeat allocation, model smoke, retained-denominator count, coverage job,
top-up, support-cell status edit, and any inference or support claim were all
rejected for this tranche.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche112-spatial-drac-package-install-load-terminal-review.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche112-spatial-drac-package-install-load-proof/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-03-q-series-tranche112-q1-mu-one-slope-spatial-drac-package-install-load-terminal-review.md`

Pre-existing modified runner files and AGENTS/CLAUDE files were not edited for
this tranche.

## 5. Checks Run

The Slurm packet passed `bash -n`, was staged to Rorqual, submitted once, polled
to terminal state, and fetched back locally. Final scheduler evidence records
`FAILED`, exit `1:0`, elapsed `00:03:04`, node `rc32301`.

Dashboard and package validation checks are recorded in `docs/dev-log/check-log.md`.

## 6. Tests of the Tests

The validator now fails if the T112 sidecar is missing, has the wrong row count
or fields, points at missing artifacts, changes the linked support cell, omits
the failed-install evidence, treats T112 as package-install success or
package-load success, omits the no-model/no-denominator boundary, or allows a
repeat allocation before T113 review.

The focused conversion-contract test reads the T112 sidecar, terminal summary,
remote terminal status, install stderr, unchanged support cell, queue row, and
Rose/Fisher/Gauss/Noether/Grace member-board rows.

## 7a. Issue Ledger

- Fixed: T112 produced a host-separated terminal proof instead of relying on
  local assumptions about Rorqual package install/load behavior.
- Found: CRAN `PACKAGES` was unreachable from the allocation, blocking
  dependency install before `R CMD INSTALL`.
- Found: the installer error branch is brittle when `install.packages()` fails
  without returning a condition object.
- Found: T112 host provenance recorded `source_sha` as `NA`; future route review
  must classify whether source identity is recoverable from the staged snapshot.
- Deferred: package install success, `R CMD INSTALL`, `library(drmTMB)`, model
  fit, retained denominator, coverage, top-up, and support-cell movement remain
  unauthorized.

## 8. Consistency Audit

Rose audit: T112 is a failed package-install/load proof attempt only. It is not
package-install success, not `R CMD INSTALL` success, not `library(drmTMB)`
success, not package-load success, not fit evidence, not denominator evidence,
not admission evidence, not coverage evidence, not `inference_ready`, not
`supported`, not a tier claim, and not public support.

The q1 `mu` one-slope spatial support cell remains
`point_fit/planned/planned`, and no q4 coverage or support boundary moved.

## 9. What Did Not Go Smoothly

The polling helper failed to parse the final `sacct` row, so it waited on a
stale `pending` state after the job had left `squeue`. A direct `sacct` and
`scontrol show job` cross-check resolved the terminal state and those outputs
are saved as local artifacts.

## 10. Known Residuals

Tranche 113 must be no-compute review only. It should classify CRAN access,
dependency-library reuse, installer error handling, `source_sha` provenance, and
source/run-root integrity before any repeat allocation.

The worktree still contains pre-existing modified files outside this tranche,
including protected runner files under user review; those were left untouched.

## 11. Team Learning

A successful module/executable route is not a package-load route. The cheap
proof found the next real blocker without spending model-compute time, which is
exactly the right economy for this stage.
