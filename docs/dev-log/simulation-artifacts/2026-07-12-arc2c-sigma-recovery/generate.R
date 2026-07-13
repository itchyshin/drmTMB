# Arc 2c — sigma random INTERCEPT (1 | id) recovery bias sweep for lognormal + gamma.
# Fisher's bar: single-seed point fits are blind to the systematic ML-Laplace
# small-cluster RE-SD bias, so report mean RELATIVE SD bias across >=50 seeds,
# plus BLUP-vs-truth correlation on the log-sigma (latent) scale, the scale the
# sigma random intercept lives on for both families.
suppressWarnings(suppressMessages(devtools::load_all(".", quiet = TRUE)))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

N_SEEDS <- 60L
N_ID <- 40L
N_EACH <- 15L
SD_SIGMA <- 0.4

base_sigma <- function(seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(N_ID), each = N_EACH)); n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(N_ID, sd = SD_SIGMA); u <- u - mean(u)
  list(id = id, n = n, x = x, u = u)
}

sim_fit <- function(family, seed) {
  b <- base_sigma(seed)
  fit <- tryCatch({
    if (family == "lognormal") {
      meanlog <- 0.2 + 0.5 * b$x
      sdlog <- exp(-0.5 + b$u[b$id])
      y <- stats::rlnorm(b$n, meanlog = meanlog, sdlog = sdlog)
      d <- data.frame(y = y, x = b$x, id = b$id)
      drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = lognormal(), data = d)
    } else if (family == "gamma") {
      mu_i <- exp(0.2 + 0.5 * b$x)
      sigma_i <- exp(-0.6 + b$u[b$id])
      shape <- 1 / sigma_i^2; scale <- mu_i * sigma_i^2
      y <- stats::rgamma(b$n, shape = shape, scale = scale)
      d <- data.frame(y = y, x = b$x, id = b$id)
      drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = Gamma(link = "log"), data = d)
    } else stop("unknown")
  }, error = function(e) e)
  if (inherits(fit, "error")) {
    return(data.frame(seed = seed, ok = FALSE, sd_hat = NA_real_, cor = NA_real_))
  }
  lab <- "(1 | id)"
  ok <- isTRUE(fit$opt$convergence == 0) && isTRUE(fit$sdr$pdHess)
  sd_hat <- tryCatch(unname(fit$sdpars$sigma[[lab]]), error = function(e) NA_real_)
  blup <- tryCatch(fit$random_effects$sigma$terms[[lab]], error = function(e) NULL)
  cor_bt <- if (!is.null(blup)) suppressWarnings(stats::cor(blup, b$u)) else NA_real_
  data.frame(seed = seed, ok = ok, sd_hat = sd_hat, cor = cor_bt)
}

families <- c("lognormal", "gamma")
seeds <- 20260712L + seq_len(N_SEEDS)
rows <- list()
for (fam in families) {
  res <- do.call(rbind, lapply(seeds, function(s) sim_fit(fam, s)))
  okr <- res[res$ok & is.finite(res$sd_hat), ]
  rel_bias <- (okr$sd_hat - SD_SIGMA) / SD_SIGMA
  rows[[fam]] <- data.frame(
    family = fam,
    n_ok = nrow(okr),
    n_seeds = N_SEEDS,
    sd_true = SD_SIGMA,
    sd_hat_mean = round(mean(okr$sd_hat), 4),
    rel_bias_mean = round(mean(rel_bias), 4),
    rel_bias_median = round(stats::median(rel_bias), 4),
    cor_median = round(stats::median(okr$cor, na.rm = TRUE), 4),
    cor_min = round(min(okr$cor, na.rm = TRUE), 4)
  )
  cat(sprintf(
    "%-10s n_ok=%d/%d  sd_hat=%.3f (true %.2f)  rel_bias mean=%+.3f med=%+.3f  cor med=%.3f min=%.3f\n",
    fam, nrow(okr), N_SEEDS, mean(okr$sd_hat), SD_SIGMA,
    mean(rel_bias), stats::median(rel_bias),
    stats::median(okr$cor, na.rm = TRUE), min(okr$cor, na.rm = TRUE)))
}
tab <- do.call(rbind, rows)
outdir <- "docs/dev-log/simulation-artifacts/2026-07-12-arc2c-sigma-recovery"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
write.table(tab, file.path(outdir, "bias-table.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nWROTE", file.path(outdir, "bias-table.tsv"), "\n")
cat("SWEEP DONE\n")
