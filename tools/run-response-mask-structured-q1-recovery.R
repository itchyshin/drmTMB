#!/usr/bin/env Rscript

# One retained task for the approved q1 structured Gaussian REML
# missing-response recovery campaign.  Intended for a SLURM array, never CI.

args <- commandArgs(trailingOnly = TRUE)
task <- suppressWarnings(as.integer(if (length(args)) args[[1L]] else NA_integer_))
if (!is.finite(task) || task < 1L || task > 300L) {
  stop("Usage: run-response-mask-structured-q1-recovery.R <task 1..300>", call. = FALSE)
}
output_dir <- Sys.getenv("DRMTMB_RESPONSE_MASK_OUTPUT_DIR", unset = "")
if (!nzchar(output_dir)) stop("Set DRMTMB_RESPONSE_MASK_OUTPUT_DIR", call. = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

providers <- c("spatial", "animal", "relmat")
provider <- providers[[(task - 1L) %/% 100L + 1L]]
seed <- 2026081000L + (task - 1L) %% 100L

installed_library <- Sys.getenv("DRMTMB_RESPONSE_MASK_LIBRARY", unset = "")
if (nzchar(installed_library)) {
  .libPaths(c(installed_library, .libPaths()))
}
if (identical(Sys.getenv("DRMTMB_RESPONSE_MASK_USE_INSTALLED"), "true")) {
  if (!requireNamespace("drmTMB", quietly = TRUE)) {
    stop("Installed drmTMB is unavailable in DRMTMB_RESPONSE_MASK_LIBRARY", call. = FALSE)
  }
  library(drmTMB)
} else {
  pkgload::load_all(".", quiet = TRUE)
}

pedigree <- function(labels) {
  n <- length(labels); dam <- sire <- rep(NA_character_, n)
  if (n > 4L) { dam[5:n] <- labels[rep(1:4, length.out = n - 4L)]; sire[5:n] <- labels[rep(2:5, length.out = n - 4L)] }
  data.frame(id = labels, dam = dam, sire = sire, stringsAsFactors = FALSE)
}
fixture <- function(provider, seed, g = 64L, n_each = 8L) {
  set.seed(seed); labels <- paste0("id", seq_len(g))
  if (provider == "spatial") {
    theta <- seq(0, 1.5 * pi, length.out = g)
    coords <- data.frame(x = cos(theta) + seq_len(g) / (3 * g), y = sin(theta), row.names = labels)
    K <- solve(as.matrix(drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "id")$precision))
    form <- bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1)
  } else if (provider == "animal") {
    ped <- pedigree(labels); K <- drmTMB:::drm_pedigree_additive_relationship(ped)
    form <- bf(y ~ x + animal(1 | id, A = K), sigma ~ 1)
  } else {
    K <- outer(seq_len(g), seq_len(g), function(i, j) 0.35^abs(i - j)); diag(K) <- diag(K) + 0.15; dimnames(K) <- list(labels, labels)
    form <- bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
  }
  b <- drop(t(chol(K)) %*% rnorm(g)) * 0.5
  id <- rep(labels, each = n_each); x <- rep(seq(-1, 1, length.out = n_each), g)
  y <- 0.4 + 0.25 * x + b[match(id, labels)] + rnorm(g * n_each, sd = 0.5)
  dat <- data.frame(y = y, x = x, id = factor(id, levels = labels))
  set.seed(seed + 100000L)
  missing <- unlist(lapply(split(seq_len(nrow(dat)), dat$id), function(i) sample(i, 2L)), use.names = FALSE)
  dat$y[missing] <- NA_real_
  list(data = dat, form = form)
}

row <- tryCatch({
  fx <- fixture(provider, seed)
  fit <- drmTMB(fx$form, data = fx$data,
    REML = TRUE, missing = miss_control(response = "include"), control = drm_control(optimizer_preset = "robust", se = FALSE))
  convergence <- fit$opt$convergence
  pd_hess <- isTRUE(fit$sdr$pdHess)
  beta0 <- fit$par$mu[[1L]]
  beta_x <- fit$par$mu[[2L]]
  sigma <- exp(fit$par$sigma[[1L]])
  sd <- fit$sdpars$mu[[1L]]
  data.frame(
    task, provider, seed,
    status = if (convergence == 0L && pd_hess) "ok" else "diagnostic",
    convergence, pd_hess,
    message = if (convergence == 0L && pd_hess) NA_character_ else "non-zero convergence or non-positive-definite Hessian",
    beta0, beta_x, sigma, sd,
    abs_error_beta0 = abs(beta0 - 0.4),
    abs_error_beta_x = abs(beta_x - 0.25),
    abs_error_sigma = abs(sigma - 0.5),
    abs_error_sd = abs(sd - 0.5),
    stringsAsFactors = FALSE
  )
}, error = function(e) data.frame(
  task, provider, seed, status = "error", convergence = NA_integer_, pd_hess = NA,
  message = conditionMessage(e), beta0 = NA_real_, beta_x = NA_real_, sigma = NA_real_, sd = NA_real_,
  abs_error_beta0 = NA_real_, abs_error_beta_x = NA_real_, abs_error_sigma = NA_real_, abs_error_sd = NA_real_,
  stringsAsFactors = FALSE
))
target <- file.path(output_dir, sprintf("task-%03d.csv", task))
temporary <- paste0(target, ".tmp-", Sys.getpid())
write.csv(row, temporary, row.names = FALSE)
if (!file.rename(temporary, target)) stop("Could not atomically publish task receipt", call. = FALSE)
