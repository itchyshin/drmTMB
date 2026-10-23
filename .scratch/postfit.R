suppressMessages(devtools::load_all(".", quiet = TRUE))
sim <- function(n, b1, b2, s1, s2, nu, rho) {
  x <- seq(-1, 1, length.out = n); z1 <- rnorm(n)
  z2 <- rho * z1 + sqrt(1 - rho^2) * rnorm(n); s <- sqrt(nu / rchisq(n, df = nu))
  data.frame(x = x, y1 = b1[1] + b1[2] * x + s1 * z1 * s, y2 = b2[1] + b2[2] * x + s2 * z2 * s)
}
set.seed(6401); d <- sim(400, c(0.2, 0.45), c(-0.3, -0.25), 0.55, 0.85, 7, 0.35)
f <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1)
ft <- drmTMB(f, family = biv_student(), data = d, engine = "tmb")
fj <- drmTMB(f, family = biv_student(), data = d, engine = "julia")
for (nm in c("tmb", "julia")) {
  fit <- if (nm == "tmb") ft else fj
  r <- tryCatch(rho12(fit), error = function(e) e)
  cat("###", nm, "rho12:", if (inherits(r, "condition")) paste("ERR", conditionMessage(r))
      else sprintf("len=%d first=%.10f", length(r), r[1]), "\n")
  for (dp in c("mu1", "sigma1", "nu")) {
    p <- tryCatch(predict(fit, dpar = dp), error = function(e) e)
    cat("    predict", dp, ":", if (inherits(p, "condition")) paste("ERR", gsub("\n", " ", conditionMessage(p)))
        else sprintf("len=%d first=%.8f", length(p), p[1]), "\n")
  }
  s <- tryCatch(capture.output(summary(fit)), error = function(e) paste("ERR", conditionMessage(e)))
  cat("    summary lines:", length(s), "\n")
  cf <- tryCatch(confint(fit), error = function(e) e)
  cat("    confint:", if (inherits(cf, "condition")) paste("ERR", gsub("\n", " ", conditionMessage(cf))) else sprintf("nrow=%d", nrow(cf)), "\n")
}
