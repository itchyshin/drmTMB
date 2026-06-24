#!/usr/bin/env Rscript

devtools::load_all(quiet = TRUE)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-spatial-mu-lower-start-diagnostic"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-spatial-mu-lower-start-diagnostic-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-spatial-mu-lower-start-diagnostic.tsv"
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

correlated_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

make_spatial_data <- function(seed, n_each, sds) {
  set.seed(seed)
  n <- 8L
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(
    x = cos(theta) + seq_len(n) / (3 * n),
    y = sin(theta)
  )
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = labels,
    group = "site"
  )
  K <- solve(as.matrix(precision$precision))
  effects <- correlated_effects(K, sds)
  rownames(effects) <- labels

  site <- rep(labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(labels))
  eta_mu <- 0.35 +
    0.20 * x +
    effects[site, "mu_intercept"] +
    effects[site, "mu_x"] * x
  eta_sigma <- -1.05 +
    effects[site, "sigma_intercept"] +
    effects[site, "sigma_x"] * x
  data <- data.frame(
    y = eta_mu + exp(eta_sigma) * stats::rnorm(length(x)),
    x = x,
    site = site
  )

  list(
    data = data,
    coords = coords,
    realized_sds = apply(effects, 2L, stats::sd)
  )
}

fit_spatial <- function(sim) {
  coords <- sim$coords
  drmTMB(
    bf(
      y ~ x + spatial(1 + x | site, coords = coords),
      sigma ~ spatial(1 + x | site, coords = coords)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1200, iter.max = 1200))
  )
}

endpoint_evaluator_with_start <- function(
  object,
  target_position,
  control,
  start_mode
) {
  par0 <- object$opt$par
  free <- seq_along(par0) != target_position
  start_free <- par0[free]
  last_free <- start_free

  evaluate <- function(theta) {
    full0 <- par0
    start <- if (identical(start_mode, "reset")) {
      start_free
    } else {
      last_free
    }
    fn_free <- function(pfree) {
      full <- full0
      full[free] <- pfree
      full[[target_position]] <- theta
      object$obj$fn(full)
    }
    gr_free <- function(pfree) {
      full <- full0
      full[free] <- pfree
      full[[target_position]] <- theta
      object$obj$gr(full)[free]
    }
    opt <- stats::nlminb(start, fn_free, gr_free, control = control)
    opt_message <- opt$message
    if (is.null(opt_message) || length(opt_message) == 0L) {
      opt_message <- "unknown"
    }
    opt_gradient <- tryCatch(
      gr_free(opt$par),
      error = function(err) rep(NA_real_, length(opt$par))
    )
    max_abs_gradient <- suppressWarnings(max(abs(opt_gradient), na.rm = TRUE))
    if (!is.finite(max_abs_gradient)) {
      max_abs_gradient <- NA_real_
    }
    convergence_tolerated <- opt$convergence %in% c(0L, 1L)
    if (
      !is.finite(opt$objective) ||
        is.null(opt$convergence) ||
        !convergence_tolerated
    ) {
      cli::cli_abort(c(
        "Constrained endpoint optimization failed.",
        i = "Target internal value: {format(theta, digits = 6)}.",
        i = "Maximum absolute gradient: {format(max_abs_gradient, digits = 4)}.",
        x = "Optimizer message: {opt_message[[1L]]}"
      ))
    }
    last_free <<- opt$par
    list(nll = unname(opt$objective), par = opt$par)
  }

  list(evaluate = evaluate, start_free = start_free)
}

initial_step_from_strategy <- function(
  theta_hat,
  cutoff,
  curvature_se,
  strategy
) {
  current <- drmTMB:::profile_endpoint_initial_step(
    theta_hat = theta_hat,
    direction = -1L,
    cutoff = cutoff,
    curvature_se = curvature_se
  )
  if (identical(strategy$step_rule, "curvature")) {
    return(current)
  }
  if (identical(strategy$step_rule, "capped_1")) {
    return(list(step = min(current$step, 1), source = "curvature_capped_1"))
  }
  if (identical(strategy$step_rule, "fixed_025")) {
    return(list(step = 0.25, source = "fixed_025"))
  }
  cli::cli_abort("Unknown step rule {.val {strategy$step_rule}}.")
}

probe_lower_side <- function(fit, target, strategy, max_eval = 120L) {
  warning_text <- character()
  position <- as.integer(drmTMB:::profile_target_opt_positions(fit, target))
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  theta_hat <- unname(fit$opt$par[[position]])
  nll_hat <- unname(fit$opt$objective)
  cutoff <- stats::qchisq(0.70, df = 1) / 2
  curvature_se <- drmTMB:::profile_endpoint_curvature_se(fit, position)
  step_info <- initial_step_from_strategy(
    theta_hat = theta_hat,
    cutoff = cutoff,
    curvature_se = curvature_se,
    strategy = strategy
  )
  control <- if (is.list(fit$control) && is.list(fit$control$optimizer)) {
    fit$control$optimizer
  } else {
    list()
  }
  control$eval.max <- max(control$eval.max %||% 0L, strategy$eval_max)
  control$iter.max <- max(control$iter.max %||% 0L, strategy$iter_max)
  evaluator <- endpoint_evaluator_with_start(
    object = fit,
    target_position = position,
    control = control,
    start_mode = strategy$start_mode
  )
  result <- withCallingHandlers(
    tryCatch(
      profile_crossing_with_step(
        evaluator = evaluator,
        theta_hat = theta_hat,
        nll_hat = nll_hat,
        cutoff = cutoff,
        initial_step = step_info$step,
        target_name = target$parm,
        max_eval = max_eval
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warning_text <<- c(warning_text, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(result, "error")) {
    return(data.frame(
      theta_hat = theta_hat,
      curvature_se = curvature_se,
      cutoff = cutoff,
      initial_step = step_info$step,
      step_source = step_info$source,
      theta = NA_real_,
      endpoint = NA_real_,
      root_error = NA_real_,
      n_eval = NA_integer_,
      bracket_step = NA_real_,
      n_bracket_step = NA_integer_,
      side_status = "error",
      side_message = clean_text(conditionMessage(result)),
      side_warnings = clean_text(paste(warning_text, collapse = " | ")),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    theta_hat = theta_hat,
    curvature_se = curvature_se,
    cutoff = cutoff,
    initial_step = step_info$step,
    step_source = step_info$source,
    theta = result$theta,
    endpoint = exp(result$theta),
    root_error = result$root_error,
    n_eval = result$n_eval,
    bracket_step = result$bracket_step,
    n_bracket_step = result$n_bracket_step,
    side_status = "ok",
    side_message = "ok",
    side_warnings = clean_text(paste(warning_text, collapse = " | ")),
    stringsAsFactors = FALSE
  )
}

profile_crossing_with_step <- function(
  evaluator,
  theta_hat,
  nll_hat,
  cutoff,
  initial_step,
  target_name,
  root_tol = 1e-4,
  max_bracket_steps = 60L,
  max_eval = NULL
) {
  n_eval <- 0L
  eval_root <- function(theta) {
    if (!is.null(max_eval) && n_eval >= max_eval) {
      cli::cli_abort(c(
        "Endpoint profile evaluation budget was reached for target {.val {target_name}}.",
        i = "Budget: {max_eval} constrained endpoint evaluation(s) per side."
      ))
    }
    n_eval <<- n_eval + 1L
    out <- evaluator$evaluate(theta)
    out$nll - nll_hat - cutoff
  }

  at_hat <- -cutoff
  if (!is.finite(at_hat) || at_hat >= 0) {
    cli::cli_abort(
      "Could not start endpoint profile for target {.val {target_name}}."
    )
  }
  step <- initial_step
  n_bracket_step <- 0L
  outer <- theta_hat - step
  outer_value <- eval_root(outer)
  for (i in seq_len(max_bracket_steps)) {
    if (is.finite(outer_value) && outer_value >= 0) {
      break
    }
    step <- step * 1.6
    n_bracket_step <- i
    outer <- theta_hat - step
    outer_value <- eval_root(outer)
  }
  if (!is.finite(outer_value) || outer_value < 0) {
    cli::cli_abort(c(
      "Could not bracket profile endpoint for target {.val {target_name}}.",
      i = "This can indicate a flat, one-sided, or boundary-limited profile."
    ))
  }

  root <- stats::uniroot(
    eval_root,
    interval = sort(c(theta_hat, outer)),
    f.lower = outer_value,
    f.upper = at_hat,
    tol = root_tol
  )
  root_error <- abs(root$f.root)
  if (!is.finite(root_error) || root_error > 5e-3) {
    cli::cli_abort(c(
      "Endpoint profile root for target {.val {target_name}} did not satisfy the likelihood-ratio equation closely enough.",
      i = "Absolute root error: {format(root_error, digits = 4)}."
    ))
  }
  list(
    theta = root$root,
    root_error = root_error,
    n_eval = n_eval,
    bracket_step = step,
    n_bracket_step = n_bracket_step
  )
}

diagnostic_status <- function(side_status, design_id) {
  if (identical(side_status, "ok")) {
    if (identical(design_id, "smoke_seed102")) {
      return("finite_control")
    }
    return("lower_side_rescued")
  }
  if (identical(design_id, "strong_seed202")) {
    return("boundary_not_rescued")
  }
  "lower_side_not_rescued"
}

claim_boundary <- function(status) {
  clean_text(paste(
    "Fixed-covariance spatial mu:x lower-side start diagnostic only;",
    "status =",
    status,
    "with no range-estimating spatial support, no interval reliability,",
    "interval coverage, REML, AI-REML, broad bridge support, public support,",
    "or coverage denominator admission promoted."
  ))
}

next_gate <- function(status) {
  if (identical(status, "lower_side_rescued")) {
    return(
      "Treat as start-strategy evidence only; require runtime review and replicated denominator evidence before coverage wording."
    )
  }
  if (identical(status, "finite_control")) {
    return(
      "Use as finite control only; require replicated denominators before coverage wording."
    )
  }
  "Keep this design out of coverage denominators until lower-side strategy evidence improves."
}

designs <- list(
  smoke_seed102 = list(
    seed = 102L,
    n_each = 10L,
    sds = c(
      mu_intercept = 0.40,
      mu_x = 0.24,
      sigma_intercept = 0.22,
      sigma_x = 0.14
    )
  ),
  strong_seed202 = list(
    seed = 202L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  strong_n50_seed202 = list(
    seed = 202L,
    n_each = 50L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  mu_dominant_seed202 = list(
    seed = 202L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.80,
      mu_x = 0.60,
      sigma_intercept = 0.12,
      sigma_x = 0.08
    )
  )
)

strategies <- list(
  baseline_warm_curvature = list(
    start_mode = "warm",
    step_rule = "curvature",
    eval_max = 1200L,
    iter_max = 1200L
  ),
  reset_curvature = list(
    start_mode = "reset",
    step_rule = "curvature",
    eval_max = 1200L,
    iter_max = 1200L
  ),
  reset_capped_step1 = list(
    start_mode = "reset",
    step_rule = "capped_1",
    eval_max = 1200L,
    iter_max = 1200L
  ),
  reset_fixed_step025 = list(
    start_mode = "reset",
    step_rule = "fixed_025",
    eval_max = 1200L,
    iter_max = 1200L
  )
)

target_name <- "sd:mu:mu:spatial(0 + x | site)"
rows <- list()

for (design_id in names(designs)) {
  design <- designs[[design_id]]
  sim <- make_spatial_data(
    seed = design$seed,
    n_each = design$n_each,
    sds = design$sds
  )
  fit <- fit_spatial(sim)
  targets <- profile_targets(fit)
  target <- targets[targets$parm == target_name, , drop = FALSE]

  for (strategy_name in names(strategies)) {
    strategy <- strategies[[strategy_name]]
    side_row <- probe_lower_side(
      fit = fit,
      target = target,
      strategy = strategy
    )
    status <- diagnostic_status(
      side_status = side_row$side_status[[1L]],
      design_id = design_id
    )
    diagnostic_id <- paste0(
      "spatial_mu_x_lower_start_",
      design_id,
      "_",
      strategy_name
    )
    rows[[length(rows) + 1L]] <- data.frame(
      diagnostic_id = diagnostic_id,
      cell_id = "qseries_spatial_q1_mu_sigma_one_slope",
      design_id = design_id,
      strategy = strategy_name,
      start_mode = strategy$start_mode,
      step_rule = strategy$step_rule,
      optimizer_eval_max = strategy$eval_max,
      optimizer_iter_max = strategy$iter_max,
      seed = design$seed,
      n_each = design$n_each,
      formula_cell = "spatial(1 + x | site, coords = coords) in mu and sigma",
      structured_type = "spatial",
      target_kind = "direct_sd",
      endpoint_member = "mu:x",
      direct_sd_target = "sd_mu_x",
      profile_target = target_name,
      profile_side = "lower",
      source_artifact = file.path(
        "docs",
        "dev-log",
        "simulation-artifacts",
        "2026-06-24-spatial-mu-lower-start-diagnostic",
        "structured-re-spatial-mu-lower-start-diagnostic-results.tsv"
      ),
      source_geometry = "docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv",
      source_strategy = "docs/dev-log/dashboard/structured-re-spatial-mu-profile-strategy.tsv",
      intended_sd_mu_intercept = design$sds[["mu_intercept"]],
      intended_sd_mu_x = design$sds[["mu_x"]],
      intended_sd_sigma_intercept = design$sds[["sigma_intercept"]],
      intended_sd_sigma_x = design$sds[["sigma_x"]],
      realized_sd_mu_intercept = sim$realized_sds[["mu_intercept"]],
      realized_sd_mu_x = sim$realized_sds[["mu_x"]],
      realized_sd_sigma_intercept = sim$realized_sds[["sigma_intercept"]],
      realized_sd_sigma_x = sim$realized_sds[["sigma_x"]],
      estimate = target$estimate[[1L]],
      profile_ready = target$profile_ready[[1L]],
      theta_hat = side_row$theta_hat,
      curvature_se = side_row$curvature_se,
      cutoff = side_row$cutoff,
      initial_step = side_row$initial_step,
      step_source = side_row$step_source,
      theta = side_row$theta,
      endpoint = side_row$endpoint,
      root_error = side_row$root_error,
      n_eval = side_row$n_eval,
      bracket_step = side_row$bracket_step,
      n_bracket_step = side_row$n_bracket_step,
      side_status = side_row$side_status,
      side_message = side_row$side_message,
      side_warnings = side_row$side_warnings,
      fit_convergence = fit$opt$convergence,
      n_pdhess = as.integer(isTRUE(fit$sdr$pdHess)),
      diagnostic_status = status,
      interval_claim_status = "diagnostic_only",
      denominator_admission = "not_admitted",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-24-spatial-mu-lower-start-diagnostic.md",
      claim_boundary = claim_boundary(status),
      next_gate = next_gate(status),
      stringsAsFactors = FALSE
    )
  }
}

out <- do.call(rbind, rows)
character_cols <- vapply(out, is.character, logical(1L))
out[character_cols] <- lapply(out[character_cols], clean_text)

utils::write.table(
  out,
  file = artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  out,
  file = status_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(status_path, winslash = "/"))
