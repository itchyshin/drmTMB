#!/usr/bin/env Rscript
#
# q4 animal partial-Cholesky transform diagnostic.
#
# This runner compares a zero-correlation positive control, the current
# all-free staged fit, and a partial-Cholesky correlation transform for the hard
# animal q4 all-four one-slope seeds. It is diagnostic/admission evidence only:
# interval coverage, inference_ready, supported, q8, REML, AI-REML, production
# status changes, and broad bridge support are out of scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-animal-partial-cholesky-transform-diagnostic.R [options]",
      "",
      "Options:",
      "  --replicates=a,b          Replicate indices (default: 910101,910102,910110).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate + variant offset (default: 910000).",
      "  --variant=NAME            Variant to run: strong or more_levels (default: more_levels).",
      "  --output-dir=PATH         Artifact directory; --out-dir is accepted as an alias.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard sidecar.",
      "",
      "This is diagnostic/admission evidence only. It does not promote q4/q8",
      "interval coverage, inference_ready, supported, REML, AI-REML, or bridge support.",
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
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-q4-animal-partial-cholesky-transform-local"
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
  "structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-partial-cholesky-transform-run-log.tsv"
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
  "structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-partial-cholesky-transform-run-log.tsv"
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
  values <- tryCatch(as.numeric(values), error = function(e) numeric())
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

build_start_map_object <- function(sim, strategy, source_fit = NULL) {
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

  if (isTRUE(strategy$copy_from_staged_fit)) {
    spec0$start <- copy_start_from_fit(spec0$start, source_fit)
  }
  if (identical(strategy$log_sd_start, "truth")) {
    spec0$start$log_sd_phylo <- log(as.numeric(spec$sds))
  }
  if (identical(strategy$log_sd_start, "staged")) {
    spec0$start <- copy_start_from_fit(spec0$start, source_fit)
  }
  if (identical(strategy$theta_start, "zero")) {
    spec0$start$theta_phylo[] <- 0
  }
  if (identical(strategy$theta_start, "small_positive")) {
    spec0$start$theta_phylo[] <- 0.08
  }
  if (identical(strategy$theta_start, "staged")) {
    spec0$start <- copy_start_from_fit(spec0$start, source_fit)
  }
  if (isTRUE(strategy$fix_theta_zero)) {
    spec0$start$theta_phylo[] <- 0
    spec0$map$theta_phylo <- factor(rep(NA, length(spec0$start$theta_phylo)))
  }
  if (isTRUE(strategy$fix_log_sd_truth)) {
    spec0$start$log_sd_phylo <- log(as.numeric(spec$sds))
    spec0$map$log_sd_phylo <- factor(rep(NA, length(spec0$start$log_sd_phylo)))
  }

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

fit_start_map_object <- function(obj) {
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

theta_indices <- function(par) {
  which(names(par) == "theta_phylo")
}

theta_q_from_count <- function(n_theta) {
  q <- (1 + sqrt(1 + 8 * n_theta)) / 2
  if (!isTRUE(all.equal(q, as.integer(q)))) {
    stop("Invalid theta count for a q4 correlation block.", call. = FALSE)
  }
  as.integer(q)
}

partial_cholesky_corr <- function(eta) {
  q <- theta_q_from_count(length(eta))
  partial <- tanh(eta)
  lower <- matrix(0, nrow = q, ncol = q)
  lower[1L, 1L] <- 1
  pos <- 1L
  for (row in seq.int(2L, q)) {
    remaining <- 1
    for (col in seq_len(row - 1L)) {
      value <- partial[[pos]]
      scale <- sqrt(max(remaining, .Machine$double.eps))
      lower[row, col] <- value * scale
      remaining <- remaining * max(1 - value^2, .Machine$double.eps)
      pos <- pos + 1L
    }
    lower[row, row] <- sqrt(max(remaining, .Machine$double.eps))
  }
  corr <- lower %*% t(lower)
  diag(corr) <- 1
  corr
}

partial_cholesky_tmb_theta <- function(eta) {
  corr <- partial_cholesky_corr(eta)
  getFromNamespace(
    "correlation_matrix_to_tmb_unstructured_theta",
    "drmTMB"
  )(corr)
}

partial_cholesky_inner_par <- function(par, theta_index) {
  out <- par
  if (length(theta_index)) {
    out[theta_index] <- partial_cholesky_tmb_theta(par[theta_index])
  }
  out
}

partial_cholesky_outer_gradient <- function(obj, par, theta_index) {
  inner <- partial_cholesky_inner_par(par, theta_index)
  grad <- obj$gr(inner)
  if (!length(theta_index)) {
    return(grad)
  }
  eta <- par[theta_index]
  theta0 <- inner[theta_index]
  jacobian <- matrix(NA_real_, nrow = length(theta0), ncol = length(eta))
  for (j in seq_along(eta)) {
    eps <- max(1e-5, abs(eta[[j]]) * 1e-5)
    eta_plus <- eta
    eta_minus <- eta
    eta_plus[[j]] <- eta_plus[[j]] + eps
    eta_minus[[j]] <- eta_minus[[j]] - eps
    theta_plus <- partial_cholesky_tmb_theta(eta_plus)
    theta_minus <- partial_cholesky_tmb_theta(eta_minus)
    jacobian[, j] <- (theta_plus - theta_minus) / (2 * eps)
  }
  grad[theta_index] <- as.vector(crossprod(jacobian, grad[theta_index]))
  grad
}

fit_partial_cholesky_start_map_object <- function(obj) {
  theta_index <- theta_indices(obj$par)
  if (!length(theta_index)) {
    return(list(
      fit_error = simpleError(
        "No live theta_phylo parameters for partial-Cholesky fit."
      ),
      warnings = character(),
      outer_gradient = NA_real_,
      partial_eta_max = NA_real_,
      partial_corr_max = NA_real_,
      partial_boundary_saturation = NA
    ))
  }
  warnings <- character()
  start_outer <- obj$par
  start_outer[theta_index] <- 0
  opt <- withCallingHandlers(
    tryCatch(
      stats::nlminb(
        start = start_outer,
        objective = function(par) {
          obj$fn(partial_cholesky_inner_par(
            par,
            theta_index
          ))
        },
        gradient = function(par) {
          partial_cholesky_outer_gradient(
            obj,
            par,
            theta_index
          )
        },
        control = list(eval.max = 1600L, iter.max = 1600L)
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(opt, "error")) {
    return(list(
      fit_error = opt,
      warnings = warnings,
      outer_gradient = NA_real_,
      partial_eta_max = NA_real_,
      partial_corr_max = NA_real_,
      partial_boundary_saturation = NA
    ))
  }
  outer_par <- opt$par
  inner_par <- partial_cholesky_inner_par(outer_par, theta_index)
  outer_gradient <- tryCatch(
    partial_cholesky_outer_gradient(obj, outer_par, theta_index),
    error = function(e) numeric()
  )
  opt$outer_par <- outer_par
  opt$par <- inner_par
  opt$objective <- obj$fn(inner_par)
  opt$message <- opt$message %||% "NA"
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
  theta_inner <- inner_par[theta_index]
  list(
    obj = obj,
    opt = opt,
    sdr = sdr,
    attempts = data.frame(
      optimizer_preset = "partial_cholesky_nlminb",
      convergence = opt$convergence,
      objective = opt$objective,
      stringsAsFactors = FALSE
    ),
    selected = list(optimizer_preset = "partial_cholesky_nlminb"),
    warnings = warnings,
    outer_gradient = if (length(outer_gradient)) {
      max(abs(outer_gradient), na.rm = TRUE)
    } else {
      NA_real_
    },
    partial_eta_max = if (length(theta_index)) {
      max(abs(outer_par[theta_index]), na.rm = TRUE)
    } else {
      NA_real_
    },
    partial_corr_max = if (length(theta_index)) {
      corr <- partial_cholesky_corr(outer_par[theta_index])
      max(abs(corr[lower.tri(corr)]), na.rm = TRUE)
    } else {
      NA_real_
    },
    partial_boundary_saturation = if (length(theta_index)) {
      corr <- partial_cholesky_corr(outer_par[theta_index])
      max(abs(corr[lower.tri(corr)]), na.rm = TRUE) >= 0.999
    } else {
      NA
    }
  )
}

direct_sd_interval_geometry <- function(fit, level = 0.70) {
  empty <- list(
    n_direct_sd_interval_rows = 0L,
    n_direct_sd_interval_finite = 0L,
    all_direct_sd_intervals_finite = FALSE,
    direct_sd_interval_method = "sdreport_wald_inner_tmb_curvature",
    direct_sd_interval_detail = "NA"
  )
  if (!is.null(fit$fit_error) || inherits(fit$sdr, "error")) {
    return(empty)
  }
  sdr_summary <- tryCatch(summary(fit$sdr), error = function(e) e)
  if (inherits(sdr_summary, "error") || is.null(dim(sdr_summary))) {
    empty$direct_sd_interval_detail <- clean_text(conditionMessage(sdr_summary))
    return(empty)
  }
  direct_rows <- which(rownames(sdr_summary) == "sd_phylo")
  if (!length(direct_rows)) {
    empty$direct_sd_interval_detail <- "sd_phylo rows not found in sdreport"
    return(empty)
  }
  z <- stats::qnorm((1 + level) / 2)
  estimate <- as.numeric(sdr_summary[direct_rows, "Estimate"])
  std_error <- as.numeric(sdr_summary[direct_rows, "Std. Error"])
  lower <- estimate - z * std_error
  upper <- estimate + z * std_error
  finite <- is.finite(estimate) & is.finite(std_error) &
    is.finite(lower) & is.finite(upper)
  labels <- endpoint_members[seq_along(estimate)]
  if (length(labels) != length(estimate)) {
    labels <- paste0("sd_phylo_", seq_along(estimate))
  }
  list(
    n_direct_sd_interval_rows = length(estimate),
    n_direct_sd_interval_finite = sum(finite),
    all_direct_sd_intervals_finite = length(estimate) == 8L && all(finite),
    direct_sd_interval_method = "sdreport_wald_inner_tmb_curvature",
    direct_sd_interval_detail = paste(
      paste0(labels, "=", ifelse(finite, "finite", "nonfinite")),
      collapse = ";"
    )
  )
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
      cov_condition = NA_real_,
      finite_covariance = FALSE,
      theta_max = NA_real_,
      outer_gradient = fit$outer_gradient %||% NA_real_,
      partial_eta_max = fit$partial_eta_max %||% NA_real_,
      partial_corr_max = fit$partial_corr_max %||% NA_real_,
      partial_boundary_saturation = fit$partial_boundary_saturation %||% NA,
      large_eta_flag = NA,
      corr_condition = NA_real_,
      corr_eig_min = NA_real_,
      corr_max_abs = NA_real_,
      corr_boundary_margin_min = NA_real_,
      direct_sd_min = NA_real_,
      direct_sd_max = NA_real_,
      n_direct_sd_interval_rows = 0L,
      n_direct_sd_interval_finite = 0L,
      all_direct_sd_intervals_finite = FALSE,
      direct_sd_interval_method = "sdreport_wald_inner_tmb_curvature",
      direct_sd_interval_detail = "NA"
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
      cov_condition = NA_real_,
      finite_covariance = FALSE,
      theta_max = NA_real_,
      outer_gradient = fit$outer_gradient %||% NA_real_,
      partial_eta_max = fit$partial_eta_max %||% NA_real_,
      partial_corr_max = fit$partial_corr_max %||% NA_real_,
      partial_boundary_saturation = fit$partial_boundary_saturation %||% NA,
      large_eta_flag = if (is.finite(fit$partial_eta_max %||% NA_real_)) {
        fit$partial_eta_max > 10
      } else {
        NA
      },
      corr_condition = NA_real_,
      corr_eig_min = NA_real_,
      corr_max_abs = NA_real_,
      corr_boundary_margin_min = NA_real_,
      direct_sd_min = NA_real_,
      direct_sd_max = NA_real_,
      n_direct_sd_interval_rows = 0L,
      n_direct_sd_interval_finite = 0L,
      all_direct_sd_intervals_finite = FALSE,
      direct_sd_interval_method = "sdreport_wald_inner_tmb_curvature",
      direct_sd_interval_detail = "NA"
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
  theta <- as.numeric(report$theta_phylo %||% numeric())
  corr <- report$phylo_q4_corr %||% NULL
  corr_eig <- matrix_eigenvalues(corr)
  corr_abs <- if (!is.null(corr) && length(corr)) {
    abs(as.matrix(corr)[lower.tri(as.matrix(corr))])
  } else {
    numeric()
  }
  direct_sd <- as.numeric(
    report$sd_phylo %||% fit$obj$env$parList(fit$opt$par)$log_sd_phylo
  )
  if (length(direct_sd) && any(direct_sd <= 0, na.rm = TRUE)) {
    direct_sd <- exp(direct_sd)
  }
  interval <- direct_sd_interval_geometry(fit)
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
    cov_condition = log10_condition(cov_eig),
    finite_covariance = !is.null(cov_eig) && all(is.finite(cov_eig)),
    theta_max = if (length(theta)) max(abs(theta)) else NA_real_,
    outer_gradient = fit$outer_gradient %||% NA_real_,
    partial_eta_max = fit$partial_eta_max %||% NA_real_,
    partial_corr_max = fit$partial_corr_max %||% NA_real_,
    partial_boundary_saturation = fit$partial_boundary_saturation %||% NA,
    large_eta_flag = if (is.finite(fit$partial_eta_max %||% NA_real_)) {
      fit$partial_eta_max > 10
    } else {
      NA
    },
    corr_condition = log10_condition(corr_eig),
    corr_eig_min = if (is.null(corr_eig)) NA_real_ else min(corr_eig),
    corr_max_abs = if (length(corr_abs)) {
      max(corr_abs, na.rm = TRUE)
    } else {
      NA_real_
    },
    corr_boundary_margin_min = if (length(corr_abs)) {
      1 - max(corr_abs, na.rm = TRUE)
    } else {
      NA_real_
    },
    direct_sd_min = if (length(direct_sd)) min(direct_sd) else NA_real_,
    direct_sd_max = if (length(direct_sd)) max(direct_sd) else NA_real_,
    n_direct_sd_interval_rows = interval$n_direct_sd_interval_rows,
    n_direct_sd_interval_finite = interval$n_direct_sd_interval_finite,
    all_direct_sd_intervals_finite = interval$all_direct_sd_intervals_finite,
    direct_sd_interval_method = interval$direct_sd_interval_method,
    direct_sd_interval_detail = interval$direct_sd_interval_detail
  )
}

strategy_status <- function(strategy, geom) {
  if (isTRUE(geom$fit_error)) {
    return("fit_error")
  }
  if (isTRUE(geom$sdreport_error)) {
    return("sdreport_error")
  }
  if (isTRUE(strategy$partial_cholesky) && isTRUE(geom$large_eta_flag)) {
    return("partial_cholesky_large_eta_blocked")
  }
  if (
    isTRUE(strategy$partial_cholesky) &&
      isTRUE(geom$partial_boundary_saturation)
  ) {
    return("partial_cholesky_boundary_blocked")
  }
  if (
    isTRUE(geom$pdHess) &&
      identical(geom$convergence, 0L) &&
      is.finite(geom$max_gradient) &&
      geom$max_gradient <= 1e-3 &&
      (!isTRUE(strategy$partial_cholesky) ||
        (is.finite(geom$outer_gradient) &&
          geom$outer_gradient <= 1e-3 &&
          !isTRUE(geom$partial_boundary_saturation) &&
          !isTRUE(geom$large_eta_flag))) &&
      identical(as.integer(geom$cov_neg), 0L) &&
      isTRUE(geom$finite_covariance) &&
      (!isTRUE(strategy$partial_cholesky) ||
        isTRUE(geom$all_direct_sd_intervals_finite))
  ) {
    if (isTRUE(strategy$fix_theta_zero)) {
      return("zero_correlation_control_pass")
    }
    if (isTRUE(strategy$partial_cholesky)) {
      return("partial_cholesky_admission_smoke_pass")
    }
    return("pdhess_pass_smoke")
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
  "start_map_watch"
}

blocker_component <- function(strategy, geom, status) {
  if (status == "zero_correlation_control_pass") {
    return("free_q4_correlation_block_removed")
  }
  if (status == "partial_cholesky_admission_smoke_pass") {
    return("partial_cholesky_geometry_promising")
  }
  if (status == "partial_cholesky_large_eta_blocked") {
    return("partial_cholesky_large_eta")
  }
  if (status == "partial_cholesky_boundary_blocked") {
    return("partial_cholesky_correlation_boundary")
  }
  if (status == "pdhess_pass_smoke") {
    return("no_blocker_in_smoke")
  }
  if (!isTRUE(strategy$fix_theta_zero)) {
    return("free_q4_correlation_block_active")
  }
  if (isTRUE(strategy$fix_log_sd_truth)) {
    return("fixed_sd_and_zero_correlation_watch")
  }
  "zero_correlation_map_watch"
}

strategies <- list(
  corr_zero_map_default_sd = list(
    route = "zero_correlation_control",
    transform_family = "fixed_zero_correlation_control",
    description = "q4 correlations fixed at zero with current default SD starts",
    log_sd_start = "default",
    theta_start = "zero",
    fix_theta_zero = TRUE,
    fix_log_sd_truth = FALSE,
    copy_from_staged_fit = FALSE,
    staged_from = "none",
    partial_cholesky = FALSE,
    uses_fixed_cap = FALSE,
    uses_optimizer_penalty = FALSE
  ),
  current_unbounded_diag_stage = list(
    route = "current_unbounded_all_free",
    transform_family = "current_tmb_unstructured_corr",
    description = "current all-free q4 theta fit staged from the zero-correlation solution",
    log_sd_start = "staged",
    theta_start = "staged",
    fix_theta_zero = FALSE,
    fix_log_sd_truth = FALSE,
    copy_from_staged_fit = TRUE,
    staged_from = "corr_zero_map_default_sd",
    partial_cholesky = FALSE,
    uses_fixed_cap = FALSE,
    uses_optimizer_penalty = FALSE
  ),
  partial_cholesky_all_free = list(
    route = "partial_cholesky_all_free",
    transform_family = "partial_correlation_cholesky",
    description = "all-free q4 correlation block represented by partial-correlation Cholesky coordinates",
    log_sd_start = "staged",
    theta_start = "zero",
    fix_theta_zero = FALSE,
    fix_log_sd_truth = FALSE,
    copy_from_staged_fit = TRUE,
    staged_from = "corr_zero_map_default_sd",
    partial_cholesky = TRUE,
    uses_fixed_cap = FALSE,
    uses_optimizer_penalty = FALSE
  )
)

claim_boundary_text <- paste(
  "Animal q4 all-four one-slope partial-Cholesky transform diagnostic only:",
  "hard seeds compare a zero-correlation control, the current all-free staged",
  "fit, and one all-free partial-correlation Cholesky coordinate route;",
  "no coverage, no inference_ready, no supported, no q8 inference,",
  "no q4 REML, no REML, no AI-REML, no broad q4 bridge support,",
  "no shipped production parameterization change, no cap-saturated bounded",
  "route, no optimizer-layer ridge penalty, and no derived-correlation",
  "interval claim."
)
next_gate_text <- paste(
  "Use this local hard-seed diagnostic to decide whether the partial-Cholesky",
  "route is eligible for Fisher/Rose review and a prespecified Totoro/FIIA",
  "smoke; do not submit Nibi/Rorqual admission, DRAC coverage, or edit status",
  "tiers unless all three hard seeds pass the admission gate."
)

rows <- list()
for (replicate_index in replicate_indices) {
  seed <- seed_base + replicate_index + spec$seed_offset
  message(
    "Running animal q4 partial-Cholesky replicate ",
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
  replicate_fits <- list()
  current_objective <- NA_real_
  for (strategy_name in names(strategies)) {
    strategy <- strategies[[strategy_name]]
    message("  strategy: ", strategy_name)
    source_fit <- if (!identical(strategy$staged_from, "none")) {
      replicate_fits[[strategy$staged_from]]
    } else {
      NULL
    }
    built <- build_start_map_object(sim, strategy, source_fit = source_fit)
    started_at <- proc.time()[["elapsed"]]
    fit <- if (isTRUE(strategy$partial_cholesky)) {
      fit_partial_cholesky_start_map_object(built$obj)
    } else {
      fit_start_map_object(built$obj)
    }
    elapsed_sec <- proc.time()[["elapsed"]] - started_at
    fit$obj <- built$obj
    replicate_fits[[strategy_name]] <- fit
    geom <- fit_geometry(fit)
    if (identical(strategy_name, "current_unbounded_diag_stage")) {
      current_objective <- geom$objective
    }
    status <- strategy_status(strategy, geom)
    rows[[length(rows) + 1L]] <- data.frame(
      diagnostic_id = paste0(
        "q4_animal_partial_cholesky_",
        replicate_index,
        "_",
        strategy_name
      ),
      cell_id = "qseries_animal_q4_all_four_one_slope_planned",
      variant = variant,
      replicate_index = replicate_index,
      seed = seed,
      route = strategy$route,
      strategy = strategy_name,
      transform_family = strategy$transform_family,
      strategy_description = strategy$description,
      q_phylo = 8L,
      theta_count = 28L,
      n_levels = spec$n,
      n_each = spec$n_each,
      map_theta_phylo = if (isTRUE(strategy$fix_theta_zero)) {
        "fixed_zero"
      } else {
        "free"
      },
      map_log_sd_phylo = if (isTRUE(strategy$fix_log_sd_truth)) {
        "fixed_truth"
      } else {
        "free"
      },
      start_log_sd_source = strategy$log_sd_start,
      start_theta_source = strategy$theta_start,
      staged_from_strategy = strategy$staged_from,
      fit_error = geom$fit_error,
      sdreport_error = geom$sdreport_error,
      convergence = geom$convergence,
      pdHess = geom$pdHess,
      objective = format_num(geom$objective, digits = 10L),
      objective_delta_vs_current = if (is.finite(current_objective) &&
        is.finite(geom$objective)) {
        format_num(geom$objective - current_objective, digits = 10L)
      } else {
        "NA"
      },
      optimizer_selected_preset = geom$selected,
      optimizer_attempt_count = geom$attempt_count,
      elapsed_sec = format_num(elapsed_sec, digits = 8L),
      warning_count = length(fit$warnings %||% character()),
      warning_messages = clean_text(paste(
        unique(fit$warnings %||% character()),
        collapse = " | "
      )),
      error_message = geom$error_message,
      max_abs_gradient_fixed = format_num(geom$max_gradient, digits = 8L),
      max_abs_gradient_outer = format_num(geom$outer_gradient, digits = 8L),
      max_abs_eta_partial = format_num(geom$partial_eta_max, digits = 8L),
      max_abs_partial_corr = format_num(geom$partial_corr_max, digits = 8L),
      min_partial_corr_margin = format_num(
        geom$corr_boundary_margin_min,
        digits = 8L
      ),
      large_eta_flag = as.character(isTRUE(geom$large_eta_flag)),
      boundary_flag = as.character(isTRUE(geom$partial_boundary_saturation)),
      uses_fixed_cap = as.character(isTRUE(strategy$uses_fixed_cap)),
      cap_saturation = "not_applicable",
      uses_optimizer_penalty = as.character(isTRUE(strategy$uses_optimizer_penalty)),
      sdr_cov_fixed_eig_min = format_num(geom$cov_min, digits = 8L),
      sdr_cov_fixed_n_negative = geom$cov_neg,
      sdr_cov_fixed_condition_log10 = format_num(
        geom$cov_condition,
        digits = 8L
      ),
      finite_covariance = geom$finite_covariance,
      corr_eig_min = format_num(geom$corr_eig_min, digits = 8L),
      corr_condition_log10 = format_num(geom$corr_condition, digits = 8L),
      max_abs_corr = format_num(geom$corr_max_abs, digits = 8L),
      corr_boundary_margin_min = format_num(
        geom$corr_boundary_margin_min,
        digits = 8L
      ),
      theta_max_abs = format_num(geom$theta_max, digits = 8L),
      min_direct_sd_estimate = format_num(geom$direct_sd_min, digits = 8L),
      max_direct_sd_estimate = format_num(geom$direct_sd_max, digits = 8L),
      n_direct_sd_interval_rows = geom$n_direct_sd_interval_rows,
      n_direct_sd_interval_finite = geom$n_direct_sd_interval_finite,
      all_direct_sd_intervals_finite = geom$all_direct_sd_intervals_finite,
      direct_sd_interval_method = geom$direct_sd_interval_method,
      direct_sd_interval_detail = geom$direct_sd_interval_detail,
      route_status = status,
      blocker_component = blocker_component(strategy, geom, status),
      admission_status = if (identical(
        status,
        "partial_cholesky_admission_smoke_pass"
      )) {
        "hard_seed_route_passed_local_admission_smoke"
      } else if (isTRUE(strategy$partial_cholesky)) {
        "hard_seed_route_blocked_local_admission_smoke"
      } else {
        "reference_not_admission"
      },
      interval_claim_status = "diagnostic_only",
      coverage_status = "not_evaluable",
      source_artifact = paste(
        "docs/dev-log/simulation-artifacts",
        basename(artifact_dir),
        "structured-re-q4-animal-partial-cholesky-transform-diagnostic.tsv",
        sep = "/"
      ),
      evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-q4-animal-partial-cholesky-transform-diagnostic.md",
      claim_boundary = claim_boundary_text,
      next_gate = next_gate_text,
      stringsAsFactors = FALSE
    )
  }
}

out <- do.call(rbind, rows)
rownames(out) <- NULL
run_log <- data.frame(
  log_id = "q4_animal_partial_cholesky_transform_diagnostic",
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  replicates = paste(replicate_indices, collapse = ","),
  strategies = paste(names(strategies), collapse = ","),
  transform_family = "partial_correlation_cholesky",
  direct_sd_interval_method = "sdreport_wald_inner_tmb_curvature",
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

message("Wrote partial-Cholesky transform artifact: ", artifact_path)
if (write_dashboard) {
  message("Wrote dashboard sidecar: ", dashboard_path)
}
