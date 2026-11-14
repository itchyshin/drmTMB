# Which ordinary (non-structured) correlated-slope shapes does native drmTMB fit with SD formulas?
.libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths())); suppressMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
set.seed(1); G <- 60; nr <- 14
g <- factor(rep(sprintf("g%02d", 1:G), each = nr)); x <- rep(seq(-1.2, 1.2, length.out = nr), G)
z0 <- rep(rep(c(-1, 1), G/2), each = nr); z1 <- rep(round(seq(-1, 1, length.out = G), 6)[sample.int(G)], each = nr)
n0 <- rnorm(G); n1 <- rnorm(G); rho <- 0.5
u0 <- n0; u1 <- rho*n0 + sqrt(1-rho^2)*n1
gi <- as.integer(g)
b0 <- exp(log(.5) + .3*z0[!duplicated(gi)])[gi]*u0[gi]
b1 <- exp(log(.3) - .3*z1[!duplicated(gi)])[gi]*u1[gi]
eta <- .3 + .4*x + b0 + x*b1
d <- data.frame(g = g, x = x, z0 = z0, z1 = z1, yp = rpois(G*nr, exp(eta)),
                yn = rnbinom(G*nr, mu = exp(eta), size = 1/0.6^2))
s0 <- sd(g, level = "iid", dpar = "mu", coef = "(Intercept)") ~ z0
try1 <- function(lbl, fm, fam) { r <- tryCatch(drmTMB(fm, family = fam, data = d), error = function(e) e)
  cat(lbl, ":", if (inherits(r, "error")) paste("REFUSES:", gsub("\\s+", " ", conditionMessage(r))) else sprintf("ll=%.6f conv=%d", as.numeric(logLik(r)), r$opt$convergence), "\n"); invisible(r) }
for (lab in c("labelled", "plain")) {
  term <- if (lab == "labelled") "(1 + x | p | g)" else "(1 + x | g)"
  for (fn in c("poisson", "nb2")) {
    f <- as.formula(paste(if (fn == "poisson") "yp" else "yn", "~ x +", term))
    for (sdv in c("variants")) {
      a0 <- sd(g, dpar = "mu", coef = "(Intercept)") ~ z0
    }
    for (spec in list(c("iid","0"), c("<none>","0"))) {}
    fam <- if (fn == "poisson") poisson() else nbinom2()
    for (lv in c(NA)) {
      s0 <- as.formula(if (is.na(lv)) 'sd(g, dpar = "mu", coef = "(Intercept)") ~ z0' else sprintf('sd(g, level = "%s", dpar = "mu", coef = "(Intercept)") ~ z0', lv))
      s1 <- as.formula(if (is.na(lv)) 'sd(g, dpar = "mu", coef = "x") ~ z1' else sprintf('sd(g, level = "%s", dpar = "mu", coef = "x") ~ z1', lv))
      fm <- if (fn == "poisson") bf(f, s0, s1) else bf(f, sigma ~ 1, s0, s1)
      try1(sprintf("%s %s level=%s", fn, lab, lv), fm, fam)
    }
    fm <- if (fn == "poisson") bf(f) else bf(f, sigma ~ 1)
    try1(sprintf("%s %s const-SD", fn, lab), fm, fam)
  }
}
