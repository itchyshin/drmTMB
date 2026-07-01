# Q-Series q1 `mu` SR475 Aggregate

## 1. Task

Aggregate the reviewed Nibi SR150 q1 `mu` intercept pregrid with the completed
Nibi SR325 top-up shards for the four Gaussian low-q direct-SD `mu` intercept
rows, then expose the result as review-pending evidence without changing any
support-cell status.

## 2. Scope

Rows covered:

- `qseries_phylo_q1_mu_intercept`
- `qseries_spatial_q1_mu_intercept`
- `qseries_animal_q1_mu_intercept`
- `qseries_relmat_q1_mu_intercept`

The aggregate covers only q1 `mu:(Intercept)` direct-SD location-axis targets.
It does not cover q1 `sigma`, matched `mu+sigma`, q2, q4/q8, non-Gaussian
rows, REML, AI-REML, bridge support, or public-support claims.

## 3. Implementation

- Imported the completed top-up shard outputs from Nibi into
  `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/`.
- Added `tools/summarize-structured-re-gaussian-lowq-mu-intercept-sr475.R`.
- Wrote
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`.
- Wrote the retained replicate artifact
  `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/structured-re-gaussian-lowq-mu-intercept-sr475-results-replicates.tsv`.
- Updated the Q-Series widget to show the SR475 aggregate as a separate review
  table and per-row evidence link.
- Imported the Nibi per-shard metadata directory and replaced the broken
  result-level `git-sha.txt` mirrors with the intended dirty-source label
  `77b634ed-dirty-q1-mu-topup-r163`.
- Updated mission-control validation and the focused conversion-contract test
  to require the top-up metadata, source manifests, exact commands, run logs,
  and dirty-source labels.

## 4. Run Evidence

Nibi run root:

```text
/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr475-topup-77b634ed-r163
```

The original array job `16978889` completed the phylo, spatial, and animal
shards. The original relmat task failed before the R runner with a CVMFS R
`INSTALL` input/output error; relmat retry job `16979505` completed and was
imported. The dispatch ledger now records the three completed/imported original
shards and the completed/imported relmat retry.

The imported top-up artifact includes per-shard `metadata/shard_*` directories
with exact commands, module lists, run logs, run status, source manifests,
session info, scheduler efficiency output when available, and source provenance.
The run source is recorded as the dirty snapshot label
`77b634ed-dirty-q1-mu-topup-r163`, not as a clean repository SHA.

## 5. Results

| Provider | Retained | Finite intervals | Coverage | MCSE | Lower miss | Upper miss | Review signal |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| phylo | 475 | 475 | 0.9832 | 0.005904 | 4 | 4 | MCSE met, review pending |
| spatial | 475 | 475 | 0.9705 | 0.007760 | 4 | 10 | MCSE met, review pending |
| animal | 475 | 473 | 0.9747 | 0.007200 | 6 | 4 | review required; finite-interval caveat retained |
| relmat | 475 | 475 | 0.9789 | 0.006587 | 3 | 7 | MCSE met, review pending |

All four rows have 475/475 fit success, convergence, `pdHess`, and `confint`
calls. Animal has 473/475 usable intervals, so it is not a clean promotion
candidate from this aggregate alone.

The two animal unusable intervals are retained boundary rows at seeds `812407`
and `812444` (`wald_at_boundary`, `conf.low = 0`, `conf.high = Inf`). They are
not import gaps and should be reviewed as interval-channel blockers.

## 6. Claim Boundary

This promotes exactly no Q-Series row under the SR475 retained-denominator
aggregate with no status-table edit and does not claim q1 `sigma`, matched
`mu+sigma`, q2, q4/q8, non-Gaussian intervals, REML, AI-REML, bridge support,
public support, `inference_ready`, or `supported`.

The linked support cells remain `point_fit/planned/planned`.

## 7. Review Gate

Fisher/Rose/Grace must review retained denominator, convergence, `pdHess`,
finite intervals, warning ledger, lower/upper misses, coverage MCSE, failure
taxonomy, animal's two unusable intervals, and blocked neighbours before any
support-cell status edit.

## 8. Files Changed

- `tools/summarize-structured-re-gaussian-lowq-mu-intercept-sr475.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/metadata/`
- `docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-topup-nibi/results/shard_*/git-sha.txt`

## 9. Validation

Validation is recorded after the focused checks in `docs/dev-log/check-log.md`.
The required checks for this slice are mission control, dashboard script syntax,
focused conversion-contract tests, and `git diff --check` over the touched
files. The post-provenance rerun passed `mission_control_ok` and the focused
`structured-re-conversion-contracts` test with 9335 PASS / 0 FAIL / 0 WARN /
0 SKIP.

## 10. Residual Risk

The aggregate comes from a dirty source snapshot, so it is appropriate as a
review artifact, not as an automatic status promotion. Spatial has more upper
misses than lower misses (10 vs 4), and relmat has upper/lower ratio 2.3333.
Animal retains two `wald_at_boundary` unusable intervals at seeds `812407` and
`812444`. These are review inputs, not hidden successes.

## 11. Next Step

Run Fisher/Rose/Grace review on the SR475 table. If accepted, update only the
exact rows that pass, with a new status edit, validator allow-list update,
focused test update, check-log entry, and after-task report. If animal or any
miss-balance signal is rejected, keep the row at `point_fit/planned/planned` and
write the blocker into the widget.
