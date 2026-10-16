# t6 confirmation of KNOWN drmTMB #1536 at pin ca3ddefa5ea11bbfd3b765615dfbb89305d2485a:
# predict() silently drops unused `...` (se.fit, interval) and simulate() has no
# newdata formal, so simulate(fit, newdata = nd) silently returns training rows.
suppressPackageStartupMessages(library(drmTMB))
d <- read.csv("/home/user/drmTMB/sweep-oct16/t6/data/gaussian_fixed.csv", stringsAsFactors = FALSE)
nd <- read.csv("/home/user/drmTMB/sweep-oct16/t6/data/nd_main.csv", stringsAsFactors = FALSE)
fit <- drmTMB(bf(y ~ x + f, sigma ~ x), family = gaussian(), data = d)
p <- predict(fit, se.fit = TRUE)
cat("predict(se.fit = TRUE): class", class(p), "length", length(p), "identical to predict(fit):", identical(p, predict(fit)), "\n")
pi <- predict(fit, newdata = nd, interval = "confidence")
cat("predict(interval = 'confidence'): identical to plain:", identical(pi, predict(fit, newdata = nd)), "\n")
s <- simulate(fit, nsim = 1, seed = 1, newdata = nd)
cat("simulate(newdata = nd_main [18 rows]): nrow =", nrow(s), "; identical to no-newdata call:",
  identical(s, simulate(fit, nsim = 1, seed = 1)), "\n")
