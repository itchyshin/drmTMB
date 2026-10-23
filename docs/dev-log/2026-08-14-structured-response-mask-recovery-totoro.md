# Structured response-mask recovery: Totoro receipt

## Scope

This is the approved 300-attempt MCAR recovery campaign for the q1 structured
Gaussian REML response-mask cells: spatial (`mc-0287`), animal (`mc-0299`),
and relmat (`mc-0311`).  It does not assess intervals, coverage, MAR, slopes,
or any other formula cell.

## Execution

The canonical run used the frozen source at `96ec662f`, with the runner-only
diagnostic correction in `f7323969f`, on Totoro at 96 one-thread workers.  The
retained output root is
`/home/snakagaw/hsq_work/drmtmb-response-mask-20260814-totoro-96ec662f/results`.
All 300 task receipts were written: 100 deterministic seeds per provider.

An earlier 300-row output is retained separately as `results-se-false`.  It
set `se = FALSE` while reading `fit$sdr$pdHess`, so it disabled its own Hessian
diagnostic.  It is an instrumentation record only and is not used for any
formula status or recovery conclusion.

## Corrected campaign result

Every corrected fit returned optimizer convergence zero and `pdHess = TRUE`.
The predeclared absolute-recovery rule nevertheless fails, so no G3 promotion
is made:

| Provider | mean abs. intercept error | mean abs. slope error | mean abs. residual-SD error | mean abs. structured-SD error | max structured-SD error |
| --- | ---: | ---: | ---: | ---: | ---: |
| spatial | 0.2988 | 0.0315 | 0.0150 | 0.0732 | 0.3039 |
| animal | 0.2167 | 0.0325 | 0.0148 | 0.1337 | 0.5746 |
| relmat | 0.0796 | 0.0327 | 0.0149 | 0.0396 | 0.1223 |

The gate required mean absolute error no greater than 0.15 for every reported
target and no structured-SD error above 0.35.  Spatial and animal fail the
intercept criterion, and animal also fails the maximum structured-SD criterion.
Those are retained results, not dropped diagnostics.  The three cells remain
`formula_oracle_validated` at G2.

## Next decision

The fixed structured-field DGP has ordinary finite-field variation in the
intercept.  A later, separate design can assess paired masked-versus-complete
response recovery if that is needed for a response-masking claim.  It must not
retroactively replace this failed absolute-truth gate.  This campaign does not
justify rerunning it or changing its thresholds.
