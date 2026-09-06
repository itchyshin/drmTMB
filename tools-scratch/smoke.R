devtools::load_all(".", quiet = TRUE)
mk <- function(with_gradient = TRUE, converged = TRUE,
               gradient = c(0.0002, -0.0005, 0.0001), vcov = diag(c(0.01,0.02,0.03))) {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  result <- list(coef_names = coef_names, coefficients = c(0.5, 1.2, -0.3),
    vcov = vcov, loglik = -20, aic = 46, bic = 49, df = 3L, nobs = 50L,
    converged = converged, fitted = rep(1, 50), residuals = rep(0, 50),
    sigma = rep(0.8, 50), corpairs = list())
  if (with_gradient) { result$gradient <- gradient; result$gradient_names <- coef_names }
  drmTMB:::new_drmTMB_julia(result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ 1), family = gaussian(),
    data = data.frame(y = rep(1, 50), x = rep(1, 50)), family_type = "gaussian")
}
f <- mk()
d <- check_drm(f)
print(d[, c("check","status","value")])
cat("ok=", attr(d, "ok"), "\n")
cat("--- no gradient ---\n")
d2 <- check_drm(mk(with_gradient = FALSE))
print(d2[, c("check","status","value")])
cat("ok=", attr(d2, "ok"), "\n")
cat("--- dead vcov ---\n")
f3 <- mk(vcov = matrix(NaN, 3, 3))
cat("uncertainty status:", f3$uncertainty$status, "\n")
d3 <- check_drm(f3)
print(d3[, c("check","status","value")])
cat("ok=", attr(d3, "ok"), "\n")
cat("--- negative variance ---\n")
d4 <- check_drm(mk(vcov = diag(c(0.01, -0.02, 0.03))))
print(d4[, c("check","status","value")])
cat("ok=", attr(d4, "ok"), "\n")
