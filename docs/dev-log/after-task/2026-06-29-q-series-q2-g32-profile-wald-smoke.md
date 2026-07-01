# After Task: Q-Series q2 g32 profile/Wald smoke

## 1. Goal

Bank a tiny local g=32 profile/Wald diagnostic for the spatial q2 row without
changing q-series status.

Correction, 2026-06-29: the animal rows from the original smoke were
invalidated after review. The animal design is a fixed 8-pedigree, and the
pre-guard runner recycled group labels when `GSWEEP_N_GROUPS=32`. The dashboard
now records those animal g=32 rows as zero-count invalidated guard rows. The
clean fixed-8 animal correlation smoke is tracked separately in
`structured-re-q2-animal-correlation-holdout-diagnostic.tsv`.

## 2. Implemented

This promotes exactly no q-series row under the `wald;endpoint_profile`
diagnostic channel with one local g=32 smoke replicate for the three spatial
targets and does not claim spatial q2, animal q2, correlation-target
reliability, q4/q8, REML, AI-REML, bridge support, `supported`, or public
support.

Ran the existing q2 coverage-grid runner locally with `GSWEEP_N_GROUPS=32`,
`n_each=8`, `n_rep=1`, and `bootstrap=0` for:

- spatial `mu1:x`
- spatial `mu2:x`
- spatial `mu1:x+mu2:x`

Each valid spatial target had one fit, convergence, `pdHess = TRUE`, no
boundary flag, one finite Wald interval, and one finite endpoint-profile
interval. The animal direct-SD rows that were initially run under
`GSWEEP_N_GROUPS=32` are invalidated and no longer counted as usable evidence.

## 3a. Decisions and Rejected Alternatives

This is an executable smoke and table sync, not a coverage grid. It checks that
the g=32 route can run through the existing profile/Wald machinery for the
currently executable spatial targets.

Rejected alternatives:

- Do not call one replicate coverage evidence.
- Do not infer animal readiness from an invalid g-sweep over a fixed pedigree.
- Do not modify spatial or animal q2 support-cell status.
- Do not broaden into q4/q8 or non-Gaussian rows.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-slope-g32-profile-wald-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-row-gate-synthesis.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-slope-g32-profile-wald-smoke-local/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-g32-profile-wald-smoke.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 GSWEEP_N_GROUPS=32 Rscript --no-init-file tools/run-structured-re-q2-slope-coverage-grid.R --shard=<4..8> --n_rep=1 --seed_start=732001 --n_each=8 --bootstrap=0 --out_dir=docs/dev-log/simulation-artifacts/2026-06-29-q2-slope-g32-profile-wald-smoke-local
/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
git diff --check
```

Results at the time: the original local smoke command ran five shards, but only
the three spatial shards are now treated as valid g=32 evidence. The two animal
direct-SD shard outputs are retained as invalidated audit artifacts. Formatting
passed; Python compilation passed; mission control passed with 6 structured RE
q2 slope g32 profile/Wald smoke rows; the focused structured-RE conversion
contract test passed with 6595 PASS / 0 FAIL / 0 WARN / 0 SKIP; `git diff
--check` passed.

## 6. Tests of the Tests

The validator and focused test now check the six exact smoke rows, the three
valid spatial local summary artifact paths, the three animal zero-count guard
rows, linked planned/planned support-cell status, `do_not_promote` decisions,
and forbidden claim wording.

## 7a. Issue Ledger

No GitHub issue action was taken. This is local Q-Series mission-control
evidence.

## 8. Consistency Audit

The q2 row-gate synthesis now records spatial g=32 smoke as finite for all
three spatial targets. Animal g=32 smoke is recorded as not applicable to the
fixed 8-pedigree, with the invalidated direct-SD artifacts kept for audit.
Spatial and animal q2 support cells remain planned/planned.

## 9. What Did Not Go Smoothly

The original command ran, but review found a data-design mistake for animal:
`GSWEEP_N_GROUPS=32` did not match the fixed 8-pedigree labels. That made the
animal direct-SD smoke unusable as g=32 evidence. The spatial smoke still uses
one replicate per executable target and therefore cannot support coverage or
miss-balance wording.

## 10. Known Residuals

Animal q2 still lacks retained-denominator correlation coverage. Spatial q2
correlation has finite g=32 smoke but still has SR475 undercoverage at g=8.
Spatial and animal `mu2:x` tail balance remains unresolved. A real
retained-denominator spatial g=32 comparison still needs adequate replicates
and Fisher/Rose review; animal needs fixed-8 row-level evidence rather than a
g-sweep claim.

## 11. Team Learning

The existing coverage-grid runner can be reused for g-sweep smoke through
`GSWEEP_N_GROUPS` only for providers whose covariance labels scale with the
requested group count. Fixed-provider designs need explicit guards. The shard
map itself is part of the evidence: excluded targets need explicit rows so a
missing shard is not mistaken for a pass.

## 12. Next Actions

Use the separate fixed-8 animal correlation holdout diagnostic to design the
next retained-denominator animal q2 run, and decide whether the next spatial
compute step is an adequate retained g=32 comparison or a tail-shape diagnostic
for the `mu2:x` endpoints.
