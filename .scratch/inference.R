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
show <- function(tag, expr) {
  r <- tryCatch(eval(expr), error = function(e) e)
  cat(sprintf("%-34s : %s\n", tag,
    if (inherits(r, "condition")) paste("REFUSED:", gsub("\\s+", " ", paste(conditionMessage(r), collapse = " ")))
    else paste("RETURNED", class(r)[1], if (is.matrix(r) || is.data.frame(r)) paste0("nrow=", nrow(r)) else paste0("len=", length(r)))))
}
show("tmb   confint()",            quote(confint(ft)))
show("julia confint()",            quote(confint(fj)))
show("tmb   profile()",            quote(profile(ft)))
show("julia profile()",            quote(profile(fj)))
show("tmb   predict_parameters(ci)", quote(predict_parameters(ft, interval = "confidence")))
show("julia predict_parameters(ci)", quote(predict_parameters(fj, interval = "confidence")))
show("tmb   profile_targets()",     quote(profile_targets(ft)))
show("julia profile_targets()",     quote(profile_targets(fj)))
cat("\n--- summary print (julia) ---\n"); print(summary(fj))
