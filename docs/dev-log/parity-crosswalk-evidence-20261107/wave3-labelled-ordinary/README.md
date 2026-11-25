# Wave 3: labelled ordinary `(1 + x | p | g)` q2, Poisson and NB2 (R vs Julia)

Julia branch `claude/labelled-ordinary-poisson-nb2-20261108` (DRModels.jl). Native drmTMB 0.8.1.

## What native R does for this shape (`r_probe.R`, `r_probe.log`)

Native drmTMB **refuses the labelled ordinary form** `(1 + x | p | g)` for Poisson and
NB2, with and without SD formulas ("labelled covariance blocks ... remain unsupported",
`validate_poisson_mu_random_terms`). It **fits the unlabelled `(1 + x | g)`** with two
coefficient SD formulas (`sd(g, dpar = "mu", coef = "(Intercept)") ~ z0`, `coef = "x"`
`~ z1`) and one free intercept-slope correlation (`eta_cor_mu`, `0.999999 tanh`). That
is the same model Julia fits for the labelled form (the label `p` is a pure label), so
the comparison is Julia labelled `(1 + x | p | g)` vs R unlabelled `(1 + x | g)`.
`sd(..., level = "iid")` is not accepted by R's `sd()` grammar; omit `level`.

## Agreement at the optimum (`compare.R`, 10 seeds x 2 families, 80 groups x 16 rows)

Parameter order is identical (beta_mu, [beta_sigma], intercept-SD coefficients,
slope-SD coefficients, eta_cor). All 20 fits converge in R (code 0) and Julia.

| family  | max abs param diff | max diff / R se | max abs rho diff | log-lik Julia - R | se ratio (Julia / R), range over seeds |
|---------|--------------------|-----------------|------------------|-------------------|----------|
| poisson | 1.4e-06            | 5.1e-06         | 6.7e-07          | -1.6e-09 to 8.7e-10 | 0.99999733 to 1.0000025 |
| nb2     | 5.2e-06            | 5.7e-06         | 1.0e-06          | -2.6e-10 to 1.1e-09 | 0.99999872 to 1.0004733 (largest: seed 2026110802, 1.0005) |

Fitted rho (R) ranges 0.24-0.75 (Poisson) and 0.29-0.90 (NB2); true rho = 0.5.
This is agreement of two implementations of one likelihood, not a calibration or
coverage claim.

## Files

`make_data.R` (SEED=...), `r_probe.R`, `r_fit.R`, `julia_fit.jl`, `compare.R`,
`data_<seed>.csv`, `r_*`/`julia_*` per-fit tables, `comparison_by_parameter.csv`,
`comparison_summary.csv`. Run order: `make_data.R` per seed, `r_fit.R`
(`DRMTMB_LIB`, `SEEDS`), `julia_fit.jl` (`SEEDS`), `compare.R`.
