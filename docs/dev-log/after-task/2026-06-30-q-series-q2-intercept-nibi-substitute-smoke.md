# After Task: Q-Series q2 Intercept Nibi Substitute Smoke

## 1. Goal

Import the exact Nibi `n=5` substitute-host smoke for the 12 Gaussian q2
intercept direct-SD and direct-correlation targets under
`structured-re-q-series-smoke-substitution-contract.tsv`, without promoting any
linked support cell or starting denominator work.

## 2. Implemented

This promotes exactly no Q-Series row under a Nibi/Rorqual substitute-host smoke
channel with all attempted target rows retained. The new evidence shows that all
12 q2 intercept target summaries passed the tiny smoke on Nibi, with 5/5 fit,
convergence, `pdHess`, Wald-finite, and profile-finite replicates per target.

## 3a. Decisions and Rejected Alternatives

The smoke exercises the existing q2 intercept contract only: for each of phylo,
spatial, animal, and relmat, it keeps separate targets for
`sd_mu1_intercept`, `sd_mu2_intercept`, and `cor_mu1_mu2_intercept`. The direct
correlation target stays profile-gated; the result is not coverage evidence and
does not change the interval or coverage denominator rules.

Rejected alternatives: do not promote any q2 intercept cell from this n=5
artifact, do not treat Nibi/Rorqual substitute smoke as denominator evidence,
do not infer q2 slope, q2-plus-q2, q4/q8, or non-Gaussian status from this run,
and do not call the result `supported`.

## 4. Files Touched

- Added `docs/dev-log/dashboard/structured-re-q2-intercept-nibi-smoke.tsv`.
- Fetched artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-30-q2-intercept-smoke-nibi-r44/`.
- Updated `docs/dev-log/dashboard/index.html` with a `Q2 intercept Nibi n5`
  card, table, per-row evidence link, and per-row smoke summary.
- Updated `tools/validate-mission-control.py` with schema, artifact, SLURM
  provenance, seed-manifest, local-state, source-manifest, and no-promotion
  checks for the new sidecar.
- Updated `tests/testthat/test-structured-re-conversion-contracts.R` with
  focused sidecar, artifact, replicate, seed, and no-promotion checks.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/dev-log/check-log.md`, and `docs/dev-log/dashboard/version.txt`.

## 5. Checks Run

- Nibi SLURM job `16974191`: `COMPLETED`, exit code `0:0`.
- Artifact result: 12/12 target summaries passed; 60/60 raw target-replicate
  rows were fit-ok, converged, `pdHess` true, Wald finite, and profile finite;
  20 seed-manifest rows retained seeds `823001` through `823005` for all four
  providers.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 12 q2 intercept Nibi smoke rows.
- Extracted the dashboard `<script>` block and ran `node --check`: passed.
- `git diff --check -- tools/validate-mission-control.py
  tests/testthat/test-structured-re-conversion-contracts.R
  docs/dev-log/dashboard/index.html docs/dev-log/dashboard/README.md
  docs/dev-log/dashboard/structured-re-q2-intercept-nibi-smoke.tsv
  docs/dev-log/simulation-artifacts/2026-06-30-q2-intercept-smoke-nibi-r44`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  8821 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 6. Tests of the Tests

The focused test reads both the dashboard sidecar and the fetched artifact TSVs,
then normalizes only local artifact-path fields before comparing them. It also
checks the raw replicate denominator, seed manifest, SLURM host fields, and that
the linked q2 intercept support cells remain `point_fit/planned/planned`.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on in this slice. The work is
recorded in the local dashboard, check log, and after-task report; this is an
evidence import under the existing Q-Series campaign rather than a new public
support claim.

## 8. Consistency Audit

The dashboard sidecar mirrors the fetched artifact summary after normalizing
`artifact_dir`, `evidence_url`, `metadata_dir`, and `log_dir` to local paths.
The validator checks the raw replicate TSV, seed manifest, session info, exact
command, R 4.4.0 module list, run status, source-provenance metadata, source
SHA manifest, local git-state metadata, install logs, smoke logs, scheduler
stdout, and `seff` file presence.

Stale-wording scans run:

```sh
rg -n "q2 intercept|q2_intercept|Q2 intercept|q2-intercept|Nibi n5|substitute-host smoke|inference_ready|supported" docs/dev-log/dashboard/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-30-q-series-q2-intercept-nibi-substitute-smoke.md docs/dev-log/dashboard/index.html docs/dev-log/dashboard/structured-re-q2-intercept-nibi-smoke.tsv tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
rg -n "q2 intercept.*(inference_ready|supported)|q2_intercept.*(inference_ready|supported)|q2-intercept.*(inference_ready|supported)|supported.*q2 intercept|inference_ready.*q2 intercept" README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The hits were claim-boundary text, tests that forbid promotion, or historical
artifacts; no current q2 intercept `inference_ready` or `supported` promotion
was added.

## 9. What Did Not Go Smoothly

The first Nibi attempt used an R module bundle that resolved to R 4.5.0, so it
was canceled before import. The final run used `module load StdEnv/2023
gcc/12.3 r/4.4.0`. Totoro and FIIA were not reachable from this shell, and
Rorqual lacked the project R library dependencies, so Nibi was the wise
substitute host under the existing smoke-substitution contract.

## 10. Known Residuals

This is smoke evidence, not denominator or coverage evidence. It does not claim
`interval_status`, `coverage_status`, `inference_ready`, `supported`, q2 slope,
q2-plus-q2, q4/q8, non-Gaussian intervals, REML, AI-REML, bridge support, DRAC
denominator evidence, or public support. Fisher/Rose still need to review the
artifact before any denominator grid is planned.

Run Fisher/Rose review on the q2 intercept Nibi substitute-host artifact. If
accepted, decide whether the next bounded step is a denominator pregrid for q2
intercepts or another smoke-only tranche; do not promote any row from this
artifact alone.

## 11. Team Learning

Grace's audit was right to require real SLURM runtime proof instead of a
label-only host flag. The runner now requires `SLURM_CLUSTER_NAME` and
`SLURM_JOB_ID` for substitute-host mode, and the imported artifact retains the
local-state and source-manifest metadata needed to audit a dirty snapshot.
