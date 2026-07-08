# S5 (biv extension): does native REML debias the BIVARIATE ordinary sigma-RE
# covariance block vs ML, with replication? Model: mu1,mu2 fixed; sigma1,sigma2 with
# a labelled scale-side block (1|s|id) -> a 2x2 scale-side covariance (SDs + corr).
# Gate drm_validate_reml_spec_biv (~:2049) bypassed to probe.
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(parallel)})
assignInNamespace("drm_validate_reml_spec_biv", function(spec) invisible(TRUE), ns = "drmTMB")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
truth <- c(sd_s1 = 0.4, sd_s2 = 0.35, cor_s = 0.3)
Ss <- chol(matrix(c(.4^2, .3 * .4 * .35, .3 * .4 * .35, .35^2), 2, 2))

sim <- function(n_each, seed) {
  n_id <- 60L; set.seed(seed * 90001L + n_each)
  a <- matrix(rnorm(n_id * 2), n_id, 2) %*% Ss
  id <- rep(seq_len(n_id), each = n_each); n <- n_id * n_each; x <- rnorm(n)
  d <- data.frame(id = factor(id), x = x,
    y1 = 0.3 + 0.5 * x + rnorm(n, 0, exp(log(0.5) + a[id, 1])),
    y2 = 0.6 + 0.2 * x + rnorm(n, 0, exp(log(0.6) + a[id, 2])))
  form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
    sigma1 = ~ 1 + (1 | s | id), sigma2 = ~ 1 + (1 | s | id), rho12 = ~ 1)
  o <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(suppressWarnings(drmTMB(form, biv_gaussian(), d, REML = (est == "REML"),
           control = drm_control(optimizer_preset = "robust"))), error = function(e) NULL)
    if (is.null(f)) return(NULL)
    pr <- summary(f)$parameters; g <- function(rx) unname(pr$estimate[grep(rx, pr$parm)][1])
    o[[est]] <- c(sd_s1 = g("sd:sigma:sigma1"), sd_s2 = g("sd:sigma:sigma2"),
                  cor_s = g("^cor.*id"), pd = isTRUE(f$sdr$pdHess))
  }
  data.frame(n_each = n_each, seed = seed, par = names(truth), truth = truth,
             ml = o$ML[names(truth)], reml = o$REML[names(truth)],
             pd_ml = o$ML[["pd"]], pd_reml = o$REML[["pd"]], row.names = NULL)
}

g <- expand.grid(seed = 1:12, n_each = c(3L, 8L, 15L))
res <- do.call(rbind, mcmapply(sim, g$n_each, g$seed, SIMPLIFY = FALSE, mc.cores = 8))
cat("=== biv sigma-RE recovery (n_id=60, 12 seeds) ===\n")
for (p in names(truth)) for (k in c(3L, 8L, 15L)) {
  s <- res[res$par == p & res$n_each == k, ]; tr <- truth[[p]]
  cat(sprintf("  %-7s n_each=%-2d truth %+.2f : biasML %+.3f biasREML %+.3f\n",
      p, k, tr, mean(s$ml, na.rm = TRUE) - tr, mean(s$reml, na.rm = TRUE) - tr))
}
d1 <- res[res$par == "sd_s1", ]
cat(sprintf("\npdHess: ML=%.2f REML=%.2f\n", mean(as.logical(d1$pd_ml), na.rm=TRUE), mean(as.logical(d1$pd_reml), na.rm=TRUE)))
cat("BIV SIGMA-RE PROBE DONE\n")
