suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student", quiet = TRUE))
sim <- function(n, beta1, beta2, sigma1, sigma2, nu, rho12) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n); z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  sh <- sqrt(nu / stats::rchisq(n, df = nu))
  data.frame(x = x, z = stats::rnorm(n),
             y1 = beta1[[1L]] + beta1[[2L]] * x + sigma1 * z1 * sh,
             y2 = beta2[[1L]] + beta2[[2L]] * x + sigma2 * z2 * sh)
}
set.seed(6401)
dat <- sim(120, c(0.2, 0.45), c(-0.3, -0.25), 0.55, 0.85, 7, 0.35)
dat$sp <- factor(rep(paste0("s", 1:8), length.out = 120))

cat("\n### CELL D: phylo() on mu1 (8 species)\n")
tr <- ape::compute.brlen(ape::stree(8, type = "balanced"), method = "Grafen")
tr$tip.label <- paste0("s", 1:8)
ph <- bf(mu1 = y1 ~ x + phylo(1 | sp, tree = tr), mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
d_t <- tryCatch(drmTMB(ph, family = biv_student(), data = dat, engine = "tmb"), error = function(e) e)
d_j <- tryCatch(drmTMB(ph, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
cat("tmb:", if (inherits(d_t, "error")) conditionMessage(d_t) else "FITS (!!)", "\n")
cat("julia:", if (inherits(d_j, "error")) conditionMessage(d_j) else "FITS (!!)", "\n")

cat("\n### CELL D2: relmat() on mu1\n")
K <- diag(8); dimnames(K) <- list(paste0("s", 1:8), paste0("s", 1:8))
rm_f <- bf(mu1 = y1 ~ x + relmat(1 | sp, K = K), mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
d2_j <- tryCatch(drmTMB(rm_f, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
cat("julia:", if (inherits(d2_j, "error")) conditionMessage(d2_j) else "FITS (!!)", "\n")

cat("\n### CELL E: sigma1 ~ z (native refuses 'intercept-only'; DRM.jl supports it)\n")
ah <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
e_t <- tryCatch(drmTMB(ah, family = biv_student(), data = dat, engine = "tmb"), error = function(e) e)
e_j <- tryCatch(drmTMB(ah, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
cat("tmb:", if (inherits(e_t, "error")) conditionMessage(e_t) else sprintf("FITS logLik %.6f", as.numeric(logLik(e_t))), "\n")
cat("julia:", if (inherits(e_j, "error")) conditionMessage(e_j) else sprintf("FITS logLik %.10f", as.numeric(logLik(e_j))), "\n")

cat("\n### CELL F: REML = TRUE\n")
full <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
f_j <- tryCatch(drmTMB(full, family = biv_student(), data = dat, engine = "julia", REML = TRUE), error = function(e) e)
cat("julia REML:", if (inherits(f_j, "error")) conditionMessage(f_j) else "FITS (!!)", "\n")

cat("\n### CELL G: weights (native refuses)\n")
g_j <- tryCatch(drmTMB(full, family = biv_student(), data = dat, engine = "julia", weights = rep(1, nrow(dat))), error = function(e) e)
cat("julia weights:", if (inherits(g_j, "error")) conditionMessage(g_j) else "FITS (!!)", "\n")
