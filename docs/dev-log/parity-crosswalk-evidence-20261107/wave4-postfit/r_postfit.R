# Native drmTMB 0.8.1: labelled animal(1 + x | p | g) q2 with coefficient SD formulas, from A and from Ainv, for
# Poisson, NB2, Gamma and Gaussian; plus the ordinary unlabelled (1 + x | g) Poisson / NB2 fit on the wave-3 data.
# For each fit writes per-row: y, conditional mu (predict), sigma, PIT bounds lo = F(y-), hi = F(y) from
# fitted_distribution(), and the package's quantile residual r (drm_quantile_residuals, seed 1).
# Usage: DRMTMB_LIB=<lib> Rscript r_postfit.R   (run from this directory)
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
dir.create("out", showWarnings = FALSE)
summ <- NULL
dump_fit <- function(tag, fit, y, discrete) {
  mu <- as.numeric(predict(fit, dpar = "mu"))
  sg <- tryCatch(as.numeric(predict(fit, dpar = "sigma")), error = function(e) rep(NA_real_, length(y)))
  fd <- fitted_distribution(fit)
  hi <- as.numeric(fd$p(y)); lo <- if (discrete) as.numeric(fd$p(y - 1)) else hi
  r <- as.numeric(drmTMB:::drm_quantile_residuals(fit, seed = 1))
  write.csv(data.frame(row = seq_along(y), y = y, mu = mu, sigma = sg, lo = lo, hi = hi, r = r),
            sprintf("out/r_%s.csv", tag), row.names = FALSE)
  write.csv(data.frame(name = names(fit$opt$par), est = unname(fit$opt$par)), sprintf("out/rcoef_%s.csv", tag), row.names = FALSE)
  data.frame(tag = tag, ll = as.numeric(logLik(fit)), conv = fit$opt$convergence, sd_r = sd(r))
}
d <- read.csv("data/data.csv"); d$g <- factor(d$g, levels = unique(d$g))
A <- as.matrix(read.csv("data/A.csv", header = FALSE)); dimnames(A) <- list(levels(d$g), levels(d$g))
Ainv <- solve(A); dimnames(Ainv) <- dimnames(A)
s0 <- sd(g, dpar = "mu", level = "animal", coef = "(Intercept)") ~ w1
s1 <- sd(g, dpar = "mu", level = "animal", coef = "x") ~ w2
for (spec in list(c("poisson", "y_cnt", TRUE), c("nb2", "y_nb2", TRUE), c("gamma", "y_gamma", FALSE), c("gaussian", "y_gauss", FALSE))) {
  fam <- spec[1]; resp <- spec[2]; disc <- as.logical(spec[3])
  for (inp in c("A", "Ainv")) {
    trm <- sprintf("animal(1 + x | p | g, %s = %s)", inp, inp)
    f <- as.formula(paste(resp, "~ x +", trm))
    fm <- if (fam == "poisson") bf(f, s0, s1) else bf(f, sigma ~ 1, s0, s1)
    fa <- switch(fam, poisson = stats::poisson(), nb2 = nbinom2(), gamma = Gamma(link = "log"), gaussian = gaussian())
    fit <- drmTMB(fm, family = fa, data = d)
    summ <- rbind(summ, dump_fit(sprintf("%s_%s", fam, inp), fit, d[[resp]], disc))
  }
}
# ordinary unlabelled (1 + x | g), Poisson / NB2, wave-3 data (seed 2026110801)
d3 <- read.csv("data/wave3_data_2026110801.csv"); d3$g <- factor(d3$g)
t0 <- sd(g, dpar = "mu", coef = "(Intercept)") ~ z0; t1 <- sd(g, dpar = "mu", coef = "x") ~ z1
for (fn in c("poisson", "nb2")) {
  resp <- if (fn == "poisson") "yp" else "yn"
  f <- as.formula(paste(resp, "~ x + (1 + x | g)"))
  fm <- if (fn == "poisson") bf(f, t0, t1) else bf(f, sigma ~ 1, t0, t1)
  fit <- drmTMB(fm, family = if (fn == "poisson") stats::poisson() else nbinom2(), data = d3)
  summ <- rbind(summ, dump_fit(sprintf("ordinary_%s", fn), fit, d3[[resp]], TRUE))
}
write.csv(summ, "out/r_summary.csv", row.names = FALSE); print(summ)
