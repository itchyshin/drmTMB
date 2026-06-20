# Non-Gaussian fixed-effect recovery + Wald calibration (PILOT)

Status: **pilot (50 reps/cell), not yet promotion-grade.** Scale to 500 reps and
re-audit before promoting any matrix cell.

Native R/TMB fixed-effect `mu = b0 + b1*x` recovery + Wald-interval coverage for
the implemented one-response non-Gaussian families. Extends the binomial
approach to characterise the shared "Non-Gaussian models" matrix row.

## Pilot result (50 reps x 2 cells x 6 families = 1,200 fits)

0 fit/confint errors; pdHess rate 1.000 every cell; near-unbiased recovery
(|bias| <= ~0.01) for every family; Wald coverage 0.90-0.98 (centred on 0.95,
the few 0.90 cells are within ~1.5 MCSE at 50 reps). Families: poisson, nbinom2,
Gamma(log), lognormal, beta, student. Elapsed 30.2 s.

See `tables/nongaussian-fe-coverage-summary.csv`.

## Next step (for the resuming session)

Run `Rscript --vanilla run.R 500` (~12-15 min), re-audit (Fisher/Rose). If the
500-rep coverage holds 0.93-0.97 with MCSE ~0.01 across all six families, the
"Non-Gaussian models" matrix **point** cell can be promoted `partial -> covered`
(scoped: fixed-effect mu coefficient recovery for the implemented one-response
families). The **wald** cell may also promote if all families' coverage is
clean; otherwise keep it partial and flag the off families. Random/structured
effects, scale/shape intervals, profile/bootstrap, bivariate/mixed, and the
Julia bridge stay planned regardless.

## Boundary

Native R/TMB, fixed-effect `mu` only, complete data. No recovery/power claim for
random or structured effects; no interval claim beyond fixed-effect mu Wald.
