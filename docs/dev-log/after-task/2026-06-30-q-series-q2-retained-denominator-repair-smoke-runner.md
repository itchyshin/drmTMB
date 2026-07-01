# After Task: Q-Series q2 Retained-Denominator Repair-Smoke Runner

## Goal

Turn the five-row q2 retained-denominator repair contract into an executable
dry-run/dispatch wrapper, without promoting any Q-Series support cell.

## Implemented

Added `tools/run-structured-re-q2-retained-denominator-repair-smoke.R`. The
wrapper reads
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-contract.tsv`,
requires the exact five Fisher/Rose/Grace repair-contract cells, maps each
`smoke_seed_range` to the existing runner seed arguments, and writes a command
manifest at
`structured-re-q2-retained-denominator-repair-smoke-command.tsv`.

The q2 intercept cells dispatch to
`tools/run-structured-re-q2-intercept-smoke.R` by provider. The q2-plus-q2 cell
dispatches to `tools/run-structured-re-q2-plus-q2-intercept-smoke.R` with
exactly five direct contract IDs: `mu1`, `mu2`, `cor_mu1_mu2`, `sigma1`, and
`sigma2`. The held `cor_sigma1_sigma2` target and cross-block correlations stay
out of the repair smoke.

## Mathematical Contract

No likelihood, parameterization, estimator, or interval formula changed. This
is executable evidence plumbing only. It prepares a bounded small repair smoke
for the already-declared contract and keeps all output artifact-only by forcing
`--write-dashboard=false`.

## Files Changed

- `tools/run-structured-re-q2-retained-denominator-repair-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-q2-retained-denominator-repair-smoke.R")); invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`
- Dry-run manifest check for `qseries_phylo_q2_mu1_mu2_intercept` and
  `qseries_phylo_q2_plus_q2_intercept`.
- `python3 -m py_compile tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `git diff --check -- tools/run-structured-re-q2-retained-denominator-repair-smoke.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`

Result: `mission_control_ok`; focused test passed 9956 / 0 / 0 / 0.

## Tests Of The Tests

Mission-control now statically checks the repair-smoke wrapper for the repair
contract source, seed-range handling, no-promotion wording, Totoro cleanup
gate, Trillium source/root gate, and q2-plus direct-target exclusion. The
focused R test executes a dry run, reads the generated manifest, checks all five
repair cells, verifies seed bases `920000` through `924000`, confirms
`--write-dashboard=false`, and confirms the q2-plus manifest excludes
`q2_plus_q2_intercept_phylo_cor_sigma1_sigma2`.

## Consistency Audit

No support-cell status changed. The wrapper is a dispatch gate only. It does
not import new coverage evidence and does not write dashboard summaries from a
repair smoke.

## What Did Not Go Smoothly

The first ad hoc dry-run reader failed because the manifest path was not passed
into the check process environment. The wrapper itself had already written the
manifest; rerunning the check with the manifest path fixed the verification.

## Team Learning

Grace/Rose rule: repair compute should be one command-manifest layer away from
the status table. The command manifest makes seed ranges, host labels, and
excluded targets reviewable before any Totoro or DRAC cores are spent.

## Known Limitations

This promotes exactly no Q-Series row. No actual repair smoke was launched in
this slice. The existing SR150 evidence still blocks promotion for the five q2
retained-denominator cells until Fisher/Rose/Grace accept a repaired interval
route or a follow-up diagnostic result. Totoro was observed under heavy load
earlier in the session, and Trillium is reachable but still needs a synced
qseries run/source root before use.

## Next Actions

Run the repair-smoke wrapper only after deciding what interval repair or
diagnostic change is being evaluated. Use Totoro only when load and cleanup are
acceptable, or use one DRAC host with synced source/root artifacts. Keep the
result artifact-only until Fisher/Rose/Grace review the raw replicates,
per-target summaries, seed manifest, run log, `sessionInfo.txt`, `git-sha.txt`,
module list, scheduler logs, and `seff.txt` where available.
