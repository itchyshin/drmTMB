#!/usr/bin/env Rscript
#
# Small q4 animal one-theta release diagnostic.
#
# This runner starts from the passing zero-correlation q4 animal map, releases
# exactly one theta_phylo coordinate at a time under the production TMB
# parameterization, and records whether any single correlation coordinate
# explains the hard-seed all-free blocker. It is diagnostic evidence only:
# interval coverage, inference_ready, supported, q8, REML, AI-REML, and broad
# bridge support are out of scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-animal-one-theta-release-diagnostic.R [options]",
      "",
      "Options:",
      "  --replicates=a,b          Replicate indices (default: 910101,910102,910110).",
      "  --theta-indices=a,b       Theta indices to release, or all (default: all).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate + variant offset (default: 910000).",
      "  --variant=NAME            Variant to run: strong or more_levels (default: more_levels).",
      "  --output-dir=PATH         Artifact directory; --out-dir is accepted as an alias.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard sidecar.",
      "",
      "This is diagnostic evidence only. It does not promote q4/q8 interval",
      "coverage, inference_ready, supported, REML, AI-REML, or bridge support.",
      sep = "\n"
    ),
    "\n"
  )
  quit(status = 0L)
}

arg_value <- function(name, default = NULL) {
  dashed <- paste0("--", name, "=")
  underscored <- gsub("-", "_", dashed, fixed = TRUE)
  hit <- c(
    grep(paste0("^", dashed), args, value = TRUE),
    grep(paste0("^", underscored), args, value = TRUE)
  )
  if (!length(hit)) {
    return(default)
  }
  sub("^[^=]+=", "", hit[[length(hit)]])
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (any(args %in% paste0("--", name))) {
    return(TRUE)
  }
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
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

replicate_arg <- strsplit(
  arg_value("replicates", "910101,910102,910110"),
  ",",
  fixed = TRUE
)[[1L]]
replicate_indices <- as.integer(trimws(replicate_arg[nzchar(trimws(
  replicate_arg
))]))
if (!length(replicate_indices) || any(!is.finite(replicate_indices))) {
  stop("`--replicates` must be a comma-separated integer list.", call. = FALSE)
}
seed_base <- as.integer(arg_value("seed-base", "910000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
variant <- arg_value("variant", "more_levels")
theta_arg <- arg_value("theta-indices", "all")
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-q4-animal-one-theta-release-local"
)
artifact_dir_arg <- arg_value(
  "output-dir",
  arg_value("out-dir", default_artifact_dir)
)
artifact_dir <- normalizePath(artifact_dir_arg, mustWork = FALSE)
if (dir.exists(artifact_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-one-theta-release-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-one-theta-release-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-one-theta-release-run-log.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

load_result <- tryCatch(
  {
    suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
    list(
      ok = TRUE,
      status = "devtools_load_all",
      detail = "loaded current source with devtools::load_all"
    )
  },
  error = function(e) {
    list(
      ok = FALSE,
      status = "devtools_load_all_failed",
      detail = clean_text(conditionMessage(e))
    )
  }
)
if (!isTRUE(load_result$ok)) {
  stop(load_result$detail, call. = FALSE)
}

source_q4_stability_prefix <- function() {
  runner <- file.path(
    repo_root,
    "tools",
    "run-structured-re-q4-slope-interval-stability-probe.R"
  )
  src <- readLines(runner, warn = FALSE)
  src <- src[!grepl("^devtools::load_all\\(", src)]
  main_line <- grep("^plan\\s*<-\\s*utils::read.delim", src)[1L]
  if (!is.finite(main_line)) {
    stop("Could not find q4 stability probe main entrypoint.", call. = FALSE)
  }
  tmp <- tempfile(fileext = ".R")
  writeLines(src[seq_len(main_line - 1L)], tmp)
  source(tmp, local = .GlobalEnv)
  invisible(TRUE)
}
source_q4_stability_prefix()
artifact_dir <- normalizePath(artifact_dir_arg, mustWork = FALSE)
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-one-theta-release-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-one-theta-release-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-one-theta-release-run-log.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

q4_variants <- list(
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
    seed_offset = 100000L,
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
if (!variant %in% names(q4_variants)) {
  stop("`--variant` must be `strong` or `more_levels`.", call. = FALSE)
}
spec <- q4_variants[[variant]]

endpoint_members <- c(
  "mu1:(Intercept)",
  "mu1:x",
  "mu2:(Intercept)",
  "mu2:x",
  "sigma1:(Intercept)",
  "sigma1:x",
  "sigma2:(Intercept)",
  "sigma2:x"
)
endpoint_tokens <- names(spec$sds)
theta_pair_index <- which(
  lower.tri(matrix(FALSE, length(endpoint_members), length(endpoint_members))),
  arr.ind = TRUE
)
theta_pair_map <- data.frame(
  theta_index = seq_len(nrow(theta_pair_index)),
  assumed_lower_tri_row = theta_pair_index[, "row"],
  assumed_lower_tri_col = theta_pair_index[, "col"],
  endpoint_i = endpoint_members[theta_pair_index[, "row"]],
  endpoint_j = endpoint_members[theta_pair_index[, "col"]],
  endpoint_token_i = endpoint_tokens[theta_pair_index[, "row"]],
  endpoint_token_j = endpoint_tokens[theta_pair_index[, "col"]],
  stringsAsFactors = FALSE
)
if (identical(tolower(theta_arg), "all")) {
  theta_indices <- theta_pair_map$theta_index
} else {
  theta_indices <- as.integer(strsplit(theta_arg, ",", fixed = TRUE)[[1L]])
}
theta_indices <- sort(unique(theta_indices[is.finite(theta_indices)]))
if (
  !length(theta_indices) ||
    any(theta_indices < 1L) ||
    any(theta_indices > nrow(theta_pair_map))
) {
  stop(
    "`--theta-indices` must be `all` or integers from 1 to 28.",
    call. = FALSE
  )
}

format_num <- function(x, digits = 8L) {
  if (!is.finite(x)) {
    return("NA")
  }
  formatC(x, digits = digits, format = "fg", flag = "#")
}

matrix_eigenvalues <- function(x) {
  if (is.null(x) || !length(x)) {
    return(NULL)
  }
  mat <- tryCatch(as.matrix(x), error = function(e) NULL)
  if (is.null(mat) || length(dim(mat)) != 2L || nrow(mat) != ncol(mat)) {
    return(NULL)
  }
  if (!all(is.finite(mat))) {
    return(NULL)
  }
  tryCatch(
    eigen(mat, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) NULL
  )
}

log10_condition <- function(values) {
  values <- abs(values)
  values <- values[is.finite(values) & values > 0]
  if (!length(values)) {
    return(NA_real_)
  }
  log10(max(values) / min(values))
}

make_animal_formula <- function(sim) {
  env <- new.env(parent = globalenv())
  env$A <- sim$A
  form <- with(
    env,
    bf(
      mu1 = y1 ~ x + animal(1 + x | p | id, A = A),
      mu2 = y2 ~ x + animal(1 + x | p | id, A = A),
      sigma1 = ~ z + animal(1 + x | p | id, A = A),
      sigma2 = ~ z + animal(1 + x | p | id, A = A),
      rho12 = ~1
    )
  )
  list(formula = form, env = env)
}

copy_start_from_fit <- function(start, fit) {
  if (is.null(fit) || is.null(fit$obj) || is.null(fit$opt)) {
    return(start)
  }
  source <- fit$obj$env$parList(fit$opt$par)
  for (nm in intersect(names(start), names(source))) {
    if (length(start[[nm]]) == length(source[[nm]])) {
      start[[nm]] <- unname(source[[nm]])
    }
  }
  start
}

build_animal_q4_object <- function(
  sim,
  theta_index = NA_integer_,
  source_fit = NULL
) {
  form <- make_animal_formula(sim)
  build_spec <- getFromNamespace("drm_build_biv_gaussian_spec", "drmTMB")
  spec0 <- build_spec(
    formula = form$formula,
    data = sim$data,
    env = form$env,
    weights = NULL
  )
  spec0$response_names <- getFromNamespace("drm_spec_response_names", "drmTMB")(
    spec0
  )
  spec0 <- getFromNamespace("add_covariance_probe_parameter", "drmTMB")(spec0)
  spec0$start <- copy_start_from_fit(spec0$start, source_fit)
  spec0$start$theta_phylo[] <- 0
  theta_map <- rep(NA_integer_, length(spec0$start$theta_phylo))
  if (is.finite(theta_index)) {
    theta_map[[theta_index]] <- 1L
  }
  spec0$map$theta_phylo <- factor(theta_map)

  obj <- TMB::MakeADFun(
    data = spec0$tmb_data,
    parameters = spec0$start,
    map = spec0$map,
    random = spec0$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )
  list(obj = obj, spec = spec0)
}

fit_q4_object <- function(obj) {
  control <- drm_control(optimizer = list(eval.max = 1600, iter.max = 1600))
  warnings <- character()
  opt_result <- withCallingHandlers(
    tryCatch(
      getFromNamespace("drm_optimize_with_preset_retry", "drmTMB")(
        obj,
        control,
        warn = FALSE
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(opt_result, "error")) {
    return(list(fit_error = opt_result, warnings = warnings))
  }
  opt <- opt_result$opt
  getFromNamespace("drm_pin_tmb_object_to_optimum", "drmTMB")(obj, opt)
  sdr <- withCallingHandlers(
    tryCatch(
      TMB::sdreport(obj, getJointPrecision = FALSE),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(
    obj = obj,
    opt = opt,
    sdr = sdr,
    attempts = opt_result$attempts,
    selected = opt_result$selected,
    warnings = warnings
  )
}

direct_sd_from_fit <- function(fit) {
  if (!is.null(fit$fit_error) || inherits(fit$sdr, "error")) {
    return(rep(NA_real_, length(endpoint_members)))
  }
  report <- tryCatch(fit$obj$report(), error = function(e) list())
  if (!is.null(report$sd_phylo)) {
    out <- as.numeric(report$sd_phylo)
  } else {
    par_list <- fit$obj$env$parList(fit$opt$par)
    out <- exp(as.numeric(par_list$log_sd_phylo %||% numeric()))
  }
  if (length(out) != length(endpoint_members)) {
    return(rep(NA_real_, length(endpoint_members)))
  }
  stats::setNames(out, endpoint_members)
}

theta_from_fit <- function(fit) {
  if (!is.null(fit$fit_error) || inherits(fit$sdr, "error")) {
    return(rep(NA_real_, nrow(theta_pair_map)))
  }
  report <- tryCatch(fit$obj$report(), error = function(e) list())
  theta <- as.numeric(report$theta_phylo %||% numeric())
  if (length(theta) != nrow(theta_pair_map)) {
    return(rep(NA_real_, nrow(theta_pair_map)))
  }
  theta
}

fit_geometry <- function(fit) {
  if (!is.null(fit$fit_error)) {
    return(list(
      fit_error = TRUE,
      sdreport_error = FALSE,
      error_message = clean_text(conditionMessage(fit$fit_error)),
      convergence = NA_integer_,
      pdHess = FALSE,
      objective = NA_real_,
      selected = "error",
      attempt_count = 0L,
      max_gradient = NA_real_,
      cov_neg = NA_integer_,
      cov_min = NA_real_,
      theta_max = NA_real_,
      corr_condition = NA_real_,
      direct_sd_min = NA_real_,
      direct_sd_max = NA_real_
    ))
  }
  if (inherits(fit$sdr, "error")) {
    return(list(
      fit_error = FALSE,
      sdreport_error = TRUE,
      error_message = clean_text(conditionMessage(fit$sdr)),
      convergence = as.integer(fit$opt$convergence),
      pdHess = FALSE,
      objective = as.numeric(fit$opt$objective),
      selected = fit$selected$optimizer_preset %||% "NA",
      attempt_count = nrow(fit$attempts),
      max_gradient = NA_real_,
      cov_neg = NA_integer_,
      cov_min = NA_real_,
      theta_max = NA_real_,
      corr_condition = NA_real_,
      direct_sd_min = NA_real_,
      direct_sd_max = NA_real_
    ))
  }
  gradient <- fit$sdr$gradient.fixed %||%
    tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  max_gradient <- if (length(gradient) && any(is.finite(gradient))) {
    max(abs(gradient), na.rm = TRUE)
  } else {
    NA_real_
  }
  cov_eig <- tryCatch(
    eigen(fit$sdr$cov.fixed, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) NULL
  )
  report <- tryCatch(fit$obj$report(), error = function(e) list())
  corr_eig <- matrix_eigenvalues(report$phylo_q4_corr %||% NULL)
  direct_sd <- direct_sd_from_fit(fit)
  theta <- theta_from_fit(fit)
  list(
    fit_error = FALSE,
    sdreport_error = FALSE,
    error_message = "NA",
    convergence = as.integer(fit$opt$convergence),
    pdHess = isTRUE(fit$sdr$pdHess),
    objective = as.numeric(fit$opt$objective),
    selected = fit$selected$optimizer_preset %||% "NA",
    attempt_count = nrow(fit$attempts),
    max_gradient = max_gradient,
    cov_neg = if (is.null(cov_eig)) NA_integer_ else sum(cov_eig <= 0),
    cov_min = if (is.null(cov_eig)) NA_real_ else min(cov_eig),
    theta_max = if (length(theta)) max(abs(theta), na.rm = TRUE) else NA_real_,
    corr_condition = log10_condition(corr_eig),
    direct_sd_min = min(direct_sd, na.rm = TRUE),
    direct_sd_max = max(direct_sd, na.rm = TRUE)
  )
}

fit_status <- function(geom, release_kind) {
  if (isTRUE(geom$fit_error)) {
    return("fit_error")
  }
  if (isTRUE(geom$sdreport_error)) {
    return("sdreport_error")
  }
  if (
    isTRUE(geom$pdHess) &&
      identical(geom$convergence, 0L) &&
      is.finite(geom$max_gradient) &&
      geom$max_gradient <= 1e-3 &&
      identical(as.integer(geom$cov_neg), 0L)
  ) {
    if (identical(release_kind, "zero_correlation_control")) {
      return("zero_correlation_control_pass")
    }
    return("one_theta_release_pass_smoke")
  }
  if (
    !isTRUE(geom$pdHess) &&
      is.finite(geom$max_gradient) &&
      geom$max_gradient > 1e-3
  ) {
    return("gradient_hessian_blocked")
  }
  if (!isTRUE(geom$pdHess)) {
    return("hessian_blocked")
  }
  "release_watch"
}

blocker_component <- function(status, objective_gain) {
  if (identical(status, "zero_correlation_control_pass")) {
    return("free_q4_correlation_block_removed")
  }
  if (identical(status, "one_theta_release_pass_smoke")) {
    if (is.finite(objective_gain) && objective_gain > 0) {
      return("single_theta_candidate")
    }
    return("single_theta_fit_stable_without_objective_gain")
  }
  if (status %in% c("gradient_hessian_blocked", "hessian_blocked")) {
    return("one_theta_hessian_blocked")
  }
  status
}

collapse_named_numbers <- function(x, digits = 8L) {
  if (!length(x)) {
    return("NA")
  }
  paste(
    paste0(
      names(x),
      "=",
      vapply(x, format_num, character(1L), digits = digits)
    ),
    collapse = ";"
  )
}

claim_boundary_text <- paste(
  "Animal q4 all-four one-slope one-theta release diagnostic only:",
  "each row releases exactly one theta_phylo coordinate from the",
  "zero-correlation map under the production TMB parameterization;",
  "theta-pair labels are an assumed lower-triangle diagnostic map;",
  "no coverage, no inference_ready, no supported, no q8 inference,",
  "no q4 REML, no REML, no AI-REML, no broad q4 bridge support,",
  "no production parameterization change, and no derived-correlation interval claim."
)
next_gate_text <- paste(
  "Use this one-theta release diagnostic to decide whether a single",
  "correlation coordinate, multiple-coordinate MAP/penalty sensitivity,",
  "or a production transform is the next local q4 animal hard-seed gate;",
  "do not submit DRAC coverage or edit status tiers until Fisher/Rose",
  "approve denominator policy and the hard-seed correlation gate."
)

rows <- list()
for (replicate_index in replicate_indices) {
  seed <- seed_base + replicate_index + spec$seed_offset
  message(
    "Running animal q4 one-theta release replicate ",
    replicate_index,
    " (",
    variant,
    ", seed ",
    seed,
    ")"
  )
  sim <- make_provider_data(
    "animal",
    seed = seed,
    n = spec$n,
    n_each = spec$n_each,
    sds = spec$sds
  )
  zero_built <- build_animal_q4_object(sim, theta_index = NA_integer_)
  zero_fit <- fit_q4_object(zero_built$obj)
  zero_fit$obj <- zero_built$obj
  zero_geom <- fit_geometry(zero_fit)
  zero_status <- fit_status(zero_geom, "zero_correlation_control")
  zero_direct_sd <- direct_sd_from_fit(zero_fit)

  for (theta_index in theta_indices) {
    pair <- theta_pair_map[
      theta_pair_map$theta_index == theta_index,
      ,
      drop = FALSE
    ]
    message("  theta index: ", theta_index)
    fit <- NULL
    if (!isTRUE(zero_geom$fit_error) && !isTRUE(zero_geom$sdreport_error)) {
      built <- build_animal_q4_object(
        sim,
        theta_index = theta_index,
        source_fit = zero_fit
      )
      fit <- fit_q4_object(built$obj)
      fit$obj <- built$obj
      geom <- fit_geometry(fit)
    } else {
      fit <- list(
        fit_error = simpleError(
          "zero-correlation control failed; release fit not run"
        ),
        warnings = character()
      )
      geom <- fit_geometry(fit)
    }

    status <- fit_status(geom, "one_theta_release")
    direct_sd <- direct_sd_from_fit(fit)
    direct_sd_shift <- direct_sd - zero_direct_sd
    theta <- theta_from_fit(fit)
    theta_value <- theta[[theta_index]]
    objective_gain <- zero_geom$objective - geom$objective
    rows[[length(rows) + 1L]] <- data.frame(
      diagnostic_id = paste0(
        "q4_animal_one_theta_release_",
        replicate_index,
        "_theta_",
        theta_index
      ),
      cell_id = "qseries_animal_q4_all_four_one_slope_planned",
      variant = variant,
      replicate_index = replicate_index,
      seed = seed,
      theta_index = theta_index,
      assumed_lower_tri_row = pair$assumed_lower_tri_row[[1L]],
      assumed_lower_tri_col = pair$assumed_lower_tri_col[[1L]],
      endpoint_i = pair$endpoint_i[[1L]],
      endpoint_j = pair$endpoint_j[[1L]],
      endpoint_token_i = pair$endpoint_token_i[[1L]],
      endpoint_token_j = pair$endpoint_token_j[[1L]],
      n_levels = spec$n,
      n_each = spec$n_each,
      theta_release_map = "one_free_other_27_fixed_zero",
      theta_parameterization = "current_tmb_theta",
      start_log_sd_source = "zero_correlation_control_fit",
      start_theta_source = "zero",
      zero_control_status = zero_status,
      zero_control_convergence = zero_geom$convergence,
      zero_control_pdHess = zero_geom$pdHess,
      zero_control_objective = format_num(zero_geom$objective, digits = 10L),
      zero_control_max_abs_gradient_fixed = format_num(
        zero_geom$max_gradient,
        digits = 8L
      ),
      zero_control_sdr_cov_fixed_eig_min = format_num(
        zero_geom$cov_min,
        digits = 8L
      ),
      zero_control_sdr_cov_fixed_n_negative = zero_geom$cov_neg,
      fit_error = geom$fit_error,
      sdreport_error = geom$sdreport_error,
      convergence = geom$convergence,
      pdHess = geom$pdHess,
      objective = format_num(geom$objective, digits = 10L),
      objective_gain_vs_zero = format_num(objective_gain, digits = 10L),
      optimizer_selected_preset = geom$selected,
      optimizer_attempt_count = geom$attempt_count,
      warning_count = length(fit$warnings %||% character()),
      warning_messages = clean_text(paste(
        unique(fit$warnings %||% character()),
        collapse = " | "
      )),
      error_message = geom$error_message,
      max_abs_gradient_fixed = format_num(geom$max_gradient, digits = 8L),
      sdr_cov_fixed_eig_min = format_num(geom$cov_min, digits = 8L),
      sdr_cov_fixed_n_negative = geom$cov_neg,
      theta_value = format_num(theta_value, digits = 8L),
      theta_abs = format_num(abs(theta_value), digits = 8L),
      theta_max_abs = format_num(geom$theta_max, digits = 8L),
      corr_log10_condition = format_num(geom$corr_condition, digits = 8L),
      min_direct_sd_estimate = format_num(geom$direct_sd_min, digits = 8L),
      max_direct_sd_estimate = format_num(geom$direct_sd_max, digits = 8L),
      max_abs_direct_sd_shift_vs_zero = format_num(
        max(abs(direct_sd_shift), na.rm = TRUE),
        digits = 8L
      ),
      direct_sd_estimates = collapse_named_numbers(direct_sd, digits = 8L),
      direct_sd_shift_vs_zero = collapse_named_numbers(
        direct_sd_shift,
        digits = 8L
      ),
      release_status = status,
      blocker_component = blocker_component(status, objective_gain),
      interval_claim_status = "diagnostic_only",
      coverage_status = "not_evaluable",
      source_artifact = paste(
        "docs/dev-log/simulation-artifacts",
        basename(artifact_dir),
        "structured-re-q4-animal-one-theta-release-diagnostic.tsv",
        sep = "/"
      ),
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-q4-animal-one-theta-release-diagnostic.md",
      claim_boundary = claim_boundary_text,
      next_gate = next_gate_text,
      stringsAsFactors = FALSE
    )
  }
}

out <- do.call(rbind, rows)
rownames(out) <- NULL
run_log <- data.frame(
  log_id = "q4_animal_one_theta_release_diagnostic",
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  replicates = paste(replicate_indices, collapse = ","),
  theta_indices = if (length(theta_indices) == nrow(theta_pair_map)) {
    "all"
  } else {
    paste(theta_indices, collapse = ",")
  },
  seed_base = seed_base,
  variant = variant,
  load_status = load_result$status,
  load_detail = load_result$detail,
  output_dir = artifact_dir,
  dashboard_output = if (write_dashboard) dashboard_path else "not_written",
  claim_boundary = claim_boundary_text,
  next_gate = next_gate_text,
  stringsAsFactors = FALSE
)

write_tsv(out, artifact_path)
write_tsv(run_log, run_log_path)
if (write_dashboard) {
  write_tsv(out, dashboard_path)
}

git_sha <- tryCatch(
  {
    old_wd <- setwd(repo_root)
    on.exit(setwd(old_wd), add = TRUE)
    out <- system2(
      "git",
      c("rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = FALSE
    )
    if (!length(out)) "unknown" else out[[1L]]
  },
  error = function(e) "unknown"
)
writeLines(git_sha, git_sha_path)
writeLines(capture.output(sessionInfo()), session_info_path)

message("Wrote one-theta release artifact: ", artifact_path)
if (write_dashboard) {
  message("Wrote dashboard sidecar: ", dashboard_path)
}
