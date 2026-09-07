suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-fam-biv-student", quiet = TRUE))
sim <- function(n, nu = 7, rho12 = 0.35) {
  x <- seq(-1, 1, length.out = n); z1 <- rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * rnorm(n); s <- sqrt(nu / rchisq(n, df = nu))
  data.frame(x = x, y1 = 0.2 + 0.45 * x + 0.55 * z1 * s, y2 = -0.3 - 0.25 * x + 0.85 * z2 * s)
}
set.seed(6401); dat <- sim(200); dat$z <- rnorm(nrow(dat)); dat$g <- factor(rep(1:20, each = 10))
probe <- function(label, f, ...) {
  cat("\n@@@@ ", label, "\n")
  for (eng in c("tmb", "julia")) {
    r <- tryCatch(drmTMB(f, family = biv_student(), data = dat, engine = eng, ...), error = function(e) e)
    cat("  ", eng, ": ", if (inherits(r, "condition")) paste("REFUSED:", gsub("\\s+", " ", paste(conditionMessage(r), collapse = " ")))
        else sprintf("FITTED logLik=%.8f npar=%d", as.numeric(logLik(r)), length(unlist(fixef(r)))), "\n", sep = "")
  }
}
base <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1)
probe("J. baseline (control)", base)
probe("K. stray univariate `sigma = ~ z` alongside mu1/mu2",
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma = ~ z, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1))
probe("L. offset() on mu1", bf(mu1 = y1 ~ x + offset(z), mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1))
probe("M. sd(g) scale submodel", bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, nu = ~1, rho12 = ~1, sd(g) ~ 1))
probe("N. sigma1 = ~ (1) redundant parens", bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ (1), sigma2 = ~1, nu = ~1, rho12 = ~1))
probe("O. sigma1 = ~ 0 + z (no intercept)", bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 0 + z, sigma2 = ~1, nu = ~1, rho12 = ~1))
probe("P. omitted sigma1/sigma2/nu/rho12 (short form)", bf(mu1 = y1 ~ x, mu2 = y2 ~ x))
