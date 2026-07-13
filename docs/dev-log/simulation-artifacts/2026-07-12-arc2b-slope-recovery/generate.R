# Arc 2b — mu random SLOPE (0 + x | id) recovery bias sweep for the five families.
# Fisher's bar: single-seed point fits are blind to the systematic ML-Laplace
# small-cluster RE-SD bias, so report mean RELATIVE SD bias across >=50 seeds,
# plus BLUP-vs-truth correlation on the linear-predictor (latent) scale.
suppressWarnings(suppressMessages(devtools::load_all(".", quiet = TRUE)))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

N_SEEDS <- 60L
N_ID <- 40L
N_EACH <- 15L
SLOPE_SD <- 0.5

base_slope <- function(seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(N_ID), each = N_EACH)); n <- length(id)
  x <- stats::rnorm(n)
  slope <- stats::rnorm(N_ID, sd = SLOPE_SD); slope <- slope - mean(slope)
  list(id = id, n = n, x = x, slope = slope, eta_slope = slope[id] * x)
}

sim_fit <- function(family, seed) {
  b <- base_slope(seed)
  fit <- tryCatch({
    if (family == "skew_normal") {
      z <- stats::rnorm(b$n)
      mu <- 0.2 + 0.6 * b$x + b$eta_slope
      sigma <- exp(-0.3 + 0.15 * z); nu <- 1.6
      delta <- nu / sqrt(1 + nu^2); ms <- sqrt(2 / pi) * delta
      omega <- sigma / sqrt(1 - ms^2); xi <- mu - omega * ms
      y <- xi + omega * (delta * abs(stats::rnorm(b$n)) + sqrt(1 - delta^2) * stats::rnorm(b$n))
      d <- data.frame(y = y, x = b$x, z = z, id = b$id)
      drmTMB(bf(y ~ x + (0 + x | id), sigma ~ z, nu ~ 1), family = skew_normal(), data = d)
    } else if (family == "tweedie") {
      mu <- exp(0.2 + 0.5 * b$x + b$eta_slope)
      y <- drmTMB:::rtweedie_compound(b$n, mu = mu, phi = 1.4, power = 1.5)
      d <- data.frame(y = y, x = b$x, id = b$id)
      drmTMB(bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1), family = tweedie(), data = d)
    } else if (family == "zero_one_beta") {
      mu <- stats::plogis(0.3 + 0.7 * b$x + b$eta_slope); phi <- 1 / 0.4^2
      y <- stats::rbeta(b$n, mu * phi, (1 - mu) * phi)
      bound <- stats::runif(b$n) < 0.15
      y[bound] <- ifelse(stats::runif(sum(bound)) < 0.5, 1, 0)
      d <- data.frame(y = y, x = b$x, id = b$id)
      drmTMB(bf(y ~ x + (0 + x | id)), family = zero_one_beta(), data = d)
    } else if (family == "binomial") {
      p <- stats::plogis(-0.2 + 0.7 * b$x + b$eta_slope); trials <- stats::rpois(b$n, 10) + 4
      succ <- stats::rbinom(b$n, trials, p)
      d <- data.frame(succ = succ, fail = trials - succ, x = b$x, id = b$id)
      drmTMB(bf(cbind(succ, fail) ~ x + (0 + x | id)), family = binomial(), data = d)
    } else if (family == "cumulative_logit") {
      cut <- c(-1, 0, 1)
      lat <- 0.8 * b$x + b$eta_slope + stats::rlogis(b$n)
      y <- ordered(findInterval(lat, cut) + 1L, levels = 1:4)
      d <- data.frame(y = y, x = b$x, id = b$id)
      drmTMB(bf(y ~ x + (0 + x | id)), family = cumulative_logit(), data = d)
    } else stop("unknown")
  }, error = function(e) e)
  if (inherits(fit, "error")) return(data.frame(seed = seed, ok = FALSE, sd_hat = NA, cor = NA))
  lab <- "(0 + x | id)"
  ok <- isTRUE(fit$opt$convergence == 0) && isTRUE(fit$sdr$pdHess)
  sd_hat <- tryCatch(unname(fit$sdpars$mu[[lab]]), error = function(e) NA_real_)
  blup <- tryCatch(fit$random_effects$mu$terms[[lab]], error = function(e) NULL)
  cor_bt <- if (!is.null(blup)) suppressWarnings(stats::cor(blup, b$slope)) else NA_real_
  data.frame(seed = seed, ok = ok, sd_hat = sd_hat, cor = cor_bt)
}

families <- c("skew_normal", "tweedie", "zero_one_beta", "binomial", "cumulative_logit")
seeds <- 20260712L + seq_len(N_SEEDS)
rows <- list()
for (fam in families) {
  res <- do.call(rbind, lapply(seeds, function(s) sim_fit(fam, s)))
  okr <- res[res$ok & is.finite(res$sd_hat), ]
  rel_bias <- (okr$sd_hat - SLOPE_SD) / SLOPE_SD
  rows[[fam]] <- data.frame(
    family = fam,
    n_ok = nrow(okr),
    n_seeds = N_SEEDS,
    sd_true = SLOPE_SD,
    sd_hat_mean = round(mean(okr$sd_hat), 4),
    rel_bias_mean = round(mean(rel_bias), 4),
    rel_bias_median = round(stats::median(rel_bias), 4),
    cor_median = round(stats::median(okr$cor, na.rm = TRUE), 4),
    cor_min = round(min(okr$cor, na.rm = TRUE), 4)
  )
  cat(sprintf("%-18s n_ok=%d/%d  sd_hat=%.3f (true %.2f)  rel_bias mean=%+.3f med=%+.3f  cor med=%.3f min=%.3f\n",
              fam, nrow(okr), N_SEEDS, mean(okr$sd_hat), SLOPE_SD,
              mean(rel_bias), stats::median(rel_bias),
              stats::median(okr$cor, na.rm = TRUE), min(okr$cor, na.rm = TRUE)))
}
tab <- do.call(rbind, rows)
outdir <- "docs/dev-log/simulation-artifacts/2026-07-12-arc2b-slope-recovery"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
write.table(tab, file.path(outdir, "bias-table.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nWROTE", file.path(outdir, "bias-table.tsv"), "\n")
cat("SWEEP DONE\n")
