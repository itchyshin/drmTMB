#!/usr/bin/env Rscript

# C12 retained local receipt. It runs the newly admitted IID ZINB sigma
# control first. The C11 structured route is attempted only after all four
# control attempts satisfy the frozen control gate.

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}

clean_text <- function(x) {
  trimws(gsub(" +", " ", gsub("[\r\n\t]+", " ", paste(as.character(x), collapse = "; "))))
}

new_data <- function(seed, structured, n_plant = 8L, n_pollinator = 8L,
                     n_each = 18L, tau = .60, sigma_intercept = -.20,
                     zi_probability = .20) {
  set.seed(seed)
  plant_tree <- ape::stree(n_plant, type = "balanced")
  pollinator_tree <- ape::stree(n_pollinator, type = "balanced")
  plant_tree$edge.length <- rep(1, nrow(plant_tree$edge))
  pollinator_tree$edge.length <- rep(1, nrow(pollinator_tree$edge))
  plant_tree$tip.label <- paste0("plant_", seq_len(n_plant))
  pollinator_tree$tip.label <- paste0("poll_", seq_len(n_pollinator))
  grid <- expand.grid(plant = plant_tree$tip.label, pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  pair_cov <- if (structured) {
    kronecker(
      drmTMB:::drm_phylo_tip_covariance(pollinator_tree),
      drmTMB:::drm_phylo_tip_covariance(plant_tree)
    )
  } else {
    diag(nrow(grid))
  }
  pair_effect <- as.numeric(t(chol(pair_cov)) %*% stats::rnorm(nrow(grid), sd = tau))
  names(pair_effect) <- paste(grid$plant, grid$pollinator, sep = ":")
  ids <- rep(seq_len(nrow(grid)), each = n_each)
  data <- grid[ids, , drop = FALSE]
  data$pair <- factor(paste(data$plant, data$pollinator, sep = ":"))
  data$x <- stats::rnorm(nrow(data))
  data$x <- data$x - ave(data$x, data$pair, FUN = mean)
  data$x <- data$x / stats::sd(data$x)
  log_sigma <- sigma_intercept + pair_effect[as.character(data$pair)]
  structural_zero <- stats::runif(nrow(data)) < zi_probability
  nb_count <- stats::rnbinom(nrow(data), mu = exp(1.40 + .30 * data$x), size = exp(-2 * log_sigma))
  data$count <- ifelse(structural_zero, 0L, nb_count)
  support <- aggregate(
    cbind(structural_zero = as.integer(structural_zero), positive = as.integer(data$count > 0L)) ~ pair,
    data = data, FUN = sum
  )
  list(
    data = data, plant_tree = plant_tree, pollinator_tree = pollinator_tree,
    pair_effect = pair_effect, support = support,
    dgp_digest = digest::digest(list(structured, pair_cov, data$x, log_sigma, structural_zero, nb_count))
  )
}

accepted_data <- function(seed, structured) {
  for (draw in seq_len(10000L)) {
    sim <- new_data(seed + (draw - 1L) * 100000L, structured)
    if (all(sim$support$structural_zero >= 1L) && all(sim$support$positive >= 6L)) {
      sim$accepted_draw <- draw
      return(sim)
    }
  }
  stop("No DGP draw met the predeclared per-pair support rule.", call. = FALSE)
}

fit_one <- function(sim, structured) {
  formula <- if (structured) {
    drmTMB::bf(count ~ x, sigma ~ phylo_interaction(
      1 | plant:pollinator, tree1 = sim$plant_tree, tree2 = sim$pollinator_tree
    ), zi ~ 1)
  } else {
    drmTMB::bf(count ~ x, sigma ~ 1 + (1 | pair), zi ~ 1)
  }
  drmTMB::drmTMB(formula, family = drmTMB::nbinom2(), data = sim$data,
    control = list(eval.max = 1000, iter.max = 1000))
}

run_one <- function(source_sha, runner_sha, attempt_id, seed, structured) {
  route <- if (structured) "c11_structured_retry" else "c12_iid_control"
  out <- data.frame(
    fixture_id = "lane_c_c12_zinb_sigma_control_local", route, source_sha, runner_sha,
    attempt_id, seed, n_plant = 8L, n_pollinator = 8L, n_each = 18L, n_obs = 1152L,
    accepted_dgp_draw = NA_integer_, dgp_digest = NA_character_, structural_zero_min = NA_integer_, positive_min = NA_integer_,
    beta0_truth = 1.40, beta1_truth = .30, sigma_intercept_truth = -.20, tau_truth = .60, zi_probability_truth = .20,
    fit_status = NA_character_, error_stage = NA_character_, warning = NA_character_, convergence = NA_integer_, pdHess = NA,
    max_gradient = NA_real_, boundary_hit = NA, beta0_hat = NA_real_, beta1_hat = NA_real_, sigma_intercept_hat = NA_real_,
    tau_hat = NA_real_, zi_logit_hat = NA_real_, mode_correlation = NA_real_, elapsed_sec = NA_real_
  )
  warnings <- character()
  sim <- tryCatch(accepted_data(seed, structured), error = identity)
  if (inherits(sim, "error")) {
    out$fit_status <- "fit_error"; out$error_stage <- "dgp"; out$warning <- clean_text(conditionMessage(sim)); return(out)
  }
  out$accepted_dgp_draw <- sim$accepted_draw; out$dgp_digest <- sim$dgp_digest
  out$structural_zero_min <- min(sim$support$structural_zero); out$positive_min <- min(sim$support$positive)
  elapsed <- system.time(fit <- tryCatch(withCallingHandlers(fit_one(sim, structured),
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }), error = identity))
  out$elapsed_sec <- unname(elapsed[["elapsed"]])
  if (inherits(fit, "error")) {
    out$fit_status <- "fit_error"; out$error_stage <- "fit"; out$warning <- clean_text(c(warnings, conditionMessage(fit))); return(out)
  }
  gradient <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  out$fit_status <- "fit_ok"; out$error_stage <- "none"; out$warning <- clean_text(warnings)
  out$convergence <- fit$opt$convergence; out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$max_gradient <- if (all(is.finite(gradient))) max(abs(gradient)) else NA_real_
  out$beta0_hat <- fit$coefficients$mu[["(Intercept)"]]; out$beta1_hat <- fit$coefficients$mu[["x"]]
  out$sigma_intercept_hat <- fit$coefficients$sigma[["(Intercept)"]]
  out$zi_logit_hat <- fit$coefficients$zi[["(Intercept)"]]
  term <- if (structured) "phylo_interaction(1 | plant:pollinator)" else "(1 | pair)"
  out$tau_hat <- fit$sdpars$sigma[[term]]
  re_name <- if (structured) "phylo_interaction_sigma" else "sigma"
  fitted <- ranef(fit, re_name)$terms[[term]]
  out$mode_correlation <- suppressWarnings(stats::cor(
    unname(fitted[names(sim$pair_effect)]), unname(sim$pair_effect)
  ))
  finite <- all(is.finite(unlist(out[c("beta0_hat", "beta1_hat", "sigma_intercept_hat", "tau_hat", "zi_logit_hat")])))
  out$boundary_hit <- !finite || out$tau_hat <= .05 || out$tau_hat >= 3 ||
    plogis(out$zi_logit_hat) <= .02 || plogis(out$zi_logit_hat) >= .98
  out
}

summarise_attempts <- function(x) {
  nm <- c("beta0_hat", "beta1_hat", "sigma_intercept_hat", "tau_hat", "zi_logit_hat")
  valid <- x$fit_status == "fit_ok" & x$convergence == 0L & x$pdHess & x$max_gradient <= .01 &
    !x$boundary_hit & stats::complete.cases(x[, nm]) & x$mode_correlation > .45
  means <- if (any(valid)) colMeans(x[valid, nm, drop = FALSE]) else stats::setNames(rep(NA_real_, length(nm)), nm)
  pass <- length(valid) == 4L && all(valid) &&
    max(abs(means[c("beta0_hat", "beta1_hat")] - c(1.40, .30))) <= .20 &&
    abs(means[["sigma_intercept_hat"]] + .20) <= .20 &&
    abs(means[["tau_hat"]] / .60 - 1) <= .40 &&
    abs(means[["zi_logit_hat"]] - qlogis(.20)) <= .25
  data.frame(
    fixture_id = unique(x$fixture_id), route = unique(x$route), planned_attempts = 4L,
    attempted_attempts = nrow(x), fit_ok = sum(x$fit_status == "fit_ok"),
    nonconverged = sum(x$fit_status == "fit_ok" & x$convergence != 0L),
    pdhess_false = sum(x$fit_status == "fit_ok" & !x$pdHess),
    boundary_hits = sum(x$fit_status == "fit_ok" & x$boundary_hit),
    mean_beta0_hat = means[["beta0_hat"]], mean_beta1_hat = means[["beta1_hat"]],
    mean_sigma_intercept_hat = means[["sigma_intercept_hat"]], mean_tau_hat = means[["tau_hat"]],
    mean_zi_logit_hat = means[["zi_logit_hat"]], decision = if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
repo_root <- normalizePath(file.path(dirname(script), "..")); setwd(repo_root)
pkgload::load_all(repo_root, quiet = TRUE, export_all = FALSE)
run_id <- sub("^--run-id=", "", grep("^--run-id=", commandArgs(TRUE), value = TRUE)[1L])
if (is.na(run_id) || !nzchar(run_id)) run_id <- "run-1"
artifact_dir <- file.path(repo_root, "docs", "dev-log", "implementation-recovery", paste0("2026-07-30-lane-c-c12-zinb-sigma-control-local-", run_id))
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
head <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
source_sha <- paste0(head, if (system2("git", c("diff", "--quiet")) != 0L) "-dirty" else "")
runner_sha <- unname(tools::md5sum(script)); seeds <- 2026075301:2026075304

run_route <- function(structured) {
  route <- if (structured) "c11_structured_retry" else "c12_iid_control"
  rows <- vector("list", length(seeds)); path <- file.path(artifact_dir, paste0(route, "-raw-attempts.tsv"))
  for (i in seq_along(seeds)) {
    rows[[i]] <- run_one(source_sha, runner_sha, i, seeds[[i]], structured)
    write_tsv(do.call(rbind, rows[seq_len(i)]), path)
  }
  rows <- do.call(rbind, rows); write_tsv(rows, path)
  summary <- summarise_attempts(rows)
  write_tsv(summary, file.path(artifact_dir, paste0(route, "-summary.tsv")))
  summary
}

iid_summary <- run_route(FALSE)
if (identical(iid_summary$decision, "PASS_POINT_RECOVERY_LOCAL")) {
  run_route(TRUE)
} else {
  write_tsv(data.frame(route = "c11_structured_retry", decision = "NOT_RUN_IID_CONTROL_BLOCKED"),
    file.path(artifact_dir, "c11_structured_retry-summary.tsv"))
}
message("Wrote retained local receipt: ", artifact_dir)
