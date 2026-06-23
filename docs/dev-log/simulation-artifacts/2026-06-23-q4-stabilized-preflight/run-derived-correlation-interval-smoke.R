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
    "This derived-correlation smoke artifact only permits one replicate; use --n-rep=1.",
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

make_result_rows <- function() {
  sim <- make_q4_data(seed = seed_start, sd_scale = sd_scale)
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

  if (inherits(fit, "try-error")) {
    stop(
      gsub("[[:space:]]+", " ", as.character(fit)[[1L]]),
      call. = FALSE
    )
  }

  pairs <- corpairs(fit, level = "phylogenetic", conf.int = TRUE)
  pairs <- pairs[order(pairs$from_dpar, pairs$to_dpar), , drop = FALSE]
  axis_pair <- paste(pairs$from_dpar, pairs$to_dpar, sep = "_")
  claim_boundary <- paste(
    "Q4 derived-correlation interval smoke only; no q4 interval reliability,",
    "interval coverage, q4 REML, AI-REML, or broad bridge support is promoted."
  )

  data.frame(
    replicate_id = "derived_smoke_001",
    seed = seed_start,
    sd_scale = sd_scale,
    axis_pair = axis_pair,
    target_name = paste0("cor_", axis_pair),
    target_kind = "derived_correlation",
    true_value = sim$true_cor,
    estimate = pairs$estimate,
    fit_status = "fit_ok",
    convergence = fit$opt$convergence,
    converged = identical(fit$opt$convergence, 0L),
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
    fit_elapsed_sec = elapsed,
    parameter = pairs$parameter,
    from_dpar = pairs$from_dpar,
    to_dpar = pairs$to_dpar,
    class = pairs$class,
    profile_target = pairs$profile_target,
    interval_method = pairs$conf.method,
    interval_status = pairs$conf.status,
    interval_source = pairs$interval_source,
    lower = pairs$conf.low,
    upper = pairs$conf.high,
    warning_context = collapse_context(warnings_seen),
    failure_reason = "derived_interval_unavailable_by_profile_targets",
    coverage_indicator = "not_evaluated",
    coverage_mcse = "not_computed_single_replicate",
    failure_rate_mcse = "not_computed_single_replicate",
    mcse_status = "insufficient_replicates",
    claim_boundary = claim_boundary,
    stringsAsFactors = FALSE
  )
}

results <- make_result_rows()
path <- file.path(
  artifact_dir,
  "q4-derived-correlation-interval-smoke-results.tsv"
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
