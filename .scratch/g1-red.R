# G1 RED: the WORKING native biv_student call (exact shape of
# tests/testthat/test-biv-student.R) refused through engine = "julia".
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
biv_student_test_formula <- function() {
  bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1)
}
set.seed(6401)
dat <- simulate_biv_student_truth(n = 120, beta1 = c(0.2, 0.45), beta2 = c(-0.3, -0.25),
                                  sigma1 = 0.55, sigma2 = 0.85, nu = 7, rho12 = 0.35)

cat("=== SAME CALL, engine = \"tmb\" (control: the call is well formed) ===\n")
tfit <- try(drmTMB(biv_student_test_formula(), family = biv_student(), data = dat), silent = TRUE)
if (inherits(tfit, "try-error")) {
  cat("TMB_FIT_FAILED:", conditionMessage(attr(tfit, "condition")), "\n")
} else {
  cat("TMB_FIT_OK logLik =", sprintf("%.10f", as.numeric(logLik(tfit))), "\n")
  cat("TMB_COEF:\n"); print(coef(tfit))
}

cat("\n=== SAME CALL, engine = \"julia\" (the refusal under test) ===\n")
jfit <- tryCatch(
  drmTMB(biv_student_test_formula(), family = biv_student(), data = dat, engine = "julia"),
  error = function(e) e)
if (inherits(jfit, "condition")) {
  cat("JULIA_REFUSED_VERBATIM:\n")
  cat(paste(conditionMessage(jfit), collapse = "\n"), "\n")
} else {
  cat("JULIA_UNEXPECTEDLY_FITTED\n")
}

cat("\n=== registry: is there a biv_student row on this source? ===\n")
cat("family_tag =", tryCatch(as.character(drm_julia_family_tag("biv_student")),
                             error = function(e) paste("ERROR:", conditionMessage(e))), "\n")
cat("fe families =", paste(drm_julia_registry_families("fe"), collapse = ", "), "\n")
