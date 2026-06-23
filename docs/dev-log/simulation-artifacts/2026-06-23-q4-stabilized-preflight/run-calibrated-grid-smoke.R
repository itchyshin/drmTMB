#!/usr/bin/env Rscript

suppressPackageStartupMessages(devtools::load_all(quiet = TRUE))
if (!requireNamespace("ape", quietly = TRUE)) {
  stop("The ape package is required for this artifact.", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
value_arg <- function(name, default) {
  prefix <- paste0("--", name, "=")
  hit <- grep(paste0("^", prefix), args, value = TRUE)
  if (!length(hit)) {
    return(default)
  }
  sub(prefix, "", hit[[1L]], fixed = TRUE)
}

n_rep <- as.integer(value_arg("n-rep", "1"))
seed_start <- as.integer(value_arg("seed-start", "202606902"))
sd_scale <- as.numeric(value_arg("sd-scale", "0.50"))
if (is.na(n_rep) || n_rep != 1L) {
  stop(
    "This smoke artifact only permits one replicate; use --n-rep=1.",
    call. = FALSE
  )
}
if (is.na(seed_start) || seed_start <= 0L) {
  stop("--seed-start must be a positive integer.", call. = FALSE)
}
if (is.na(sd_scale) || sd_scale <= 0) {
  stop("--sd-scale must be a positive number.", call. = FALSE)
}

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
artifact_dir <- if (length(script_arg)) {
  script_path <- sub("^--file=", "", script_arg[[1L]])
  if (file.exists(script_path)) {
    dirname(normalizePath(script_path, mustWork = TRUE))
  } else {
    getwd()
  }
} else {
  getwd()
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

balanced_ultrametric_tree <- function(n_tip = 32L) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
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

make_q4_data <- function(
  seed,
  n_tip = 32L,
  n_each = 8L,
  sd_scale = 0.50,
  corr_offdiag = 0.05,
  rho12 = 0.10
) {
  set.seed(seed)
  sd_phylo <- c(mu1 = 0.90, mu2 = 0.80, sigma1 = sd_scale, sigma2 = sd_scale)
  corr <- diag(4L)
  corr[lower.tri(corr)] <- corr[upper.tri(corr)] <- corr_offdiag
  tree <- balanced_ultrametric_tree(n_tip)
  covariance <- diag(sd_phylo) %*% corr %*% diag(sd_phylo)
  tip_covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_phylo <- matrix(stats::rnorm(n_tip * 4L), n_tip, 4L)
  phylo_effect <- t(chol(tip_covariance)) %*%
    z_phylo %*%
    chol(covariance)
  dimnames(phylo_effect) <- list(tree$tip.label, names(sd_phylo))

  species <- rep(tree$tip.label, each = n_each)
  n <- length(species)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  eta_mu1 <- 0.35 + 0.30 * x + phylo_effect[species, "mu1"]
  eta_mu2 <- -0.20 - 0.25 * x + phylo_effect[species, "mu2"]
  log_sigma1 <- -1.15 + 0.20 * z + phylo_effect[species, "sigma1"]
  log_sigma2 <- -1.05 - 0.15 * z + phylo_effect[species, "sigma2"]
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

  list(
    true_sd = sd_phylo,
    true_cor = corr_offdiag,
    tree = tree,
    data = data.frame(
      y1 = eta_mu1 + exp(log_sigma1) * e1,
      y2 = eta_mu2 + exp(log_sigma2) * e2,
      x = x,
      z = z,
      species = species
    )
  )
}

append_warning <- function(store, warning) {
  unique(c(store, conditionMessage(warning)))
}

collapse_context <- function(x) {
  x <- unique(x[nzchar(x)])
  if (length(x)) {
    paste(gsub("[[:space:]]+", " ", x), collapse = ";")
  } else {
    "none"
  }
}

squash_text <- function(x) {
  gsub("[[:space:]]+", " ", x)
}

make_result_rows <- function() {
  n_tip <- 32L
  n_each <- 8L
  corr_offdiag <- 0.05
  sim <- make_q4_data(
    seed = seed_start,
    n_tip = n_tip,
    n_each = n_each,
    sd_scale = sd_scale,
    corr_offdiag = corr_offdiag
  )
  dat <- sim$data
  tree <- sim$tree
  warnings_seen <- character()
  elapsed <- system.time({
    fit <- try(
      withCallingHandlers(
        drmTMB(
          bf(
            mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
            mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
            sigma1 = ~ z + phylo(1 | p | species, tree = tree),
            sigma2 = ~ z + phylo(1 | p | species, tree = tree),
            rho12 = ~1
          ),
          family = c(gaussian(), gaussian()),
          data = dat,
          control = list(eval.max = 1000, iter.max = 1000)
        ),
        warning = function(w) {
          warnings_seen <<- append_warning(warnings_seen, w)
          invokeRestart("muffleWarning")
        }
      ),
      silent = TRUE
    )
  })[["elapsed"]]

  axes <- c("mu1", "mu2", "sigma1", "sigma2")
  direct_targets <- paste0("sd_", axes)
  direct_parms <- paste0("sd:mu:", axes, ":phylo(1 | p | species)")
  cor_pairs <- c(
    "mu1_mu2",
    "mu1_sigma1",
    "mu1_sigma2",
    "mu2_sigma1",
    "mu2_sigma2",
    "sigma1_sigma2"
  )
  claim_boundary <- paste(
    "Q4 stabilized calibrated-grid smoke only; no q4 interval reliability,",
    "interval coverage, q4 REML, AI-REML, or broad bridge support is promoted."
  )

  if (inherits(fit, "try-error")) {
    failure_reason <- squash_text(as.character(fit)[[1L]])
    direct <- data.frame(
      replicate_id = "smoke_001",
      seed = seed_start,
      sd_scale = sd_scale,
      axis = axes,
      target_name = direct_targets,
      target_kind = "direct_sd",
      true_value = unname(sim$true_sd[axes]),
      fit_status = "fit_error",
      convergence = NA_integer_,
      converged = FALSE,
      pdHess = FALSE,
      max_gradient = NA_real_,
      fit_elapsed_sec = elapsed,
      interval_method = "wald",
      interval_status = "fit_error",
      lower = NA_real_,
      upper = NA_real_,
      warning_context = collapse_context(warnings_seen),
      failure_reason = failure_reason,
      coverage_indicator = "not_evaluated",
      coverage_mcse = "not_computed_single_replicate",
      failure_rate_mcse = "not_computed_single_replicate",
      mcse_status = "insufficient_replicates",
      claim_boundary = claim_boundary
    )
    derived <- direct[rep(1L, length(cor_pairs)), , drop = FALSE]
    derived$axis <- cor_pairs
    derived$target_name <- paste0("cor_", cor_pairs)
    derived$target_kind <- "derived_correlation"
    derived$true_value <- corr_offdiag
    derived$interval_method <- "not_available"
    derived$interval_status <- "fit_error"
    return(rbind(direct, derived))
  }

  direct_rows <- data.frame()
  confint_warning <- character()
  intervals <- NULL
  if (isTRUE(fit$sdr$pdHess)) {
    intervals <- try(
      withCallingHandlers(
        stats::confint(fit),
        warning = function(w) {
          confint_warning <<- append_warning(confint_warning, w)
          invokeRestart("muffleWarning")
        }
      ),
      silent = TRUE
    )
  }
  all_warnings <- c(warnings_seen, confint_warning)
  max_gradient <- max(abs(fit$obj$gr(fit$opt$par)))
  if (!inherits(intervals, "try-error") && !is.null(intervals)) {
    direct_rows <- intervals[
      intervals$tmb_parameter == "log_sd_phylo" &
        intervals$method == "wald",
      ,
      drop = FALSE
    ]
  }

  direct <- lapply(seq_along(axes), function(i) {
    has_interval <- nrow(direct_rows) >= i &&
      is.finite(direct_rows$lower[[i]]) &&
      is.finite(direct_rows$upper[[i]])
    lower <- if (has_interval) direct_rows$lower[[i]] else NA_real_
    upper <- if (has_interval) direct_rows$upper[[i]] else NA_real_
    truth <- unname(sim$true_sd[[axes[[i]]]])
    covered <- if (has_interval && truth >= lower && truth <= upper) {
      "covered_by_interval"
    } else if (has_interval) {
      "missed_by_interval"
    } else {
      "not_evaluated"
    }
    data.frame(
      replicate_id = "smoke_001",
      seed = seed_start,
      sd_scale = sd_scale,
      axis = axes[[i]],
      target_name = direct_targets[[i]],
      target_kind = "direct_sd",
      true_value = truth,
      fit_status = "fit_ok",
      convergence = fit$opt$convergence,
      converged = identical(fit$opt$convergence, 0L),
      pdHess = isTRUE(fit$sdr$pdHess),
      max_gradient = max_gradient,
      fit_elapsed_sec = elapsed,
      interval_method = "wald",
      interval_status = if (has_interval) "finite" else "unavailable",
      lower = lower,
      upper = upper,
      warning_context = collapse_context(all_warnings),
      failure_reason = if (has_interval) {
        "none"
      } else {
        "wald_interval_unavailable"
      },
      coverage_indicator = covered,
      coverage_mcse = "not_computed_single_replicate",
      failure_rate_mcse = "not_computed_single_replicate",
      mcse_status = "insufficient_replicates",
      claim_boundary = claim_boundary
    )
  })
  direct <- do.call(rbind, direct)

  derived <- data.frame(
    replicate_id = "smoke_001",
    seed = seed_start,
    sd_scale = sd_scale,
    axis = cor_pairs,
    target_name = paste0("cor_", cor_pairs),
    target_kind = "derived_correlation",
    true_value = corr_offdiag,
    fit_status = "fit_ok",
    convergence = fit$opt$convergence,
    converged = identical(fit$opt$convergence, 0L),
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max_gradient,
    fit_elapsed_sec = elapsed,
    interval_method = "not_available",
    interval_status = "derived_correlation_interval_not_reconstructed",
    lower = NA_real_,
    upper = NA_real_,
    warning_context = collapse_context(all_warnings),
    failure_reason = "derived_correlation_interval_reconstruction_not_available",
    coverage_indicator = "not_evaluated",
    coverage_mcse = "not_computed_single_replicate",
    failure_rate_mcse = "not_computed_single_replicate",
    mcse_status = "insufficient_replicates",
    claim_boundary = claim_boundary
  )

  rbind(direct, derived)
}

results <- make_result_rows()
path <- file.path(
  artifact_dir,
  "q4-stabilized-calibrated-grid-smoke-results.tsv"
)
utils::write.table(
  results,
  file = path,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)
message("Wrote ", path)
