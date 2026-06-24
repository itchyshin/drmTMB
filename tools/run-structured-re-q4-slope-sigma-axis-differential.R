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

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
hessian_geometry_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-hessian-geometry.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-slope-sigma-axis-differential"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-slope-sigma-axis-differential-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-sigma-axis-differential.tsv"
)

hessian_script <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q4-slope-hessian-geometry.R"
)

load_hessian_helpers <- function(path) {
  exprs <- parse(path)
  stop_at <- which(vapply(
    exprs,
    function(expr) {
      is.call(expr) &&
        identical(as.character(expr[[1L]]), "<-") &&
        identical(as.character(expr[[2L]]), "rows")
    },
    logical(1L)
  ))[1L]
  if (is.na(stop_at)) {
    stop("Could not find Hessian helper boundary in ", path, call. = FALSE)
  }
  for (i in seq_len(stop_at - 1L)) {
    eval(exprs[[i]], envir = .GlobalEnv)
  }
}

load_hessian_helpers(hessian_script)

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-slope-sigma-axis-differential"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-slope-sigma-axis-differential-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-sigma-axis-differential.tsv"
)

provider_axis_formula <- function(provider, model_axis) {
  provider_formula <- switch(
    provider,
    phylo = "phylo(1 + x | p | species, tree = tree)",
    spatial = "spatial(1 + x | p | site, coords = coords)",
    animal = "animal(1 + x | p | id, A = A)",
    relmat = "relmat(1 + x | p | id, K = K)"
  )
  switch(
    model_axis,
    mu_axis_only = paste0(
      provider_formula,
      " in mu1/mu2 only; sigma1/sigma2 fixed effects only"
    ),
    sigma_axis_only = paste0(
      provider_formula,
      " in sigma1/sigma2 only; mu1/mu2 fixed effects only"
    ),
    all_four_slope = paste0(provider_formula, " in all four endpoints")
  )
}

fit_provider_axis <- function(provider, sim, model_axis) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- switch(
      model_axis,
      mu_axis_only = bf(
        mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      sigma_axis_only = bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + phylo(1 + x | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 + x | p | species, tree = tree),
        rho12 = ~1
      )
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- switch(
      model_axis,
      mu_axis_only = bf(
        mu1 = y1 ~ x + spatial(1 + x | p | site, coords = coords),
        mu2 = y2 ~ x + spatial(1 + x | p | site, coords = coords),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      sigma_axis_only = bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + spatial(1 + x | p | site, coords = coords),
        sigma2 = ~ z + spatial(1 + x | p | site, coords = coords),
        rho12 = ~1
      )
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- switch(
      model_axis,
      mu_axis_only = bf(
        mu1 = y1 ~ x + animal(1 + x | p | id, A = A),
        mu2 = y2 ~ x + animal(1 + x | p | id, A = A),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      sigma_axis_only = bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + animal(1 + x | p | id, A = A),
        sigma2 = ~ z + animal(1 + x | p | id, A = A),
        rho12 = ~1
      )
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- switch(
      model_axis,
      mu_axis_only = bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, K = K),
        mu2 = y2 ~ x + relmat(1 + x | p | id, K = K),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      sigma_axis_only = bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + relmat(1 + x | p | id, K = K),
        sigma2 = ~ z + relmat(1 + x | p | id, K = K),
        rho12 = ~1
      )
    )
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(
      fallback_optimizer = "BFGS",
      optimizer = list(eval.max = 1600, iter.max = 1600)
    )
  )
}

axis_endpoint_set <- function(model_axis) {
  switch(
    model_axis,
    all_four_slope = "mu1+mu2+sigma1+sigma2",
    mu_axis_only = "mu1+mu2",
    sigma_axis_only = "sigma1+sigma2"
  )
}

axis_member_count <- function(model_axis) {
  switch(
    model_axis,
    all_four_slope = 8L,
    mu_axis_only = 4L,
    sigma_axis_only = 4L
  )
}

axis_claim_boundary <- function(provider, model_axis, differential_status) {
  clean_text(paste(
    provider_label(provider),
    "q4 all-four one-slope sigma-axis differential diagnostic only;",
    "model_axis =",
    model_axis,
    "status =",
    differential_status,
    "with",
    provider_boundary(provider),
    "no interval reliability, interval coverage, q4 REML, AI-REML,",
    "broad bridge support, public support, or broader q8 support promoted."
  ))
}

axis_next_gate <- function(differential_status) {
  if (grepl("sigma_sd_lower_bound", differential_status, fixed = TRUE)) {
    return(
      "Use the sigma-axis contrast to separate lower-bound sigma geometry from covariance/Hessian failure before denominator accounting."
    )
  }
  if (grepl("pdhess_true", differential_status, fixed = TRUE)) {
    return(
      "Compare sigma-suppressed and sigma-axis-only geometry before any denominator accounting or coverage-grid design."
    )
  }
  "Diagnose reduced-axis q4 geometry before any denominator accounting or coverage-grid design."
}

classify_axis_geometry <- function(
  model_axis,
  pdhess,
  n_mu_sd_at_lower_bound,
  n_sigma_sd_at_lower_bound,
  cov_fixed_status,
  fallback_selected
) {
  pieces <- c(model_axis)
  pieces <- c(pieces, if (isTRUE(pdhess)) "pdhess_true" else "pdhess_false")
  if (n_sigma_sd_at_lower_bound > 0L) {
    pieces <- c(pieces, "sigma_sd_lower_bound")
  }
  if (n_mu_sd_at_lower_bound > 0L) {
    pieces <- c(pieces, "mu_sd_lower_bound")
  }
  if (!n_sigma_sd_at_lower_bound && !n_mu_sd_at_lower_bound) {
    pieces <- c(pieces, "no_direct_sd_lower_bound")
  }
  pieces <- c(pieces, paste0("cov_fixed_", cov_fixed_status))
  if (isTRUE(fallback_selected)) {
    pieces <- c(pieces, "fallback_selected")
  }
  paste(pieces, collapse = ";")
}

safe_min <- function(x) {
  if (!length(x)) {
    return(NA_real_)
  }
  min(x)
}

safe_max_abs <- function(x) {
  if (!length(x)) {
    return(NA_real_)
  }
  max(abs(x))
}

baseline_row <- function(provider, variant, spec, geometry) {
  source <- geometry[
    geometry$structured_type == provider & geometry$variant == variant,
    ,
    drop = FALSE
  ]
  if (nrow(source) != 1L) {
    stop(
      "Expected one Hessian-geometry source row for ",
      variant,
      "/",
      provider,
      call. = FALSE
    )
  }
  model_axis <- "all_four_slope"
  differential_status <- paste0("baseline;", source$geometry_status[[1L]])
  data.frame(
    differential_id = paste0(
      "q4_slope_sigma_axis_differential_",
      variant,
      "_",
      provider,
      "_",
      model_axis
    ),
    cell_id = paste0("qseries_", provider, "_q4_all_four_one_slope_planned"),
    variant = variant,
    model_axis = model_axis,
    formula_cell = source$formula_cell[[1L]],
    structured_type = provider,
    structured_endpoint_set = axis_endpoint_set(model_axis),
    structured_member_count = axis_member_count(model_axis),
    source_hessian_geometry = "docs/dev-log/dashboard/structured-re-q4-slope-hessian-geometry.tsv",
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-sigma-axis-differential",
      "structured-re-q4-slope-sigma-axis-differential-results.tsv"
    ),
    n_levels = spec$n,
    n_each = spec$n_each,
    intended_sd_mu1_intercept = spec$sds[["mu1_intercept"]],
    intended_sd_mu1_x = spec$sds[["mu1_x"]],
    intended_sd_mu2_intercept = spec$sds[["mu2_intercept"]],
    intended_sd_mu2_x = spec$sds[["mu2_x"]],
    intended_sd_sigma1_intercept = spec$sds[["sigma1_intercept"]],
    intended_sd_sigma1_x = spec$sds[["sigma1_x"]],
    intended_sd_sigma2_intercept = spec$sds[["sigma2_intercept"]],
    intended_sd_sigma2_x = spec$sds[["sigma2_x"]],
    fit_convergence = source$fit_convergence[[1L]],
    n_pdhess = source$n_pdhess[[1L]],
    logLik = source$logLik[[1L]],
    max_abs_gradient_fixed = source$max_abs_gradient_fixed[[1L]],
    optimizer_attempt_count = source$optimizer_attempt_count[[1L]],
    optimizer_selected = source$optimizer_selected[[1L]],
    optimizer_selected_preset = source$optimizer_selected_preset[[1L]],
    optimizer_selected_status = source$optimizer_selected_status[[1L]],
    fallback_selected = source$fallback_selected[[1L]],
    optimizer_attempt_presets = source$optimizer_attempt_presets[[1L]],
    optimizer_attempt_statuses = source$optimizer_attempt_statuses[[1L]],
    cov_fixed_status = source$cov_fixed_status[[1L]],
    cov_fixed_dim = source$cov_fixed_dim[[1L]],
    cov_fixed_finite_count = source$cov_fixed_finite_count[[1L]],
    cov_fixed_total = source$cov_fixed_total[[1L]],
    min_cov_fixed_eigenvalue = source$min_cov_fixed_eigenvalue[[1L]],
    max_cov_fixed_eigenvalue = source$max_cov_fixed_eigenvalue[[1L]],
    n_cov_fixed_nonpositive_eigenvalues = source$n_cov_fixed_nonpositive_eigenvalues[[
      1L
    ]],
    raw_hessian_status = source$raw_hessian_status[[1L]],
    raw_hessian_message = source$raw_hessian_message[[1L]],
    direct_sd_target_count = source$direct_sd_target_count[[1L]],
    n_profile_ready_direct_sd = source$n_profile_ready_direct_sd[[1L]],
    min_direct_sd_estimate = source$min_direct_sd_estimate[[1L]],
    max_direct_sd_estimate = source$max_direct_sd_estimate[[1L]],
    n_direct_sd_at_lower_bound = source$n_direct_sd_at_lower_bound[[1L]],
    n_mu_direct_sd_at_lower_bound = source$n_mu_direct_sd_at_lower_bound[[1L]],
    n_sigma_direct_sd_at_lower_bound = source$n_sigma_direct_sd_at_lower_bound[[
      1L
    ]],
    min_mu_direct_sd_estimate = source$min_mu_direct_sd_estimate[[1L]],
    min_sigma_direct_sd_estimate = source$min_sigma_direct_sd_estimate[[1L]],
    max_abs_derived_correlation = source$max_abs_derived_correlation[[1L]],
    n_abs_derived_correlation_gt_0_95 = source$n_abs_derived_correlation_gt_0_95[[
      1L
    ]],
    n_derived_correlation_zero = source$n_derived_correlation_zero[[1L]],
    differential_status = differential_status,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-sigma-axis-differential.md",
    claim_boundary = axis_claim_boundary(
      provider,
      model_axis,
      differential_status
    ),
    next_gate = axis_next_gate(differential_status),
    stringsAsFactors = FALSE
  )
}

fit_error_axis_row <- function(provider, variant, model_axis, spec, message) {
  differential_status <- paste0(model_axis, ";fit_error")
  data.frame(
    differential_id = paste0(
      "q4_slope_sigma_axis_differential_",
      variant,
      "_",
      provider,
      "_",
      model_axis
    ),
    cell_id = paste0("qseries_", provider, "_q4_all_four_one_slope_planned"),
    variant = variant,
    model_axis = model_axis,
    formula_cell = provider_axis_formula(provider, model_axis),
    structured_type = provider,
    structured_endpoint_set = axis_endpoint_set(model_axis),
    structured_member_count = axis_member_count(model_axis),
    source_hessian_geometry = "docs/dev-log/dashboard/structured-re-q4-slope-hessian-geometry.tsv",
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-sigma-axis-differential",
      "structured-re-q4-slope-sigma-axis-differential-results.tsv"
    ),
    n_levels = spec$n,
    n_each = spec$n_each,
    intended_sd_mu1_intercept = spec$sds[["mu1_intercept"]],
    intended_sd_mu1_x = spec$sds[["mu1_x"]],
    intended_sd_mu2_intercept = spec$sds[["mu2_intercept"]],
    intended_sd_mu2_x = spec$sds[["mu2_x"]],
    intended_sd_sigma1_intercept = spec$sds[["sigma1_intercept"]],
    intended_sd_sigma1_x = spec$sds[["sigma1_x"]],
    intended_sd_sigma2_intercept = spec$sds[["sigma2_intercept"]],
    intended_sd_sigma2_x = spec$sds[["sigma2_x"]],
    fit_convergence = NA_integer_,
    n_pdhess = 0L,
    logLik = NA_real_,
    max_abs_gradient_fixed = NA_real_,
    optimizer_attempt_count = 0L,
    optimizer_selected = "NA",
    optimizer_selected_preset = "NA",
    optimizer_selected_status = "fit_error",
    fallback_selected = FALSE,
    optimizer_attempt_presets = "NA",
    optimizer_attempt_statuses = "fit_error",
    cov_fixed_status = "missing",
    cov_fixed_dim = "NA",
    cov_fixed_finite_count = 0L,
    cov_fixed_total = 0L,
    min_cov_fixed_eigenvalue = NA_real_,
    max_cov_fixed_eigenvalue = NA_real_,
    n_cov_fixed_nonpositive_eigenvalues = NA_integer_,
    raw_hessian_status = "not_run_fit_error",
    raw_hessian_message = clean_text(message),
    direct_sd_target_count = 0L,
    n_profile_ready_direct_sd = 0L,
    min_direct_sd_estimate = NA_real_,
    max_direct_sd_estimate = NA_real_,
    n_direct_sd_at_lower_bound = NA_integer_,
    n_mu_direct_sd_at_lower_bound = NA_integer_,
    n_sigma_direct_sd_at_lower_bound = NA_integer_,
    min_mu_direct_sd_estimate = NA_real_,
    min_sigma_direct_sd_estimate = NA_real_,
    max_abs_derived_correlation = NA_real_,
    n_abs_derived_correlation_gt_0_95 = NA_integer_,
    n_derived_correlation_zero = NA_integer_,
    differential_status = differential_status,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-sigma-axis-differential.md",
    claim_boundary = axis_claim_boundary(
      provider,
      model_axis,
      differential_status
    ),
    next_gate = axis_next_gate(differential_status),
    stringsAsFactors = FALSE
  )
}

diagnose_axis_fit <- function(provider, variant, model_axis, spec, fit) {
  targets <- profile_targets(fit)
  direct_sd <- targets[grepl("^sd:", targets$parm), , drop = FALSE]
  derived_cor <- targets[grepl("^cor:", targets$parm), , drop = FALSE]
  mu_sd <- direct_sd[
    !grepl("sigma", direct_sd$parm, fixed = TRUE),
    ,
    drop = FALSE
  ]
  sigma_sd <- direct_sd[
    grepl("sigma", direct_sd$parm, fixed = TRUE),
    ,
    drop = FALSE
  ]
  lower_bound <- 0.0500001
  cov_info <- finite_cov_spectrum(fit$sdr$cov.fixed)
  raw_hessian <- raw_hessian_diagnostic(fit)
  selected <- selected_attempt(fit)
  attempts <- fit$optimizer_attempts
  fallback_selected <- grepl(
    "^fallback:",
    selected$optimizer_preset[[1L]] %||% "",
    fixed = FALSE
  )
  n_mu_sd_at_lower_bound <- sum(mu_sd$estimate <= lower_bound)
  n_sigma_sd_at_lower_bound <- sum(sigma_sd$estimate <= lower_bound)
  pdhess <- isTRUE(fit$sdr$pdHess)
  differential_status <- classify_axis_geometry(
    model_axis = model_axis,
    pdhess = pdhess,
    n_mu_sd_at_lower_bound = n_mu_sd_at_lower_bound,
    n_sigma_sd_at_lower_bound = n_sigma_sd_at_lower_bound,
    cov_fixed_status = cov_info$status,
    fallback_selected = fallback_selected
  )

  data.frame(
    differential_id = paste0(
      "q4_slope_sigma_axis_differential_",
      variant,
      "_",
      provider,
      "_",
      model_axis
    ),
    cell_id = paste0("qseries_", provider, "_q4_all_four_one_slope_planned"),
    variant = variant,
    model_axis = model_axis,
    formula_cell = provider_axis_formula(provider, model_axis),
    structured_type = provider,
    structured_endpoint_set = axis_endpoint_set(model_axis),
    structured_member_count = axis_member_count(model_axis),
    source_hessian_geometry = "docs/dev-log/dashboard/structured-re-q4-slope-hessian-geometry.tsv",
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-sigma-axis-differential",
      "structured-re-q4-slope-sigma-axis-differential-results.tsv"
    ),
    n_levels = spec$n,
    n_each = spec$n_each,
    intended_sd_mu1_intercept = spec$sds[["mu1_intercept"]],
    intended_sd_mu1_x = spec$sds[["mu1_x"]],
    intended_sd_mu2_intercept = spec$sds[["mu2_intercept"]],
    intended_sd_mu2_x = spec$sds[["mu2_x"]],
    intended_sd_sigma1_intercept = spec$sds[["sigma1_intercept"]],
    intended_sd_sigma1_x = spec$sds[["sigma1_x"]],
    intended_sd_sigma2_intercept = spec$sds[["sigma2_intercept"]],
    intended_sd_sigma2_x = spec$sds[["sigma2_x"]],
    fit_convergence = fit$opt$convergence,
    n_pdhess = as.integer(pdhess),
    logLik = as.numeric(stats::logLik(fit)),
    max_abs_gradient_fixed = max(abs(fit$sdr$gradient.fixed), na.rm = TRUE),
    optimizer_attempt_count = if (is.data.frame(attempts)) {
      nrow(attempts)
    } else {
      0L
    },
    optimizer_selected = selected$optimizer[[1L]],
    optimizer_selected_preset = selected$optimizer_preset[[1L]],
    optimizer_selected_status = selected$status[[1L]],
    fallback_selected = fallback_selected,
    optimizer_attempt_presets = if (is.data.frame(attempts)) {
      paste(attempts$optimizer_preset, collapse = ";")
    } else {
      "NA"
    },
    optimizer_attempt_statuses = if (is.data.frame(attempts)) {
      paste(attempts$status, collapse = ";")
    } else {
      "NA"
    },
    cov_fixed_status = cov_info$status,
    cov_fixed_dim = if (is.matrix(fit$sdr$cov.fixed)) {
      paste(dim(fit$sdr$cov.fixed), collapse = "x")
    } else {
      "NA"
    },
    cov_fixed_finite_count = cov_info$finite_count,
    cov_fixed_total = cov_info$total,
    min_cov_fixed_eigenvalue = cov_info$min_eigen,
    max_cov_fixed_eigenvalue = cov_info$max_eigen,
    n_cov_fixed_nonpositive_eigenvalues = cov_info$n_nonpositive,
    raw_hessian_status = raw_hessian$status,
    raw_hessian_message = raw_hessian$message,
    direct_sd_target_count = nrow(direct_sd),
    n_profile_ready_direct_sd = sum(direct_sd$profile_ready),
    min_direct_sd_estimate = safe_min(direct_sd$estimate),
    max_direct_sd_estimate = if (nrow(direct_sd)) {
      max(direct_sd$estimate)
    } else {
      NA_real_
    },
    n_direct_sd_at_lower_bound = sum(direct_sd$estimate <= lower_bound),
    n_mu_direct_sd_at_lower_bound = n_mu_sd_at_lower_bound,
    n_sigma_direct_sd_at_lower_bound = n_sigma_sd_at_lower_bound,
    min_mu_direct_sd_estimate = safe_min(mu_sd$estimate),
    min_sigma_direct_sd_estimate = safe_min(sigma_sd$estimate),
    max_abs_derived_correlation = safe_max_abs(derived_cor$estimate),
    n_abs_derived_correlation_gt_0_95 = sum(abs(derived_cor$estimate) > 0.95),
    n_derived_correlation_zero = sum(abs(derived_cor$estimate) < 1e-12),
    differential_status = differential_status,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-sigma-axis-differential.md",
    claim_boundary = axis_claim_boundary(
      provider,
      model_axis,
      differential_status
    ),
    next_gate = axis_next_gate(differential_status),
    stringsAsFactors = FALSE
  )
}

hessian_geometry <- utils::read.delim(
  hessian_geometry_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

model_axes <- c("mu_axis_only", "sigma_axis_only")
rows <- list()

for (variant in names(variants)) {
  spec <- variants[[variant]]
  for (provider in providers) {
    rows[[length(rows) + 1L]] <- baseline_row(
      provider,
      variant,
      spec,
      hessian_geometry
    )
    sim <- make_provider_data(
      provider,
      seed = seeds[[provider]] + spec$seed_offset,
      n = spec$n,
      n_each = spec$n_each,
      sds = spec$sds
    )
    for (model_axis in model_axes) {
      message(
        "Fitting ",
        provider,
        " q4 sigma-axis differential model (",
        variant,
        ", ",
        model_axis,
        ")"
      )
      fit <- tryCatch(
        fit_provider_axis(provider, sim, model_axis),
        error = function(e) e
      )
      if (inherits(fit, "error")) {
        rows[[length(rows) + 1L]] <- fit_error_axis_row(
          provider,
          variant,
          model_axis,
          spec,
          conditionMessage(fit)
        )
      } else {
        rows[[length(rows) + 1L]] <- diagnose_axis_fit(
          provider,
          variant,
          model_axis,
          spec,
          fit
        )
      }
    }
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
