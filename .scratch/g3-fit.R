suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student", quiet = TRUE))
simulate_biv_student_truth <- function(n, beta1, beta2, sigma1, sigma2, nu, rho12) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  shared_scale <- sqrt(nu / stats::rchisq(n, df = nu))
  data.frame(x = x,
             y1 = beta1[[1L]] + beta1[[2L]] * x + sigma1 * z1 * shared_scale,
             y2 = beta2[[1L]] + beta2[[2L]] * x + sigma2 * z2 * shared_scale)
}
f <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1)
set.seed(6401)
dat <- simulate_biv_student_truth(120, c(0.2, 0.45), c(-0.3, -0.25), 0.55, 0.85, 7, 0.35)

cat("=== engine = julia, FULL formula ===\n")
j <- tryCatch(drmTMB(f, family = biv_student(), data = dat, engine = "julia"),
              error = function(e) e)
if (inherits(j, "condition")) { cat("JULIA_ERROR:\n", paste(conditionMessage(j), collapse="\n"), "\n") } else {
  cat("JULIA_FIT_OK logLik =", sprintf("%.10f", as.numeric(logLik(j))), "\n")
  print(coef(j))
}
cat("\n=== engine = tmb, same call ===\n")
t <- drmTMB(f, family = biv_student(), data = dat)
cat("TMB_FIT_OK logLik =", sprintf("%.10f", as.numeric(logLik(t))), "\n")
print(coef(t))

cat("\n=== engine = julia, SHORT formula (mu1/mu2 only; defaulted labels) ===\n")
fs <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x)
js <- tryCatch(drmTMB(fs, family = biv_student(), data = dat, engine = "julia"),
               error = function(e) e)
if (inherits(js, "condition")) { cat("SHORT_JULIA_ERROR:\n", paste(conditionMessage(js), collapse="\n"), "\n") } else {
  cat("SHORT_JULIA_OK logLik =", sprintf("%.10f", as.numeric(logLik(js))), "\n")
}
