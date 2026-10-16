# t6 P9 reference values from drmTMB at pin ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
# Prints predict(newdata = nd_main) link/response for the dpars whose
# cross-engine response values differ (student nu, skew_normal nu,
# zero_one_beta mu, lognormal mu) and the cumulative_logit mu predictions that
# DRModels.jl refuses. Pair with julia/repro/jl_p9_response_semantics.jl.
suppressPackageStartupMessages(library(drmTMB))
D <- "/home/user/drmTMB/sweep-oct16/t6/data"
nd <- read.csv(file.path(D, "nd_main.csv"), stringsAsFactors = FALSE)
show <- function(fit, dp) {
  l <- predict(fit, newdata = nd, dpar = dp, type = "link")
  r <- predict(fit, newdata = nd, dpar = dp, type = "response")
  cat(sprintf("  %-5s link[1:3] = %s | response[1:3] = %s\n", dp,
    paste(format(l[1:3], digits = 12), collapse = ", "), paste(format(r[1:3], digits = 12), collapse = ", ")))
}
d <- read.csv(file.path(D, "student_fixed.csv"), stringsAsFactors = FALSE)
fit <- drmTMB(bf(y ~ x + f, sigma ~ x, nu ~ 1), family = student(), data = d)
cat("student_fixed: coef nu =", format(fit$coefficients$nu, digits = 12), "; 2 + exp(coef) =", format(2 + exp(fit$coefficients$nu), digits = 12), "\n")
show(fit, "nu")
d <- read.csv(file.path(D, "skew_normal_fixed.csv"), stringsAsFactors = FALSE)
fit <- drmTMB(bf(y ~ x + f, sigma ~ x, nu ~ 1), family = skew_normal(), data = d)
cat("skew_normal_fixed: coef nu =", format(fit$coefficients$nu, digits = 12), "\n")
show(fit, "nu")
d <- read.csv(file.path(D, "zero_one_beta_fixed.csv"), stringsAsFactors = FALSE)
fit <- drmTMB(bf(y ~ x + f, sigma ~ x, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = d)
cat("zero_one_beta_fixed:\n"); show(fit, "mu")
d <- read.csv(file.path(D, "lognormal_fixed.csv"), stringsAsFactors = FALSE)
fit <- drmTMB(bf(y ~ x + f, sigma ~ x), family = lognormal(), data = d)
cat("lognormal_fixed:\n"); show(fit, "mu")
d <- read.csv(file.path(D, "cumulative_logit_fixed.csv"), stringsAsFactors = FALSE)
d$y <- ordered(d$y)
fit <- drmTMB(bf(y ~ x + f), family = cumulative_logit(), data = d)
cat("cumulative_logit_fixed: cutpoints =", format(fit$ordinal$cutpoints, digits = 12), "\n"); show(fit, "mu")
print(sessionInfo())
