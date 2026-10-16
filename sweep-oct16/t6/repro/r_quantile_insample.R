# drmTMB: on fitted rows of a (1 | g) fit, predict(type = "quantile"), exceedance() and residuals(type = "quantile")
# use mu = X beta + b-hat[g] (conditional on the random-effect modes), but ?predict.drmTMB and ?exceedance say they are
# evaluated "at predict_parameters()'s fixed-effect, population-level parameter estimates", and ?residuals.drmTMB says
# quantile residuals are "at the fitted, fixed-effect distributional parameters" / "conditional on the fixed-effect prediction".
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a (R 4.3.3); DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (not used).
# Data: sweep-oct16/t6/data/gaussian_ri.csv, cells.csv seed 20261016601 (R seed 261016601), committed at
# https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
suppressPackageStartupMessages(library(drmTMB))
d <- read.csv("https://raw.githubusercontent.com/itchyshin/drmTMB/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data/gaussian_ri.csv")
fit <- drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x), family = gaussian(), data = d)
mu_pop  <- predict(fit, newdata = d, dpar = "mu")   # documented population-level X beta
mu_cond <- predict(fit, dpar = "mu")                # documented fitted-row X beta + b-hat[g]
sig     <- predict(fit, dpar = "sigma")             # no sigma random effect: same either way
q50 <- predict(fit, type = "quantile", prob = 0.5)[, 1]
ex  <- exceedance(fit, threshold = 1)
rq  <- residuals(fit, type = "quantile")
rbind(  # docs imply column "vs_population" = 0; observed: "vs_conditional" = 0
  quantile   = c(vs_population = max(abs(q50 - mu_pop)), vs_conditional = max(abs(q50 - mu_cond))),
  exceedance = c(max(abs(ex - pnorm(1, mu_pop, sig, lower.tail = FALSE))), max(abs(ex - pnorm(1, mu_cond, sig, lower.tail = FALSE)))),
  quant_resid = c(max(abs(rq - (d$y - mu_pop) / sig)), max(abs(rq - (d$y - mu_cond) / sig))))
# observed: quantile 1.04 / 0, exceedance 0.48 / 1e-16, quant_resid 2.34 / 5e-15 (1.04 = max |b-hat|)
max(abs(predict(fit, newdata = d, type = "quantile", prob = 0.5)[, 1] - mu_pop))  # 0: with newdata it is population-level
