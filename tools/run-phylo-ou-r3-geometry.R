#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "--preflight"
if (!mode %in% c("--contract", "--preflight", "--run")) stop("Usage: Rscript tools/run-phylo-ou-r3-geometry.R [--contract|--preflight|--run]", call. = FALSE)
if (identical(mode, "--contract")) { cat("OU_V1_R3_RUNNER_CONTRACT_PASS\n"); quit(status = 0L) }
if (!requireNamespace("ape", quietly = TRUE) || !requireNamespace("pkgload", quietly = TRUE) || !requireNamespace("statmod", quietly = TRUE)) stop("R3 needs ape, pkgload, and statmod.", call. = FALSE)

root_r2 <- file.path("docs", "dev-log", "evidence", "ou-v1-r2")
out_dir <- file.path("docs", "dev-log", "evidence", "ou-v1-r3")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
run_started <- Sys.time(); pkgload::load_all(".", compile = TRUE, quiet = TRUE)

fit_fixed_rates <- function(dat, tree, rates) {
  formula <- bf(y ~ phylo(1 | species, tree = tree, model = "ou"), sigma ~ phylo(1 | species, tree = tree, model = "ou"))
  control <- drmTMB:::drm_parse_control(drm_control(optimizer = list(eval.max = 1500, iter.max = 1500)))
  spec <- drmTMB:::drm_build_gaussian_ls_spec(formula, dat, env = environment(), weights = NULL, control = control, impute = NULL, missing = drmTMB:::drm_parse_missing_control(miss_control()))
  spec$map$log_decay_phylo <- factor(c(NA, NA)); spec$start$log_decay_phylo <- log(rates)
  warnings <- character(); begun <- Sys.time()
  fit <- tryCatch(withCallingHandlers(drmTMB:::drm_fit_spec(spec, formula, gaussian(), control, REML = FALSE, penalty = NULL, estimator = "ml"), warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }), error = identity)
  if (inherits(fit, "error")) return(list(fit = NULL, elapsed = as.numeric(difftime(Sys.time(), begun, units = "secs")), warning = paste(warnings, collapse = " | "), error = conditionMessage(fit)))
  list(fit = fit, elapsed = as.numeric(difftime(Sys.time(), begun, units = "secs")), warning = paste(warnings, collapse = " | "), error = NA_character_)
}

profile_rows <- function(task_id, grid) {
  tree_id <- sub("^R2_n128_m12_.*_rep", "r2_tree_rate", task_id)
  replicate <- sub(".*_rep", "", task_id)
  rate_id <- if (grepl("amu0p7", task_id, fixed = TRUE)) 1L else 2L
  tree <- ape::read.tree(file.path(root_r2, "trees", sprintf("r2_tree_rate%d_rep%s.nwk", rate_id, replicate)))
  dat <- utils::read.csv(file.path(root_r2, "data", paste0(task_id, ".csv")), stringsAsFactors = FALSE)
  out <- do.call(rbind, lapply(grid$alpha_mu, function(alpha_mu) do.call(rbind, lapply(grid$alpha_sigma, function(alpha_sigma) {
    z <- fit_fixed_rates(dat, tree, c(alpha_mu, alpha_sigma))
    if (is.null(z$fit)) return(data.frame(task_id, alpha_mu, alpha_sigma, objective = NA_real_, convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_, sd_mu = NA_real_, sd_sigma = NA_real_, elapsed_seconds = z$elapsed, warning = z$warning, error = z$error))
    data.frame(task_id, alpha_mu, alpha_sigma, objective = z$fit$opt$objective, convergence = z$fit$opt$convergence, pdHess = isTRUE(z$fit$sdr$pdHess), max_gradient = max(abs(z$fit$obj$gr(z$fit$opt$par))), sd_mu = unname(z$fit$sdpars$mu[[1L]]), sd_sigma = unname(z$fit$sdpars$sigma[[1L]]), elapsed_seconds = z$elapsed, warning = z$warning, error = NA_character_)
  }))))
  finite <- is.finite(out$objective); out$delta_objective <- NA_real_; out$delta_objective[finite] <- out$objective[finite] - min(out$objective[finite]); out
}

normal_product_loglik <- function(dat, tree, beta_mu, beta_sigma, sd_mu, sd_sigma, alpha_mu, alpha_sigma, n_node) {
  nodes <- statmod::gauss.quad.prob(n_node, "normal"); grid <- as.matrix(expand.grid(rep(list(nodes$nodes), 6L))); logw <- rowSums(log(as.matrix(expand.grid(rep(list(nodes$weights), 6L)))))
  distance <- ape::cophenetic.phylo(tree); L_mu <- t(chol(sd_mu^2 * exp(-alpha_mu * distance))); L_sigma <- t(chol(sd_sigma^2 * exp(-alpha_sigma * distance)))
  state_mu <- grid[, 1:3, drop = FALSE] %*% L_mu; state_sigma <- grid[, 4:6, drop = FALSE] %*% L_sigma
  index <- match(dat$species, tree$tip.label); log_density <- logw
  for (i in seq_len(nrow(dat))) log_density <- log_density + stats::dnorm(dat$y[[i]], mean = beta_mu + state_mu[, index[[i]]], sd = exp(beta_sigma + state_sigma[, index[[i]]]), log = TRUE)
  m <- max(log_density); -(m + log(sum(exp(log_density - m))))
}

integration_rows <- function() {
  set.seed(2026091401); tree <- ape::rcoal(3); tree$tip.label <- paste0("sp", 1:3); h <- max(ape::node.depth.edgelength(tree)[1:3]); tree$edge.length <- tree$edge.length / h
  d <- ape::cophenetic.phylo(tree); u <- drop(t(chol(0.45^2 * exp(-0.7 * d))) %*% rnorm(3)); v <- drop(t(chol(0.25^2 * exp(-1.3 * d))) %*% rnorm(3)); species <- rep(tree$tip.label, each = 3); index <- match(species, tree$tip.label); dat <- data.frame(y = u[index] + rnorm(9, sd = exp(-1 + v[index])), species = species)
  fit_result <- fit_fixed_rates(dat, tree, c(0.7, 1.3)); if (is.null(fit_result$fit)) stop(fit_result$error, call. = FALSE)
  fit <- fit_result$fit; beta_mu <- unname(fit$par$mu[[1L]]); beta_sigma <- unname(fit$par$sigma[[1L]]); sd_mu <- unname(fit$sdpars$mu[[1L]]); sd_sigma <- unname(fit$sdpars$sigma[[1L]])
  rows <- do.call(rbind, lapply(c(5L, 7L), function(n) data.frame(quadrature_nodes = n, quadrature_objective = normal_product_loglik(dat, tree, beta_mu, beta_sigma, sd_mu, sd_sigma, 0.7, 1.3, n))))
  rows$laplace_objective <- fit$opt$objective; rows$laplace_minus_quadrature <- rows$laplace_objective - rows$quadrature_objective; rows$quadrature_refinement <- c(NA_real_, abs(diff(rows$quadrature_objective))); rows
}

grid <- data.frame(alpha_mu = c(0.3, 0.7, 1.3, 3, 8), alpha_sigma = c(0.3, 0.7, 1.3, 3, 8))
if (identical(mode, "--preflight")) {
  z <- profile_rows("R2_n128_m12_amu0p7_asigma1p3_rep1", data.frame(alpha_mu = 0.7, alpha_sigma = 1.3))
  utils::write.csv(z, file.path(out_dir, "preflight.csv"), row.names = FALSE)
  utils::write.csv(data.frame(profile_points = 50L, observed_seconds = z$elapsed_seconds, projected_seconds = 50 * z$elapsed_seconds, within_30_minutes = 50 * z$elapsed_seconds <= 1800), file.path(out_dir, "preflight-summary.csv"), row.names = FALSE)
} else {
  profile <- rbind(profile_rows("R2_n128_m12_amu0p7_asigma1p3_rep1", grid), profile_rows("R2_n128_m12_amu1p3_asigma0p7_rep1", grid))
  integration <- integration_rows(); utils::write.csv(profile, file.path(out_dir, "profile.csv"), row.names = FALSE); utils::write.csv(integration, file.path(out_dir, "integration.csv"), row.names = FALSE)
  writeLines(c("# OU v1 R3 likelihood geometry", "", "R3 is a diagnostic, not a recovery or G15 promotion claim.", sprintf("Profile finite points: %d/%d; minimum delta objective: %.6f.", sum(is.finite(profile$objective)), nrow(profile), min(profile$delta_objective, na.rm = TRUE)), sprintf("Laplace minus 7-node quadrature objective: %.6f; 5-to-7-node refinement: %.6f.", integration$laplace_minus_quadrature[[2L]], integration$quadrature_refinement[[2L]])), file.path(out_dir, "RESULTS.md"))
}
cat(sprintf("OU_V1_R3_%s_PASS output=%s\n", toupper(sub("--", "", mode)), normalizePath(out_dir)))
