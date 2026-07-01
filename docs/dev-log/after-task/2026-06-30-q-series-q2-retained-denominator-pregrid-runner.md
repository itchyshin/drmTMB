# After Task: Q-Series q2 retained-denominator pregrid runner

## Goal

Move the Tranche 2 q2 retained-denominator gate from design-only to executable SR150 pregrid dispatch, without promoting any Q-Series support cell.

## Implemented

Added `tools/run-structured-re-q2-retained-denominator-pregrid.R`, a guarded wrapper that reads `structured-re-q2-retained-denominator-design.tsv`, requires exactly 17 ready targets plus one repair-held target, and runs only `--n-rep=150` artifact-only pregrid work on Nibi/Rorqual SLURM.

Added `tools/slurm/q2-retained-denominator-pregrid-nibi.sbatch`, a five-shard Nibi array: four q2-intercept provider shards and one q2-plus-q2 shard for the five ready phylo targets. Updated `tools/run-structured-re-q2-plus-q2-intercept-smoke.R` so pregrid wrappers can pass a direct-target `--contract-ids` subset while the exact n=5 substitute smoke still requires all six targets.

## Mathematical Contract

This slice does not change likelihoods, estimands, or interval definitions. It preserves the existing target split: q2 intercept direct SD and direct-correlation targets remain separate, q2-plus-q2 sigma-side targets do not inherit the location-axis bias+t default, and the q2-plus-q2 `cor_sigma1_sigma2` target remains held for profile repair.

## Files Changed

- `tools/run-structured-re-q2-retained-denominator-pregrid.R`
- `tools/run-structured-re-q2-plus-q2-intercept-smoke.R`
- `tools/slurm/q2-retained-denominator-pregrid-nibi.sbatch`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-q-series-q2-retained-denominator-pregrid-runner.md`

## Checks Run

- `ssh -o BatchMode=yes -o ConnectTimeout=8 nibi hostname`: reached `l5.nibi.sharcnet`.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 rorqual hostname`: reached `rorqual2`.
- q2-plus local filter probe with `n_rep=1`, five ready `--contract-ids`, `profile-max-eval=12`: passed and wrote exactly five summary rows; the repair-held `q2_plus_q2_intercept_phylo_cor_sigma1_sigma2` target was excluded.
- Staged a Nibi source snapshot at `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q2-retained-pregrid-77b634eda91b-codex`, submitted job array `16987720`, then canceled it while still pending because Nibi reported `(ReqNodeNotAvail, Reserved for maintenance)`.
- Staged a Rorqual source snapshot at `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q2-retained-pregrid-77b634eda91b-codex-rorqual` and submitted job array `14966341`; at handoff it was pending with reason `(Priority)` and had not produced runner logs yet.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse(file=...)'` for the new wrapper, q2-plus smoke runner, and focused test file: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `bash -n tools/slurm/q2-retained-denominator-pregrid-nibi.sbatch`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 9698 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## Tests Of The Tests

The focused test now executes dry-run mode for both q2 pregrid families. It checks that q2 intercept selects three targets for one provider, q2-plus-q2 selects exactly five ready phylo targets, the inner host label is sanitized for the older smoke-runner guard, the q2-plus command includes `--contract-ids`, and the repair-held sigma1/sigma2 correlation target is absent.

## Consistency Audit

Mission control now statically checks the pregrid wrapper, q2-plus target-filter guard, and five-shard Nibi sbatch. The q2 retained-denominator design still has 18 target rows, 17 ready targets, one repair-held target, and linked support cells at `point_fit/planned/planned`.

## GitHub Issue Maintenance

No GitHub issue was opened or closed. This is an internal Tranche 2 dispatch-pack slice and no public claim changed.

## What Did Not Go Smoothly

The q2-plus smoke runner still accepted the older pre-Nibi contract-status vocabulary. The first local filter probe failed until `nibi_substitute_smoke_reviewed_profile_hold` was added to the allowed contract states. The first focused test also exposed a repo-root fallback bug when the wrapper was invoked from `tests/testthat` under a path containing a space; the wrapper now walks fallback candidates up to the package root.

## Team Learning

Pregrid wrappers should validate host and design contracts themselves, then pass neutral inner host labels to older smoke runners whose Nibi/Rorqual labels mean exact n=5 substitute smoke. That avoids accidental reuse of a smoke guard as a pregrid policy.

## Known Limitations

This submits the SR150 array only as an external Rorqual campaign; it does not import denominator evidence. It does not change `interval_status`, `coverage_status`, `inference_ready`, `supported`, q2 slope, q4/q8, non-Gaussian interval, REML, AI-REML, bridge support, or public support wording.

## Next Actions

Monitor Rorqual job array `14966341`, inspect install and runner logs as soon as shards start, then import the reviewed artifacts through a new summary sidecar only after all five shards finish and Fisher/Rose/Grace review the retained-denominator evidence.
