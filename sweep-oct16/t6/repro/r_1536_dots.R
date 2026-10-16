# drmTMB #1536, executed: predict() drops se.fit/interval/level and simulate() drops newdata, silently.
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a (R 4.3.3); DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7 (not used).
# Data: sweep-oct16/t6/data/gaussian_fixed.csv, cells.csv seed 20261016600 (R seed 261016600), committed at
# https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
suppressPackageStartupMessages(library(drmTMB))
d <- read.csv("https://raw.githubusercontent.com/itchyshin/drmTMB/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data/gaussian_fixed.csv")
fit <- drmTMB(bf(y ~ x + f, sigma ~ x), family = gaussian(), data = d)
nd <- data.frame(x = c(-1, 0, 1.5), f = c("a", "b", "c"))
p <- predict(fit, newdata = nd, dpar = "mu")
p_se <- predict(fit, newdata = nd, dpar = "mu", se.fit = TRUE)
p_ci <- predict(fit, newdata = nd, dpar = "mu", interval = "confidence", level = 0.9)
p_typo <- predict(fit, newdata = nd, dpar = "mu", not_an_arg = 1)
c(se.fit = identical(p_se, p), interval = identical(p_ci, p), typo = identical(p_typo, p))  # all TRUE, no warning; expected: error or SEs
class(p_se); length(p_se)                       # "numeric" 3 (no $se.fit); expected: list with se.fit, or an error
s <- simulate(fit, nsim = 1, seed = 1, newdata = nd)
nrow(s)                                          # 240 (training rows); expected 3 = nrow(nd), or an error
identical(s, simulate(fit, nsim = 1, seed = 1))  # TRUE: newdata ignored
# Contrast: predict_parameters() refuses unused dots and is the supported SE route.
try(predict_parameters(fit, newdata = nd, dpar = "mu", se.fit = TRUE))  # Error: `...` is reserved for future options.
predict_parameters(fit, newdata = nd, dpar = "mu", conf.int = TRUE, conf.level = 0.9, include_newdata = FALSE)[,
  c("estimate", "std.error", "conf.low", "conf.high", "conf.status")]   # Wald SE/CI, conf.status "wald"
