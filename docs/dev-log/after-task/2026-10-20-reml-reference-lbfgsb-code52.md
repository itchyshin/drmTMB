# Arc 1a REML reference fit no longer ends on L-BFGS-B code 52

## 1. Goal

Stop `test-reml-structured-location.R` failing on Linux with
`reference$convergence` equal to 52 (issue #1592). The failing side is the
independent reference fit in `arc1a_reml_reference()`, not the drmTMB fit.

## 2. Implemented

The reference fit still starts with `stats::optim(method = "L-BFGS-B")`. When
that returns a non-zero code, it is polished from where it stopped with
`stats::nlminb()` under the same bounds. The polished result is used only if its
objective is no worse than the L-BFGS-B value, so the reference cannot move away
from the restricted-likelihood optimum.

## 3a. Decisions and Rejected Alternatives

Reproduced by switching the container to OpenBLAS with
`OPENBLAS_NUM_THREADS=1`: the spatial one-slope fixture then returns code 52,
while the objective (118.416415197) and the SDs match the passing runs. So the
optimum is right and only the line search ends abnormally. The drmTMB
expectations were not loosened and no assertion was dropped. Tighter `factr`
or `pgtol` were not tried: they would not change how the line search ends.

## 4. Files Touched

`tests/testthat/test-reml-structured-location.R` only (reference helper and one
new test). No package code.

## 5. Checks Run

Single-threaded OpenBLAS, R 4.3.3: the new test fails before the change (code 52,
spatial one_slope) and passes after (12 expectations). The whole file passes with
`NOT_CRAN=true`, including the TMB-versus-reference comparisons. With four BLAS
threads and with the reference BLAS the reference fit returned code 0 before and
after.

## 6. Tests of the Tests

The new test is not gated by `skip_fragile_recovery()` and does not fit a TMB
model, so it runs on CI.

## 7a. Issue Ledger

Closes #1592.
