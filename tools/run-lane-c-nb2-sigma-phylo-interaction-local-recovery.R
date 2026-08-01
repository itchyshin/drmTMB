#!/usr/bin/env Rscript

# Lane C C7 retained local point-recovery receipt. This tests exactly ordinary
# NB2 sigma ~ phylo_interaction(1 | plant:pollinator), not profiles or intervals.

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
clean_text <- function(x) trimws(gsub(" +", " ", gsub("[\r\n\t]+", " ", paste(as.character(x), collapse = "; "))))

new_data <- function(seed, n_plant = 8L, n_pollinator = 8L, n_each = 18L,
                     tau = .60, sigma_intercept = -.20) {
  set.seed(seed)
  plant_tree <- ape::stree(n_plant, type = "balanced")
  pollinator_tree <- ape::stree(n_pollinator, type = "balanced")
  plant_tree$edge.length <- rep(1, nrow(plant_tree$edge))
  pollinator_tree$edge.length <- rep(1, nrow(pollinator_tree$edge))
  plant_tree$tip.label <- paste0("plant_", seq_len(n_plant))
  pollinator_tree$tip.label <- paste0("poll_", seq_len(n_pollinator))
  V1 <- drmTMB:::drm_phylo_tip_covariance(plant_tree)
  V2 <- drmTMB:::drm_phylo_tip_covariance(pollinator_tree)
  pair_cov <- kronecker(V2, V1)
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  pair_effect <- as.numeric(t(chol(pair_cov)) %*% stats::rnorm(nrow(pair_grid), sd = tau))
  names(pair_effect) <- paste(pair_grid$plant, pair_grid$pollinator, sep = ":")
  pair_id <- rep(seq_len(nrow(pair_grid)), each = n_each)
  data <- pair_grid[pair_id, , drop = FALSE]
  data$x <- stats::rnorm(nrow(data))
  data$x <- data$x - ave(data$x, interaction(data$plant, data$pollinator, drop = TRUE), FUN = mean)
  data$x <- data$x / stats::sd(data$x)
  log_sigma <- sigma_intercept + pair_effect[paste(data$plant, data$pollinator, sep = ":")]
  data$count <- stats::rnbinom(nrow(data), mu = exp(1.40 + .30 * data$x), size = exp(-2 * log_sigma))
  list(data = data, plant_tree = plant_tree, pollinator_tree = pollinator_tree,
       tau = tau, sigma_intercept = sigma_intercept,
       dgp_digest = digest::digest(list(pair_cov = pair_cov, x = data$x, log_sigma = log_sigma)))
}

fit_one <- function(sim) {
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  drmTMB::drmTMB(
    drmTMB::bf(count ~ x, sigma ~ phylo_interaction(
      1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree
    )),
    family = drmTMB::nbinom2(), data = sim$data,
    control = list(eval.max = 1000, iter.max = 1000)
  )
}

run_one <- function(source_sha, runner_sha, attempt_id, seed) {
  out <- data.frame(
    fixture_id = "lane_c_nb2_sigma_phylo_interaction_local", source_sha, runner_sha,
    attempt_id, seed, r_version = R.version.string,
    drmTMB_version = as.character(utils::packageVersion("drmTMB")),
    tmb_version = as.character(utils::packageVersion("TMB")),
    n_plant = 8L, n_pollinator = 8L, n_each = 18L, n_obs = 1152L,
    formula = "count ~ x; sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)",
    beta0_truth = 1.40, beta1_truth = .30, sigma_intercept_truth = -.20, tau_truth = .60,
    dgp_digest = NA_character_, fit_status = NA_character_, error_stage = NA_character_,
    warning = NA_character_, convergence = NA_integer_, pdHess = NA,
    objective = NA_real_, max_gradient = NA_real_, boundary_hit = NA,
    beta0_hat = NA_real_, beta1_hat = NA_real_, sigma_intercept_hat = NA_real_,
    tau_hat = NA_real_, elapsed_sec = NA_real_
  )
  warnings <- character(); sim <- tryCatch(new_data(seed), error = identity)
  if (inherits(sim, "error")) { out$fit_status <- "fit_error"; out$error_stage <- "dgp"; out$warning <- clean_text(conditionMessage(sim)); return(out) }
  out$dgp_digest <- sim$dgp_digest
  elapsed <- system.time(fit <- tryCatch(withCallingHandlers(
    fit_one(sim), warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }
  ), error = identity))
  out$elapsed_sec <- unname(elapsed[["elapsed"]])
  if (inherits(fit, "error")) { out$fit_status <- "fit_error"; out$error_stage <- "fit"; out$warning <- clean_text(c(warnings, conditionMessage(fit))); return(out) }
  grad <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  out$fit_status <- "fit_ok"; out$error_stage <- "none"; out$warning <- clean_text(warnings)
  out$convergence <- fit$opt$convergence; out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$objective <- fit$opt$objective; out$max_gradient <- if (all(is.finite(grad))) max(abs(grad)) else NA_real_
  out$beta0_hat <- fit$coefficients$mu[["(Intercept)"]]; out$beta1_hat <- fit$coefficients$mu[["x"]]
  out$sigma_intercept_hat <- fit$coefficients$sigma[["(Intercept)"]]
  out$tau_hat <- fit$sdpars$sigma[["phylo_interaction(1 | plant:pollinator)"]]
  finite <- all(is.finite(unlist(out[c("beta0_hat", "beta1_hat", "sigma_intercept_hat", "tau_hat")])))
  out$boundary_hit <- !finite || out$tau_hat <= .05 || out$tau_hat >= 3
  out
}

summarise_attempts <- function(x) {
  nm <- c("beta0_hat", "beta1_hat", "sigma_intercept_hat", "tau_hat")
  valid <- x$fit_status == "fit_ok" & x$convergence == 0L & x$pdHess & !x$boundary_hit & stats::complete.cases(x[, nm])
  means <- if (any(valid)) colMeans(x[valid, nm, drop = FALSE]) else stats::setNames(rep(NA_real_, length(nm)), nm)
  pass <- length(valid) == 4L && all(valid) && abs(means[["beta0_hat"]] - 1.40) <= .20 &&
    abs(means[["beta1_hat"]] - .30) <= .20 && abs(means[["sigma_intercept_hat"]] + .20) <= .25 &&
    abs(means[["tau_hat"]] / .60 - 1) <= .40
  data.frame(fixture_id = "lane_c_nb2_sigma_phylo_interaction_local", planned_attempts = 4L,
    attempted_attempts = nrow(x), fit_ok = sum(x$fit_status == "fit_ok"),
    fit_error = sum(x$fit_status == "fit_error"), nonconverged = sum(x$fit_status == "fit_ok" & x$convergence != 0L),
    pdhess_false = sum(x$fit_status == "fit_ok" & !x$pdHess), boundary_hits = sum(x$fit_status == "fit_ok" & x$boundary_hit),
    mean_beta0_hat = means[["beta0_hat"]], mean_beta1_hat = means[["beta1_hat"]],
    mean_sigma_intercept_hat = means[["sigma_intercept_hat"]], mean_tau_hat = means[["tau_hat"]],
    decision = if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE")
}

run_iid_dgp_control <- function(source_sha, seed = 2026072999L, n_draw = 8192L) {
  set.seed(seed); tau <- .60; draws <- stats::rnorm(n_draw, sd = tau)
  data.frame(control_id = "lane_c_nb2_sigma_phylo_interaction_iid_dgp", source_sha, seed, n_draw,
    tau_truth = tau, tau_empirical = stats::sd(draws),
    decision = if (abs(stats::sd(draws) / tau - 1) <= .04) "PASS_IID_DGP_CONTROL" else "BLOCKED_IID_DGP_CONTROL")
}

run_iid_fitted_control <- function(source_sha, runner_sha, seed = 2026072999L) {
  set.seed(seed)
  n_pair <- 64L; n_each <- 18L; tau <- .60
  pair <- factor(rep(paste0("pair_", seq_len(n_pair)), each = n_each))
  x <- stats::rnorm(length(pair)); x <- x - ave(x, pair, FUN = mean); x <- x / stats::sd(x)
  pair_effect <- stats::rnorm(n_pair, sd = tau); names(pair_effect) <- levels(pair)
  log_sigma <- -.20 + pair_effect[as.character(pair)]
  data <- data.frame(
    count = stats::rnbinom(length(pair), mu = exp(1.40 + .30 * x), size = exp(-2 * log_sigma)),
    x = x, pair = pair
  )
  out <- data.frame(control_id = "lane_c_nb2_sigma_phylo_interaction_iid_fit", source_sha, runner_sha, seed,
    n_pair, n_each, n_obs = nrow(data), tau_truth = tau, fit_status = NA_character_,
    convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_, boundary_hit = NA,
    tau_hat = NA_real_, decision = NA_character_)
  fit <- tryCatch(drmTMB::drmTMB(
    drmTMB::bf(count ~ x, sigma ~ (1 | pair)), family = drmTMB::nbinom2(), data = data,
    control = list(eval.max = 1000, iter.max = 1000)
  ), error = identity)
  if (inherits(fit, "error")) { out$fit_status <- "fit_error"; out$decision <- "BLOCKED_IID_FIT_CONTROL"; return(out) }
  grad <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  out$fit_status <- "fit_ok"; out$convergence <- fit$opt$convergence; out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$max_gradient <- if (all(is.finite(grad))) max(abs(grad)) else NA_real_
  out$tau_hat <- unname(fit$sdpars$sigma[["(1 | pair)"]])
  out$boundary_hit <- !is.finite(out$tau_hat) || out$tau_hat <= .05 || out$tau_hat >= 3
  out$decision <- if (out$convergence == 0L && out$pdHess && !out$boundary_hit && abs(out$tau_hat / tau - 1) <= .40) "PASS_IID_FIT_CONTROL" else "BLOCKED_IID_FIT_CONTROL"
  out
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
repo_root <- normalizePath(file.path(dirname(script), "..")); setwd(repo_root)
pkgload::load_all(repo_root, quiet = TRUE, export_all = FALSE)
artifact_dir <- file.path(repo_root, "docs", "dev-log", "implementation-recovery", "2026-07-29-lane-c-nb2-sigma-phylo-interaction-local-repaired-run-1")
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
head <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
source_sha <- paste0(head, if (length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L) "-dirty" else "")
runner_sha <- unname(tools::md5sum(script)); seeds <- 2026072901:2026072904
if ("--iid-control-only" %in% commandArgs(TRUE)) {
  write_tsv(run_iid_dgp_control(source_sha), file.path(artifact_dir, "iid-dgp-control.tsv"))
  write_tsv(run_iid_fitted_control(source_sha, runner_sha), file.path(artifact_dir, "iid-fit-control.tsv"))
  quit(status = 0L)
}
attempts <- vector("list", length(seeds)); path <- file.path(artifact_dir, "raw-attempts.tsv")
for (i in seq_along(seeds)) { attempts[[i]] <- run_one(source_sha, runner_sha, i, seeds[[i]]); write_tsv(do.call(rbind, attempts[seq_len(i)]), path) }
attempts <- do.call(rbind, attempts); write_tsv(attempts, path); write_tsv(summarise_attempts(attempts), file.path(artifact_dir, "summary.tsv"))
message("Wrote retained local receipt: ", artifact_dir)
