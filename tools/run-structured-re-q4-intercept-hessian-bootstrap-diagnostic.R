#!/usr/bin/env Rscript

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
smoke_script <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q4-intercept-interval-smoke.R"
)
precheck_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-denominator-precheck.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-interval-diagnostic-status.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-q4-intercept-hessian-bootstrap-diagnostic"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-intercept-hessian-bootstrap-diagnostic-results.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv"
)

source_precheck_rel <- file.path(
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-q4-intercept-denominator-precheck.tsv"
)
source_status_rel <- file.path(
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-q4-intercept-interval-diagnostic-status.tsv"
)
source_interval_artifact_rel <- file.path(
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-q4-intercept-interval-smoke",
  "structured-re-q4-intercept-interval-smoke-results.tsv"
)
source_artifact_rel <- file.path(
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-q4-intercept-hessian-bootstrap-diagnostic",
  "structured-re-q4-intercept-hessian-bootstrap-diagnostic-results.tsv"
)
evidence_rel <- file.path(
  "docs",
  "dev-log",
  "after-task",
  "2026-06-25-q4-intercept-hessian-bootstrap-diagnostic.md"
)

load_smoke_helpers <- function(path) {
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
    stop("Could not find smoke helper boundary in ", path, call. = FALSE)
  }
  for (i in seq_len(stop_at - 1L)) {
    eval(exprs[[i]], envir = .GlobalEnv)
  }
}

load_smoke_helpers(smoke_script)

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-25-q4-intercept-hessian-bootstrap-diagnostic"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-intercept-hessian-bootstrap-diagnostic-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-interval-diagnostic-status.tsv"
)
output_path <- file.path(
  dashboard_dir,
  "structured-re-q4-intercept-hessian-bootstrap-diagnostic.tsv"
)
evidence_rel <- file.path(
  "docs",
  "dev-log",
  "after-task",
  "2026-06-25-q4-intercept-hessian-bootstrap-diagnostic.md"
)

precheck <- utils::read.delim(
  precheck_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
status <- utils::read.delim(
  status_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

provider_label <- function(provider) {
  switch(
    provider,
    phylo = "Phylo",
    spatial = "Fixed-covariance spatial",
    animal = "Animal A-matrix",
    relmat = "Relmat K-matrix",
    provider
  )
}

provider_boundary <- function(provider) {
  switch(
    provider,
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q bridge marshalling,",
    ""
  )
}

provider_formula <- function(provider) {
  row <- precheck[precheck$structured_type == provider, , drop = FALSE]
  row$formula_cell[[1L]]
}

collapse_unique <- function(x) {
  x <- unique(as.character(x))
  x <- x[!is.na(x) & nzchar(x)]
  if (!length(x)) {
    return("NA")
  }
  paste(sort(x), collapse = ";")
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

diagnostic_status <- function(
  provider,
  pdhess,
  cov_fixed_status,
  precheck_rows
) {
  if (!isTRUE(pdhess)) {
    pieces <- c("pdhess_false")
    if (identical(cov_fixed_status, "nonfinite")) {
      pieces <- c(pieces, "nonfinite_cov_fixed")
    } else if (identical(cov_fixed_status, "finite_indefinite")) {
      pieces <- c(pieces, "indefinite_cov_fixed")
    }
    return(paste(pieces, collapse = ";"))
  }
  if (
    any(
      precheck_rows$denominator_admission == "not_admitted_bootstrap_nonfinite"
    )
  ) {
    return("bootstrap_nonfinite_after_pdhess_true")
  }
  "diagnostic_not_blocked"
}

claim_boundary <- function(provider, diagnostic_status) {
  clean_text(paste0(
    provider_label(provider),
    " q4 all-four intercept Hessian/bootstrap diagnostic only; status = ",
    diagnostic_status,
    ";",
    provider_boundary(provider),
    " derived-correlation intervals still blocked, no interval reliability,",
    " interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,",
    " HSquared AI-REML, broad bridge support, public support, calibrated",
    " coverage wording, denominator admission, or DRAC/Totoro execution",
    " promoted."
  ))
}

next_gate <- function(diagnostic_status) {
  if (identical(diagnostic_status, "bootstrap_nonfinite_after_pdhess_true")) {
    return(paste(
      "Diagnose bootstrap nonfinite behavior under replicated fixtures",
      "before denominator accounting or coverage-grid design."
    ))
  }
  paste(
    "Diagnose Hessian geometry under stability variants before denominator",
    "accounting or coverage-grid design."
  )
}

fit_error_row <- function(provider, sim, message) {
  diagnostic_status <- "fit_error"
  provider_precheck <- precheck[
    precheck$structured_type == provider,
    ,
    drop = FALSE
  ]
  provider_status <- status[status$structured_type == provider, , drop = FALSE]
  data.frame(
    diagnostic_id = paste0("q4_intercept_hessian_bootstrap_", provider),
    cell_id = paste0("qseries_", provider, "_q4_all_four_intercept"),
    formula_cell = provider_formula(provider),
    structured_type = provider,
    source_denominator_precheck = source_precheck_rel,
    source_interval_status = source_status_rel,
    source_interval_artifact = source_interval_artifact_rel,
    source_artifact = source_artifact_rel,
    n_levels = length(unique(sim$data[[sim$group]])),
    n_each = as.integer(table(sim$data[[sim$group]])[[1L]]),
    intended_sd_mu1_intercept = make_endpoint_covariance()[1L, 1L]^0.5,
    intended_sd_mu2_intercept = make_endpoint_covariance()[2L, 2L]^0.5,
    intended_sd_sigma1_intercept = make_endpoint_covariance()[3L, 3L]^0.5,
    intended_sd_sigma2_intercept = make_endpoint_covariance()[4L, 4L]^0.5,
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
    max_abs_derived_correlation = NA_real_,
    n_abs_derived_correlation_gt_0_95 = NA_integer_,
    n_derived_correlation_zero = NA_integer_,
    n_precheck_targets = nrow(provider_precheck),
    n_precheck_not_admitted_pdhess_false = sum(
      provider_precheck$denominator_admission == "not_admitted_pdhess_false"
    ),
    n_precheck_not_admitted_bootstrap_nonfinite = sum(
      provider_precheck$denominator_admission ==
        "not_admitted_bootstrap_nonfinite"
    ),
    smoke_interval_statuses = collapse_unique(
      provider_precheck$smoke_interval_status
    ),
    smoke_wald_statuses = collapse_unique(provider_precheck$smoke_wald_status),
    smoke_profile_statuses = collapse_unique(
      provider_precheck$smoke_profile_status
    ),
    smoke_bootstrap_statuses = collapse_unique(
      provider_precheck$smoke_bootstrap_status
    ),
    smoke_failure_classes = collapse_unique(provider_status$failure_class),
    n_smoke_bootstrap_nonfinite = sum(
      provider_precheck$smoke_bootstrap_status == "nonfinite"
    ),
    precheck_diagnosis = collapse_unique(provider_precheck$precheck_diagnosis),
    denominator_admission = collapse_unique(
      provider_precheck$denominator_admission
    ),
    diagnostic_status = diagnostic_status,
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = evidence_rel,
    claim_boundary = claim_boundary(provider, diagnostic_status),
    next_gate = next_gate(diagnostic_status),
    stringsAsFactors = FALSE
  )
}

diagnose_fit <- function(provider, sim, fit) {
  endpoint_cov <- make_endpoint_covariance()
  provider_precheck <- precheck[
    precheck$structured_type == provider,
    ,
    drop = FALSE
  ]
  provider_status <- status[status$structured_type == provider, , drop = FALSE]
  targets <- profile_targets(fit)
  direct_sd <- targets[grepl("^sd:", targets$parm), , drop = FALSE]
  derived_cor <- targets[grepl("^cor:", targets$parm), , drop = FALSE]
  cov_info <- finite_cov_spectrum(fit$sdr$cov.fixed)
  raw_hessian <- raw_hessian_diagnostic(fit)
  selected <- selected_attempt(fit)
  attempts <- fit$optimizer_attempts
  fallback_selected <- grepl(
    "^fallback:",
    selected$optimizer_preset[[1L]] %||% "",
    fixed = FALSE
  )
  pdhess <- isTRUE(fit$sdr$pdHess)
  diagnostic_status <- diagnostic_status(
    provider,
    pdhess,
    cov_info$status,
    provider_precheck
  )

  data.frame(
    diagnostic_id = paste0("q4_intercept_hessian_bootstrap_", provider),
    cell_id = paste0("qseries_", provider, "_q4_all_four_intercept"),
    formula_cell = provider_formula(provider),
    structured_type = provider,
    source_denominator_precheck = source_precheck_rel,
    source_interval_status = source_status_rel,
    source_interval_artifact = source_interval_artifact_rel,
    source_artifact = source_artifact_rel,
    n_levels = length(unique(sim$data[[sim$group]])),
    n_each = as.integer(table(sim$data[[sim$group]])[[1L]]),
    intended_sd_mu1_intercept = endpoint_cov[1L, 1L]^0.5,
    intended_sd_mu2_intercept = endpoint_cov[2L, 2L]^0.5,
    intended_sd_sigma1_intercept = endpoint_cov[3L, 3L]^0.5,
    intended_sd_sigma2_intercept = endpoint_cov[4L, 4L]^0.5,
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
    min_direct_sd_estimate = min(direct_sd$estimate),
    max_direct_sd_estimate = max(direct_sd$estimate),
    max_abs_derived_correlation = max(abs(derived_cor$estimate)),
    n_abs_derived_correlation_gt_0_95 = sum(abs(derived_cor$estimate) > 0.95),
    n_derived_correlation_zero = sum(abs(derived_cor$estimate) < 1e-12),
    n_precheck_targets = nrow(provider_precheck),
    n_precheck_not_admitted_pdhess_false = sum(
      provider_precheck$denominator_admission == "not_admitted_pdhess_false"
    ),
    n_precheck_not_admitted_bootstrap_nonfinite = sum(
      provider_precheck$denominator_admission ==
        "not_admitted_bootstrap_nonfinite"
    ),
    smoke_interval_statuses = collapse_unique(
      provider_precheck$smoke_interval_status
    ),
    smoke_wald_statuses = collapse_unique(provider_precheck$smoke_wald_status),
    smoke_profile_statuses = collapse_unique(
      provider_precheck$smoke_profile_status
    ),
    smoke_bootstrap_statuses = collapse_unique(
      provider_precheck$smoke_bootstrap_status
    ),
    smoke_failure_classes = collapse_unique(provider_status$failure_class),
    n_smoke_bootstrap_nonfinite = sum(
      provider_precheck$smoke_bootstrap_status == "nonfinite"
    ),
    precheck_diagnosis = collapse_unique(provider_precheck$precheck_diagnosis),
    denominator_admission = collapse_unique(
      provider_precheck$denominator_admission
    ),
    diagnostic_status = diagnostic_status,
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = evidence_rel,
    claim_boundary = claim_boundary(provider, diagnostic_status),
    next_gate = next_gate(diagnostic_status),
    stringsAsFactors = FALSE
  )
}

providers <- c("phylo", "spatial", "animal", "relmat")
seeds <- c(phylo = 901L, spatial = 902L, animal = 903L, relmat = 904L)
rows <- list()

for (provider in providers) {
  message("Diagnosing ", provider, " q4 all-four intercept fit")
  sim <- make_provider_data(provider, seed = seeds[[provider]])
  fit <- tryCatch(fit_provider(provider, sim), error = function(e) e)
  rows[[length(rows) + 1L]] <- if (inherits(fit, "error")) {
    fit_error_row(provider, sim, conditionMessage(fit))
  } else {
    diagnose_fit(provider, sim, fit)
  }
}

out <- do.call(rbind, rows)
character_cols <- vapply(out, is.character, logical(1L))
out[character_cols] <- lapply(out[character_cols], clean_text)

utils::write.table(
  out,
  artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  out,
  output_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(output_path, winslash = "/"))
