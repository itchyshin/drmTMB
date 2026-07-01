# After Task: Q-Series q2 Repair Sidecar And NotebookLM Issue Parking

## 1. Goal

Add a diagnostic-only repair-sidecar hook for q2 retained-denominator smokes,
preserve current dashboard truth, and park useful NotebookLM scout leads in
GitHub issues without changing any Q-Series status.

## 2. Implemented

The q2 intercept and q2-plus-q2 smoke runners now accept
`--interval-repair-channel`, with
`bounded_tmbprofile_direct_correlation_sidecar` as the only non-`none` channel.
The sidecar attempts a bounded TMB profile interval only for
`direct_correlation` targets and records its result separately from the primary
Wald/profile evidence.

The wrapper, dispatch summarizer, review summarizer, mission-control validator,
and focused conversion tests now carry the sidecar fields:
`interval_repair_channel`, attempted and finite repair counts, repair coverage
smoke summaries, repair MCSE, repair lower/upper misses, and a
`repair_sidecar_signal`. Existing artifacts without those fields import as
`interval_repair_channel=none`.

Regenerating the current review from the existing Totoro smoke preserved the
negative decision. The five q2 repair-smoke review rows remain no-promotion
rows, and `qseries_phylo_q2_mu1_mu2_intercept` keeps the direct-SD endpoint
route blocker as its row-state authority.

I then ran one tiny local plumbing smoke for the new sidecar:
`phylo`, `cor_mu1_mu2_intercept`, `n_rep=2`, bootstrap off. The run wrote only
local artifacts, did not update dashboard status, and produced 2/2 finite
sidecar intervals.

I also read the NotebookLM notebook titled `Fast & Accurate Algorithms for
Mixed & Latent-Variable Model Fitting (HSquared * DRM * GLLVM)` as a scout
source and parked the useful future-method leads:

- drmTMB#687 for q2 retained-denominator DDF repair sidecars.
- drmTMB#686 for non-Gaussian PQL/AIRWLS warm-start and soft-penalty ideas.
- A scout comment on drmTMB#555 for high-q sparse-Hessian and selected-inversion
  leads.

## 3a. Decisions and Rejected Alternatives

I rejected changing public `confint()` behavior or support-cell status from the
sidecar plumbing. The channel is diagnostic-only until Fisher, Rose, and Grace
accept a row-specific route and evidence.

I rejected treating NotebookLM as evidence. It is useful for finding possible
methods, but every method lead needs primary-source verification before it
changes code, docs, intervals, or Q-Series status.

I also rejected overwriting the special phylo q2 intercept row with generic
retained-denominator repair evidence. That row's current blocker is the direct
SD endpoint-route failure, so the generator now preserves
`structured-re-q2-direct-sd-endpoint-route-smoke.tsv` as its row-state
evidence.

## 4. Files Touched

- `tools/run-structured-re-q2-intercept-smoke.R`
- `tools/run-structured-re-q2-plus-q2-intercept-smoke.R`
- `tools/run-structured-re-q2-retained-denominator-repair-smoke.R`
- `tools/summarize-structured-re-q2-retained-denominator-repair-smoke.R`
- `tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local/git-sha.txt`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local/sessionInfo.txt`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local/structured-re-q2-intercept-local-smoke-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local/structured-re-q2-intercept-local-smoke-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local/structured-re-q2-intercept-local-smoke.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-q-series-q2-repair-sidecar-and-notebooklm-issues.md`

Several of the q2 runner and dashboard files are untracked in this branch as
part of the ongoing Q-Series arc, so `git diff --name-only` does not show every
path listed above.

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R"))'`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R --dispatch=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv --output=docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv --sync-dashboard=true --overwrite=true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 Q-Series cells and 8 Q-Series inference-evidence summary rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 10234 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q2-intercept-smoke.R --n-rep=2 --seed-start=1 --seed-base=930000 --providers=phylo --estimands=cor_mu1_mu2_intercept --bootstrap=0 --profile-max-eval=30 --interval-repair-channel=bounded_tmbprofile_direct_correlation_sidecar --host-class=local --host-name=codex --output-dir=docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local --overwrite=true --write-dashboard=false`: passed. The local plumbing smoke wrote 1 summary row and 2 replicate rows; repair attempted/finite was 2/2 and repair lower/upper misses were 0/0.

## 6. Tests of the Tests

Mission control first failed after review sync because the generator overwrote
the special phylo q2 intercept row-state evidence with the generic repair-smoke
review source. That failure showed the validator catches stale or wrong
evidence routing for the exact blocker row.

After patching the generator, mission control passed and the focused R test
confirmed the added sidecar fields, default `interval_repair_channel=none`,
review-schema contract, dry-run manifest field, and no-promotion wording.

The local two-replicate sidecar smoke is a positive test of the new columns:
`repair_status=finite`, `repair_conf_status=profile`, finite lower/upper bounds,
and `repair_contains=TRUE` appeared in both replicate rows. This would fail
visibly if the direct-correlation sidecar were not being attempted or recorded.

## 7a. Issue Ledger

- Created drmTMB#687:
  `Methods: q2 retained-denominator DDF repair sidecars, coverage-gated`.
- Created drmTMB#686:
  `Methods: non-Gaussian recovery warm starts and soft penalties, scout note`.
- Added a scout comment to drmTMB#555 for high-q sparse-Hessian and
  selected-inversion ideas.

All three are future-method parking only. They do not authorize Q-Series status
changes.

## 8. Consistency Audit

I checked open issues before filing new ones. Existing drmTMB#682 already covers
profile-likelihood CI doctrine, drmTMB#680 covers small-sample CI calibration,
drmTMB#555 covers the Ayumi/q4 harness, and drmTMB#496 covers the GVA engine.
The new issues were limited to leads not already represented clearly: q2 DDF
sidecars and non-Gaussian recovery warm starts or soft penalties.

The current dashboard rows preserve `point_fit/planned/planned` for the five q2
repair cells. The support-cell, Gaussian low-q audit, and row-selection rows for
`qseries_phylo_q2_mu1_mu2_intercept` now again point at
`docs/dev-log/dashboard/structured-re-q2-direct-sd-endpoint-route-smoke.tsv`.

The sidecar plumbing smoke stayed out of dashboard status. It wrote only under
`docs/dev-log/simulation-artifacts/2026-06-30-q2-direct-correlation-repair-sidecar-local/`
and did not change the q2 repair-smoke review decision table.

## 9. What Did Not Go Smoothly

The first regeneration briefly replaced the special direct-SD endpoint blocker
with generic retained-denominator repair review evidence. Mission control caught
the mismatch, and I fixed the generator rather than patching the TSV by hand.

The GitHub issue creates ran in parallel, so the non-Gaussian issue received
number #686 and the q2 DDF issue received #687.

## 10. Known Residuals

The new repair sidecar has not been run on fresh smokes yet. Current regenerated
evidence is explicitly `interval_repair_channel=none` and only confirms schema
and dashboard readiness.

The local sidecar smoke is only `n=2` for one phylo direct-correlation target.
It is not coverage evidence, not a retained-denominator review, and not a
top-up gate. A real sidecar evaluation still needs a row-specific smoke design,
source/root checks, and Fisher/Rose/Grace review.

The NotebookLM leads still need primary-source review. In particular,
containment or modified DDF routes, PQL/AIRWLS warm starts, MSPL-style penalties,
and selected-inversion/sparse-solver claims must not be treated as implemented
or validated.

## 11. Team Learning

Parallel issue parking is helpful, but it must stay outside the evidence path.
The durable pattern is: use NotebookLM to find candidate methods, file them as
future-method issues with primary-source verification gates, then let mission
control and row-level evidence decide every Q-Series status change.
