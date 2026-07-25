# Direct bivariate-lognormal `rho12` uncertainty smoke

This is a non-empty mechanism smoke, not a coverage study or a capability
promotion. It simulates 160 paired positive outcomes from the exact
`biv_lognormal()` model with covariate-adjusted locations, unequal log-scale
standard deviations (0.4 and 0.7), and true residual correlation `rho12 = 0.5`.

The run fits the whole direct model and calls guarded link-scale Wald,
likelihood-profile, and joint parametric-bootstrap intervals. The bootstrap
uses nine retained refits only to prove the full resimulation/refit path; it is
far too small to assess calibration. `summary.csv` records the fitted object
diagnostics and method statuses, while `intervals.rds` retains method output.

Run again from a local installation of this branch with:

```sh
R_LIBS=/private/tmp/drmtmb-arc6-Rlib \
  Rscript --no-init-file inst/sim/run/sim_run_biv_lognormal_rho12_smoke.R
```

The next lane must preserve all attempts and use the predeclared
`n = 100, 300, 1000` by `rho12 = 0, 0.5, 0.85` coverage ladder on Totoro.
