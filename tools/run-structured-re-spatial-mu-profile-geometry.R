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
  "2026-06-24-spatial-mu-profile-geometry"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-spatial-mu-profile-geometry-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-spatial-mu-profile-geometry.tsv"
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
    effects = effects,
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

probe_side <- function(fit, target, direction, max_eval = 80L) {
  warning_text <- character()
  position <- as.integer(drmTMB:::profile_target_opt_positions(fit, target))
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  theta_hat <- unname(fit$opt$par[[position]])
  nll_hat <- unname(fit$opt$objective)
  cutoff <- stats::qchisq(0.70, df = 1) / 2
  curvature_se <- drmTMB:::profile_endpoint_curvature_se(fit, position)
  step_info <- drmTMB:::profile_endpoint_initial_step(
    theta_hat = theta_hat,
    direction = direction,
    cutoff = cutoff,
    curvature_se = curvature_se
  )
  control <- if (is.list(fit$control) && is.list(fit$control$optimizer)) {
    fit$control$optimizer
  } else {
    list()
  }
  evaluator <- drmTMB:::profile_endpoint_evaluator(
    object = fit,
    target_position = position,
    control = control
  )
  result <- withCallingHandlers(
    tryCatch(
      drmTMB:::profile_endpoint_crossing(
        evaluator = evaluator,
        theta_hat = theta_hat,
        nll_hat = nll_hat,
        cutoff = cutoff,
        direction = direction,
        root_tol = 1e-4,
        max_bracket_steps = 40L,
        target_name = target$parm,
        curvature_se = curvature_se,
        max_eval = max_eval
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warning_text <<- c(warning_text, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  side <- if (direction < 0L) "lower" else "upper"
  if (inherits(result, "error")) {
    return(data.frame(
      profile_side = side,
      side_status = "error",
      side_message = clean_text(conditionMessage(result)),
      side_warnings = clean_text(paste(warning_text, collapse = " | ")),
      theta_hat = theta_hat,
      curvature_se = curvature_se,
      initial_step = step_info$step,
      step_source = step_info$source,
      theta = NA_real_,
      endpoint = NA_real_,
      root_error = NA_real_,
      n_eval = NA_integer_,
      bracket_step = NA_real_,
      n_bracket_step = NA_integer_,
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    profile_side = side,
    side_status = "ok",
    side_message = "ok",
    side_warnings = clean_text(paste(warning_text, collapse = " | ")),
    theta_hat = theta_hat,
    curvature_se = curvature_se,
    initial_step = step_info$step,
    step_source = step_info$source,
    theta = result$theta,
    endpoint = exp(result$theta),
    root_error = result$root_error,
    n_eval = result$n_eval,
    bracket_step = result$bracket_step,
    n_bracket_step = result$n_bracket_step,
    stringsAsFactors = FALSE
  )
}

diagnostic_status <- function(side, side_status) {
  if (identical(side_status, "ok")) {
    return("side_profile_ok")
  }
  if (identical(side, "lower")) {
    return("lower_endpoint_optimizer_error")
  }
  "upper_endpoint_optimizer_error"
}

claim_boundary <- function(status) {
  clean_text(paste(
    "Fixed-covariance spatial mu:x endpoint-profile geometry diagnostic only;",
    "status =",
    status,
    "with no range-estimating spatial support, no interval reliability,",
    "interval coverage, REML, AI-REML, broad bridge support, or public support",
    "promoted."
  ))
}

next_gate <- function(status) {
  if (identical(status, "side_profile_ok")) {
    return(
      "Use as side-specific geometry evidence only; require denominator replication before coverage wording."
    )
  }
  "Diagnose lower-side constrained-optimizer geometry before coverage-grid design."
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
  strong_seed102 = list(
    seed = 102L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  strong_seed302 = list(
    seed = 302L,
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

rows <- list()
target_name <- "sd:mu:mu:spatial(0 + x | site)"

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

  for (direction in c(-1L, 1L)) {
    side_row <- probe_side(fit, target, direction = direction)
    status <- diagnostic_status(
      side = side_row$profile_side[[1L]],
      side_status = side_row$side_status[[1L]]
    )
    geometry_id <- paste0(
      "spatial_mu_x_profile_geometry_",
      design_id,
      "_",
      side_row$profile_side[[1L]]
    )
    rows[[length(rows) + 1L]] <- data.frame(
      geometry_id = geometry_id,
      cell_id = "qseries_spatial_q1_mu_sigma_one_slope",
      design_id = design_id,
      seed = design$seed,
      n_each = design$n_each,
      formula_cell = "spatial(1 + x | site, coords = coords) in mu and sigma",
      structured_type = "spatial",
      target_kind = "direct_sd",
      endpoint_member = "mu:x",
      direct_sd_target = "sd_mu_x",
      profile_target = target_name,
      source_artifact = file.path(
        "docs",
        "dev-log",
        "simulation-artifacts",
        "2026-06-24-spatial-mu-profile-geometry",
        "structured-re-spatial-mu-profile-geometry-results.tsv"
      ),
      source_diagnostic = "docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv",
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
      profile_side = side_row$profile_side,
      side_status = side_row$side_status,
      side_message = side_row$side_message,
      side_warnings = side_row$side_warnings,
      theta_hat = side_row$theta_hat,
      curvature_se = side_row$curvature_se,
      initial_step = side_row$initial_step,
      step_source = side_row$step_source,
      theta = side_row$theta,
      endpoint = side_row$endpoint,
      root_error = side_row$root_error,
      n_eval = side_row$n_eval,
      bracket_step = side_row$bracket_step,
      n_bracket_step = side_row$n_bracket_step,
      fit_convergence = fit$opt$convergence,
      n_pdhess = as.integer(isTRUE(fit$sdr$pdHess)),
      logLik = as.numeric(stats::logLik(fit)),
      diagnostic_status = status,
      interval_claim_status = "diagnostic_only",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-24-spatial-mu-profile-geometry.md",
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
