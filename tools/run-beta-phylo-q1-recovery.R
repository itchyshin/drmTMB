#!/usr/bin/env Rscript

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    mode = "smoke",
    reps = NULL,
    cores = 1L,
    output = NULL,
    seed = NULL,
    m = NULL
  )
  for (arg in args) {
    if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--reps=")) {
      out$reps <- as.integer(sub("^--reps=", "", arg))
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--seed=")) {
      out$seed <- as.integer(sub("^--seed=", "", arg))
    } else if (startsWith(arg, "--m=")) {
      out$m <- as.integer(sub("^--m=", "", arg))
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  out$mode <- match.arg(
    out$mode,
    c("smoke", "pilot", "certification", "addendum", "diagnostic")
  )
  defaults <- switch(
    out$mode,
    smoke = list(reps = 1L, m = 2L, seed = 2026071601L),
    pilot = list(reps = 10L, m = 2L, seed = 2026071601L),
    certification = list(reps = 400L, m = 2L, seed = 2026071601L),
    addendum = list(reps = 400L, m = 4L, seed = 2026071602L),
    diagnostic = list(reps = 1L, m = 2L, seed = 2026071601L)
  )
  out$reps <- out$reps %||% defaults$reps
  out$m <- out$m %||% defaults$m
  out$seed <- out$seed %||% defaults$seed
  if (
    anyNA(c(out$reps, out$cores, out$seed, out$m)) ||
      out$reps < 1L ||
      out$cores < 1L ||
      out$cores > 32L ||
      out$m < 1L
  ) {
    stop(
      "`reps`, `m`, `cores`, and `seed` must be valid; cores must be 1 through 32.",
      call. = FALSE
    )
  }
  if (
    identical(out$mode, "certification") &&
      (!identical(out$reps, 400L) || !identical(out$m, 2L))
  ) {
    stop(
      "Certification is frozen at 400 replicates per cell and m=2.",
      call. = FALSE
    )
  }
  if (
    identical(out$mode, "addendum") &&
      (!identical(out$reps, 400L) || !identical(out$m, 4L))
  ) {
    stop(
      "Addendum mode is frozen at 400 replicates per cell and m=4.",
      call. = FALSE
    )
  }
  out
}

`%||%` <- function(x, y) if (is.null(x)) y else x

recovery_grid <- function(reps, seed, m) {
  cells <- data.frame(g = c(64L, 256L, 1024L), m = m)
  cells$cell_number <- seq_len(nrow(cells))
  cells$cell_id <- sprintf("g%04d_m%02d", cells$g, cells$m)
  grid <- merge(
    cells,
    data.frame(replicate = seq_len(reps)),
    by = NULL,
    sort = FALSE
  )
  grid$seed <- as.integer(seed + 100000L * grid$cell_number + grid$replicate)
  grid[order(grid$cell_number, grid$replicate), , drop = FALSE]
}

beta_phylo_dgp <- function(g, m, seed) {
  set.seed(seed)
  truth <- c(
    beta_mu_intercept = 0,
    beta_mu_x = 0.35,
    beta_sigma_intercept = log(0.25),
    beta_sigma_x = 0.20,
    log_tau = log(0.30)
  )
  tree <- ape::rcoal(g)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  effect <- as.vector(exp(truth[["log_tau"]]) * t(chol(A)) %*% stats::rnorm(g))
  names(effect) <- tree$tip.label
  spp_id <- factor(rep(tree$tip.label, each = m), levels = tree$tip.label)
  x <- as.numeric(scale(stats::rnorm(length(spp_id))))
  eta_mu <- truth[["beta_mu_intercept"]] +
    truth[["beta_mu_x"]] * x +
    effect[as.character(spp_id)]
  log_sigma <- truth[["beta_sigma_intercept"]] + truth[["beta_sigma_x"]] * x
  mu <- stats::plogis(eta_mu)
  phi <- exp(-2 * log_sigma)
  list(
    data = data.frame(
      y = stats::rbeta(length(mu), mu * phi, (1 - mu) * phi),
      x,
      spp_id
    ),
    tree = tree,
    truth = truth
  )
}

clean_text <- function(x) {
  x <- paste(as.character(x), collapse = " | ")
  trimws(gsub("[\r\n\t]+", " ", x))
}

recovery_attempt <- function(row) {
  started <- proc.time()[["elapsed"]]
  generated <- beta_phylo_dgp(row$g, row$m, row$seed)
  tree <- generated$tree
  warnings <- character()
  error <- NA_character_
  fit <- tryCatch(
    withCallingHandlers(
      drmTMB::drmTMB(
        drmTMB::bf(y ~ x + drmTMB::phylo(1 | spp_id, tree = tree), sigma ~ x),
        family = drmTMB::beta(),
        data = generated$data,
        control = drmTMB::drm_control(optimizer_preset = "robust")
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      error <<- clean_text(conditionMessage(e))
      NULL
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  estimate <- c(
    beta_mu_intercept = NA_real_,
    beta_mu_x = NA_real_,
    beta_sigma_intercept = NA_real_,
    beta_sigma_x = NA_real_,
    log_tau = NA_real_
  )
  gradient <- numeric()
  if (!is.null(fit)) {
    estimate <- c(
      beta_mu_intercept = fit$par$mu[[1L]],
      beta_mu_x = fit$par$mu[[2L]],
      beta_sigma_intercept = fit$par$sigma[[1L]],
      beta_sigma_x = fit$par$sigma[[2L]],
      log_tau = log(fit$sdpars$mu[[1L]])
    )
    gradient <- tryCatch(
      as.numeric(fit$sdr$gradient.fixed),
      error = function(e) numeric()
    )
    if (!length(gradient) || any(!is.finite(gradient))) {
      gradient <- tryCatch(
        as.numeric(fit$obj$gr(fit$opt$par)),
        error = function(e) numeric()
      )
    }
  }
  base <- data.frame(
    cell_id = row$cell_id,
    cell_number = row$cell_number,
    g = row$g,
    m = row$m,
    replicate = row$replicate,
    seed = row$seed,
    elapsed = elapsed,
    fit_success = !is.null(fit),
    convergence = if (is.null(fit)) NA_integer_ else fit$opt$convergence,
    pdHess = if (is.null(fit)) FALSE else isTRUE(fit$sdr$pdHess),
    max_gradient = if (length(gradient) && all(is.finite(gradient))) {
      max(abs(gradient))
    } else {
      NA_real_
    },
    boundary = if (is.null(fit)) FALSE else isTRUE(fit$sdpars$mu[[1L]] < 1e-5),
    warning_count = length(warnings),
    warnings = clean_text(warnings),
    error = error,
    stringsAsFactors = FALSE
  )
  cbind(
    base,
    as.data.frame(as.list(setNames(
      generated$truth,
      paste0("truth_", names(generated$truth))
    ))),
    as.data.frame(as.list(setNames(
      estimate,
      paste0("estimate_", names(estimate))
    )))
  )
}

summarize_recovery <- function(raw) {
  parameters <- c(
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_x",
    "log_tau"
  )
  cells <- unique(raw[c("cell_id", "cell_number", "g", "m")])
  do.call(
    rbind,
    lapply(seq_len(nrow(cells)), function(i) {
      do.call(
        rbind,
        lapply(parameters, function(parameter) {
          rows <- raw[raw$cell_id == cells$cell_id[[i]], , drop = FALSE]
          estimate <- rows[[paste0("estimate_", parameter)]]
          truth <- rows[[paste0("truth_", parameter)]]
          usable <- rows$convergence == 0L & is.finite(estimate)
          usable[is.na(usable)] <- FALSE
          error <- estimate[usable] - truth[usable]
          data.frame(
            cells[i, , drop = FALSE],
            parameter = parameter,
            attempted = nrow(rows),
            usable = sum(usable),
            convergence_rate = sum(rows$convergence == 0L, na.rm = TRUE) /
              nrow(rows),
            pdHess_rate = sum(rows$pdHess, na.rm = TRUE) / nrow(rows),
            boundary_rate = sum(rows$boundary, na.rm = TRUE) / nrow(rows),
            bias = if (length(error)) mean(error) else NA_real_,
            rmse = if (length(error)) sqrt(mean(error^2)) else NA_real_,
            mcse_bias = if (length(error) > 1L) {
              stats::sd(error) / sqrt(length(error))
            } else {
              NA_real_
            },
            stringsAsFactors = FALSE
          )
        })
      )
    })
  )
}

gate_summary <- function(raw, summary, reps) {
  high <- summary[summary$g >= 256L, , drop = FALSE]
  slope <- high[
    high$parameter %in% c("beta_mu_x", "beta_sigma_x", "log_tau"),
    ,
    drop = FALSE
  ]
  slope$limit <- 0.10
  key <- paste(raw$cell_id, raw$replicate, raw$seed, sep = ":")
  rows <- list(
    data.frame(
      gate = "attempt_rows",
      scope = "campaign",
      observed = nrow(raw),
      threshold = paste0("exactly ", 3L * reps),
      pass = nrow(raw) == 3L * reps
    ),
    data.frame(
      gate = "unique_attempt_keys",
      scope = "campaign",
      observed = length(unique(key)),
      threshold = paste0("exactly ", 3L * reps),
      pass = !anyDuplicated(key) && length(unique(key)) == 3L * reps
    )
  )
  for (cell in unique(high$cell_id)) {
    x <- high[high$cell_id == cell, , drop = FALSE][1L, ]
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "convergence_rate",
      scope = cell,
      observed = x$convergence_rate,
      threshold = ">= 0.95",
      pass = x$attempted == reps && x$convergence_rate >= 0.95
    )
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "pdHess_rate",
      scope = cell,
      observed = x$pdHess_rate,
      threshold = ">= 0.90",
      pass = x$attempted == reps && x$pdHess_rate >= 0.90
    )
  }
  for (i in seq_len(nrow(slope))) {
    rows[[length(rows) + 1L]] <- data.frame(
      gate = "absolute_bias",
      scope = paste0(slope$cell_id[[i]], ":", slope$parameter[[i]]),
      observed = abs(slope$bias[[i]]),
      threshold = "<= 0.10",
      pass = slope$usable[[i]] > 0L && abs(slope$bias[[i]]) <= slope$limit[[i]]
    )
  }
  out <- do.call(rbind, rows)
  out$status <- ifelse(out$pass, "PASS", "HOLD")
  out
}

rmse_difference <- function(raw) {
  parameters <- c(
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "beta_sigma_x",
    "log_tau"
  )
  do.call(
    rbind,
    lapply(seq_along(parameters), function(i) {
      parameter <- parameters[[i]]
      errors <- function(g) {
        rows <- raw[raw$g == g, , drop = FALSE]
        estimate <- rows[[paste0("estimate_", parameter)]]
        truth <- rows[[paste0("truth_", parameter)]]
        usable <- rows$convergence == 0L & is.finite(estimate)
        usable[is.na(usable)] <- FALSE
        estimate[usable] - truth[usable]
      }
      error256 <- errors(256L)
      error1024 <- errors(1024L)
      rmse256 <- if (length(error256)) sqrt(mean(error256^2)) else NA_real_
      rmse1024 <- if (length(error1024)) sqrt(mean(error1024^2)) else NA_real_
      set.seed(2026071690L + i)
      boot256 <- if (length(error256) > 1L) {
        replicate(
          1000L,
          sqrt(mean(sample(error256, length(error256), replace = TRUE)^2))
        )
      } else {
        NA_real_
      }
      boot1024 <- if (length(error1024) > 1L) {
        replicate(
          1000L,
          sqrt(mean(sample(error1024, length(error1024), replace = TRUE)^2))
        )
      } else {
        NA_real_
      }
      se_delta <- stats::sd(boot1024 - boot256, na.rm = TRUE)
      data.frame(
        parameter = parameter,
        n256 = length(error256),
        n1024 = length(error1024),
        rmse256 = rmse256,
        rmse1024 = rmse1024,
        delta = rmse1024 - rmse256,
        se_delta = se_delta,
        pass = is.finite(se_delta) && rmse1024 <= rmse256 + se_delta
      )
    })
  )
}

run_recovery <- function(args = parse_args()) {
  if (!requireNamespace("ape", quietly = TRUE)) {
    stop("Package `ape` is required.", call. = FALSE)
  }
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop(
      "Package `devtools` is required for a source recovery run.",
      call. = FALSE
    )
  }
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_path <- if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    "tools/run-beta-phylo-q1-recovery.R"
  }
  repo_root <- normalizePath(
    file.path(dirname(script_path), ".."),
    mustWork = TRUE
  )
  devtools::load_all(repo_root, quiet = TRUE)
  grid <- recovery_grid(args$reps, args$seed, args$m)
  rows <- split(grid, seq_len(nrow(grid)))
  worker <- function(x) recovery_attempt(x[1L, , drop = FALSE])
  result <- if (args$cores == 1L || .Platform$OS.type == "windows") {
    lapply(rows, worker)
  } else {
    parallel::mclapply(
      rows,
      worker,
      mc.cores = args$cores,
      mc.preschedule = FALSE
    )
  }
  raw <- do.call(rbind, result)
  summary <- summarize_recovery(raw)
  gates <- gate_summary(raw, summary, args$reps)
  rmse <- rmse_difference(raw)
  rmse_gates <- data.frame(
    gate = "rmse_nonincrease",
    scope = rmse$parameter,
    observed = rmse$delta,
    threshold = paste0(
      "delta <= MCSE (",
      format(rmse$se_delta, digits = 5L),
      ")"
    ),
    pass = rmse$pass,
    status = ifelse(rmse$pass, "PASS", "HOLD")
  )
  gates <- rbind(gates, rmse_gates)
  out_dir <- args$output %||%
    file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery"
    )
  if (dir.exists(out_dir) && length(list.files(out_dir, all.files = FALSE))) {
    stop(
      "Refusing to overwrite nonempty output directory: ",
      out_dir,
      call. = FALSE
    )
  }
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    grid,
    file.path(out_dir, "design.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    raw,
    file.path(out_dir, "raw-attempts.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    summary,
    file.path(out_dir, "summary.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    gates,
    file.path(out_dir, "gates.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  utils::write.table(
    rmse,
    file.path(out_dir, "rmse-difference.tsv"),
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = "NA"
  )
  writeLines(
    capture.output(sessionInfo()),
    file.path(out_dir, "session-info.txt")
  )
  invisible(list(raw = raw, summary = summary, gates = gates, rmse = rmse))
}

if (sys.nframe() == 0L) {
  run_recovery()
}
