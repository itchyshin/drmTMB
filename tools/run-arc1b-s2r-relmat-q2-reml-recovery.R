#!/usr/bin/env Rscript

parse_arc1b_s2r_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    n_rep = 400L,
    cores = 1L,
    master_seed = 2026071503L,
    out_dir = file.path(
      "docs", "dev-log", "simulation-artifacts",
      "2026-07-15-arc1b-s2r-relmat-q2-reml"
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
      out$n_rep < 1L || out$cores < 1L || out$cores > 32L
  ) {
    stop(
      "`n-rep` and `cores` must be positive; `cores` must be <= 32.",
      call. = FALSE
    )
  }
  out
}

arc1b_s2r_recovery_grid <- function(n_rep, master_seed) {
  cells <- expand.grid(
    g = c(16L, 32L, 64L),
    m = c(3L, 6L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  cells <- cells[order(cells$g, cells$m), , drop = FALSE]
  cells$cell_number <- seq_len(nrow(cells))
  cells$cell_id <- sprintf("g%02d_m%02d", cells$g, cells$m)
  grid <- merge(
    cells,
    data.frame(replicate = seq_len(n_rep)),
    by = NULL,
    sort = FALSE
  )
  grid$seed <- as.integer(
    master_seed + grid$cell_number * 100000L + grid$replicate
  )
  grid[order(grid$cell_number, grid$replicate), , drop = FALSE]
}

arc1b_s2r_recovery_K <- function(g) {
  level <- sprintf("id_%03d", seq_len(g))
  K <- outer(seq_len(g), seq_len(g), function(i, j) 0.4^abs(i - j))
  dimnames(K) <- list(level, level)
  K
}

arc1b_s2r_K_digest <- function(K) {
  paste0(
    nrow(K), "x", ncol(K),
    ";sum=", formatC(sum(K), digits = 14L, format = "fg"),
    ";diag=", formatC(sum(diag(K)), digits = 14L, format = "fg"),
    ";logdet=", formatC(
      as.numeric(determinant(K, logarithm = TRUE)$modulus),
      digits = 14L,
      format = "fg"
    ),
    ";first=", rownames(K)[[1L]],
    ";last=", rownames(K)[[nrow(K)]]
  )
}

arc1b_s2r_recovery_dgp <- function(g, m, seed) {
  set.seed(seed)
  truth <- c(
    beta1_intercept = 0.30,
    beta1_x1 = 0.50,
    beta2_intercept = -0.20,
    beta2_x2 = -0.25,
    tau1 = 0.80,
    tau2 = 0.65,
    rho_K = 0.35,
    sigma1 = 0.30,
    sigma2 = 0.35,
    rho12 = -0.20
  )
  K <- arc1b_s2r_recovery_K(g)
  level <- rownames(K)
  L <- t(chol(K))
  z1 <- stats::rnorm(g)
  z2 <- stats::rnorm(g)
  u1 <- truth[["tau1"]] * as.vector(L %*% z1)
  u2 <- truth[["tau2"]] * as.vector(
    L %*% (
      truth[["rho_K"]] * z1 +
        sqrt(1 - truth[["rho_K"]]^2) * z2
    )
  )
  names(u1) <- names(u2) <- level
  id <- factor(rep(level, each = m), levels = level)
  x1 <- stats::rnorm(length(id))
  x2 <- stats::rnorm(length(id))
  e1 <- stats::rnorm(length(id))
  e2 <- truth[["rho12"]] * e1 +
    sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(id))
  data <- data.frame(
    y1 = truth[["beta1_intercept"]] + truth[["beta1_x1"]] * x1 +
      u1[as.character(id)] + truth[["sigma1"]] * e1,
    y2 = truth[["beta2_intercept"]] + truth[["beta2_x2"]] * x2 +
      u2[as.character(id)] + truth[["sigma2"]] * e2,
    x1 = x1,
    x2 = x2,
    id = id
  )
  list(data = data, K = K, truth = truth)
}

arc1b_s2r_recovery_attempt <- function(row) {
  started <- proc.time()[["elapsed"]]
  warnings <- character()
  error <- NA_character_
  generated <- arc1b_s2r_recovery_dgp(row$g, row$m, row$seed)
  K <- generated$K
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB::drmTMB(
        drmTMB::bf(
          mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
          mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
          sigma1 = ~1,
          sigma2 = ~1,
          rho12 = ~1
        ),
        family = drmTMB::biv_gaussian(),
        data = generated$data,
        REML = TRUE,
        control = drmTMB::drm_control(optimizer_preset = "robust")
      ),
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

  truth <- generated$truth
  estimate <- rep(NA_real_, length(truth))
  names(estimate) <- names(truth)
  if (!is.null(fit)) {
    estimate <- c(
      beta1_intercept = as.numeric(fit$par$mu1[[1L]]),
      beta1_x1 = as.numeric(fit$par$mu1[[2L]]),
      beta2_intercept = as.numeric(fit$par$mu2[[1L]]),
      beta2_x2 = as.numeric(fit$par$mu2[[2L]]),
      tau1 = unname(fit$sdpars$mu[[1L]]),
      tau2 = unname(fit$sdpars$mu[[2L]]),
      rho_K = unname(fit$corpars$relmat[[1L]]),
      sigma1 = stats::sigma(fit)$sigma1[[1L]],
      sigma2 = stats::sigma(fit)$sigma2[[1L]],
      rho12 = drmTMB::rho12(fit)[[1L]]
    )
  }
  structured_boundary <- any(
    estimate[c("tau1", "tau2")] < 1e-5,
    abs(estimate[["rho_K"]]) >= 0.98,
    na.rm = TRUE
  )
  base <- data.frame(
    cell_id = row$cell_id,
    cell_number = row$cell_number,
    g = row$g,
    m = row$m,
    replicate = row$replicate,
    seed = row$seed,
    K_digest = arc1b_s2r_K_digest(K),
    elapsed = elapsed,
    fit_success = !is.null(fit),
    convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
    pdHess = if (is.null(fit)) FALSE else isTRUE(fit$sdr$pdHess),
    max_gradient = max_gradient,
    structured_boundary = structured_boundary,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    error = error,
    stringsAsFactors = FALSE
  )
  cbind(
    base,
    as.data.frame(as.list(setNames(truth, paste0("truth_", names(truth))))),
    as.data.frame(as.list(setNames(estimate, paste0("estimate_", names(estimate)))))
  )
}

arc1b_s2r_bootstrap_rmse <- function(
  errors,
  cell_number,
  parameter_number,
  n_boot = 2000L
) {
  if (length(errors) < 2L) {
    return(rep(NA_real_, n_boot))
  }
  set.seed(2026071599L + 1000L * cell_number + parameter_number)
  replicate(
    n_boot,
    sqrt(mean(sample(errors, length(errors), replace = TRUE)^2))
  )
}

arc1b_s2r_bootstrap_rmse_mcse <- function(...) {
  stats::sd(arc1b_s2r_bootstrap_rmse(...), na.rm = TRUE)
}

arc1b_s2r_recovery_summary <- function(raw) {
  parameters <- c(
    "beta1_intercept", "beta1_x1", "beta2_intercept", "beta2_x2",
    "tau1", "tau2", "rho_K", "sigma1", "sigma2", "rho12"
  )
  cells <- unique(raw[c("cell_id", "cell_number", "g", "m")])
  out <- lapply(seq_len(nrow(cells)), function(i) {
    cell <- cells[i, , drop = FALSE]
    rows <- raw[raw$cell_id == cell$cell_id, , drop = FALSE]
    do.call(rbind, lapply(seq_along(parameters), function(parameter_number) {
      parameter <- parameters[[parameter_number]]
      truth <- rows[[paste0("truth_", parameter)]]
      estimate <- rows[[paste0("estimate_", parameter)]]
      usable <- rows$convergence == 0L & is.finite(estimate)
      usable[is.na(usable)] <- FALSE
      errors <- estimate[usable] - truth[usable]
      attempted <- nrow(rows)
      data.frame(
        cell_id = cell$cell_id,
        cell_number = cell$cell_number,
        g = cell$g,
        m = cell$m,
        parameter = parameter,
        attempted = attempted,
        usable = sum(usable),
        fit_success = sum(rows$fit_success),
        converged = sum(rows$convergence == 0L, na.rm = TRUE),
        pdHess = sum(rows$pdHess, na.rm = TRUE),
        boundary = sum(rows$structured_boundary, na.rm = TRUE),
        fit_success_rate = sum(rows$fit_success) / attempted,
        convergence_rate = sum(rows$convergence == 0L, na.rm = TRUE) / attempted,
        pdHess_rate = sum(rows$pdHess, na.rm = TRUE) / attempted,
        boundary_rate = sum(rows$structured_boundary, na.rm = TRUE) / attempted,
        mcse_convergence_rate = sqrt(
          (sum(rows$convergence == 0L, na.rm = TRUE) / attempted) *
            (1 - sum(rows$convergence == 0L, na.rm = TRUE) / attempted) /
            attempted
        ),
        mcse_pdHess_rate = sqrt(
          (sum(rows$pdHess, na.rm = TRUE) / attempted) *
            (1 - sum(rows$pdHess, na.rm = TRUE) / attempted) /
            attempted
        ),
        mcse_boundary_rate = sqrt(
          (sum(rows$structured_boundary, na.rm = TRUE) / attempted) *
            (1 - sum(rows$structured_boundary, na.rm = TRUE) / attempted) /
            attempted
        ),
        elapsed_median = stats::median(rows$elapsed),
        elapsed_p90 = unname(stats::quantile(rows$elapsed, 0.90)),
        bias = if (length(errors)) mean(errors) else NA_real_,
        rmse = if (length(errors)) sqrt(mean(errors^2)) else NA_real_,
        mcse_bias = if (length(errors) > 1L) {
          stats::sd(errors) / sqrt(length(errors))
        } else {
          NA_real_
        },
        mcse_rmse = arc1b_s2r_bootstrap_rmse_mcse(
          errors,
          cell_number = cell$cell_number,
          parameter_number = parameter_number
        ),
        stringsAsFactors = FALSE
      )
    }))
  })
  do.call(rbind, out)
}

arc1b_s2r_rmse_difference <- function(raw) {
  parameters <- c("tau1", "tau2", "rho_K")
  parameter_numbers <- match(
    parameters,
    c(
      "beta1_intercept", "beta1_x1", "beta2_intercept", "beta2_x2",
      "tau1", "tau2", "rho_K", "sigma1", "sigma2", "rho12"
    )
  )
  do.call(rbind, lapply(seq_along(parameters), function(i) {
    parameter <- parameters[[i]]
    extract_errors <- function(g) {
      rows <- raw[raw$g == g & raw$m == 6L, , drop = FALSE]
      estimate <- rows[[paste0("estimate_", parameter)]]
      truth <- rows[[paste0("truth_", parameter)]]
      usable <- rows$convergence == 0L & is.finite(estimate)
      usable[is.na(usable)] <- FALSE
      estimate[usable] - truth[usable]
    }
    errors32 <- extract_errors(32L)
    errors64 <- extract_errors(64L)
    cell32 <- unique(raw$cell_number[raw$g == 32L & raw$m == 6L])
    cell64 <- unique(raw$cell_number[raw$g == 64L & raw$m == 6L])
    stopifnot(length(cell32) == 1L, length(cell64) == 1L)
    boot32 <- arc1b_s2r_bootstrap_rmse(
      errors32, cell32, parameter_numbers[[i]]
    )
    boot64 <- arc1b_s2r_bootstrap_rmse(
      errors64, cell64, parameter_numbers[[i]]
    )
    rmse32 <- if (length(errors32)) sqrt(mean(errors32^2)) else NA_real_
    rmse64 <- if (length(errors64)) sqrt(mean(errors64^2)) else NA_real_
    data.frame(
      parameter = parameter,
      n32 = length(errors32),
      n64 = length(errors64),
      rmse32 = rmse32,
      rmse64 = rmse64,
      delta = rmse64 - rmse32,
      se_delta = stats::sd(boot64 - boot32, na.rm = TRUE),
      pass = rmse64 <= rmse32 + stats::sd(boot64 - boot32, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
}

arc1b_s2r_gate_summary <- function(raw, summary, rmse_difference) {
  key <- paste(raw$cell_id, raw$replicate, raw$seed, sep = ":")
  high <- unique(summary[
    summary$g >= 32L & summary$m == 6L,
    c("cell_id", "attempted", "convergence_rate", "pdHess_rate")
  ])
  target <- summary[
    summary$g == 64L & summary$m == 6L &
      summary$parameter %in% c("tau1", "tau2", "rho_K"),
    c("parameter", "usable", "bias")
  ]
  target$limit <- ifelse(target$parameter == "rho_K", 0.12, 0.10)
  rows <- list(
    data.frame(
      gate = "attempt_rows",
      scope = "campaign",
      observed = nrow(raw),
      threshold = "exactly 2400",
      pass = nrow(raw) == 2400L,
      stringsAsFactors = FALSE
    ),
    data.frame(
      gate = "unique_attempt_keys",
      scope = "campaign",
      observed = length(unique(key)),
      threshold = "exactly 2400",
      pass = length(unique(key)) == 2400L && !anyDuplicated(key),
      stringsAsFactors = FALSE
    )
  )
  for (i in seq_len(nrow(high))) {
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "convergence_rate",
      scope = high$cell_id[[i]],
      observed = high$convergence_rate[[i]],
      threshold = ">= 0.95",
      pass = high$attempted[[i]] == 400L &&
        high$convergence_rate[[i]] >= 0.95,
      stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "pdHess_rate",
      scope = high$cell_id[[i]],
      observed = high$pdHess_rate[[i]],
      threshold = ">= 0.90",
      pass = high$attempted[[i]] == 400L && high$pdHess_rate[[i]] >= 0.90,
      stringsAsFactors = FALSE
    )
  }
  for (i in seq_len(nrow(target))) {
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "absolute_bias",
      scope = paste0("g64_m06:", target$parameter[[i]]),
      observed = abs(target$bias[[i]]),
      threshold = paste0("<= ", format(target$limit[[i]], nsmall = 2L)),
      pass = target$usable[[i]] > 0L &&
        abs(target$bias[[i]]) <= target$limit[[i]],
      stringsAsFactors = FALSE
    )
  }
  for (i in seq_len(nrow(rmse_difference))) {
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "rmse_nonincrease",
      scope = paste0("m06:", rmse_difference$parameter[[i]]),
      observed = rmse_difference$delta[[i]],
      threshold = paste0(
        "delta <= SE_delta (", format(rmse_difference$se_delta[[i]], digits = 8L),
        ")"
      ),
      pass = isTRUE(rmse_difference$pass[[i]]),
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, rows)
  out$status <- ifelse(out$pass, "PASS", "HOLD")
  out
}

run_arc1b_s2r_recovery <- function(args = parse_arc1b_s2r_args()) {
  dir.create(args$out_dir, recursive = TRUE, showWarnings = FALSE)
  grid <- arc1b_s2r_recovery_grid(args$n_rep, args$master_seed)
  rows <- split(grid, seq_len(nrow(grid)))
  worker <- function(row) {
    arc1b_s2r_recovery_attempt(row[1L, , drop = FALSE])
  }
  results <- if (args$cores == 1L || .Platform$OS.type == "windows") {
    lapply(rows, worker)
  } else {
    parallel::mclapply(
      rows,
      worker,
      mc.cores = args$cores,
      mc.preschedule = FALSE
    )
  }
  raw <- do.call(rbind, results)
  summary <- arc1b_s2r_recovery_summary(raw)
  rmse_difference <- arc1b_s2r_rmse_difference(raw)
  gates <- arc1b_s2r_gate_summary(raw, summary, rmse_difference)
  failures <- raw[
    !raw$fit_success | raw$convergence != 0L | !raw$pdHess |
      raw$structured_boundary | raw$warning_count > 0L,
    , drop = FALSE
  ]
  matrix_digests <- do.call(rbind, lapply(c(16L, 32L, 64L), function(g) {
    data.frame(g = g, K_digest = arc1b_s2r_K_digest(arc1b_s2r_recovery_K(g)))
  }))
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
  utils::write.table(
    rmse_difference,
    file.path(args$out_dir, "rmse-difference.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  utils::write.table(
    gates,
    file.path(args$out_dir, "gates.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  utils::write.table(
    failures,
    file.path(args$out_dir, "failure-ledger.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  utils::write.table(
    matrix_digests,
    file.path(args$out_dir, "matrix-digests.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE, na = "NA"
  )
  writeLines(
    capture.output(sessionInfo()),
    file.path(args$out_dir, "session-info.txt")
  )
  invisible(list(
    grid = grid,
    raw = raw,
    summary = summary,
    rmse_difference = rmse_difference,
    gates = gates,
    failures = failures,
    matrix_digests = matrix_digests
  ))
}

if (sys.nframe() == 0L) {
  run_arc1b_s2r_recovery()
}
