# t6 candidate repro: predict(type = "quantile") in-sample on a (1 | g) fit is
# CONDITIONAL on the fitted random-intercept modes, while ?predict.drmTMB,
# ?exceedance and the R/distributional-outputs.R header say the quantiles are
# evaluated "at predict_parameters()'s fixed-effect, population-level parameter
# estimates". drmTMB pin ca3ddefa5ea11bbfd3b765615dfbb89305d2485a.
suppressPackageStartupMessages(library(drmTMB))
d <- read.csv("/home/user/drmTMB/sweep-oct16/t6/data/gaussian_ri.csv", stringsAsFactors = FALSE)
fit <- drmTMB(bf(y ~ x + f + (1 | g), sigma ~ x), family = gaussian(), data = d)
q <- predict(fit, type = "quantile", prob = 0.5)[, 1]
b <- fit$coefficients$mu
eta_pop <- b[["(Intercept)"]] + b[["x"]] * d$x + b[["fb"]] * (d$f == "b") + b[["fc"]] * (d$f == "c")
bhat <- fit$random_effects$mu$values[paste0("(1 | g):", d$g)]
cat("max |q50 - population mu|   =", max(abs(q - eta_pop)), "\n")          # ~1.04 (= max |bhat|)
cat("max |q50 - (mu + bhat[g])|  =", max(abs(q - (eta_pop + bhat))), "\n") # 0
cat("max |bhat|                  =", max(abs(bhat)), "\n")
# exceedance() (same fitted_distribution() route; ?exceedance makes the same
# "fixed-effect, population-level" claim)
s <- exp(fit$coefficients$sigma[["(Intercept)"]] + fit$coefficients$sigma[["x"]] * d$x)
ex <- exceedance(fit, threshold = 1)
cat("max |exceedance - (1 - pnorm(1, mu_pop, s))|        =", max(abs(ex - (1 - pnorm(1, eta_pop, s)))), "\n")
cat("max |exceedance - (1 - pnorm(1, mu_pop + bhat, s))| =", max(abs(ex - (1 - pnorm(1, eta_pop + bhat, s)))), "\n")
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n"); print(sessionInfo()$R.version$version.string)
