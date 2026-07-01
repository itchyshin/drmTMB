# After Task: Q-Series q2 animal correlation pregrid

## 1. Goal

Run a retained-denominator fixed-8 animal q2 correlation pregrid and expose the
result in the Q-Series widget without promoting the linked support cell.

## 2. Implemented

This promotes exactly no q-series row under the `fixed8_wald_endpoint_profile`
pregrid channel with 150 retained animal correlation replicates and does not
claim animal q2, coverage readiness, interval readiness, `inference_ready`,
`supported`, q4/q8, REML, AI-REML, bridge support, or public support.

The pregrid result is negative: the route is executable and intervals are
finite, but coverage is low and upper-tail misses dominate. The linked animal
q2 row remains `interval_status = planned` and `coverage_status = planned`.

## 3a. Decisions and Rejected Alternatives

Decision: bank the result as a blocker sidecar rather than top up immediately.
At SR150, Wald coverage is 0.8800 and endpoint-profile coverage is 0.8867,
with MCSE still above 0.01 and one retained convergence/boundary flag.

Rejected alternatives:

- Do not treat 150 finite intervals as interval readiness.
- Do not top up blindly before diagnosing the upper-tail miss pattern.
- Do not combine this animal fixed-8 result with spatial g=32 evidence.
- Do not promote animal q2 or any neighbouring q4/q8 row.

## 3b. Mathematical Contract

The target is `cor:animal:cor(mu1:x,mu2:x | p | id)` in the fixed 8-pedigree
animal q2 model. The truth is 0.20. The run retains the full denominator:
fit errors, convergence failures, non-positive-definite Hessians, boundary
flags, and non-finite intervals would be recorded rather than silently removed.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-animal-correlation-pregrid-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-row-gate-synthesis.tsv`
- `docs/dev-log/dashboard/structured-re-q2-animal-correlation-holdout-diagnostic.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-pregrid-local/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
unset GSWEEP_N_GROUPS
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q2-slope-coverage-grid.R --holdout=animal_cor --n_rep=150 --seed_start=733101 --n_each=20 --bootstrap=0 --out_dir=docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-pregrid-local
air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
```

Results: 150/150 fits, 149/150 convergence, 150/150 `pdHess`, 1 retained
boundary/convergence flag at seed 733197, 150/150 finite Wald intervals, and
150/150 finite endpoint-profile intervals. Wald coverage was 132/150 = 0.8800
with lower/upper misses 4/14. Profile coverage was 133/150 = 0.8867 with
lower/upper misses 4/13. Mission control passed and counted 1 q2 animal
correlation pregrid result row. The focused structured-RE conversion contract
test passed with 6689 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 6. Tests of the Tests

The focused test checks the exact pregrid row, artifact paths, full denominator
counts, boundary seed, finite interval counts, coverage, MCSE, lower/upper
misses, linked planned/planned status, `do_not_promote`, and forbidden-claim
wording. It also checks that the animal q2 row-gate points to the pregrid
blocker rather than the older five-replicate holdout.

## 7a. Issue Ledger

No GitHub issue action was taken. This was a local Q-Series evidence-board and
mission-control update.

## 8. Consistency Audit

The Q-Series widget now shows the animal q2 pregrid as a separate top-of-board
blocker. The animal q2 support cell remains planned/planned. The row-gate says
the animal correlation target is measured at SR150 but blocked by low coverage,
upper-tail miss imbalance, and boundary seed 733197. The dashboard build is
`r100`.

## 9. What Did Not Go Smoothly

The run itself completed cleanly. The result is scientifically awkward in the
useful way: the endpoint-profile route is finite, but finite intervals do not
rescue coverage. This means the next step should diagnose interval shape rather
than simply increasing replicate count.

## 10. Known Residuals

Animal q2 remains blocked. The animal `mu2:x` SD endpoint still has upper-tail
miss imbalance, and the animal correlation pregrid now shows the same kind of
upper-tail pressure. No q2 animal interval, coverage, `inference_ready`, or
`supported` claim is justified.

## 11. Team Learning

For q2 animal, the blocker has moved from "can the correlation profile run?" to
"why are finite intervals missing on the upper side?" That is a better problem:
it is now a calibration/shape question rather than an execution-path question.

## 12. Next Actions

Diagnose the fixed-8 animal q2 correlation upper-tail misses and the boundary
seed 733197. Then decide whether a skew-aware interval, stronger profile route,
or another calibrated channel is worth testing before any SR475/SR1000 top-up.
