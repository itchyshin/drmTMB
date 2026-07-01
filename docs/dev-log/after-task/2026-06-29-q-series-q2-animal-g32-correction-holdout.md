# After Task: Q-Series q2 animal g32 correction and holdout

## 1. Goal

Correct the animal q2 g=32 smoke overclaim and bank a clean fixed-8 animal
correlation holdout diagnostic without promoting any Q-Series row.

## 2. Implemented

This promotes exactly no q-series row under the `fixed8_wald_endpoint_profile`
diagnostic channel with a five-replicate animal correlation holdout and does
not claim animal q2, g=32 animal evidence, coverage, interval readiness,
`inference_ready`, `supported`, q4/q8, REML, AI-REML, bridge support, or public
support.

The q2 coverage-grid runner now builds `x` from the actual provider labels, so
fixed-provider designs such as animal cannot silently recycle labels when
`GSWEEP_N_GROUPS` is larger than the fixed pedigree. It also accepts the
explicit diagnostic route `--holdout=animal_cor`, leaving the normal shard map
unchanged.

The dashboard now separates:

- valid spatial g=32 smoke in `structured-re-q2-slope-g32-profile-wald-smoke.tsv`;
- zero-count invalidated/not-applicable animal rows in that same g=32 sidecar;
- clean fixed-8 animal correlation smoke in
  `structured-re-q2-animal-correlation-holdout-diagnostic.tsv`.

## 3a. Decisions and Rejected Alternatives

Decision: animal q2 is a fixed-8 pedigree diagnostic path, not a g-sweep path.
The runner now guards the data construction by using the actual provider labels
for replicate length, and the dashboard marks earlier animal g=32 outputs as
invalidated audit artifacts.

Rejected alternatives:

- Do not delete the invalidated animal artifacts; keep them documented for
  auditability.
- Do not treat the five-replicate fixed-8 holdout as coverage evidence.
- Do not promote the linked animal q2 support cell.
- Do not make q4/q8, REML, AI-REML, bridge, or public-support claims.

## 3b. Mathematical Contract

The animal q2 design uses a fixed 8-animal additive relationship matrix. It is
not a g-sweep design. The fixed-8 holdout targets
`cor:animal:cor(mu1:x,mu2:x | p | id)` with truth `0.20` and records only
whether Wald and endpoint-profile intervals are finite in a small diagnostic.
It is not a coverage denominator and cannot support miss-balance or interval
readiness claims.

## 4. Files Touched

- `tools/run-structured-re-q2-slope-coverage-grid.R`
- `docs/dev-log/dashboard/structured-re-q2-slope-g32-profile-wald-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-q2-animal-correlation-holdout-diagnostic.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-row-gate-synthesis.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-slope-g32-profile-wald-smoke-local/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-holdout-diagnostic-local/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-g32-profile-wald-smoke.md`

## 5. Checks Run

```sh
unset GSWEEP_N_GROUPS
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q2-slope-coverage-grid.R --holdout=animal_cor --n_rep=5 --seed_start=733001 --n_each=20 --bootstrap=0 --out_dir=docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-holdout-diagnostic-local
air format tools/run-structured-re-q2-slope-coverage-grid.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
git diff --check
rg -n 'five executed target[s]|five executable local g=3[2]|animal g=32 smoke as finit[e]|g32_smoke_animal_sd_target[s]|correlation_holdout_not_ru[n]|holdout_not_run_profile_failure_not_reconcile[d]|animal.*finite g=3[2]' docs/dev-log/dashboard docs/dev-log/after-task docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
```

Results: the animal holdout produced 5/5 fits, 5/5 convergence, 5/5 `pdHess`,
0 boundary flags, 5/5 finite Wald intervals, and 5/5 finite endpoint-profile
intervals. Python compilation passed. Mission control passed with
`mission_control_ok`, including 6 q2 g32 profile/Wald smoke rows and 1 q2
animal correlation holdout diagnostic row. The focused structured-RE conversion
contract test passed with 6633 PASS / 0 FAIL / 0 WARN / 0 SKIP. `git diff
--check` passed. The stale-wording scan returned no matches after the
check-log and after-task correction.

## 6. Tests of the Tests

The focused test first failed because the three animal guard rows were checked
against a scalar zero instead of three zero-count rows. After fixing the test,
it now verifies three executed spatial g=32 rows, three animal zero-count guard
rows, the one fixed-8 animal correlation holdout row, all local artifact paths,
linked planned/planned support-cell state, `do_not_promote` decisions, and
forbidden-claim wording.

## 8. Consistency Audit

The Q-Series support cell remains planned/planned for
`qseries_animal_q2_mu1_mu2_one_slope`. The row-gate synthesis now says the
animal correlation holdout is finite for 5/5 fixed-8 smoke replicates but that
g=32 profile/Wald evidence is not applicable to the fixed pedigree. The g=32
sidecar records no usable animal g=32 evidence. The widget build is `r99`.

## 7a. Issue Ledger

No GitHub issue action was taken. This was a local dashboard, runner, and
mission-control correction inside the Q-Series evidence ledger.

## 9. What Did Not Go Smoothly

The first g=32 smoke over-applied `GSWEEP_N_GROUPS=32` to animal, even though
the runner comment already said animal should not be swept. The Rose lesson is
that comments are not guards. The follow-up holdout route also initially named
files with `NA` because the output stem still used `args$shard`; those
temporary files were removed and the holdout was rerun with a real shard label.

## 11. Team Learning

Fixed-provider covariance designs need executable guards, not just prose. When
a sidecar mixes scalable and fixed-provider rows, the widget should show
not-applicable or invalidated states explicitly rather than hiding them in a
generic holdout bucket.

## 10. Known Residuals

The fixed-8 animal correlation diagnostic is only five-replicate smoke. It does
not provide coverage, MCSE, tail balance, or row-level inference readiness.
Animal `mu2:x` tail imbalance remains unresolved, and animal q2 still needs a
retained-denominator row-level grid before any status change.

## 12. Next Actions

Design the retained-denominator animal q2 correlation grid under the fixed-8
pedigree contract, then decide whether to pair it with an animal `mu2:x`
tail-shape diagnostic before asking Fisher and Rose to review any row-gate
change.
