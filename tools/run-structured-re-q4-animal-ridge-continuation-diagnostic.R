#!/usr/bin/env Rscript
#
# q4 animal ridge-continuation diagnostic.
#
# This runner follows the q4 animal MAP/penalty sensitivity diagnostic. It asks
# whether a ridge-stabilized multi-coordinate theta_phylo fit can be annealed
# back to an unpenalized local mode. This is admission geometry evidence only:
# interval coverage, inference_ready, supported, q8 inference, REML, AI-REML,
# production parameterization changes, and broad bridge support are out of
# scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-animal-ridge-continuation-diagnostic.R [options]",
      "",
      "Options:",
      "  --replicates=a,b          Replicate indices (default: 910101,910102,910110).",
      "  --seed-base=N             Seed base; seed = seed_base + replicate + variant offset (default: 910000).",
      "  --variant=NAME            Variant to run: strong or more_levels (default: more_levels).",
      "  --strategies=a,b          Strategies: seed_nonpass,global_nonpass,all28 (default: all three).",
      "  --lambda-schedule=a,b,c   Ridge annealing schedule (default: 1,0.1,0.01,0).",
      "  --one-theta-path=PATH     One-theta diagnostic TSV used to define sets.",
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

format_num <- function(x, digits = 8L) {
  if (!is.finite(x)) {
    return("NA")
  }
  formatC(x, digits = digits, format = "fg", flag = "#")
}

finite_min <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  min(x)
}

finite_max <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  max(x)
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

strategy_arg <- strsplit(
  arg_value("strategies", "seed_nonpass,global_nonpass,all28"),
  ",",
  fixed = TRUE
)[[1L]]
requested_strategies <- trimws(strategy_arg[nzchar(trimws(strategy_arg))])
allowed_strategies <- c("seed_nonpass", "global_nonpass", "all28")
if (
  !length(requested_strategies) ||
    any(!requested_strategies %in% allowed_strategies)
) {
  stop(
    "`--strategies` must use these names: ",
    paste(allowed_strategies, collapse = ", "),
    call. = FALSE
  )
}

lambda_arg <- strsplit(
  arg_value("lambda-schedule", "1,0.1,0.01,0"),
  ",",
  fixed = TRUE
)[[1L]]
lambda_schedule <- as.numeric(trimws(lambda_arg[nzchar(trimws(lambda_arg))]))
if (
  !length(lambda_schedule) ||
    any(!is.finite(lambda_schedule)) ||
    any(lambda_schedule < 0)
) {
  stop("`--lambda-schedule` must be a non-negative numeric list.", call. = FALSE)
}
if (!identical(tail(lambda_schedule, 1L), 0)) {
  stop("`--lambda-schedule` must end at 0 for this diagnostic.", call. = FALSE)
}
schedule_label <- paste(
  vapply(lambda_schedule, format_num, character(1L), digits = 4L),
  collapse = "_"
)

seed_base <- as.integer(arg_value("seed-base", "910000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
variant <- arg_value("variant", "more_levels")
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
default_one_theta_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-one-theta-release-diagnostic.tsv"
)
one_theta_path <- normalizePath(
  arg_value("one-theta-path", default_one_theta_path),
  mustWork = FALSE
)
if (!file.exists(one_theta_path)) {
  stop("`--one-theta-path` does not exist: ", one_theta_path, call. = FALSE)
}

default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-29-q4-animal-ridge-continuation-local"
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

dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-ridge-continuation-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-ridge-continuation-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-ridge-continuation-run-log.tsv"
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
dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-ridge-continuation-diagnostic.tsv"
)
artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-ridge-continuation-diagnostic.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-ridge-continuation-run-log.tsv"
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
  theta_indices = integer(),
  source_fit = NULL,
  theta_start = c("zero", "source")
) {
  theta_start <- match.arg(theta_start)
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
  if (identical(theta_start, "zero") || is.null(source_fit)) {
    spec0$start$theta_phylo[] <- 0
  } else {
    keep <- rep(FALSE, length(spec0$start$theta_phylo))
    keep[theta_indices] <- TRUE
    spec0$start$theta_phylo[!keep] <- 0
  }
  theta_map <- rep(NA_integer_, length(spec0$start$theta_phylo))
  if (length(theta_indices)) {
    theta_map[theta_indices] <- seq_along(theta_indices)
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

theta_par_indices <- function(par) {
  which(names(par) == "theta_phylo")
}

penalized_gradient <- function(obj, par, theta_index, penalty_lambda) {
  grad <- obj$gr(par)
  if (penalty_lambda > 0 && length(theta_index)) {
    grad[theta_index] <- grad[theta_index] + penalty_lambda * par[theta_index]
  }
  grad
}

fit_q4_object <- function(obj, penalty_lambda = 0) {
  control <- drm_control(optimizer = list(eval.max = 1600, iter.max = 1600))
  warnings <- character()
  theta_index <- theta_par_indices(obj$par)

  if (penalty_lambda <= 0) {
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
    selected <- opt_result$selected
    attempts <- opt_result$attempts
    penalized_objective <- as.numeric(opt$objective)
    penalty_value <- 0
    max_penalized_gradient <- NA_real_
  } else {
    opt <- withCallingHandlers(
      tryCatch(
        stats::nlminb(
          start = obj$par,
          objective = function(par) {
            obj$fn(par) +
              0.5 * penalty_lambda * sum(par[theta_index]^2)
          },
          gradient = function(par) {
            penalized_gradient(obj, par, theta_index, penalty_lambda)
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
      return(list(fit_error = opt, warnings = warnings))
    }
    penalty_value <- 0.5 * penalty_lambda * sum(opt$par[theta_index]^2)
    penalized_objective <- as.numeric(opt$objective)
    opt$objective <- as.numeric(obj$fn(opt$par))
    opt$message <- opt$message %||% "NA"
    selected <- list(optimizer_preset = "ridge_penalty_nlminb")
    attempts <- data.frame(
      optimizer_preset = "ridge_penalty_nlminb",
      convergence = opt$convergence,
      objective = opt$objective,
      stringsAsFactors = FALSE
    )
    penalty_grad <- tryCatch(
      penalized_gradient(obj, opt$par, theta_index, penalty_lambda),
      error = function(e) numeric()
    )
    max_penalized_gradient <- if (
      length(penalty_grad) && any(is.finite(penalty_grad))
    ) {
      max(abs(penalty_grad), na.rm = TRUE)
    } else {
      NA_real_
    }
  }

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
    attempts = attempts,
    selected = selected,
    warnings = warnings,
    penalty_lambda = penalty_lambda,
    penalty_value = penalty_value,
    penalized_objective = penalized_objective,
    max_penalized_gradient = max_penalized_gradient
  )
}

direct_sd_from_fit <- function(fit) {
  if (!is.null(fit$fit_error) || inherits(fit$sdr, "error")) {
    return(stats::setNames(rep(NA_real_, length(endpoint_members)), endpoint_members))
  }
  report <- tryCatch(fit$obj$report(), error = function(e) list())
  if (!is.null(report$sd_phylo)) {
    out <- as.numeric(report$sd_phylo)
  } else {
    par_list <- fit$obj$env$parList(fit$opt$par)
    out <- exp(as.numeric(par_list$log_sd_phylo %||% numeric()))
  }
  if (length(out) != length(endpoint_members)) {
    return(stats::setNames(rep(NA_real_, length(endpoint_members)), endpoint_members))
  }
  stats::setNames(out, endpoint_members)
}

theta_from_fit <- function(fit) {
  if (!is.null(fit$fit_error) || inherits(fit$sdr, "error")) {
    return(rep(NA_real_, 28L))
  }
  report <- tryCatch(fit$obj$report(), error = function(e) list())
  theta <- as.numeric(report$theta_phylo %||% numeric())
  if (length(theta) != 28L) {
    return(rep(NA_real_, 28L))
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
      penalized_objective = NA_real_,
      penalty_value = NA_real_,
      selected = "error",
      attempt_count = 0L,
      max_unpenalized_gradient = NA_real_,
      max_penalized_gradient = NA_real_,
      cov_neg = NA_integer_,
      cov_min = NA_real_,
      theta_max = NA_real_,
      theta_l2 = NA_real_,
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
      penalized_objective = fit$penalized_objective %||% NA_real_,
      penalty_value = fit$penalty_value %||% NA_real_,
      selected = fit$selected$optimizer_preset %||% "NA",
      attempt_count = nrow(fit$attempts),
      max_unpenalized_gradient = NA_real_,
      max_penalized_gradient = fit$max_penalized_gradient %||% NA_real_,
      cov_neg = NA_integer_,
      cov_min = NA_real_,
      theta_max = NA_real_,
      theta_l2 = NA_real_,
      corr_condition = NA_real_,
      direct_sd_min = NA_real_,
      direct_sd_max = NA_real_
    ))
  }
  gradient <- fit$sdr$gradient.fixed %||%
    tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  max_unpenalized_gradient <- if (
    length(gradient) && any(is.finite(gradient))
  ) {
    max(abs(gradient), na.rm = TRUE)
  } else {
    NA_real_
  }
  max_penalized_gradient <- fit$max_penalized_gradient %||%
    max_unpenalized_gradient
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
    penalized_objective = fit$penalized_objective %||% fit$opt$objective,
    penalty_value = fit$penalty_value %||% 0,
    selected = fit$selected$optimizer_preset %||% "NA",
    attempt_count = nrow(fit$attempts),
    max_unpenalized_gradient = max_unpenalized_gradient,
    max_penalized_gradient = max_penalized_gradient,
    cov_neg = if (is.null(cov_eig)) NA_integer_ else sum(cov_eig <= 0),
    cov_min = if (is.null(cov_eig)) NA_real_ else min(cov_eig),
    theta_max = if (length(theta)) finite_max(abs(theta)) else NA_real_,
    theta_l2 = sqrt(sum(theta^2, na.rm = TRUE)),
    corr_condition = log10_condition(corr_eig),
    direct_sd_min = finite_min(direct_sd),
    direct_sd_max = finite_max(direct_sd)
  )
}

continuation_status <- function(geom, penalty_lambda) {
  if (isTRUE(geom$fit_error)) {
    return("continuation_fit_error")
  }
  if (isTRUE(geom$sdreport_error)) {
    return("continuation_sdreport_error")
  }
  if (
    !isTRUE(geom$pdHess) && is.finite(geom$theta_max) && geom$theta_max > 100
  ) {
    return("continuation_runaway_theta_hessian_blocked")
  }
  if (!isTRUE(geom$pdHess)) {
    return("continuation_hessian_blocked")
  }
  if (!identical(geom$convergence, 0L)) {
    return("continuation_convergence_watch")
  }
  if (is.finite(geom$cov_neg) && geom$cov_neg > 0) {
    return("continuation_cov_fixed_eigen_watch")
  }
  if (penalty_lambda <= 0 && is.finite(geom$theta_max) && geom$theta_max > 100) {
    return("continuation_unpenalized_large_theta_watch")
  }
  if (penalty_lambda > 0) {
    if (
      is.finite(geom$max_penalized_gradient) &&
        geom$max_penalized_gradient <= 1e-3
    ) {
      if (
        is.finite(geom$max_unpenalized_gradient) &&
          geom$max_unpenalized_gradient <= 1e-3
      ) {
        return("continuation_penalty_and_unpenalized_smoke_pass")
      }
      return("continuation_penalty_stabilized_local_mode")
    }
    return("continuation_penalty_gradient_watch")
  }
  if (
    is.finite(geom$max_unpenalized_gradient) &&
      geom$max_unpenalized_gradient <= 1e-3
  ) {
    return("continuation_unpenalized_admission_smoke_pass")
  }
  "continuation_unpenalized_gradient_watch"
}

blocker_component <- function(status, penalty_lambda) {
  if (identical(status, "continuation_unpenalized_admission_smoke_pass")) {
    return("annealed_unpenalized_candidate")
  }
  if (grepl("penalty_stabilized", status, fixed = TRUE)) {
    return("penalty_stabilized_before_anneal")
  }
  if (grepl("hessian_blocked", status, fixed = TRUE)) {
    return("annealed_hessian_blocked")
  }
  if (grepl("gradient_watch", status, fixed = TRUE)) {
    return(if (penalty_lambda > 0) "penalty_gradient_watch" else "annealed_gradient_watch")
  }
  if (grepl("large_theta_watch", status, fixed = TRUE)) {
    return("annealed_large_theta_watch")
  }
  if (grepl("convergence_watch", status, fixed = TRUE)) {
    return("annealed_convergence_watch")
  }
  "continuation_watch"
}

one_theta <- utils::read.delim(
  one_theta_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
one_theta$gain <- suppressWarnings(as.numeric(one_theta$objective_gain_vs_zero))
one_theta$theta_index <- as.integer(one_theta$theta_index)
global_nonpass <- sort(unique(one_theta$theta_index[
  one_theta$release_status != "one_theta_release_pass_smoke"
]))
if (!length(global_nonpass)) {
  stop("One-theta source has no non-pass rows.", call. = FALSE)
}

build_strategy_rows <- function(replicate_index) {
  subset <- one_theta[
    one_theta$replicate_index == replicate_index,
    ,
    drop = FALSE
  ]
  if (!nrow(subset)) {
    stop(
      "Missing one-theta rows for replicate ",
      replicate_index,
      call. = FALSE
    )
  }
  seed_nonpass <- sort(unique(subset$theta_index[
    subset$release_status != "one_theta_release_pass_smoke"
  ]))
  all_strategies <- list(
    seed_nonpass = list(
      strategy = "seed_nonpass",
      theta_set_label = "seed_nonpass",
      theta_indices = seed_nonpass,
      description = "seed-specific one-theta non-pass coordinates"
    ),
    global_nonpass = list(
      strategy = "global_nonpass",
      theta_set_label = "global_nonpass",
      theta_indices = global_nonpass,
      description = "global union of one-theta non-pass coordinates"
    ),
    all28 = list(
      strategy = "all28",
      theta_set_label = "all28",
      theta_indices = seq_len(28L),
      description = "all 28 q4 animal correlation coordinates"
    )
  )
  all_strategies[requested_strategies]
}

claim_boundary_text <- paste(
  "Animal q4 all-four one-slope ridge-continuation diagnostic only:",
  "multi-coordinate theta_phylo sets are released from the zero-correlation",
  "map and annealed through a ridge-penalty schedule to lambda=0;",
  "ridge penalties are optimizer-layer sensitivity probes, not production",
  "priors; sdreport uses the unpenalized TMB curvature at each fitted point;",
  "no coverage, no inference_ready, no supported, no q8 inference,",
  "no q4 REML, no REML, no AI-REML, no broad q4 bridge support,",
  "no production parameterization change, and no derived-correlation interval",
  "claim."
)
next_gate_text <- paste(
  "Use this ridge-continuation diagnostic to decide whether annealed",
  "multi-coordinate fits can pass hard seeds without optimizer-layer ridge",
  "support; do not submit DRAC coverage or edit status tiers until Fisher/Rose",
  "approve denominator policy and a production-transform admission design."
)

rows <- list()
for (replicate_index in replicate_indices) {
  seed <- seed_base + replicate_index + spec$seed_offset
  message(
    "Running animal q4 ridge-continuation replicate ",
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
  zero_built <- build_animal_q4_object(
    sim,
    theta_indices = integer(),
    theta_start = "zero"
  )
  zero_fit <- fit_q4_object(zero_built$obj, penalty_lambda = 0)
  zero_fit$obj <- zero_built$obj
  zero_geom <- fit_geometry(zero_fit)
  zero_direct_sd <- direct_sd_from_fit(zero_fit)

  strategies <- build_strategy_rows(replicate_index)
  for (strategy in strategies) {
    message("  strategy: ", strategy$strategy)
    source_fit <- zero_fit
    previous_lambda <- NA_real_
    for (stage_index in seq_along(lambda_schedule)) {
      penalty_lambda <- lambda_schedule[[stage_index]]
      theta_start <- if (stage_index == 1L) "zero" else "source"
      built <- build_animal_q4_object(
        sim,
        theta_indices = strategy$theta_indices,
        source_fit = source_fit,
        theta_start = theta_start
      )
      fit <- fit_q4_object(built$obj, penalty_lambda = penalty_lambda)
      fit$obj <- built$obj
      geom <- fit_geometry(fit)
      status <- continuation_status(geom, penalty_lambda)
      direct_sd <- direct_sd_from_fit(fit)
      direct_sd_shift <- direct_sd - zero_direct_sd
      theta <- theta_from_fit(fit)
      released_theta <- theta[strategy$theta_indices]
      objective_gain <- zero_geom$objective - geom$objective
      rows[[length(rows) + 1L]] <- data.frame(
        diagnostic_id = paste0(
          "q4_animal_ridge_continuation_",
          replicate_index,
          "_",
          strategy$strategy,
          "_stage",
          stage_index
        ),
        cell_id = "qseries_animal_q4_all_four_one_slope_planned",
        variant = variant,
        replicate_index = replicate_index,
        seed = seed,
        strategy = strategy$strategy,
        strategy_description = strategy$description,
        theta_set_label = strategy$theta_set_label,
        theta_indices = paste(strategy$theta_indices, collapse = ","),
        theta_count = length(strategy$theta_indices),
        schedule_label = schedule_label,
        schedule = paste(lambda_schedule, collapse = ","),
        stage_index = stage_index,
        stage_count = length(lambda_schedule),
        previous_penalty_lambda = format_num(previous_lambda, digits = 8L),
        penalty_lambda = format_num(penalty_lambda, digits = 8L),
        n_levels = spec$n,
        n_each = spec$n_each,
        start_log_sd_source = if (stage_index == 1L) {
          "zero_correlation_control_fit"
        } else {
          "previous_schedule_stage"
        },
        start_theta_source = theta_start,
        zero_control_convergence = zero_geom$convergence,
        zero_control_pdHess = zero_geom$pdHess,
        zero_control_objective = format_num(zero_geom$objective, digits = 10L),
        zero_control_max_abs_gradient_fixed = format_num(
          zero_geom$max_unpenalized_gradient,
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
        unpenalized_objective = format_num(geom$objective, digits = 10L),
        penalized_objective = format_num(geom$penalized_objective, digits = 10L),
        objective_gain_vs_zero = format_num(objective_gain, digits = 10L),
        penalty_value = format_num(geom$penalty_value, digits = 10L),
        optimizer_selected_preset = geom$selected,
        optimizer_attempt_count = geom$attempt_count,
        warning_count = length(fit$warnings %||% character()),
        warning_messages = clean_text(paste(
          unique(fit$warnings %||% character()),
          collapse = " | "
        )),
        error_message = geom$error_message,
        max_abs_gradient_unpenalized = format_num(
          geom$max_unpenalized_gradient,
          digits = 8L
        ),
        max_abs_gradient_penalized = format_num(
          geom$max_penalized_gradient,
          digits = 8L
        ),
        sdr_cov_fixed_eig_min = format_num(geom$cov_min, digits = 8L),
        sdr_cov_fixed_n_negative = geom$cov_neg,
        theta_max_abs = format_num(geom$theta_max, digits = 8L),
        theta_l2 = format_num(geom$theta_l2, digits = 8L),
        released_theta_max_abs = format_num(
          if (length(released_theta)) finite_max(abs(released_theta)) else NA_real_,
          digits = 8L
        ),
        n_released_theta_abs_gt_10 = sum(abs(released_theta) > 10, na.rm = TRUE),
        n_released_theta_abs_gt_100 = sum(abs(released_theta) > 100, na.rm = TRUE),
        corr_log10_condition = format_num(geom$corr_condition, digits = 8L),
        min_direct_sd_estimate = format_num(geom$direct_sd_min, digits = 8L),
        max_direct_sd_estimate = format_num(geom$direct_sd_max, digits = 8L),
        max_abs_direct_sd_shift_vs_zero = format_num(
          finite_max(abs(direct_sd_shift)),
          digits = 8L
        ),
        direct_sd_estimates = collapse_named_numbers(direct_sd, digits = 8L),
        direct_sd_shift_vs_zero = collapse_named_numbers(
          direct_sd_shift,
          digits = 8L
        ),
        continuation_status = status,
        blocker_component = blocker_component(status, penalty_lambda),
        interval_claim_status = "diagnostic_only",
        coverage_status = "not_evaluable",
        source_one_theta_artifact = paste(
          "docs/dev-log/dashboard",
          basename(one_theta_path),
          sep = "/"
        ),
        source_map_penalty_artifact = paste(
          "docs/dev-log/dashboard",
          "structured-re-q4-animal-map-penalty-sensitivity.tsv",
          sep = "/"
        ),
        source_artifact = paste(
          "docs/dev-log/simulation-artifacts",
          basename(artifact_dir),
          "structured-re-q4-animal-ridge-continuation-diagnostic.tsv",
          sep = "/"
        ),
        evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-q4-animal-ridge-continuation-diagnostic.md",
        claim_boundary = claim_boundary_text,
        next_gate = next_gate_text,
        stringsAsFactors = FALSE
      )
      if (!is.null(fit$opt) && is.null(fit$fit_error)) {
        source_fit <- fit
      }
      previous_lambda <- penalty_lambda
    }
  }
}

out <- do.call(rbind, rows)
rownames(out) <- NULL
run_log <- data.frame(
  log_id = "q4_animal_ridge_continuation_diagnostic",
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  replicates = paste(replicate_indices, collapse = ","),
  seed_base = seed_base,
  variant = variant,
  strategies = paste(requested_strategies, collapse = ","),
  lambda_schedule = paste(lambda_schedule, collapse = ","),
  source_one_theta_path = one_theta_path,
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
    git_out <- system2(
      "git",
      c("rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = TRUE
    )
    paste(git_out, collapse = "\n")
  },
  error = function(e) clean_text(conditionMessage(e))
)
writeLines(git_sha, git_sha_path)
writeLines(capture.output(utils::sessionInfo()), session_info_path)

status_table <- sort(table(out$continuation_status), decreasing = TRUE)
message("Wrote ", nrow(out), " rows to ", artifact_path)
if (write_dashboard) {
  message("Wrote dashboard sidecar to ", dashboard_path)
}
message("Continuation status summary:")
print(status_table)
