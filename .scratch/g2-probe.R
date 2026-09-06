# G2: does DRM.jl at pin 430ef64cc actually ROUTE the tag `biv_student` with
# the mu1/mu2/sigma1/sigma2/nu/rho12 keyed vocabulary? Probe drm_bridge direct.
suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student", quiet = TRUE))
simulate_biv_student_truth <- function(n, beta1, beta2, sigma1, sigma2, nu, rho12) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n); z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  sh <- sqrt(nu / stats::rchisq(n, df = nu))
  data.frame(x = x,
             y1 = beta1[[1L]] + beta1[[2L]] * x + sigma1 * z1 * sh,
             y2 = beta2[[1L]] + beta2[[2L]] * x + sigma2 * z2 * sh)
}
set.seed(6401)
dat <- simulate_biv_student_truth(120, c(0.2, 0.45), c(-0.3, -0.25), 0.55, 0.85, 7, 0.35)

drmTMB:::drm_julia_setup()
jform <- list(mu1 = "y1 ~ x", mu2 = "y2 ~ x", sigma1 = "sigma1 ~ 1",
              sigma2 = "sigma2 ~ 1", nu = "nu ~ 1", rho12 = "rho12 ~ 1")
res <- tryCatch(
  JuliaCall::julia_call("drmTMB_drm_bridge", jform, "biv_student", as.list(dat), NULL, NULL),
  error = function(e) e
)
if (inherits(res, "error")) {
  cat("DRM.jl DID NOT ROUTE. verbatim:\n"); cat(conditionMessage(res), "\n")
} else {
  cat("DRM.jl ROUTES the tag.\n")
  cat("coef_names: ", paste(as.character(res$coef_names), collapse = " | "), "\n", sep = "")
  cat("coefficients: ", paste(sprintf("%.10f", unlist(res$coefficients)), collapse = " | "), "\n", sep = "")
  cat("loglik: ", sprintf("%.10f", res$loglik), "\n", sep = "")
  cat("estim_method: ", paste(as.character(res$estim_method), collapse = ","), "\n", sep = "")
  cat("nobs: ", as.character(res$nobs), "  df: ", as.character(res$df), "\n", sep = "")
  cat("names(result): ", paste(names(res), collapse = ", "), "\n", sep = "")
}
