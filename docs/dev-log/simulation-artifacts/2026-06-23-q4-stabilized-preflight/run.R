#!/usr/bin/env Rscript

suppressPackageStartupMessages(devtools::load_all(quiet = TRUE))
if (!requireNamespace("ape", quietly = TRUE)) {
  stop("The ape package is required for this artifact.", call. = FALSE)
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
  sd_scale = 0.35,
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

fit_q4_preflight <- function(seed, sd_scale) {
  n_tip <- 32L
  n_each <- 8L
  corr_offdiag <- 0.05
  sim <- make_q4_data(
    seed = seed,
    n_tip = n_tip,
    n_each = n_each,
    sd_scale = sd_scale,
    corr_offdiag = corr_offdiag
  )
  dat <- sim$data
  tree <- sim$tree
  elapsed <- system.time({
    fit <- try(
      suppressWarnings(drmTMB(
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
      )),
      silent = TRUE
    )
  })[["elapsed"]]

  if (inherits(fit, "try-error")) {
    return(data.frame(
      seed = seed,
      n_tip = n_tip,
      n_each = n_each,
      sd_scale = sd_scale,
      corr_offdiag = corr_offdiag,
      fit_ok = FALSE,
      convergence = NA_integer_,
      converged = FALSE,
      pdHess = FALSE,
      max_gradient = NA_real_,
      min_direct_sd_estimate = NA_real_,
      max_abs_derived_correlation = NA_real_,
      finite_wald_direct_sd_intervals = "not_evaluated",
      direct_sd_interval_status = "fit_error",
      elapsed_sec = elapsed,
      message = as.character(fit)[[1L]]
    ))
  }

  sd_names <- c(
    "mu1:phylo(1 | p | species)",
    "mu2:phylo(1 | p | species)",
    "sigma1:phylo(1 | p | species)",
    "sigma2:phylo(1 | p | species)"
  )
  direct_sd <- unname(fit$sdpars$mu[sd_names])
  derived_cor <- unname(fit$corpars$phylo)
  finite_wald_direct_sd_intervals <- "not_evaluated"
  direct_sd_interval_status <- if (isTRUE(fit$sdr$pdHess)) "wald_unavailable" else "pdhess_false"

  if (isTRUE(fit$sdr$pdHess)) {
    intervals <- try(stats::confint(fit), silent = TRUE)
    if (!inherits(intervals, "try-error")) {
      direct_rows <- intervals[
        intervals$tmb_parameter == "log_sd_phylo" &
          intervals$method == "wald",
        ,
        drop = FALSE
      ]
      n_finite <- sum(is.finite(direct_rows$lower) & is.finite(direct_rows$upper))
      finite_wald_direct_sd_intervals <- paste0(n_finite, "_of_4")
      direct_sd_interval_status <- if (n_finite == 4L) "wald_finite" else "wald_incomplete"
    }
  }

  data.frame(
    seed = seed,
    n_tip = n_tip,
    n_each = n_each,
    sd_scale = sd_scale,
    corr_offdiag = corr_offdiag,
    fit_ok = TRUE,
    convergence = fit$opt$convergence,
    converged = identical(fit$opt$convergence, 0L),
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
    min_direct_sd_estimate = min(direct_sd, na.rm = TRUE),
    max_abs_derived_correlation = max(abs(derived_cor), na.rm = TRUE),
    finite_wald_direct_sd_intervals = finite_wald_direct_sd_intervals,
    direct_sd_interval_status = direct_sd_interval_status,
    elapsed_sec = elapsed,
    message = fit$opt$message %||% ""
  )
}

grid <- expand.grid(
  seed = c(202606901L, 202606902L),
  sd_scale = c(0.35, 0.50),
  KEEP.OUT.ATTRS = FALSE
)
rows <- Map(fit_q4_preflight, grid$seed, grid$sd_scale)
results <- do.call(rbind, rows)
results$diagnostic_class <- ifelse(
  results$pdHess & results$finite_wald_direct_sd_intervals == "4_of_4",
  "converged_pdhess_true_finite_wald_direct_sd_intervals",
  "nonconverged_pdhess_false_interior_correlation"
)

out <- file.path(artifact_dir, "q4-stabilized-preflight-results.tsv")
utils::write.table(
  results,
  file = out,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE,
  na = ""
)
print(results)
message("Wrote ", out)
