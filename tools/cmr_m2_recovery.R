run_cmr_m2_recovery_smoke <- function() {
  history_path <- "bench/cmr_m2/fixtures/histories.csv"
  phi_path <- "bench/cmr_m2/fixtures/phi_predictors.csv"
  p_path <- "bench/cmr_m2/fixtures/p_predictors.csv"
  stopifnot(file.exists(history_path), file.exists(phi_path), file.exists(p_path))
  histories <- utils::read.csv(history_path, stringsAsFactors = FALSE)
  phi_all <- utils::read.csv(phi_path, stringsAsFactors = FALSE)
  p_all <- utils::read.csv(p_path, stringsAsFactors = FALSE)
  cases <- list(
    list(cell = "survival_coefficients", replicate = 1L,
         phi = ~1 + x_phi, p = ~1, constraint = list(p = 0.6)),
    list(cell = "survival_coefficients", replicate = 2L,
         phi = ~1 + x_phi, p = ~1, constraint = list(p = 0.6)),
    list(cell = "detection_coefficients", replicate = 1L,
         phi = ~1, p = ~1 + z_p, constraint = list(phi = 0.8)),
    list(cell = "detection_coefficients", replicate = 2L,
         phi = ~1, p = ~1 + z_p, constraint = list(phi = 0.8))
  )
  results <- vector("list", length(cases))
  for (k in seq_along(cases)) {
    spec <- cases[[k]]
    h <- histories[histories$cell == spec$cell & histories$replicate == spec$replicate, , drop = FALSE]
    ids <- unique(h$id)
    occasions <- sort(unique(h$occasion))
    y <- matrix(NA_real_, length(ids), length(occasions), dimnames = list(ids, occasions))
    observed <- matrix(FALSE, length(ids), length(occasions), dimnames = dimnames(y))
    ends <- integer(length(ids))
    for (i in seq_along(ids)) {
      rows <- h[h$id == ids[[i]], , drop = FALSE]
      ix <- match(rows$occasion, occasions)
      observed[i, ix] <- as.logical(rows$observed)
      y[i, ix] <- ifelse(observed[i, ix], rows$capture, NA_real_)
      ends[[i]] <- rows$admin_end[[1L]]
    }
    data <- cmr_data(y, id = ids, observed = observed, occasions = occasions,
                     intervals = c(1, 0.5, 1.5, 1), units = "years", end = ends)
    phi_data <- phi_all[phi_all$cell == spec$cell & phi_all$replicate == spec$replicate,
                        c("id", "interval_start", "interval_end", "x_phi"), drop = FALSE]
    p_data <- p_all[p_all$cell == spec$cell & p_all$replicate == spec$replicate,
                    c("id", "occasion", "z_p"), drop = FALSE]
    fit <- tryCatch(drm_cjs(data, phi = spec$phi, p = spec$p,
                            phi_data = phi_data, p_data = p_data,
                            terminal_constraint = spec$constraint), error = identity)
    if (inherits(fit, "error")) {
      results[[k]] <- data.frame(cell = spec$cell, replicate = spec$replicate,
        status = "error", converged = FALSE, gradient_norm = NA_real_,
        logLik = NA_real_, truth_logLik = NA_real_,
        reason = conditionMessage(fit), stringsAsFactors = FALSE)
    } else {
      n_phi <- length(fit$phi$columns)
      truth <- numeric(length(fit$optimizer$par))
      if (spec$cell == "survival_coefficients") {
        truth[seq_len(n_phi)] <- c(1.20, -0.45)
        truth[n_phi + seq_along(fit$p$columns)] <- stats::qlogis(0.60)
      } else {
        truth[seq_len(n_phi)] <- stats::qlogis(0.80)
        truth[n_phi + seq_along(fit$p$columns)] <- c(0.10, 0.65)
      }
      results[[k]] <- data.frame(cell = spec$cell, replicate = spec$replicate,
        status = if (fit$convergence == 0L && is.finite(fit$gradient_norm) && fit$gradient_norm <= 1e-4) "usable" else "unusable",
        converged = fit$convergence == 0L, gradient_norm = fit$gradient_norm,
        logLik = fit$logLik, truth_logLik = -fit$obj$fn(truth),
        reason = fit$message, stringsAsFactors = FALSE)
    }
  }
  result <- do.call(rbind, results)
  print(result, row.names = FALSE)
  utils::write.csv(result, "docs/dev-log/cmr/r-m2-recovery-smoke.csv", row.names = FALSE)
  if (nrow(result) != length(cases) || any(result$status != "usable") ||
      any(!is.finite(result$logLik)) || any(!is.finite(result$truth_logLik)) ||
      any(result$logLik + 1e-6 < result$truth_logLik)) {
    stop("CMR_M2_RECOVERY_FAILED: one or more smoke fits failed convergence, finite-likelihood, or generating-likelihood checks.", call. = FALSE)
  }
  cat("CMR_M2_RECOVERY_FIXTURES=4\n")
  invisible(result)
}
