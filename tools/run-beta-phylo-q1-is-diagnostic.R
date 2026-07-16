#!/usr/bin/env Rscript

`%||%` <- function(x, y) if (is.null(x)) y else x

diagnostic_context <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_path <- if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    "tools/run-beta-phylo-q1-is-diagnostic.R"
  }
  script_path <- normalizePath(script_path, mustWork = TRUE)
  list(
    script_path = script_path,
    repo_root = normalizePath(
      file.path(dirname(script_path), ".."),
      mustWork = TRUE
    )
  )
}

diagnostic_load_helpers <- function(repo_root) {
  env <- new.env(parent = globalenv())
  sys.source(
    file.path(repo_root, "tools", "run-beta-phylo-q1-successor-recovery.R"),
    envir = env
  )
  env
}

parse_diagnostic_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  out <- list(
    mode = "screen",
    output = NULL,
    screen_output = NULL,
    cores = 1L,
    resume = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--screen-output=")) {
      out$screen_output <- sub("^--screen-output=", "", arg)
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (identical(arg, "--resume")) {
      out$resume <- TRUE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!out$mode %in% c("design", "screen", "profile")) {
    stop("`mode` must be design, screen, or profile.", call. = FALSE)
  }
  if (is.na(out$cores) || out$cores < 1L || out$cores > 24L) {
    stop("`cores` must be an integer from 1 through 24.", call. = FALSE)
  }
  out
}

diagnostic_seed_design <- function(repo_root, n_datasets = 24L) {
  path <- file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr1-disjoint-repair",
    "design.tsv"
  )
  design <- utils::read.delim(path, stringsAsFactors = FALSE)
  block <- design[design$g == 256L & design$m == 4L, , drop = FALSE]
  block <- block[order(block$replicate), , drop = FALSE]
  if (nrow(block) < n_datasets) {
    stop(
      "Frozen repair design has fewer than the required diagnostic rows.",
      call. = FALSE
    )
  }
  out <- block[seq_len(n_datasets), , drop = FALSE]
  out$diagnostic_role <- ifelse(out$replicate <= 5L, "D0_screen", "D1_only")
  rownames(out) <- NULL
  out
}

frozen_diagnostic_design_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr1-is-diagnostic",
    "design.tsv"
  )
}

assert_frozen_diagnostic_design <- function(repo_root) {
  path <- frozen_diagnostic_design_path(repo_root)
  if (!file.exists(path)) {
    stop("Frozen diagnostic design is missing: ", path, call. = FALSE)
  }
  observed <- utils::read.delim(path, stringsAsFactors = FALSE)
  expected <- diagnostic_seed_design(repo_root)
  if (!identical(observed, expected)) {
    stop(
      "Frozen diagnostic design does not match the first 24 repair rows.",
      call. = FALSE
    )
  }
  expected_hash <- "fefc3ca7cd143f946cbd68d2a99ddfab56ad2acb5001659911d393bb6dbdce6f"
  helper <- diagnostic_load_helpers(repo_root)
  if (!identical(helper$successor_sha256(path), expected_hash)) {
    stop("Frozen diagnostic design SHA-256 mismatch.", call. = FALSE)
  }
  invisible(TRUE)
}

diagnostic_seed_audit <- function(design, repo_root) {
  prior_paths <- diagnostic_load_helpers(repo_root)$prior_design_paths(
    repo_root
  )
  fitted_names <- c(
    "original_m2",
    "prior_m4_nonindependent",
    "repair_smoke",
    "repair_pilot"
  )
  prior <- lapply(prior_paths[fitted_names], function(path) {
    utils::read.delim(path, stringsAsFactors = FALSE)$seed
  })
  repair <- utils::read.delim(
    prior_paths[["repair_design"]],
    stringsAsFactors = FALSE
  )$seed
  audit <- rbind(
    data.frame(
      check = c("unique_diagnostic_seeds", "D0_rows", "D1_rows"),
      observed = c(
        length(unique(design$seed)),
        sum(design$diagnostic_role == "D0_screen"),
        nrow(design)
      ),
      expected = c(24L, 5L, 24L)
    ),
    do.call(
      rbind,
      lapply(names(prior), function(name) {
        data.frame(
          check = paste0("overlap_", name),
          observed = length(intersect(design$seed, prior[[name]])),
          expected = 0L
        )
      })
    ),
    data.frame(
      check = "membership_unrun_repair_design",
      observed = sum(design$seed %in% repair),
      expected = 24L
    )
  )
  audit$pass <- audit$observed == audit$expected
  if (!all(audit$pass)) {
    stop(
      "Diagnostic seed audit failed: ",
      paste(audit$check[!audit$pass], collapse = ", "),
      call. = FALSE
    )
  }
  audit
}

diagnostic_mc_grid <- function(dataset_replicate) {
  data.frame(
    n = c(2048L, 8192L, 32768L, 32768L),
    batch = c("A", "A", "A", "B"),
    mc_seed = c(
      2026071650L + 100L * dataset_replicate + 1L,
      2026071650L + 100L * dataset_replicate + 2L,
      2026071650L + 100L * dataset_replicate + 3L,
      2026072650L + 100L * dataset_replicate + 3L
    ),
    stringsAsFactors = FALSE
  )
}

importance_weight_stats <- function(nlratio) {
  if (
    !length(nlratio) ||
      length(nlratio) %% 2L != 0L ||
      any(!is.finite(nlratio))
  ) {
    return(c(ess = NA_real_, max_weight = NA_real_))
  }
  log_weight <- -as.numeric(nlratio)
  n <- length(log_weight) %/% 2L
  maximum <- pmax(log_weight[seq_len(n)], log_weight[n + seq_len(n)])
  pair_log_weight <- maximum +
    log(
      exp(log_weight[seq_len(n)] - maximum) +
        exp(log_weight[n + seq_len(n)] - maximum)
    ) -
    log(2)
  weight <- exp(pair_log_weight - max(pair_log_weight))
  normalized <- weight / sum(weight)
  c(
    ess = 1 / sum(normalized^2),
    max_weight = max(normalized)
  )
}

pin_full_parameter <- function(fit) {
  fit$obj$fn(fit$opt$par)
  full <- fit$obj$env$last.par
  fixed <- fit$obj$env$lfixed()
  if (!is.logical(fixed) || sum(fixed) != length(fit$opt$par)) {
    stop(
      "Could not map fixed parameters into TMB's full parameter vector.",
      call. = FALSE
    )
  }
  full[fixed] <- fit$opt$par
  full
}

fit_diagnostic_dataset <- function(row, base) {
  generated <- base$with_repair_rng(
    base$beta_phylo_dgp(g = row$g, m = row$m, seed = row$seed)
  )
  tree <- generated$tree
  warnings <- character()
  fit <- withCallingHandlers(
    drmTMB::drmTMB(
      drmTMB::bf(
        y ~ x + drmTMB::phylo(1 | spp_id, tree = tree),
        sigma ~ x
      ),
      family = drmTMB::beta(),
      data = generated$data,
      control = drmTMB::drm_control(optimizer_preset = "robust")
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, truth = generated$truth, warnings = warnings)
}

one_is_diagnostic <- function(fit, spec, base) {
  fixed_names <- names(fit$opt$par)
  tau_index <- which(fixed_names == "log_sd_phylo")
  if (length(tau_index) != 1L) {
    stop("Expected exactly one fixed `log_sd_phylo` parameter.", call. = FALSE)
  }
  full <- pin_full_parameter(fit)
  hessian <- stats::optimHess(fit$opt$par, fit$obj$fn, fit$obj$gr)
  if (!all(is.finite(hessian)) || nrow(hessian) != length(fit$opt$par)) {
    stop("Laplace fixed-parameter Hessian is unavailable.", call. = FALSE)
  }
  full <- pin_full_parameter(fit)
  eigenvalues <- eigen(hessian, symmetric = TRUE, only.values = TRUE)$values
  corrected_nll <- base$with_repair_rng(
    fit$obj$env$MC(
      par = full,
      par0 = full,
      n = spec$n,
      seed = spec$mc_seed,
      antithetic = TRUE,
      keep = TRUE,
      order = 0
    )
  )
  nlratio <- attr(corrected_nll, "nlratio")
  if (length(nlratio) != 2L * spec$n) {
    stop(
      "TMB importance sampler returned an unexpected draw count.",
      call. = FALSE
    )
  }
  weight <- importance_weight_stats(nlratio)
  corrected_score <- base$with_repair_rng(
    fit$obj$env$MC(
      par = full,
      par0 = full,
      n = spec$n,
      seed = spec$mc_seed,
      antithetic = TRUE,
      order = 1
    )
  )
  implied_shift <- tryCatch(
    -as.numeric(solve(hessian, corrected_score)),
    error = function(e) rep(NA_real_, length(corrected_score))
  )
  data.frame(
    n = spec$n,
    total_draws = 2L * spec$n,
    batch = spec$batch,
    mc_seed = spec$mc_seed,
    corrected_nll = as.numeric(corrected_nll),
    ess = unname(weight[["ess"]]),
    max_weight = unname(weight[["max_weight"]]),
    log_tau_score = corrected_score[[tau_index]],
    implied_log_tau_shift = implied_shift[[tau_index]],
    all_score_finite = all(is.finite(corrected_score)),
    hessian_pd = all(eigenvalues > 0),
    hessian_condition = max(eigenvalues) / min(eigenvalues),
    stringsAsFactors = FALSE
  )
}

screen_dataset <- function(row, base) {
  started <- proc.time()[["elapsed"]]
  fitted <- fit_diagnostic_dataset(row, base)
  fit <- fitted$fit
  grid <- diagnostic_mc_grid(row$replicate)
  result <- do.call(
    rbind,
    lapply(seq_len(nrow(grid)), function(i) {
      one_is_diagnostic(fit, grid[i, , drop = FALSE], base)
    })
  )
  result$cell_id <- row$cell_id
  result$g <- row$g
  result$m <- row$m
  result$replicate <- row$replicate
  result$dgp_seed <- row$seed
  result$laplace_log_tau <- log(fit$sdpars$mu[[1L]])
  result$truth_log_tau <- fitted$truth[["log_tau"]]
  result$convergence <- fit$opt$convergence
  result$pdHess <- isTRUE(fit$sdr$pdHess)
  result$warning_count <- length(fitted$warnings)
  result$elapsed_dataset <- proc.time()[["elapsed"]] - started
  result
}

diagnostic_screen_gates <- function(raw) {
  required <- c(
    "replicate",
    "n",
    "batch",
    "corrected_nll",
    "ess",
    "max_weight",
    "log_tau_score",
    "implied_log_tau_shift",
    "all_score_finite",
    "hessian_pd",
    "hessian_condition",
    "convergence",
    "pdHess"
  )
  if (!all(required %in% names(raw))) {
    stop("Malformed diagnostic results.", call. = FALSE)
  }
  rows <- lapply(sort(unique(raw$replicate)), function(replicate) {
    x <- raw[raw$replicate == replicate, , drop = FALSE]
    max_rows <- x[x$n == 32768L, , drop = FALSE]
    mid <- x[x$n == 8192L & x$batch == "A", , drop = FALSE]
    max_a <- x[x$n == 32768L & x$batch == "A", , drop = FALSE]
    finite <- all(is.finite(x$corrected_nll)) &&
      all(is.finite(x$log_tau_score)) &&
      all(is.finite(x$implied_log_tau_shift)) &&
      all(x$all_score_finite %in% TRUE) &&
      all(x$hessian_pd %in% TRUE) &&
      all(is.finite(x$hessian_condition)) &&
      all(x$hessian_condition <= 1e10) &&
      all(!is.na(x$convergence) & x$convergence == 0L) &&
      all(x$pdHess %in% TRUE)
    ess_pass <- nrow(max_rows) == 2L &&
      all(is.finite(max_rows$ess)) &&
      all(max_rows$ess >= 1000)
    weight_pass <- nrow(max_rows) == 2L &&
      all(is.finite(max_rows$max_weight)) &&
      all(max_rows$max_weight <= 0.01)
    batch_difference <- if (nrow(max_rows) == 2L) {
      abs(diff(max_rows$implied_log_tau_shift))
    } else {
      NA_real_
    }
    stable_batch <- is.finite(batch_difference) && batch_difference <= 0.05
    stable_sign <- nrow(mid) == 1L &&
      nrow(max_a) == 1L &&
      sign(mid$implied_log_tau_shift) == sign(max_a$implied_log_tau_shift)
    data.frame(
      replicate = replicate,
      finite = finite,
      ess_pass = ess_pass,
      weight_pass = weight_pass,
      batch_difference = batch_difference,
      stable_batch = stable_batch,
      stable_sign = stable_sign,
      pass = isTRUE(finite) &&
        isTRUE(ess_pass) &&
        isTRUE(weight_pass) &&
        isTRUE(stable_batch) &&
        isTRUE(stable_sign)
    )
  })
  gates <- do.call(rbind, rows)
  list(
    gates = gates,
    decision = data.frame(
      status = if (nrow(gates) == 5L && all(gates$pass %in% TRUE)) {
        "PASS_TO_D1"
      } else {
        "INCONCLUSIVE"
      },
      datasets = nrow(gates),
      datasets_passing = sum(gates$pass %in% TRUE)
    )
  )
}

diagnostic_profile_spec <- function(dataset_replicate) {
  data.frame(
    batch = c("A", "B"),
    n = c(8192L, 8192L),
    mc_seed = c(
      2026073650L + 100L * dataset_replicate,
      2026074650L + 100L * dataset_replicate
    ),
    stringsAsFactors = FALSE
  )
}

pin_full_at <- function(fit, fixed_parameter) {
  fit$obj$fn(fixed_parameter)
  full <- fit$obj$env$last.par
  fixed <- fit$obj$env$lfixed()
  if (!is.logical(fixed) || sum(fixed) != length(fixed_parameter)) {
    stop("Could not pin a fixed profile parameter vector.", call. = FALSE)
  }
  full[fixed] <- fixed_parameter
  full
}

corrected_evaluation <- function(
  fit,
  fixed_parameter,
  proposal_parameter,
  spec,
  base
) {
  fixed <- fit$obj$env$lfixed()
  if (!is.logical(fixed) || sum(fixed) != length(fixed_parameter)) {
    stop("Could not map corrected fixed parameters.", call. = FALSE)
  }
  full <- proposal_parameter
  full[fixed] <- fixed_parameter
  corrected_nll <- base$with_repair_rng(
    fit$obj$env$MC(
      par = full,
      par0 = proposal_parameter,
      n = spec$n,
      seed = spec$mc_seed,
      antithetic = TRUE,
      keep = TRUE,
      order = 0
    )
  )
  nlratio <- attr(corrected_nll, "nlratio")
  if (length(nlratio) != 2L * spec$n) {
    stop(
      "TMB corrected refit returned an unexpected draw count.",
      call. = FALSE
    )
  }
  weight <- importance_weight_stats(nlratio)
  score <- base$with_repair_rng(
    fit$obj$env$MC(
      par = full,
      par0 = proposal_parameter,
      n = spec$n,
      seed = spec$mc_seed,
      antithetic = TRUE,
      order = 1
    )
  )
  list(
    value = as.numeric(corrected_nll),
    score = as.numeric(score),
    ess = unname(weight[["ess"]]),
    max_weight = unname(weight[["max_weight"]])
  )
}

corrected_refit_batch <- function(fit, spec, base) {
  fixed_names <- names(fit$opt$par)
  tau_index <- which(fixed_names == "log_sd_phylo")
  if (length(tau_index) != 1L) {
    stop("Expected exactly one fixed `log_sd_phylo` parameter.", call. = FALSE)
  }
  lower <- rep(-Inf, length(fit$opt$par))
  upper <- rep(Inf, length(fit$opt$par))
  lower[[tau_index]] <- fit$opt$par[[tau_index]] - 0.60
  upper[[tau_index]] <- fit$opt$par[[tau_index]] + 0.60
  proposal_parameter <- pin_full_at(fit, fit$opt$par)
  cache <- new.env(parent = emptyenv())
  evaluate <- function(parameter) {
    key <- paste(
      format(parameter, digits = 17, scientific = TRUE),
      collapse = "|"
    )
    if (!identical(cache$key %||% NULL, key)) {
      cache$key <- key
      cache$value <- corrected_evaluation(
        fit,
        parameter,
        proposal_parameter,
        spec,
        base
      )
    }
    cache$value
  }
  optimum <- stats::nlminb(
    start = fit$opt$par,
    objective = function(parameter) evaluate(parameter)$value,
    gradient = function(parameter) evaluate(parameter)$score,
    lower = lower,
    upper = upper,
    control = list(eval.max = 100L, iter.max = 50L, rel.tol = 1e-8)
  )
  final <- corrected_evaluation(
    fit,
    optimum$par,
    proposal_parameter,
    spec,
    base
  )
  safe_names <- make.unique(fixed_names, sep = "_")
  fixed <- as.list(optimum$par)
  names(fixed) <- paste0("corrected_", safe_names)
  cbind(
    data.frame(
      batch = spec$batch,
      n = spec$n,
      total_draws = 2L * spec$n,
      mc_seed = spec$mc_seed,
      corrected_nll = final$value,
      ess = final$ess,
      max_weight = final$max_weight,
      max_abs_score = max(abs(final$score)),
      optimizer_convergence = optimum$convergence,
      optimizer_message = paste(optimum$message %||% "", collapse = " | "),
      log_tau_lower = lower[[tau_index]],
      log_tau_upper = upper[[tau_index]],
      log_tau_boundary_distance = min(
        optimum$par[[tau_index]] - lower[[tau_index]],
        upper[[tau_index]] - optimum$par[[tau_index]]
      ),
      stringsAsFactors = FALSE
    ),
    as.data.frame(fixed, check.names = FALSE)
  )
}

corrected_refit_dataset <- function(row, base) {
  started <- proc.time()[["elapsed"]]
  fitted <- fit_diagnostic_dataset(row, base)
  fit <- fitted$fit
  spec <- diagnostic_profile_spec(row$replicate)
  refits <- do.call(
    rbind,
    lapply(seq_len(nrow(spec)), function(i) {
      corrected_refit_batch(fit, spec[i, , drop = FALSE], base)
    })
  )
  tau_column <- grep("^corrected_log_sd_phylo$", names(refits), value = TRUE)
  if (length(tau_column) != 1L) {
    stop("Corrected refit did not retain one log-SD parameter.", call. = FALSE)
  }
  refits$cell_id <- row$cell_id
  refits$g <- row$g
  refits$m <- row$m
  refits$replicate <- row$replicate
  refits$dgp_seed <- row$seed
  refits$laplace_log_tau <- log(fit$sdpars$mu[[1L]])
  refits$truth_log_tau <- fitted$truth[["log_tau"]]
  refits$source_convergence <- fit$opt$convergence
  refits$source_pdHess <- isTRUE(fit$sdr$pdHess)
  row_pass <- !is.na(refits$optimizer_convergence) &
    refits$optimizer_convergence == 0L &
    is.finite(refits$ess) &
    refits$ess >= 1000 &
    is.finite(refits$max_weight) &
    refits$max_weight <= 0.01 &
    is.finite(refits$max_abs_score) &
    refits$max_abs_score <= 0.05 &
    is.finite(refits$log_tau_boundary_distance) &
    refits$log_tau_boundary_distance >= 0.05
  batch_difference <- abs(diff(refits[[tau_column]]))
  profile_pass <- all(row_pass %in% TRUE) &&
    is.finite(batch_difference) &&
    batch_difference <= 0.03 &&
    !is.na(fit$opt$convergence) &&
    fit$opt$convergence == 0L &&
    isTRUE(fit$sdr$pdHess)
  corrected <- if (profile_pass) mean(refits[[tau_column]]) else NA_real_
  summary <- data.frame(
    replicate = row$replicate,
    dgp_seed = row$seed,
    laplace_log_tau = log(fit$sdpars$mu[[1L]]),
    corrected_log_tau_a = refits[[tau_column]][refits$batch == "A"],
    corrected_log_tau_b = refits[[tau_column]][refits$batch == "B"],
    corrected_log_tau = corrected,
    truth_log_tau = fitted$truth[["log_tau"]],
    delta = corrected - log(fit$sdpars$mu[[1L]]),
    corrected_error = corrected - fitted$truth[["log_tau"]],
    batch_difference = batch_difference,
    profile_pass = profile_pass,
    elapsed_dataset = proc.time()[["elapsed"]] - started
  )
  list(refits = refits, summary = summary)
}

t_interval_mean <- function(x, level = 0.95) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) {
    return(c(mean = NA_real_, lower = NA_real_, upper = NA_real_))
  }
  estimate <- mean(x)
  half <- stats::qt(1 - (1 - level) / 2, df = length(x) - 1L) *
    stats::sd(x) /
    sqrt(length(x))
  c(mean = estimate, lower = estimate - half, upper = estimate + half)
}

diagnostic_profile_decision <- function(summary) {
  complete <- nrow(summary) == 24L && all(summary$profile_pass %in% TRUE)
  delta <- t_interval_mean(summary$delta)
  corrected <- t_interval_mean(summary$corrected_error)
  status <- if (!complete) {
    "INCONCLUSIVE"
  } else if (delta[["lower"]] > 0.10) {
    "LAPLACE_MATERIALLY_IMPLICATED"
  } else if (
    delta[["lower"]] >= -0.05 &&
      delta[["upper"]] <= 0.05 &&
      corrected[["upper"]] < -0.10
  ) {
    "LAPLACE_SHIFT_EQUIVALENT_RESIDUAL_BIAS"
  } else {
    "MIXED_OR_INCONCLUSIVE"
  }
  data.frame(
    datasets = nrow(summary),
    datasets_passing = sum(summary$profile_pass %in% TRUE),
    mean_delta = delta[["mean"]],
    delta_lower = delta[["lower"]],
    delta_upper = delta[["upper"]],
    corrected_bias = corrected[["mean"]],
    corrected_bias_lower = corrected[["lower"]],
    corrected_bias_upper = corrected[["upper"]],
    status = status,
    estimator_arc_required = identical(status, "LAPLACE_MATERIALLY_IMPLICATED")
  )
}

data_equal_exact <- function(x, y) {
  isTRUE(all.equal(x, y, tolerance = 0, check.attributes = FALSE))
}

assert_screen_pass <- function(
  screen_output,
  expected_head,
  expected_preflight,
  expected_design,
  repo_root
) {
  required <- file.path(
    screen_output,
    c(
      "design.tsv",
      "seed-audit.tsv",
      "preflight-manifest.tsv",
      "run-provenance.tsv",
      "importance-screen.tsv",
      "screen-gates.tsv",
      "screen-decision.tsv"
    )
  )
  if (any(!file.exists(required))) {
    stop("D1 requires a complete authenticated D0 screen.", call. = FALSE)
  }
  observed_design <- utils::read.delim(required[[1L]], stringsAsFactors = FALSE)
  observed_audit <- utils::read.delim(required[[2L]], stringsAsFactors = FALSE)
  observed_preflight <- utils::read.delim(
    required[[3L]],
    stringsAsFactors = FALSE
  )
  provenance <- utils::read.delim(required[[4L]], stringsAsFactors = FALSE)
  expected_audit <- diagnostic_seed_audit(expected_design, repo_root)
  if (
    !data_equal_exact(observed_design, expected_design) ||
      !data_equal_exact(observed_audit, expected_audit) ||
      !data_equal_exact(observed_preflight, expected_preflight)
  ) {
    stop(
      "D0 design, seed audit, or preflight is not current-equivalent.",
      call. = FALSE
    )
  }

  screen_design <- expected_design[
    expected_design$diagnostic_role == "D0_screen",
    ,
    drop = FALSE
  ]
  shard_dir <- file.path(screen_output, "attempts")
  expected_shards <- vapply(
    seq_len(nrow(screen_design)),
    function(i) {
      row <- screen_design[i, , drop = FALSE]
      sprintf("screen-r%04d-s%d.tsv", row$replicate, row$seed)
    },
    character(1)
  )
  observed_shards <- sort(list.files(shard_dir, pattern = "\\.tsv$"))
  if (!identical(sort(expected_shards), observed_shards)) {
    stop("D0 screen shard set is not exact.", call. = FALSE)
  }
  shard_rows <- lapply(seq_len(nrow(screen_design)), function(i) {
    row <- screen_design[i, , drop = FALSE]
    value <- utils::read.delim(
      file.path(shard_dir, expected_shards[[i]]),
      stringsAsFactors = FALSE
    )
    spec <- diagnostic_mc_grid(row$replicate)
    if (
      nrow(value) != 4L ||
        !identical(value$n, spec$n) ||
        !identical(value$batch, spec$batch) ||
        !identical(value$mc_seed, spec$mc_seed) ||
        !identical(value$total_draws, 2L * spec$n) ||
        any(value$replicate != row$replicate) ||
        any(value$dgp_seed != row$seed)
    ) {
      stop("D0 contains a malformed screen shard.", call. = FALSE)
    }
    value
  })
  raw <- do.call(rbind, shard_rows)
  rownames(raw) <- NULL
  stored_raw <- utils::read.delim(required[[5L]], stringsAsFactors = FALSE)
  recomputed <- diagnostic_screen_gates(raw)
  stored_gates <- utils::read.delim(required[[6L]], stringsAsFactors = FALSE)
  stored_decision <- utils::read.delim(required[[7L]], stringsAsFactors = FALSE)
  if (
    !data_equal_exact(stored_raw, raw) ||
      !data_equal_exact(stored_gates, recomputed$gates) ||
      !data_equal_exact(stored_decision, recomputed$decision) ||
      nrow(stored_decision) != 1L ||
      stored_decision$status != "PASS_TO_D1" ||
      nrow(provenance) != 1L ||
      provenance$status != "COMPLETE" ||
      provenance$git_head != expected_head
  ) {
    stop("D0 did not authorize D1 under the current Git head.", call. = FALSE)
  }
  invisible(TRUE)
}

run_is_diagnostic <- function(args = parse_diagnostic_args()) {
  context <- diagnostic_context()
  helper <- diagnostic_load_helpers(context$repo_root)
  base <- helper$successor_load_base_runner(context$repo_root)
  design <- diagnostic_seed_design(context$repo_root)
  out_dir <- args$output %||%
    file.path(
      context$repo_root,
      "docs/dev-log/simulation-artifacts",
      paste0("2026-07-16-beta-phylo-q1-pr1-is-", args$mode)
    )
  if (args$mode == "design") {
    base$assert_empty_output_dir(out_dir)
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    helper$write_tsv(design, file.path(out_dir, "design.tsv"))
    writeLines(
      capture.output(sessionInfo()),
      file.path(out_dir, "session-info.txt")
    )
    return(invisible(design))
  }
  assert_frozen_diagnostic_design(context$repo_root)
  protected <- c(
    "AGENTS.md",
    "docs/dev-log/2026-07-16-beta-phylo-q1-pr1-successor-evidence-contract.md",
    "tests/testthat/test-beta-phylo-q1-successor-runners.R",
    "tools/run-beta-phylo-q1-recovery.R",
    "tools/run-beta-phylo-q1-successor-recovery.R",
    "tools/run-beta-phylo-q1-is-diagnostic.R",
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr1-successor-high-information",
      "design.tsv"
    ),
    file.path(
      "docs/dev-log/simulation-designs",
      "2026-07-16-beta-phylo-q1-pr1-is-diagnostic",
      "design.tsv"
    )
  )
  design_paths <- c(
    helper$prior_design_paths(context$repo_root),
    successor = helper$frozen_successor_design_path(context$repo_root),
    diagnostic = frozen_diagnostic_design_path(context$repo_root)
  )
  design_hashes <- c(
    helper$prior_design_hashes(),
    successor = "73685aed37eda78f7a5fb86cb90e0d6974a54fb1055d11214bdea8b316415b9f",
    diagnostic = "fefc3ca7cd143f946cbd68d2a99ddfab56ad2acb5001659911d393bb6dbdce6f"
  )
  preflight <- helper$successor_preflight_manifest(
    context$repo_root,
    protected,
    design_paths,
    design_hashes,
    require_compute_host = TRUE
  )
  audit <- diagnostic_seed_audit(design, context$repo_root)
  git_head <- trimws(system2(
    "git",
    c("-C", context$repo_root, "rev-parse", "HEAD"),
    stdout = TRUE
  ))
  if (args$mode == "profile") {
    screen_output <- args$screen_output %||%
      file.path(
        context$repo_root,
        "docs/dev-log/simulation-artifacts",
        "2026-07-16-beta-phylo-q1-pr1-is-screen"
      )
    assert_screen_pass(
      screen_output,
      git_head,
      preflight,
      design,
      context$repo_root
    )
  }
  shard_dir <- helper$prepare_resumable_output(
    out_dir,
    design,
    audit,
    preflight,
    resume = args$resume
  )
  devtools::load_all(context$repo_root, quiet = TRUE)
  provenance <- data.frame(
    status = "PRE_DISPATCH",
    mode = args$mode,
    git_head = git_head,
    runner_sha256 = base$sha256_file(context$script_path),
    successor_runner_sha256 = base$sha256_file(file.path(
      context$repo_root,
      "tools",
      "run-beta-phylo-q1-successor-recovery.R"
    )),
    base_runner_sha256 = base$sha256_file(file.path(
      context$repo_root,
      "tools",
      "run-beta-phylo-q1-recovery.R"
    )),
    design_sha256 = base$sha256_file(frozen_diagnostic_design_path(
      context$repo_root
    )),
    rng_kind = paste(helper$successor_rng_kind(), collapse = "/"),
    package_version = as.character(utils::packageVersion("drmTMB")),
    TMB_version = as.character(utils::packageVersion("TMB")),
    host = Sys.info()[["nodename"]]
  )
  helper$write_tsv_atomic(provenance, file.path(out_dir, "run-provenance.tsv"))

  selected <- if (args$mode == "screen") {
    design[design$diagnostic_role == "D0_screen", , drop = FALSE]
  } else {
    design
  }
  expected_shards <- unlist(lapply(seq_len(nrow(selected)), function(i) {
    row <- selected[i, , drop = FALSE]
    prefix <- sprintf("%s-r%04d-s%d", args$mode, row$replicate, row$seed)
    if (args$mode == "screen") {
      paste0(prefix, ".tsv")
    } else {
      c(paste0(prefix, "-refits.tsv"), paste0(prefix, "-summary.tsv"))
    }
  }))
  existing_shards <- list.files(shard_dir, pattern = "\\.tsv$")
  if (length(setdiff(existing_shards, expected_shards))) {
    stop("Diagnostic shard directory contains unexpected files.", call. = FALSE)
  }
  rows <- split(selected, seq_len(nrow(selected)))
  worker <- function(x) {
    row <- x[1L, , drop = FALSE]
    prefix <- sprintf("%s-r%04d-s%d", args$mode, row$replicate, row$seed)
    if (args$mode == "screen") {
      path <- file.path(shard_dir, paste0(prefix, ".tsv"))
      if (file.exists(path)) {
        value <- utils::read.delim(path, stringsAsFactors = FALSE)
        spec <- diagnostic_mc_grid(row$replicate)
        if (
          nrow(value) != 4L ||
            !identical(value$n, spec$n) ||
            !identical(value$batch, spec$batch) ||
            !identical(value$mc_seed, spec$mc_seed) ||
            !identical(value$total_draws, 2L * spec$n) ||
            any(value$replicate != row$replicate) ||
            any(value$dgp_seed != row$seed)
        ) {
          stop("Malformed diagnostic screen shard: ", path, call. = FALSE)
        }
        return(value)
      }
      value <- screen_dataset(row, base)
      helper$write_tsv_atomic(value, path)
      return(value)
    }
    refits_path <- file.path(shard_dir, paste0(prefix, "-refits.tsv"))
    summary_path <- file.path(shard_dir, paste0(prefix, "-summary.tsv"))
    if (file.exists(refits_path) && file.exists(summary_path)) {
      value <- list(
        refits = utils::read.delim(refits_path, stringsAsFactors = FALSE),
        summary = utils::read.delim(summary_path, stringsAsFactors = FALSE)
      )
      spec <- diagnostic_profile_spec(row$replicate)
      if (
        nrow(value$refits) != 2L ||
          nrow(value$summary) != 1L ||
          !identical(value$refits$batch, spec$batch) ||
          !identical(value$refits$n, spec$n) ||
          !identical(value$refits$mc_seed, spec$mc_seed) ||
          !identical(value$refits$total_draws, 2L * spec$n) ||
          any(value$refits$replicate != row$replicate) ||
          any(value$refits$dgp_seed != row$seed) ||
          any(
            abs(
              value$refits$log_tau_lower -
                (value$refits$laplace_log_tau - 0.60)
            ) >
              1e-12
          ) ||
          any(
            abs(
              value$refits$log_tau_upper -
                (value$refits$laplace_log_tau + 0.60)
            ) >
              1e-12
          ) ||
          value$summary$replicate != row$replicate ||
          value$summary$dgp_seed != row$seed
      ) {
        stop(
          "Malformed diagnostic corrected-refit shard: ",
          refits_path,
          call. = FALSE
        )
      }
      return(value)
    }
    value <- corrected_refit_dataset(row, base)
    helper$write_tsv_atomic(value$refits, refits_path)
    helper$write_tsv_atomic(value$summary, summary_path)
    value
  }
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
  if (any(vapply(result, inherits, logical(1), "try-error"))) {
    stop(
      "Diagnostic workers failed; completed shards were preserved.",
      call. = FALSE
    )
  }
  final_shards <- sort(list.files(shard_dir, pattern = "\\.tsv$"))
  if (!identical(final_shards, sort(expected_shards))) {
    stop("Diagnostic shard set is incomplete or unexpected.", call. = FALSE)
  }

  if (args$mode == "screen") {
    raw <- do.call(rbind, result)
    if (
      nrow(raw) != 20L || anyDuplicated(paste(raw$replicate, raw$n, raw$batch))
    ) {
      stop(
        "Diagnostic screen did not retain the exact predeclared rows.",
        call. = FALSE
      )
    }
    expected_spec <- do.call(
      rbind,
      lapply(seq_len(nrow(selected)), function(i) {
        row <- selected[i, , drop = FALSE]
        cbind(
          replicate = row$replicate,
          dgp_seed = row$seed,
          diagnostic_mc_grid(row$replicate)
        )
      })
    )
    observed_spec <- raw[c("replicate", "dgp_seed", "n", "batch", "mc_seed")]
    if (!data_equal_exact(observed_spec, expected_spec)) {
      stop(
        "Diagnostic screen rows do not match the frozen MC design.",
        call. = FALSE
      )
    }
    gates <- diagnostic_screen_gates(raw)
    helper$write_tsv_atomic(raw, file.path(out_dir, "importance-screen.tsv"))
    helper$write_tsv_atomic(gates$gates, file.path(out_dir, "screen-gates.tsv"))
    helper$write_tsv_atomic(
      gates$decision,
      file.path(out_dir, "screen-decision.tsv")
    )
    value <- list(raw = raw, gates = gates$gates, decision = gates$decision)
  } else {
    refits <- do.call(rbind, lapply(result, `[[`, "refits"))
    summary <- do.call(rbind, lapply(result, `[[`, "summary"))
    if (
      nrow(refits) != 48L ||
        nrow(summary) != 24L ||
        anyDuplicated(summary$replicate) ||
        anyDuplicated(paste(
          refits$replicate,
          refits$batch
        ))
    ) {
      stop(
        "Diagnostic corrected refit did not retain the exact rows.",
        call. = FALSE
      )
    }
    expected_spec <- do.call(
      rbind,
      lapply(seq_len(nrow(selected)), function(i) {
        row <- selected[i, , drop = FALSE]
        cbind(
          replicate = row$replicate,
          dgp_seed = row$seed,
          diagnostic_profile_spec(row$replicate)
        )
      })
    )
    observed_spec <- refits[c("replicate", "dgp_seed", "batch", "n", "mc_seed")]
    if (!data_equal_exact(observed_spec, expected_spec)) {
      stop("Corrected refits do not match the frozen MC design.", call. = FALSE)
    }
    decision <- diagnostic_profile_decision(summary)
    helper$write_tsv_atomic(
      refits,
      file.path(out_dir, "corrected-refits.tsv")
    )
    helper$write_tsv_atomic(summary, file.path(out_dir, "dataset-optima.tsv"))
    helper$write_tsv_atomic(
      decision,
      file.path(out_dir, "diagnostic-decision.tsv")
    )
    value <- list(refits = refits, summary = summary, decision = decision)
  }
  writeLines(
    capture.output(sessionInfo()),
    file.path(out_dir, "session-info.txt")
  )
  provenance$status <- "COMPLETE"
  helper$write_tsv_atomic(provenance, file.path(out_dir, "run-provenance.tsv"))
  invisible(value)
}

if (sys.nframe() == 0L) {
  run_is_diagnostic()
}
