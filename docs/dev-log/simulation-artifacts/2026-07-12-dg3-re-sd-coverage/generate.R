# DG3 coverage campaign: empirical coverage of the 95% Wald CI (log-SD scale) for
# the random-effect SD, across cluster counts M, for the Arc 2b/2c capabilities.
# Interval = exp(log_sd_hat +/- 1.96 * SE) from summary(sdreport). Because the RE-SD
# point estimate is biased low at small M (ML-Laplace), coverage is expected to be
# below nominal at small M and approach 0.95 as M grows -- the DG4/DG5 gate.
.libPaths("~/Rlib")
suppressWarnings(suppressMessages({library(drmTMB); library(parallel)}))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

NSIM   <- as.integer(Sys.getenv("NSIM", "600"))
NCORES <- as.integer(Sys.getenv("NCORES", "90"))
MS     <- as.integer(strsplit(Sys.getenv("MS", "8,16,32,64"), ",")[[1]])
NEACH  <- as.integer(Sys.getenv("NEACH", "12"))
Z <- stats::qnorm(0.975)

specs <- list(
  gaussian_slope = list(  # well-behaved reference (near-exact)
    true_sd = 0.6, sdrow = "log_sd_mu",
    fit = function(d) drmTMB(bf(y ~ x + (0 + x | id)), family = gaussian(), data = d),
    sim = function(M, ne, s) { set.seed(s); id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
      x <- rnorm(n); u <- rnorm(M, sd = 0.6); u <- u - mean(u)
      data.frame(y = 0.2 + 0.7 * x + u[id] * x + rnorm(n), x = x, id = id) }),
  binomial_slope = list(  # hardest: logit link, integral bias
    true_sd = 0.6, sdrow = "log_sd_mu",
    fit = function(d) drmTMB(bf(cbind(succ, fail) ~ x + (0 + x | id)), family = binomial(), data = d),
    sim = function(M, ne, s) { set.seed(s); id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
      x <- rnorm(n); u <- rnorm(M, sd = 0.6); u <- u - mean(u)
      p <- plogis(-0.2 + 0.7 * x + u[id] * x); succ <- rbinom(n, 12, p)
      data.frame(succ = succ, fail = 12 - succ, x = x, id = id) }),
  lognormal_sigma = list(  # Arc 2c: sigma random intercept
    true_sd = 0.4, sdrow = "log_sd_sigma",
    fit = function(d) drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = lognormal(), data = d),
    sim = function(M, ne, s) { set.seed(s); id <- factor(rep(seq_len(M), each = ne)); n <- length(id)
      x <- rnorm(n); u <- rnorm(M, sd = 0.4); u <- u - mean(u)
      sdlog <- exp(-0.5 + u[id]); data.frame(y = rlnorm(n, meanlog = 0.2 + 0.5 * x, sdlog = sdlog), x = x, id = id) })
)

one <- function(spec, M, ne, s) {
  d <- spec$sim(M, ne, s)
  fit <- tryCatch(spec$fit(d), error = function(e) NULL)
  if (is.null(fit) || !isTRUE(fit$opt$convergence == 0) || !isTRUE(fit$sdr$pdHess))
    return(c(ok = 0, cover = NA, sdhat = NA, width = NA))
  sm <- summary(fit$sdr)
  r <- which(rownames(sm) == spec$sdrow)
  if (!length(r)) return(c(ok = 0, cover = NA, sdhat = NA, width = NA))
  est <- sm[r[1], "Estimate"]; se <- sm[r[1], "Std. Error"]
  lo <- exp(est - Z * se); hi <- exp(est + Z * se)
  c(ok = 1, cover = as.numeric(spec$true_sd >= lo && spec$true_sd <= hi),
    sdhat = exp(est), width = hi - lo)
}

rows <- list()
for (nm in names(specs)) {
  sp <- specs[[nm]]
  for (M in MS) {
    seeds <- 20260900L + seq_len(NSIM)
    res <- do.call(rbind, mclapply(seeds, function(s) one(sp, M, NEACH, s), mc.cores = NCORES))
    ok <- res[, "ok"] == 1
    rows[[length(rows) + 1L]] <- data.frame(
      spec = nm, M = M, n_each = NEACH, nsim = NSIM, n_ok = sum(ok),
      coverage = round(mean(res[ok, "cover"], na.rm = TRUE), 3),
      sd_true = sp$true_sd,
      sd_hat_mean = round(mean(res[ok, "sdhat"], na.rm = TRUE), 3),
      rel_bias = round((mean(res[ok, "sdhat"], na.rm = TRUE) - sp$true_sd) / sp$true_sd, 3),
      ci_width = round(mean(res[ok, "width"], na.rm = TRUE), 3))
    cat(sprintf("%-16s M=%-3d n_ok=%d/%d  coverage=%.3f  rel_bias=%+.3f\n",
                nm, M, sum(ok), NSIM, mean(res[ok, "cover"], na.rm = TRUE),
                (mean(res[ok, "sdhat"], na.rm = TRUE) - sp$true_sd) / sp$true_sd))
  }
}
tab <- do.call(rbind, rows)
write.table(tab, "~/drmTMB_work/dg3-coverage-results.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nWROTE ~/drmTMB_work/dg3-coverage-results.tsv\nDG3 DONE\n")
