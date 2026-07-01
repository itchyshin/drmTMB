# After Task: Q-Series q2 Retained-Denominator Repair Contract

## Goal

Turn the five blocked q2 retained-denominator review decisions into an explicit
small-repair-smoke contract, without promoting any Q-Series support cell.

## Implemented

Added
`tools/summarize-structured-re-q2-retained-denominator-repair-contract.R` and
generated
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-contract.tsv`.
The contract covers exactly:
`qseries_phylo_q2_mu1_mu2_intercept`,
`qseries_spatial_q2_mu1_mu2_intercept`,
`qseries_animal_q2_mu1_mu2_intercept`,
`qseries_relmat_q2_mu1_mu2_intercept`, and
`qseries_phylo_q2_plus_q2_intercept`.

The generator can also sync the dashboard surfaces with
`--sync-dashboard=true`. The support-cell, Gaussian low-q audit, row-selection,
and closure-triage rows now point at the repair contract while keeping all five
support cells at `point_fit/planned/planned`.

## Mathematical Contract

No likelihood, parameterization, estimator, or interval formula changed. This is
a row-level evidence contract only. It records the next permissible diagnostic
smoke, denominator policy, finite-interval policy, one-sided miss policy, host
policy, artifact requirements, and no-promotion boundary.

The four q2 intercept cells have `n_rep=32` repair-smoke contracts with seed
ranges `920001-920032`, `921001-921032`, `922001-922032`, and `923001-923032`.
The phylo q2-plus-q2 cell has `n_rep=16` with seed range `924001-924016`.

## Files Changed

- `tools/summarize-structured-re-q2-retained-denominator-repair-contract.R`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-contract.R --overwrite=true --sync-dashboard=true`
- `python3 -m py_compile tools/validate-mission-control.py`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-q2-retained-denominator-repair-contract.R")); invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`
- Scoped `git diff --check` over the repair summarizer, validator, focused test,
  repair TSV, and synced dashboard TSVs.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
  passed with `mission_control_ok`, including 5 q2 retained-denominator
  repair-contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`
  passed with 9927 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## Tests Of The Tests

The first focused test rerun failed because the row-selection tests still
expected the old pre-contract state: `No Totoro`, `n_rep=5`, the review-decision
evidence URL, and artifact parity for overlaid fields. The updated tests now
check the repair-contract evidence URL, `n_rep=32` or `16`, Totoro's limited
small-smoke role, Trillium's source/root gate, exact seed ranges, and the
no-promotion boundary.

## Consistency Audit

Stale scan:

```sh
rg -n "blocked_no_compute_until_q2_repair_contract|No Totoro|structured-re-q2-retained-denominator-review-decision.tsv" \
  docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv \
  docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv \
  tests/testthat/test-structured-re-conversion-contracts.R \
  tools/validate-mission-control.py \
  tools/summarize-structured-re-q2-retained-denominator-repair-contract.R
```

The old `blocked_no_compute_until_q2_repair_contract` and `No Totoro` live
dashboard wording is gone. The review-decision table remains referenced only as
provenance and validator coverage for the preceding decision layer.

No README, NEWS, formula grammar, likelihood, pkgdown, or vignette change was
needed because this task changed dashboard evidence routing only.

## GitHub Issue Maintenance

Checked overlapping open issues with:

```sh
gh issue list -R itchyshin/drmTMB --search "q2 retained denominator repair" --limit 10 --json number,title,state,url
```

Only issue #59, "Phase 18: comprehensive simulation framework and reporting",
matched. No issue comment was added because this is an internal dashboard
contract slice, not a standalone user-facing issue closeout.

## What Did Not Go Smoothly

The first test update was too narrow. Mission-control passed, but the focused R
test caught stale row-selection artifact expectations and one typed TSV column
that parsed as integer. The correction was to treat `first_smoke_n_rep` and
`claim_boundary` as intentional dashboard overlays and to compare integer smoke
counts in the direct repair-contract test.

## Team Learning

Rose's useful rule here is to distinguish provenance from the live evidence URL.
The review-decision TSV remains part of the evidence chain, but the widget now
uses the repair-contract TSV as the active q2 gate.

Grace's compute rule is also explicit: Totoro is available for small repair
smokes with 50 workers by default and <=100 workers maximum with cleanup, while
Trillium remains blocked until qseries run root and source root are synced.

## Known Limitations

This promotes exactly no Q-Series row. It does not authorize SR475/SR1000
top-up, mixed-host denominators, support-cell status edits, or public support
wording. It does not claim `interval_status`, `coverage_status`,
`inference_ready`, `supported`, q2 slope inheritance, q2-plus inheritance,
q4/q8, non-Gaussian intervals, REML, AI-REML, bridge support, or public
support.

No q2 repair smoke was run in this slice.

## Next Actions

Run one small q2 repair smoke on Totoro or one eligible DRAC host after
source/root checks pass. Preserve raw replicate TSVs, per-target summaries,
seed manifest, run log, `sessionInfo.txt`, `git-sha.txt`, `module-list.txt`,
exact command lines, scheduler logs when SLURM is used, `seff.txt` when
available, and a Totoro cleanup note when Totoro workers are used.
