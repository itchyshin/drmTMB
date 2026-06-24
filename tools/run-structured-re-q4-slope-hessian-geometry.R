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
plan_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-interval-diagnostic-plan.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-slope-hessian-geometry"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-slope-hessian-geometry-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-hessian-geometry.tsv"
)

stability_script <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q4-slope-interval-stability-probe.R"
)

load_stability_helpers <- function(path) {
  exprs <- parse(path)
  stop_at <- which(vapply(
    exprs,
    function(expr) {
      is.call(expr) &&
        identical(as.character(expr[[1L]]), "<-") &&
        identical(as.character(expr[[2L]]), "plan")
    },
    logical(1L)
  ))[1L]
  if (is.na(stop_at)) {
    stop("Could not find stability helper boundary in ", path, call. = FALSE)
  }
  for (i in seq_len(stop_at - 1L)) {
    eval(exprs[[i]], envir = .GlobalEnv)
  }
}

load_stability_helpers(stability_script)

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-slope-hessian-geometry"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-slope-hessian-geometry-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-slope-hessian-geometry.tsv"
)

variants <- list(
  strong = list(
    seed_offset = 0L,
    n = 8L,
    n_each = 24L,
    sds = c(
      mu1_intercept = 0.70,
      mu1_x = 0.48,
      mu2_intercept = 0.62,
      mu2_x = 0.44,
      sigma1_intercept = 0.50,
      sigma1_x = 0.34,
      sigma2_intercept = 0.46,
      sigma2_x = 0.30
    )
  ),
  more_levels = list(
    seed_offset = 100L,
    n = 16L,
    n_each = 12L,
    sds = c(
      mu1_intercept = 0.62,
      mu1_x = 0.42,
      mu2_intercept = 0.56,
      mu2_x = 0.38,
      sigma1_intercept = 0.42,
      sigma1_x = 0.28,
      sigma2_intercept = 0.40,
      sigma2_x = 0.26
    )
  )
)

providers <- c("phylo", "spatial", "animal", "relmat")
seeds <- c(phylo = 801L, spatial = 802L, animal = 803L, relmat = 804L)

plan <- utils::read.delim(
  plan_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]

provider_formula <- function(provider) {
  row <- direct_plan[direct_plan$structured_type == provider, , drop = FALSE]
  row$formula_cell[[1L]]
}

provider_boundary <- function(provider) {
  switch(
    provider,
    phylo = "",
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q bridge marshalling,"
  )
}

provider_label <- function(provider) {
  switch(
    provider,
    phylo = "Phylo",
    spatial = "Fixed-covariance spatial",
    animal = "Animal A-matrix",
    relmat = "Relmat K-matrix"
  )
}

claim_boundary <- function(provider, geometry_status) {
  clean_text(paste(
    provider_label(provider),
    "q4 all-four one-slope Hessian-geometry diagnostic only;",
    "status =",
    geometry_status,
    "with",
    provider_boundary(provider),
    "no interval reliability, interval coverage, q4 REML, AI-REML,",
    "broad bridge support, public support, or broader q8 support promoted."
  ))
}

next_gate <- function(geometry_status) {
  if (grepl("lower_bound", geometry_status, fixed = TRUE)) {
    return(
      "Separate sigma-endpoint lower-bound geometry from covariance parameterization before denominator accounting."
    )
  }
  "Diagnose q4 all-four covariance/Hessian geometry before denominator accounting or coverage-grid design."
}

finite_cov_spectrum <- function(cov_fixed) {
  if (!is.matrix(cov_fixed)) {
    return(list(
      status = "missing",
      finite_count = 0L,
      total = 0L,
      min_eigen = NA_real_,
      max_eigen = NA_real_,
      n_nonpositive = NA_integer_
    ))
  }
  finite_count <- sum(is.finite(cov_fixed))
  total <- length(cov_fixed)
  if (finite_count != total) {
    return(list(
      status = "nonfinite",
      finite_count = finite_count,
      total = total,
      min_eigen = NA_real_,
      max_eigen = NA_real_,
      n_nonpositive = NA_integer_
    ))
  }
  sym_cov <- (cov_fixed + t(cov_fixed)) / 2
  eigenvalues <- eigen(sym_cov, symmetric = TRUE, only.values = TRUE)$values
  list(
    status = if (all(eigenvalues > 0)) {
      "finite_positive"
    } else {
      "finite_indefinite"
    },
    finite_count = finite_count,
    total = total,
    min_eigen = min(eigenvalues),
    max_eigen = max(eigenvalues),
    n_nonpositive = sum(eigenvalues <= 0)
  )
}

raw_hessian_diagnostic <- function(fit) {
  result <- tryCatch(fit$obj$he(fit$opt$par), error = function(e) e)
  if (inherits(result, "error")) {
    return(list(
      status = if (
        grepl("random effects", conditionMessage(result), fixed = TRUE)
      ) {
        "unavailable_random_effects"
      } else {
        "error"
      },
      message = clean_text(conditionMessage(result))
    ))
  }
  list(
    status = if (all(is.finite(result))) "finite" else "nonfinite",
    message = "ok"
  )
}

selected_attempt <- function(fit) {
  attempts <- fit$optimizer_attempts
  if (!is.data.frame(attempts) || !nrow(attempts)) {
    return(data.frame(
      optimizer = NA_character_,
      optimizer_preset = NA_character_,
      status = NA_character_,
      stringsAsFactors = FALSE
    ))
  }
  selected <- attempts[attempts$selected %in% TRUE, , drop = FALSE]
  if (!nrow(selected)) {
    selected <- utils::tail(attempts, 1L)
  }
  selected[, c("optimizer", "optimizer_preset", "status"), drop = FALSE]
}

classify_geometry <- function(
  n_direct_sd_at_lower_bound,
  n_sigma_sd_at_lower_bound,
  cov_fixed_status,
  fallback_selected
) {
  pieces <- character()
  if (n_sigma_sd_at_lower_bound > 0L) {
    pieces <- c(pieces, "sigma_sd_lower_bound")
  } else if (n_direct_sd_at_lower_bound > 0L) {
    pieces <- c(pieces, "direct_sd_lower_bound")
  }
  if (identical(cov_fixed_status, "nonfinite")) {
    pieces <- c(pieces, "nonfinite_cov_fixed")
  } else if (identical(cov_fixed_status, "finite_indefinite")) {
    pieces <- c(pieces, "indefinite_cov_fixed")
  }
  if (isTRUE(fallback_selected)) {
    pieces <- c(pieces, "fallback_selected")
  }
  if (!length(pieces)) {
    return("geometry_not_classified")
  }
  paste(pieces, collapse = ";")
}

fit_error_row <- function(provider, variant, spec, message) {
  geometry_status <- "fit_error"
  data.frame(
    geometry_id = paste0("q4_slope_hessian_geometry_", variant, "_", provider),
    cell_id = paste0("qseries_", provider, "_q4_all_four_one_slope_planned"),
    variant = variant,
    formula_cell = provider_formula(provider),
    structured_type = provider,
    source_stability_probe = "docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv",
    source_stability_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-interval-stability-probe",
      "structured-re-q4-slope-interval-stability-probe-results.tsv"
    ),
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-hessian-geometry",
      "structured-re-q4-slope-hessian-geometry-results.tsv"
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
    geometry_status = geometry_status,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-hessian-geometry.md",
    claim_boundary = claim_boundary(provider, geometry_status),
    next_gate = next_gate(geometry_status),
    stringsAsFactors = FALSE
  )
}

diagnose_fit <- function(provider, variant, spec, fit) {
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
  n_direct_sd_at_lower_bound <- sum(direct_sd$estimate <= lower_bound)
  n_sigma_sd_at_lower_bound <- sum(sigma_sd$estimate <= lower_bound)
  geometry_status <- classify_geometry(
    n_direct_sd_at_lower_bound = n_direct_sd_at_lower_bound,
    n_sigma_sd_at_lower_bound = n_sigma_sd_at_lower_bound,
    cov_fixed_status = cov_info$status,
    fallback_selected = fallback_selected
  )

  data.frame(
    geometry_id = paste0("q4_slope_hessian_geometry_", variant, "_", provider),
    cell_id = paste0("qseries_", provider, "_q4_all_four_one_slope_planned"),
    variant = variant,
    formula_cell = provider_formula(provider),
    structured_type = provider,
    source_stability_probe = "docs/dev-log/dashboard/structured-re-q4-slope-interval-stability-probe.tsv",
    source_stability_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-interval-stability-probe",
      "structured-re-q4-slope-interval-stability-probe-results.tsv"
    ),
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-slope-hessian-geometry",
      "structured-re-q4-slope-hessian-geometry-results.tsv"
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
    n_pdhess = as.integer(isTRUE(fit$sdr$pdHess)),
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
    min_direct_sd_estimate = min(direct_sd$estimate),
    max_direct_sd_estimate = max(direct_sd$estimate),
    n_direct_sd_at_lower_bound = n_direct_sd_at_lower_bound,
    n_mu_direct_sd_at_lower_bound = sum(mu_sd$estimate <= lower_bound),
    n_sigma_direct_sd_at_lower_bound = n_sigma_sd_at_lower_bound,
    min_mu_direct_sd_estimate = min(mu_sd$estimate),
    min_sigma_direct_sd_estimate = min(sigma_sd$estimate),
    max_abs_derived_correlation = max(abs(derived_cor$estimate)),
    n_abs_derived_correlation_gt_0_95 = sum(abs(derived_cor$estimate) > 0.95),
    n_derived_correlation_zero = sum(abs(derived_cor$estimate) < 1e-12),
    geometry_status = geometry_status,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-slope-hessian-geometry.md",
    claim_boundary = claim_boundary(provider, geometry_status),
    next_gate = next_gate(geometry_status),
    stringsAsFactors = FALSE
  )
}

rows <- list()

for (variant in names(variants)) {
  spec <- variants[[variant]]
  for (provider in providers) {
    message("Fitting ", provider, " q4 Hessian geometry model (", variant, ")")
    sim <- make_provider_data(
      provider,
      seed = seeds[[provider]] + spec$seed_offset,
      n = spec$n,
      n_each = spec$n_each,
      sds = spec$sds
    )
    fit <- tryCatch(fit_provider(provider, sim), error = function(e) e)
    if (inherits(fit, "error")) {
      rows[[length(rows) + 1L]] <- fit_error_row(
        provider,
        variant,
        spec,
        conditionMessage(fit)
      )
    } else {
      rows[[length(rows) + 1L]] <- diagnose_fit(provider, variant, spec, fit)
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
