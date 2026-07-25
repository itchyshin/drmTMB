#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out_dir <- sub("^--out-dir=", "", args[grepl("^--out-dir=", args)])
if (length(out_dir) != 1L || identical(out_dir, "")) {
  stop("Supply one --out-dir=PATH for immutable lane-specific smoke ledgers.", call. = FALSE)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
ledger_paths <- file.path(
  out_dir,
  c("arc6-1-regression-smoke-ledger.csv", "arc6-2-new-pair-smoke-ledger.csv")
)
if (any(file.exists(ledger_paths))) {
  stop("Refusing to overwrite an immutable smoke ledger; supply a new --out-dir.", call. = FALSE)
}

devtools::load_all(quiet = TRUE)

run_arc6_1 <- function() {
  set.seed(6201)
  n <- 120L
  x <- stats::rnorm(n)
  z_g <- stats::rnorm(n)
  z_b <- 0.35 * z_g + sqrt(1 - 0.35^2) * stats::rnorm(n)
  data <- data.frame(
    x = x,
    continuous = 0.2 + 0.4 * x + z_g,
    binary = as.integer(z_b > stats::qnorm(0.6))
  )
  gaussian_fit <- drmTMB(bf(mu = continuous ~ x, sigma = ~1), gaussian(), data)
  binary_fit <- drmTMB(bf(mu = binary ~ x), stats::binomial(), data)
  fit <- associate_pairs(
    gaussian_fit, binary_fit, kernel = latent_normal(), association = ~1
  )
  reverse <- associate_pairs(
    binary_fit, gaussian_fit, kernel = latent_normal(), association = ~1
  )
  data.frame(
    lane = "arc6_1_regression",
    attempt = 1L,
    status = fit$status,
    eta = fit$eta,
    logLik = fit$logLik,
    swapped_equal = isTRUE(all.equal(fit$eta, reverse$eta, tolerance = 1e-10)) &&
      isTRUE(all.equal(fit$logLik, reverse$logLik, tolerance = 1e-10)),
    stringsAsFactors = FALSE
  )
}

run_arc6_2 <- function() {
  set.seed(6202)
  n <- 160L
  x <- stats::rnorm(n)
  z_g <- stats::rnorm(n)
  z_n <- 0.4 * z_g + sqrt(1 - 0.4^2) * stats::rnorm(n)
  mu_n <- exp(0.25 + 0.3 * x)
  sigma_n <- exp(-0.35 + 0.12 * x)
  data <- data.frame(
    x = x,
    continuous = 0.1 + 0.45 * x + exp(-0.1 + 0.08 * x) * z_g,
    count = drm_pair_nbinom2_quantile_from_normal(z_n, mu_n, sigma_n)
  )
  gaussian_fit <- drmTMB(bf(mu = continuous ~ x, sigma = ~x), gaussian(), data)
  nbinom2_fit <- drmTMB(bf(mu = count ~ x, sigma = ~x), nbinom2(), data)
  fit <- associate_pairs(
    gaussian_fit, nbinom2_fit, kernel = latent_normal(), association = ~1
  )
  reverse <- associate_pairs(
    nbinom2_fit, gaussian_fit, kernel = latent_normal(), association = ~1
  )
  data.frame(
    lane = "arc6_2_new_pair",
    attempt = 1L,
    status = fit$status,
    eta = fit$eta,
    logLik = fit$logLik,
    swapped_equal = isTRUE(all.equal(fit$eta, reverse$eta, tolerance = 1e-10)) &&
      isTRUE(all.equal(fit$logLik, reverse$logLik, tolerance = 1e-10)),
    stringsAsFactors = FALSE
  )
}

arc6_1 <- run_arc6_1()
arc6_2 <- run_arc6_2()
utils::write.csv(
  arc6_1, ledger_paths[[1L]], row.names = FALSE
)
utils::write.csv(
  arc6_2, ledger_paths[[2L]], row.names = FALSE
)
ledger <- rbind(arc6_1, arc6_2)
if (any(ledger$status == "boundary_unresolved") || any(!ledger$swapped_equal)) {
  quit(status = 1L)
}
