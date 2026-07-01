# After Task: Q-Series q2+q2 Nibi Substitute Smoke

## Task Goal

Import the exact Nibi `n=5` substitute-host smoke for the Gaussian phylo
q2-plus-q2 intercept row under
`structured-re-q-series-smoke-substitution-contract.tsv`, without promoting the
linked support cell or starting denominator work.

## Files Created Or Changed

- Added
  `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-nibi-smoke.tsv`.
- Fetched and retained artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-30-q2-plus-q2-intercept-smoke-nibi/`.
- Updated `docs/dev-log/dashboard/index.html` with the `Q2+Q2 Nibi n5` summary
  card/table and q2+q2 evidence-summary text.
- Updated `tools/validate-mission-control.py` with schema, artifact, provenance,
  and boundary-profile checks for the new sidecar.
- Updated `tests/testthat/test-structured-re-conversion-contracts.R` with focused
  sidecar and artifact checks.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/dev-log/check-log.md`, and `docs/dev-log/dashboard/version.txt`.

## Checks Run And Outcomes

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 6 q2-plus-q2 Nibi smoke rows.
- Extracted the dashboard `<script>` block and ran `node --check`: passed.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  8762 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## Consistency Audit

The dashboard sidecar mirrors the fetched artifact summary after normalizing
`artifact_dir` and `evidence_url` to the local artifact directory. The validator
also checks the raw replicate TSV, seed manifest, session info, exact command,
module list, run status, source-provenance metadata, install logs, and smoke
logs.

The q2-plus-q2 support cell remains `point_fit/planned/planned`. The dashboard
keeps fit stability, profile finiteness, inference readiness, interval status,
and coverage status separate.

Stale-wording scans run:

```sh
rg -n "q2\\+q2|q2-plus-q2|q2_plus_q2|Nibi n5|substitute-host smoke|inference_ready|supported" docs/dev-log/dashboard/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-30-q-series-q2-plus-q2-nibi-substitute-smoke.md docs/dev-log/dashboard/index.html docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-nibi-smoke.tsv tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
rg -n "q2\\+q2.*(inference_ready|supported)|q2-plus-q2.*(inference_ready|supported)|q2_plus_q2.*(inference_ready|supported)|supported.*q2\\+q2|inference_ready.*q2\\+q2" README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The hits were claim-boundary text, tests that forbid promotion, or historical
artifacts; no current q2+q2 `inference_ready` or `supported` promotion was added.

## Tests Of The Tests

The focused test reads both the dashboard sidecar and the fetched artifact TSVs,
then normalizes only the local artifact path fields before comparing them. It
also checks that each of the six direct target contracts has five replicate rows
and that exactly one profile failure is retained.

## What Did Not Go Smoothly

The first Nibi run found the synced source tree missing
`docs/dev-log/dashboard/`; the remote source layout was repaired before rerun.
The second run exposed missing `rlang` in the Nibi R library. Installing `rlang`
into the run-local library allowed the final rerun to complete, but the artifact
level `git-sha.txt` still records the non-Git snapshot warning; the authoritative
source SHA is retained in `metadata/git-sha.txt`.

## Team Learning And Process Improvements

The q2-plus-q2 smoke should treat direct correlations as boundary-sensitive even
when point fit, convergence, `pdHess`, and Wald intervals all pass. The widget
now surfaces substitute-host smoke as its own evidence layer so Fisher/Rose can
audit the target-level profile failure before any denominator grid is planned.

## Design-Doc Updates

No formula grammar, likelihood parameterization, or public support tier changed.
The existing smoke-substitution contract remains the governing design boundary.

## Pkgdown And Documentation Updates

Updated the mission-control dashboard README and dashboard widget source only.
No pkgdown articles or reference pages changed.

## GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on in this slice. The work is
recorded in the local dashboard, check log, and after-task report.

## Known Limitations And Next Actions

This is smoke evidence, not denominator or coverage evidence. Five of the six
within-block direct q2-plus-q2 targets passed; the
`q2_plus_q2_intercept_phylo_cor_sigma1_sigma2` target retained one
endpoint-profile root failure at seed `823003` after the run-local `rlang`
install. The linked support cell remains unpromoted, cross-block correlations
remain blocked, and q2-only location support, q4/q8, non-Gaussian rows, REML,
AI-REML, bridge support, `inference_ready`, `supported`, and public support
remain unclaimed.
