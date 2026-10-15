# Follow-up issue draft (filed from the round 5 session)

Refs #1477. Do not close #1477.

## Title

Gamma mi() quadrature: CV >= 3 and strong prior/likelihood conflict

## Body

Refs #1477.

Round 5 on #1513 replaced the Gamma `mi()` Gauss-Hermite rule with five
safeguarded Newton steps plus a 51-node sinh-mapped trapezoid rule on
`u = log(x)`. Against a log-space `integrate()` the per-row logLik error is
now under `1e-4` for a Gaussian response at CV 0.05 to 2 (pole, near the
mode and tail; worst `2.5e-5`) and for a Poisson response at CV 0.2 to 2 at
`y` = 0, 1, 4, 30. The CV 2 pole that was `1.06` is `9e-7`.

Still open:

1. CV `>= 3`. In a random scan (Gaussian response, `mu` in 1..30, CV 3) a
   quarter of the rows exceed `1e-4` (worst `7.8e-3`). Shape is `1/9`, so
   the left tail `exp(u / 9)` needs a wider `t` span than `[-5, 4]`.
2. Poisson response with `exp(eta)` at the prior mean of about `1e3` or
   more (for example `mu = 10`, `beta_x = 1`, `mu_y = -1`, `y = 0`, CV 0.5:
   `4.5e-2`; CV 1.5: `1.5`). Five Newton steps stop short of the mode.
   Twelve steps bring those rows to `3e-7` to `5e-5`, but the five-step
   lock was a reviewer decision, so it needs a decision before changing.
3. Poisson times Gamma `mi()` is not reachable through `drmTMB()` (the
   validator allows only a binary `mi()` predictor for Poisson), so the
   Poisson rows exercise the R mirror, not the compiled Poisson branch.

Reproduce with `tests/testthat/test-mi-quadrature-1476-1477.R` and the
`drm_gamma_mi_reference_loglik()` helper.
