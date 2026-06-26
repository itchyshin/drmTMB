#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

parse_args <- function(args) {
  out <- list(
    n_rep = 4L,
    seed_start = 760001L,
    attempt_temp_install = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (identical(arg, "--attempt-temp-install")) {
      out$attempt_temp_install <- TRUE
    }
  }
  out
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

args <- parse_args(commandArgs(TRUE))
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-26-count-slope-phylo-poisson-local-micro-shard"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

replicate_path <- file.path(
  artifact_dir,
  "structured-re-count-slope-phylo-poisson-local-micro-shard-replicates.tsv"
)
summary_path <- file.path(
  artifact_dir,
  "structured-re-count-slope-phylo-poisson-local-micro-shard-summary.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-count-slope-phylo-poisson-local-micro-shard-run-log.tsv"
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

balanced_tree <- function(n_tip = 8L) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

try_load_drmTMB <- function(attempt_temp_install) {
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(list(
      ok = TRUE,
      status = "installed_namespace_loaded",
      detail = "loaded"
    ))
  }
  if (!attempt_temp_install) {
    return(list(
      ok = FALSE,
      status = "package_not_installed",
      detail = "drmTMB is not installed and --attempt-temp-install was not requested"
    ))
  }

  temp_lib <- tempfile("drmTMB-local-lib-")
  dir.create(temp_lib, recursive = TRUE, showWarnings = FALSE)
  cmd <- file.path(R.home("bin"), "R")
  output <- tryCatch(
    system2(
      cmd,
      c(
        "CMD",
        "INSTALL",
        "--preclean",
        shQuote(paste0("--library=", temp_lib)),
        shQuote(repo_root)
      ),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) conditionMessage(e)
  )
  if (!requireNamespace("drmTMB", lib.loc = temp_lib, quietly = TRUE)) {
    return(list(
      ok = FALSE,
      status = "temp_install_failed",
      detail = clean_text(paste(tail(output, 12L), collapse = " "))
    ))
  }
  .libPaths(c(temp_lib, .libPaths()))
  suppressPackageStartupMessages(library(drmTMB))
  list(
    ok = TRUE,
    status = "temp_install_loaded",
    detail = "temporary_library_current_source"
  )
}

new_phylo_poisson_slope_data <- function(seed, n_level = 8L, n_each = 20L) {
  set.seed(seed)
  tree <- balanced_tree(n_level)
  labels <- tree$tip.label
  site <- rep(labels, each = n_each)
  x <- stats::rnorm(length(site))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  K <- K[labels, labels]
  chol_cov <- chol(K + diag(1e-8, nrow(K)))
  sd_intercept <- 0.25
  sd_slope <- 0.45
  intercept <- as.vector(
    t(chol_cov) %*% stats::rnorm(n_level, sd = sd_intercept)
  )
  slope <- as.vector(t(chol_cov) %*% stats::rnorm(n_level, sd = sd_slope))
  names(intercept) <- labels
  names(slope) <- labels
  beta_mu <- c(`(Intercept)` = 0.55, x = -0.15)
  eta <- beta_mu[[1L]] + beta_mu[[2L]] * x + intercept[site] + x * slope[site]
  data <- data.frame(
    poisson_phylo = stats::rpois(length(site), lambda = exp(eta)),
    x = x,
    site = site
  )
  list(
    data = data,
    tree = tree,
    beta_mu = beta_mu,
    sd_intercept = sd_intercept,
    sd_slope = sd_slope
  )
}

empty_result <- function(seed, replicate_id, status, stage, message) {
  data.frame(
    replicate_id = replicate_id,
    seed = seed,
    attempt_status = status,
    error_stage = stage,
    message = clean_text(message),
    convergence = NA_integer_,
    pdHess = NA,
    mu_intercept = NA_real_,
    mu_x = NA_real_,
    sd_mu_intercept = NA_real_,
    sd_mu_x = NA_real_,
    truth_mu_intercept = 0.55,
    truth_mu_x = -0.15,
    truth_sd_mu_intercept = 0.25,
    truth_sd_mu_x = 0.45,
    elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

run_one <- function(seed, replicate_id) {
  sim <- new_phylo_poisson_slope_data(seed)
  tree <- sim$tree
  warnings <- character()
  elapsed <- system.time({
    fit <- withCallingHandlers(
      drmTMB(
        bf(poisson_phylo ~ x + phylo(1 + x | site, tree = tree)),
        family = stats::poisson(link = "log"),
        data = sim$data
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })
  mu <- coef(fit, "mu")
  sd_mu <- fit$sdpars$mu
  intercept_label <- "phylo(1 | site)"
  slope_label <- "phylo(0 + x | site)"
  data.frame(
    replicate_id = replicate_id,
    seed = seed,
    attempt_status = "fit_ok",
    error_stage = "none",
    message = clean_text(paste(warnings, collapse = "; ")),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    mu_intercept = unname(mu[["(Intercept)"]]),
    mu_x = unname(mu[["x"]]),
    sd_mu_intercept = unname(sd_mu[[intercept_label]]),
    sd_mu_x = unname(sd_mu[[slope_label]]),
    truth_mu_intercept = unname(sim$beta_mu[["(Intercept)"]]),
    truth_mu_x = unname(sim$beta_mu[["x"]]),
    truth_sd_mu_intercept = sim$sd_intercept,
    truth_sd_mu_x = sim$sd_slope,
    elapsed_sec = unname(elapsed[["elapsed"]]),
    stringsAsFactors = FALSE
  )
}

summarise_results <- function(results, load_status, load_detail) {
  fit_rows <- results[results$attempt_status == "fit_ok", , drop = FALSE]
  finite_targets <- c(
    "mu_intercept",
    "mu_x",
    "sd_mu_intercept",
    "sd_mu_x"
  )
  finite_estimate_rows <- if (nrow(fit_rows) == 0L) {
    0L
  } else {
    sum(stats::complete.cases(fit_rows[, finite_targets, drop = FALSE]))
  }
  data.frame(
    micro_shard_id = "count_slope_phylo_poisson_q1_mu_one_slope_local_micro_shard",
    cell_id = "qseries_phylo_poisson_q1_mu_one_slope",
    family = "poisson()",
    structured_type = "phylo",
    planned_replicates = nrow(results),
    attempted_replicates = sum(results$attempt_status != "not_attempted"),
    fit_ok = sum(results$attempt_status == "fit_ok"),
    fit_error = sum(results$attempt_status == "fit_error"),
    nonconverged = sum(
      results$attempt_status == "fit_ok" &
        !is.na(results$convergence) &
        results$convergence != 0L
    ),
    pdhess_false = sum(
      results$attempt_status == "fit_ok" &
        !is.na(results$pdHess) &
        !results$pdHess
    ),
    finite_estimate_rows = finite_estimate_rows,
    package_load_status = load_status,
    package_load_detail = clean_text(load_detail),
    denominator_status = "not_coverage_evidence",
    coverage_evaluable = "FALSE",
    interval_status = "unsupported",
    coverage_status = "planned",
    support_status = "not_promoted",
    stringsAsFactors = FALSE
  )
}

load_result <- try_load_drmTMB(args$attempt_temp_install)
seeds <- seq.int(args$seed_start, length.out = args$n_rep)
if (!load_result$ok) {
  results <- do.call(
    rbind,
    Map(
      function(seed, i) {
        empty_result(
          seed,
          i,
          "not_attempted",
          "package_load",
          load_result$detail
        )
      },
      seeds,
      seq_along(seeds)
    )
  )
} else {
  results <- do.call(
    rbind,
    Map(
      function(seed, i) {
        tryCatch(
          run_one(seed, i),
          error = function(e) {
            empty_result(seed, i, "fit_error", "fit", conditionMessage(e))
          }
        )
      },
      seeds,
      seq_along(seeds)
    )
  )
}

summary <- summarise_results(results, load_result$status, load_result$detail)
run_log <- data.frame(
  run_id = "count_slope_phylo_poisson_q1_mu_one_slope_local_micro_shard_run",
  mode = "local_micro_shard",
  runner_script = "tools/run-structured-re-count-slope-phylo-poisson-local-micro-shard.R",
  planned_replicates = args$n_rep,
  seed_start = min(seeds),
  seed_end = max(seeds),
  package_load_status = load_result$status,
  compute_status = if (load_result$ok) {
    "local_completed"
  } else {
    "blocked_local_toolchain"
  },
  recovery_status = if (load_result$ok) {
    "local_micro_shard_executed"
  } else {
    "execution_blocked_before_fit"
  },
  denominator_status = "not_coverage_evidence",
  coverage_evaluable = "FALSE",
  claim_boundary = paste(
    "Local phylo Poisson q1 mu one-slope micro-shard only;",
    "no Totoro job submitted, no DRAC job submitted, no bridge parity,",
    "no interval reliability, no coverage evidence, no q2, no q4,",
    "no REML, no AI-REML, no public support, and no broad bridge support promoted."
  ),
  stringsAsFactors = FALSE
)

write_tsv(results, replicate_path)
write_tsv(summary, summary_path)
write_tsv(run_log, run_log_path)

message("wrote ", replicate_path)
message("wrote ", summary_path)
message("wrote ", run_log_path)
