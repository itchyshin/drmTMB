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
dat$id <- factor(rep(letters[1:12], each = 10))

flat <- function(f) { cf <- stats::coef(f); out <- numeric()
  for (nm in names(cf)) out <- c(out, stats::setNames(as.numeric(cf[[nm]]), paste0(nm, ":", names(cf[[nm]])))); out }
se_of <- function(f) { V <- as.matrix(stats::vcov(f)); stats::setNames(sqrt(diag(V)), sub("_", ":", rownames(V), fixed = TRUE)) }

full <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)

cat("\n### CELL A: full explicit formula\n")
ft <- drmTMB(full, family = biv_student(), data = dat, engine = "tmb")
fj <- drmTMB(full, family = biv_student(), data = dat, engine = "julia")
ct <- flat(ft); cj <- flat(fj)[names(flat(ft))]
cat("model_type_julia:", fj$model$model_type, " engine:", fj$engine, " estimator:", fj$estimator,
    " estim_method:", as.character(fj$bridge$estim_method), " converged:", is_converged(fj), " nobs:", nobs(fj), "\n")
cat("public_labels:", paste(fj$bridge_public_coef_labels$public, collapse = " | "), "\n")
cat("label_contract:", fj$bridge_public_coef_labels$contract, "\n")
cat("names match:", setequal(names(ct), names(flat(fj))), "\n")
cat(sprintf("max_abs_coef_diff: %.6e\n", max(abs(ct - cj))))
cat(sprintf("loglik_tmb: %.10f  loglik_julia: %.10f  diff: %.6e\n",
            as.numeric(logLik(ft)), as.numeric(logLik(fj)), abs(as.numeric(logLik(ft)) - as.numeric(logLik(fj)))))
st <- se_of(ft); sj <- se_of(fj)[names(se_of(ft))]
cat("se names match:", setequal(names(st), names(se_of(fj))), "\n")
cat(sprintf("max_abs_se_diff: %.6e  max_rel_se_diff: %.6e\n",
            max(abs(st - sj)), max(abs(st - sj) / pmax(abs(st), abs(sj)))))
print(rbind(tmb = st, julia = sj))

cat("\n### CELL B: dpars omitted -- bf(mu1 = y1 ~ x, mu2 = y2 ~ x)\n")
short <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x)
p <- drmTMB:::drm_julia_bridge_payload(formula = short, family_type = "biv_student", data = dat, env = environment())
cat("payload formula parts:", paste(names(p$formula), unlist(p$formula), sep = "=", collapse = " | "), "\n")
cat("coef_labels keys:", paste(names(p$coef_labels), collapse = ","), "\n")
b_t <- tryCatch(drmTMB(short, family = biv_student(), data = dat, engine = "tmb"), error = function(e) e)
b_j <- tryCatch(drmTMB(short, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
for (nm in c("b_t", "b_j")) { o <- get(nm)
  if (inherits(o, "error")) cat(nm, "ERROR:", conditionMessage(o), "\n") else cat(nm, sprintf("logLik %.10f\n", as.numeric(logLik(o)))) }

cat("\n### CELL C: random-effect bar on mu1 (native refuses)\n")
re <- bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
c_t <- tryCatch(drmTMB(re, family = biv_student(), data = dat, engine = "tmb"), error = function(e) e)
c_j <- tryCatch(drmTMB(re, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
cat("tmb:", if (inherits(c_t, "error")) conditionMessage(c_t) else sprintf("FITS logLik %.6f", as.numeric(logLik(c_t))), "\n")
cat("julia:", if (inherits(c_j, "error")) conditionMessage(c_j) else sprintf("FITS logLik %.6f", as.numeric(logLik(c_j))), "\n")

cat("\n### CELL D: phylo() on mu1\n")
if (requireNamespace("ape", quietly = TRUE)) {
  tr <- ape::compute.brlen(ape::stree(12, type = "balanced"), method = "Grafen")
  tr$tip.label <- levels(dat$id)
  ph <- bf(mu1 = y1 ~ x + phylo(1 | id, tree = tr), mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
  d_j <- tryCatch(drmTMB(ph, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
  cat("julia:", if (inherits(d_j, "error")) conditionMessage(d_j) else "FITS (!!)", "\n")
}

cat("\n### CELL E: sigma1 ~ z (native refuses 'intercept-only'; DRM.jl supports it)\n")
ah <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1)
e_t <- tryCatch(drmTMB(ah, family = biv_student(), data = dat, engine = "tmb"), error = function(e) e)
e_j <- tryCatch(drmTMB(ah, family = biv_student(), data = dat, engine = "julia"), error = function(e) e)
cat("tmb:", if (inherits(e_t, "error")) conditionMessage(e_t) else sprintf("FITS logLik %.6f", as.numeric(logLik(e_t))), "\n")
cat("julia:", if (inherits(e_j, "error")) conditionMessage(e_j) else sprintf("FITS logLik %.10f", as.numeric(logLik(e_j))), "\n")
