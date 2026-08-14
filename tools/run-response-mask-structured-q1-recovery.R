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

pkgload::load_all(".", quiet = TRUE)

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
  data.frame(task, provider, seed, status = if (fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)) "ok" else "diagnostic",
    beta0 = fit$par$mu[[1L]], beta_x = fit$par$mu[[2L]], sigma = exp(fit$par$sigma[[1L]]), sd = fit$sdpars$mu[[1L]], stringsAsFactors = FALSE)
}, error = function(e) data.frame(task, provider, seed, status = paste0("error: ", conditionMessage(e)), beta0 = NA_real_, beta_x = NA_real_, sigma = NA_real_, sd = NA_real_))
write.csv(row, file.path(output_dir, sprintf("task-%03d.csv", task)), row.names = FALSE)
