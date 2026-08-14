#!/usr/bin/env Rscript

# Recovery runner for the narrow MD9b joint Gaussian missing-predictor route.
# Each invocation owns one cell and a disjoint replicate range, making it safe
# for a SLURM array. It retains failures rather than silently dropping them.

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    cell = 1L,
    rep_start = 1L,
    rep_end = 1L,
    seed_base = 2026081300L,
    out_dir = file.path("docs", "dev-log", "simulation-artifacts",
                        "2026-08-13-joint-mi-gaussian-recovery")
  )
  for (arg in args) {
    if (startsWith(arg, "--cell=")) out$cell <- as.integer(sub("^--cell=", "", arg))
    else if (startsWith(arg, "--rep-start=")) out$rep_start <- as.integer(sub("^--rep-start=", "", arg))
    else if (startsWith(arg, "--rep-end=")) out$rep_end <- as.integer(sub("^--rep-end=", "", arg))
    else if (startsWith(arg, "--seed-base=")) out$seed_base <- as.integer(sub("^--seed-base=", "", arg))
    else if (startsWith(arg, "--out-dir=")) out$out_dir <- sub("^--out-dir=", "", arg)
    else stop("Unknown argument: ", arg, call. = FALSE)
  }
  if (anyNA(unlist(out[c("cell", "rep_start", "rep_end", "seed_base")])) ||
      out$cell < 1L || out$rep_start < 1L || out$rep_end < out$rep_start) {
    stop("`cell`, `rep-start`, `rep-end`, and `seed-base` must be valid integers.", call. = FALSE)
  }
  out
}

joint_mi_grid <- function() {
  grid <- expand.grid(
    n = c(300L, 600L, 1200L),
    rho_x = c(0.2, 0.6),
    missing_rate = c(0.2, 0.4),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid <- grid[order(grid$n, grid$rho_x, grid$missing_rate), , drop = FALSE]
  grid$cell <- seq_len(nrow(grid))
  grid$cell_id <- sprintf("n%04d_rho%02d_miss%02d",
    grid$n, round(100 * grid$rho_x), round(100 * grid$missing_rate))
  grid
}

joint_mi_dgp <- function(spec, seed) {
  set.seed(seed)
  n <- spec$n
  truth <- c(
    mu_intercept = 1.0, mu_z = 0.5, mu_x1 = 0.8, mu_x2 = -0.6,
    mi_x1_intercept = 0.3, mi_x1_z = 0.7,
    mi_x2_intercept = -0.2, mi_x2_z = -0.4,
    sigma_y = 0.7, sigma_x1 = 1.0, sigma_x2 = 1.2,
    rho_mi_x1_x2 = spec$rho_x
  )
  z <- stats::rnorm(n)
  e1 <- stats::rnorm(n)
  e2 <- spec$rho_x * e1 + sqrt(1 - spec$rho_x^2) * stats::rnorm(n)
  x1 <- truth[["mi_x1_intercept"]] + truth[["mi_x1_z"]] * z + truth[["sigma_x1"]] * e1
  x2 <- truth[["mi_x2_intercept"]] + truth[["mi_x2_z"]] * z + truth[["sigma_x2"]] * e2
  y <- truth[["mu_intercept"]] + truth[["mu_z"]] * z +
    truth[["mu_x1"]] * x1 + truth[["mu_x2"]] * x2 +
    stats::rnorm(n, sd = truth[["sigma_y"]])
  data <- data.frame(y = y, z = z, x1 = x1, x2 = x2)
  # Independent MCAR masks yield all four observed-predictor patterns.
  data$x1[stats::runif(n) < spec$missing_rate] <- NA_real_
  data$x2[stats::runif(n) < spec$missing_rate] <- NA_real_
  list(data = data, truth = truth)
}

fit_one <- function(spec, replicate, seed) {
  generated <- joint_mi_dgp(spec, seed)
  started <- proc.time()[["elapsed"]]
  warnings <- character()
  error <- NA_character_
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB::drmTMB(
        drmTMB::bf(y ~ z + mi(x1) + mi(x2), sigma ~ 1),
        data = generated$data,
        impute = drmTMB::impute_joint(cbind(x1, x2) ~ z),
        missing = drmTMB::miss_control(predictor = "model"),
        control = drmTMB::drm_control(se = TRUE, optimizer_preset = "robust")
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) { error <<- conditionMessage(e); NULL }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  estimate <- setNames(rep(NA_real_, length(generated$truth)), names(generated$truth))
  gradient <- NA_real_
  if (!is.null(fit)) {
    coefs <- stats::coef(fit)
    estimate[c("mu_intercept", "mu_z", "mu_x1", "mu_x2")] <- unname(coefs$mu)
    estimate[c("mi_x1_intercept", "mi_x1_z")] <- unname(coefs$mi_x1)
    estimate[c("mi_x2_intercept", "mi_x2_z")] <- unname(coefs$mi_x2)
    response_sigma <- stats::sigma(fit)
    estimate[["sigma_y"]] <- unname(if (is.list(response_sigma)) {
      response_sigma$sigma[[1L]]
    } else {
      response_sigma[[1L]]
    })
    estimate[["sigma_x1"]] <- unname(coefs$sigma_mi[["x1"]])
    estimate[["sigma_x2"]] <- unname(coefs$sigma_mi[["x2"]])
    estimate[["rho_mi_x1_x2"]] <- unname(coefs$rho_mi_x1_x2[[1L]])
    raw_gradient <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
    if (length(raw_gradient) && all(is.finite(raw_gradient))) gradient <- max(abs(raw_gradient))
  }
  cbind(
    data.frame(
      cell_id = spec$cell_id, cell = spec$cell, n = spec$n,
      rho_x = spec$rho_x, missing_rate = spec$missing_rate,
      replicate = replicate, seed = seed, elapsed = elapsed,
      fit_success = !is.null(fit),
      convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
      pdHess = if (is.null(fit)) FALSE else isTRUE(fit$sdr$pdHess),
      max_gradient = gradient, warning_count = length(warnings),
      warnings = paste(warnings, collapse = " | "), error = error,
      n_x1_missing = sum(is.na(generated$data$x1)),
      n_x2_missing = sum(is.na(generated$data$x2)),
      stringsAsFactors = FALSE
    ),
    as.data.frame(as.list(setNames(generated$truth, paste0("truth_", names(generated$truth))))),
    as.data.frame(as.list(setNames(estimate, paste0("estimate_", names(estimate)))))
  )
}

if (!identical(Sys.getenv("DRMTMB_JOINT_MI_SOURCE_ONLY"), "true")) {
  if (!identical(Sys.getenv("DRMTMB_RUN_INSTALLED"), "true")) {
    devtools::load_all(".", quiet = TRUE)
  }
  library(drmTMB)
  args <- parse_args()
  grid <- joint_mi_grid()
  if (args$cell > nrow(grid)) stop("`cell` is outside the recovery grid.", call. = FALSE)
  spec <- grid[args$cell, , drop = FALSE]
  dir.create(args$out_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- lapply(args$rep_start:args$rep_end, function(replicate) {
    seed <- args$seed_base + spec$cell * 100000L + replicate
    fit_one(spec, replicate, seed)
  })
  result <- do.call(rbind, rows)
  path <- file.path(args$out_dir, sprintf("%s_rep%04d-%04d.csv", spec$cell_id, args$rep_start, args$rep_end))
  utils::write.csv(result, path, row.names = FALSE)
  cat(sprintf("Wrote %d replicate rows to %s\n", nrow(result), path))
}
