# Native R drmTMB fits of the ordinary correlated slope with coefficient SD formulas.
# Native refuses the LABELLED form `(1 + x | p | g)`, so R fits the unlabelled
# `(1 + x | g)`, which is the same model (free intercept-slope correlation).
# Usage: SEEDS="2026110801 ..." DRMTMB_LIB=<lib> Rscript r_fit.R
if (nzchar(Sys.getenv("DRMTMB_LIB"))) .libPaths(c(Sys.getenv("DRMTMB_LIB"), .libPaths()))
suppressMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
seeds <- strsplit(Sys.getenv("SEEDS", "2026110801"), " ")[[1]]
lls <- NULL
for (sd_ in seeds) {
  d <- read.csv(sprintf("data_%s.csv", sd_)); d$g <- factor(d$g)
  for (fn in c("poisson", "nb2")) {
    resp <- if (fn == "poisson") "yp" else "yn"
    f <- as.formula(paste(resp, "~ x + (1 + x | g)"))
    s0 <- sd(g, dpar = "mu", coef = "(Intercept)") ~ z0
    s1 <- sd(g, dpar = "mu", coef = "x") ~ z1
    fm <- if (fn == "poisson") bf(f, s0, s1) else bf(f, sigma ~ 1, s0, s1)
    fam <- if (fn == "poisson") stats::poisson() else nbinom2()
    t0 <- Sys.time(); fit <- tryCatch(drmTMB(fm, family = fam, data = d), error = function(e) e)
    if (inherits(fit, "error")) {
      cat(sd_, fn, "R REFUSES:", gsub("\\s+", " ", conditionMessage(fit)), "\n")
      lls <- rbind(lls, data.frame(seed = sd_, family = fn, ll = NA_character_, convergence = NA_integer_, secs = NA_real_))
      next
    }
    el <- as.numeric(Sys.time() - t0, units = "secs")
    par <- fit$opt$par; se <- tryCatch(sqrt(diag(fit$sdr$cov.fixed)), error = function(e) rep(NA_real_, length(par)))
    cat(sd_, fn, sprintf("ll=%.10f conv=%d t=%.1fs npar=%d\n", as.numeric(logLik(fit)), fit$opt$convergence, el, length(par)))
    if (sd_ == seeds[1]) cat("  names:", paste(names(par), collapse = ", "), "\n")
    write.csv(data.frame(name = names(par), est = unname(par), se = unname(se)),
              sprintf("r_%s_%s.csv", fn, sd_), row.names = FALSE)
    lls <- rbind(lls, data.frame(seed = sd_, family = fn, ll = sprintf("%.12f", as.numeric(logLik(fit))),
                                 convergence = fit$opt$convergence, secs = el))
  }
}
write.csv(lls, "r_ll.csv", row.names = FALSE)
