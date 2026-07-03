# After Task: Q-Series Tranches 106-107 q1 mu one-slope spatial DRAC module-route install-load terminal review

## 1. Goal

Run exactly one allocation-safe no-model Rorqual module-route/install-load proof
from the Tranche 105 packet contract, then bank the terminal review without
promoting the q1 `mu` one-slope spatial support cell or authorizing coverage.

## 2. Implemented

Tranche 106 staged and submitted one Rorqual sbatch packet,
`q1-mu-slope-spatial-t106-module-route-install-load-proof.sbatch`, from the
reviewed T105 route. The packet loaded `StdEnv/2023` and `r/4.4.0`, recorded
module state, and was designed to stop before package install unless the loaded
module list contained `r/4.4.0` and both `R` and `Rscript` were available.

Tranche 107 fetched the terminal artifacts for that same job only. Job
`15103184` allocated on `rc32522` and failed with Slurm exit `127:0` after
`00:00:02`. The module-load command returned exit 0, but the loaded-module guard
failed because `module-list-after-r-load.txt` did not contain `r/4.4.0`. The
remote artifact says `module list -t` was interpreted as a match/filter request:
`Currently Loaded Modules Matching: -t; None found.`

Mission Control build `r301` now renders the T106 submission-pending and T107
terminal-review sidecars.

## 3a. Decisions and Rejected Alternatives

No model was run. The target identity remains exactly `sd_mu_intercept` and
`sd_mu_x` for the q1 `mu` one-slope spatial row. T106/T107 change no formula,
estimand, direct-SD target, profile target, likelihood, REML/AI-REML claim, or
coverage denominator.

T107 is a route failure taxonomy, not numerical evidence. It rejects treating
this as R/Rscript success, dependency-install success, package-load success, fit
evidence, pdHess evidence, Wald/profile interval evidence, retained-denominator
evidence, admission evidence, coverage evidence, support-cell movement, public
support, or denominator pooling.

The next gate is Tranche 108 only: a no-compute module-list syntax/route review
from the T107 artifacts before any repeat allocation. Inspect whether DRAC wants
`module -t list` or plain `module list` instead of `module list -t`.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche106-spatial-drac-module-route-install-load-submission-pending.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche107-spatial-drac-module-route-install-load-terminal-review.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche106-spatial-drac-module-route-install-load-proof/`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

No public API, formula grammar, `R/`, `src/`, pkgdown reference, README, NEWS,
support-cell status, or user-reviewed runner file changed.

## 5. Checks Run

- TSV width scan: T106 and T107 sidecars each have 10 lines including header and
  45 columns; queue rows have 14 columns; member rows have 12 columns.
- `bash -n docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche106-spatial-drac-module-route-install-load-proof/q1-mu-slope-spatial-t106-module-route-install-load-proof.sbatch`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed and reported 9 T106 rows and 9 T107 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'Sys.setenv(OMP_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1", MKL_NUM_THREADS = "1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`:
  passed with `DONE`.
- Support-cell invariant scan reported `104 96 8 0 0 0 0` for total rows,
  structured rows, interval+coverage `inference_ready` rows, structured
  `supported` rows, high-q `inference_ready` rows, non-Gaussian
  `inference_ready` rows, and q4 coverage-authorized rows.
- Extracted dashboard JavaScript and ran
  `node --check /tmp/drmtmb-mission-control-index-r301.js`; passed.
- Served Mission Control at `http://127.0.0.1:49716/` reports `r301`, serves
  both T106 and T107 sidecars with 10 lines each, and contains the
  `Mu T106 pending`, `Mu T107 terminal`, T106/T107 sidecar paths, T106/T107
  loaders, and `const BUILD = "r301"` markers.
- In-app browser was navigated to `http://127.0.0.1:49716/` and verified the
  page title `drmTMB mission control`, T106/T107 visible markers, and script
  build marker `r301`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-03-q-series-tranches106-107-q1-mu-one-slope-spatial-drac-module-route-install-load-terminal-review.md')"`:
  passed with `after-task structure check passed`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/codex-checkpoint.R --goal "Q-Series T106-T107 q1 mu one-slope spatial DRAC module-route/install-load terminal review" --next "Open Tranche 108 only as no-compute module-list syntax/route review from T107 artifacts; inspect module -t list/plain module list versus module list -t; no repeat sbatch/salloc/allocation, package install, R CMD INSTALL, library(drmTMB), smoke runner, model formula, fit, retained denominator, coverage, top-up, support-cell status edit, inference_ready, supported, REML, AI-REML, or denominator pooling"`:
  wrote
  `docs/dev-log/recovery-checkpoints/2026-07-03-020456-codex-checkpoint.md`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused conversion-contract tests now check the T106 submission-pending
sidecar, T107 terminal-review sidecar, job identity `15103184`, observed host
`rc32522`, failed loaded-module guard, unchanged support cell, active T108
queue gate, and SC445 member-board rows. They would fail if T106/T107 were
misread as dependency-install success, package-load success, fit evidence,
denominator evidence, coverage authorization, or support-cell status movement.

## 7a. Issue Ledger

No GitHub issue action was taken. This tranche only banks local dashboard,
validator, review, and terminal-artifact evidence inside the ongoing Q-Series
campaign.

## 8. Consistency Audit

Rose audit: T107 is a terminal route-failure review of one existing T106
Rorqual job. It is not module-list syntax resolution, not R/Rscript success, not
dependency-install success, not package-load success, not fit evidence, not
pdHess evidence, not Wald/profile interval evidence, not retained-denominator
evidence, not admission evidence, not coverage evidence, not support-cell status
evidence, not `inference_ready`, not `supported`, not public support, not REML,
not AI-REML, and not denominator pooling permission.

Fisher keeps zero retained denominators and zero interval or coverage
observations. Gauss classifies the failure before numerical diagnostics.
Noether keeps direct-SD target identity unchanged. Grace keeps the source/run
root and host provenance separate and requires a no-compute T108 route review
before any repeat allocation.

## 9. What Did Not Go Smoothly

The packet used `module list -t` as the loaded-module capture route. On this
Rorqual environment the captured output instead reported modules matching `-t`,
so the guard could not see `r/4.4.0` even though the module-load command returned
0. This is a route syntax problem to inspect in T108, not a model failure.

The old `8765` Mission Control server was still serving build `r299`, so the
fresh build was served separately at `http://127.0.0.1:49716/`.

## 10. Known Residuals

T106/T107 do not show that `R`, `Rscript`, dependency install, `R CMD INSTALL`,
or `library(drmTMB)` can succeed on Rorqual. They do not run a smoke runner,
create a retained denominator, authorize coverage, or move the q1 `mu`
one-slope spatial row beyond `point_fit/planned/planned`.

Next action: open Tranche 108 as a no-compute module-list syntax/route review
from T107 artifacts only. Do not submit another sbatch job, start `salloc`, run
package install, run `R CMD INSTALL`, call `library(drmTMB)`, run a smoke
runner, fit a model, create a retained denominator, run coverage, top up, edit
support-cell statuses, claim `inference_ready`, claim `supported`, claim public
support, claim REML or AI-REML, or pool denominators before T108 is reviewed.

## 11. Team Learning

Module-route proofs need to validate both the module-load command and the
module-list capture syntax. A load command can return 0 while the provenance
guard reads the wrong list, so the cheapest honest next step is a no-compute
syntax review.
