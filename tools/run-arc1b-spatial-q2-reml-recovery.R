#!/usr/bin/env Rscript

parse_arc1b_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    n_rep = 200L,
    cores = 1L,
    master_seed = 2026071403L,
    out_dir = file.path(
      "docs", "dev-log", "simulation-artifacts",
      "2026-07-14-arc1b-spatial-q2-reml-recovery"
    )
  )
  for (arg in args) {
    if (startsWith(arg, "--n-rep=")) {
      out$n_rep <- as.integer(sub("^--n-rep=", "", arg))
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--master-seed=")) {
      out$master_seed <- as.integer(sub("^--master-seed=", "", arg))
    } else if (startsWith(arg, "--out-dir=")) {
      out$out_dir <- sub("^--out-dir=", "", arg)
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (
    anyNA(c(out$n_rep, out$cores, out$master_seed)) ||
      out$n_rep < 1L || out$cores < 1L || out$cores > 50L
  ) {
    stop("`n-rep` and `cores` must be positive; `cores` must be <= 50.", call. = FALSE)
  }
  out
}

arc1b_recovery_grid <- function(n_rep, master_seed) {
  cells <- expand.grid(
    n_site = c(16L, 32L, 64L),
    n_each = c(3L, 6L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  cells$cell_id <- sprintf("site%02d_each%02d", cells$n_site, cells$n_each)
  grid <- merge(
    cells,
    data.frame(replicate = seq_len(n_rep)),
    by = NULL,
    sort = FALSE
  )
  cell_number <- match(grid$cell_id, cells$cell_id)
  grid$seed <- as.integer(master_seed + cell_number * 100000L + grid$replicate)
  grid[order(cell_number, grid$replicate), , drop = FALSE]
}

arc1b_spatial_kernel <- function(coords, jitter = 1e-6) {
  distances <- as.matrix(stats::dist(as.matrix(coords[, 1:2, drop = FALSE])))
  positive <- distances[distances > 0]
  range <- stats::median(positive)
  covariance <- exp(-distances / range)
  diag(covariance) <- diag(covariance) + jitter
  dimnames(covariance) <- list(rownames(coords), rownames(coords))
  covariance
}

arc1b_recovery_dgp <- function(n_site, n_each, seed) {
  set.seed(seed)
  truth <- c(
    spatial_sd1 = 0.80,
    spatial_sd2 = 0.65,
    spatial_cor = 0.35,
    sigma1 = 0.30,
    sigma2 = 0.35,
    rho12 = -0.20
  )
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    coord_x = cos(theta) + seq_len(n_site) / (3 * n_site),
    coord_y = sin(theta),
    row.names = site_levels
  )
  K <- arc1b_spatial_kernel(coords)
  L <- t(chol(K))
  z1 <- stats::rnorm(n_site)
  z2 <- stats::rnorm(n_site)
  spatial1 <- truth[["spatial_sd1"]] * as.vector(L %*% z1)
  spatial2 <- truth[["spatial_sd2"]] * as.vector(
    L %*% (
      truth[["spatial_cor"]] * z1 +
        sqrt(1 - truth[["spatial_cor"]]^2) * z2
    )
  )
  names(spatial1) <- names(spatial2) <- site_levels
  site <- rep(site_levels, each = n_each)
  x1 <- stats::rnorm(length(site))
  x2 <- stats::rnorm(length(site))
  e1 <- stats::rnorm(length(site))
  e2 <- truth[["rho12"]] * e1 +
    sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(site))
  data <- data.frame(
    y1 = 0.30 + 0.50 * x1 + spatial1[site] + truth[["sigma1"]] * e1,
    y2 = -0.20 - 0.25 * x2 + spatial2[site] + truth[["sigma2"]] * e2,
    x1 = x1,
    x2 = x2,
    site = factor(site, levels = site_levels)
  )
  list(data = data, coords = coords, truth = truth)
}

arc1b_recovery_attempt <- function(row) {
  started <- proc.time()[["elapsed"]]
  warnings <- character()
  error <- NA_character_
  fit <- tryCatch(
    withCallingHandlers(
      {
        generated <- arc1b_recovery_dgp(row$n_site, row$n_each, row$seed)
        coords <- generated$coords
        fit <- drmTMB::drmTMB(
          drmTMB::bf(
            mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
            mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
            sigma1 = ~1,
            sigma2 = ~1,
            rho12 = ~1
          ),
          family = drmTMB::biv_gaussian(),
          data = generated$data,
          REML = TRUE,
          control = drmTMB::drm_control(optimizer_preset = "robust")
        )
        attr(fit, "arc1b_truth") <- generated$truth
        fit
      },
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      error <<- conditionMessage(e)
      NULL
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  gradient <- if (is.null(fit)) {
    numeric()
  } else {
    tryCatch(as.numeric(fit$sdr$gradient.fixed), error = function(e) numeric())
  }
  if (!length(gradient) || any(!is.finite(gradient))) {
    gradient <- if (is.null(fit)) {
      numeric()
    } else {
      tryCatch(as.numeric(fit$obj$gr(fit$opt$par)), error = function(e) numeric())
    }
  }
  max_gradient <- if (length(gradient) && all(is.finite(gradient))) {
    max(abs(gradient))
  } else {
    NA_real_
  }
  base <- data.frame(
    cell_id = row$cell_id,
    n_site = row$n_site,
    n_each = row$n_each,
    replicate = row$replicate,
    seed = row$seed,
    elapsed = elapsed,
    fit_success = !is.null(fit),
    convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
    pdHess = if (is.null(fit)) NA else isTRUE(fit$sdr$pdHess),
    max_gradient = max_gradient,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    error = error,
    stringsAsFactors = FALSE
  )
  truth <- c(
    spatial_sd1 = 0.80,
    spatial_sd2 = 0.65,
    spatial_cor = 0.35,
    sigma1 = 0.30,
    sigma2 = 0.35,
    rho12 = -0.20
  )
  estimate <- rep(NA_real_, length(truth))
  names(estimate) <- names(truth)
  if (!is.null(fit)) {
    estimate <- c(
      spatial_sd1 = unname(fit$sdpars$mu[[1L]]),
      spatial_sd2 = unname(fit$sdpars$mu[[2L]]),
      spatial_cor = unname(fit$corpars$spatial[[1L]]),
      sigma1 = stats::sigma(fit)$sigma1[[1L]],
      sigma2 = stats::sigma(fit)$sigma2[[1L]],
      rho12 = drmTMB::rho12(fit)[[1L]]
    )
  }
  wide <- cbind(
    base,
    as.data.frame(as.list(setNames(truth, paste0("truth_", names(truth))))),
    as.data.frame(as.list(setNames(estimate, paste0("estimate_", names(estimate)))))
  )
  wide$target_boundary <- isTRUE(
    any(estimate[c("spatial_sd1", "spatial_sd2")] < 1e-5) ||
      abs(estimate[["spatial_cor"]]) >= 0.98
  )
  wide
}

arc1b_recovery_summary <- function(raw) {
  parameters <- c("spatial_sd1", "spatial_sd2", "spatial_cor")
  cells <- unique(raw[c("cell_id", "n_site", "n_each")])
  out <- lapply(seq_len(nrow(cells)), function(i) {
    cell <- cells[i, , drop = FALSE]
    rows <- raw[raw$cell_id == cell$cell_id, , drop = FALSE]
    do.call(rbind, lapply(parameters, function(parameter) {
      truth <- rows[[paste0("truth_", parameter)]]
      estimate <- rows[[paste0("estimate_", parameter)]]
      usable <- is.finite(estimate)
      errors <- estimate[usable] - truth[usable]
      data.frame(
        cell_id = cell$cell_id,
        n_site = cell$n_site,
        n_each = cell$n_each,
        parameter = parameter,
        attempted = nrow(rows),
        fit_success = sum(rows$fit_success),
        converged = sum(rows$convergence == 0L, na.rm = TRUE),
        pdHess = sum(rows$pdHess, na.rm = TRUE),
        boundary = sum(rows$target_boundary, na.rm = TRUE),
        usable = sum(usable),
        fit_success_rate = mean(rows$fit_success),
        convergence_rate = mean(rows$convergence == 0L, na.rm = TRUE),
        pdHess_rate = mean(rows$pdHess, na.rm = TRUE),
        boundary_rate = mean(rows$target_boundary, na.rm = TRUE),
        bias = if (length(errors)) mean(errors) else NA_real_,
        rmse = if (length(errors)) sqrt(mean(errors^2)) else NA_real_,
        empirical_sd = if (length(errors) > 1L) stats::sd(estimate[usable]) else NA_real_,
        mcse_bias = if (length(errors) > 1L) stats::sd(errors) / sqrt(length(errors)) else NA_real_,
        stringsAsFactors = FALSE
      )
    }))
  })
  do.call(rbind, out)
}

run_arc1b_recovery <- function(args = parse_arc1b_args()) {
  dir.create(args$out_dir, recursive = TRUE, showWarnings = FALSE)
  grid <- arc1b_recovery_grid(args$n_rep, args$master_seed)
  rows <- split(grid, seq_len(nrow(grid)))
  worker <- function(row) arc1b_recovery_attempt(row[1L, , drop = FALSE])
  results <- if (args$cores == 1L || .Platform$OS.type == "windows") {
    lapply(rows, worker)
  } else {
    parallel::mclapply(rows, worker, mc.cores = args$cores, mc.preschedule = FALSE)
  }
  raw <- do.call(rbind, results)
  summary <- arc1b_recovery_summary(raw)
  utils::write.table(
    grid,
    file.path(args$out_dir, "design.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  utils::write.table(
    raw,
    file.path(args$out_dir, "raw-attempts.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  utils::write.table(
    summary,
    file.path(args$out_dir, "summary.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  writeLines(capture.output(sessionInfo()), file.path(args$out_dir, "session-info.txt"))
  invisible(list(grid = grid, raw = raw, summary = summary))
}

if (sys.nframe() == 0L) {
  run_arc1b_recovery()
}
