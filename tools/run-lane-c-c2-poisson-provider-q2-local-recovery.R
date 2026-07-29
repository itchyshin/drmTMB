#!/usr/bin/env Rscript

# C2 retained local point-recovery fixture.  It deliberately fits one provider
# per invocation and records all attempts; it is not a profile, interval,
# bootstrap, coverage, or remote-compute workflow.

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}

clean_text <- function(x) {
  trimws(gsub(" +", " ", gsub("[\r\n\t]+", " ", paste(x, collapse = "; "))))
}

provider_arg <- grep("^--provider=", commandArgs(TRUE), value = TRUE)
if (length(provider_arg) != 1L) {
  stop("Supply exactly one --provider=spatial|relmat|animal", call. = FALSE)
}
provider <- sub("^--provider=", "", provider_arg)
if (!provider %in% c("spatial", "relmat", "animal")) {
  stop("Provider must be spatial, relmat, or animal.", call. = FALSE)
}

spatial_precision_from_coords <- function(coords, jitter = 1e-6) {
  distances <- as.matrix(stats::dist(as.matrix(coords[, seq_len(2L), drop = FALSE])))
  positive <- distances[distances > 0]
  range <- stats::median(positive)
  covariance <- exp(-distances / range)
  diag(covariance) <- diag(covariance) + jitter
  precision <- chol2inv(chol(covariance))
  dimnames(precision) <- dimnames(coords)
  precision
}

new_fixture_data <- function(seed, provider, n_level = 64L, n_each = 8L) {
  set.seed(seed)
  levels <- paste0("site_", seq_len(n_level))
  theta <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_level) / (4 * n_level),
    y = sin(theta),
    row.names = levels
  )
  if (identical(provider, "spatial")) {
    precision <- spatial_precision_from_coords(coords)
  } else {
    covariance <- outer(seq_len(n_level), seq_len(n_level), function(i, j) {
      0.35^abs(i - j)
    })
    diag(covariance) <- diag(covariance) + 0.15
    dimnames(covariance) <- list(levels, levels)
    precision <- solve(covariance)
  }
  covariance <- solve(precision)
  tau <- c(intercept = 0.60, slope = 0.50)
  rho <- 0.50
  covariance_effect <- diag(tau) %*%
    matrix(c(1, rho, rho, 1), nrow = 2L) %*% diag(tau)
  field <- t(chol(covariance + diag(1e-10, n_level))) %*%
    matrix(stats::rnorm(2L * n_level), nrow = n_level) %*%
    chol(covariance_effect)
  rownames(field) <- levels
  site <- rep(levels, each = n_each)
  x <- stats::rnorm(length(site))
  x <- x - ave(x, site, FUN = mean)
  x <- x / stats::sd(x)
  eta <- 1.00 + 0.35 * x + field[site, 1L] + x * field[site, 2L]
  list(
    data = data.frame(
      count = stats::rpois(length(site), lambda = exp(eta)),
      x = x,
      site = factor(site, levels = levels)
    ),
    coords = coords,
    precision = precision,
    tau = tau,
    rho = rho,
    dgp_digest = digest::digest(list(provider, coords, precision, x, field, eta))
  )
}

provider_formula <- function(provider) {
  switch(provider,
    spatial = "count ~ x + spatial(1 + x | p | site, coords = coords)",
    relmat = "count ~ x + relmat(1 + x | p | site, Q = Q)",
    animal = "count ~ x + animal(1 + x | p | site, Ainv = Ainv)"
  )
}

fit_fixture <- function(sim, provider) {
  coords <- sim$coords
  Q <- sim$precision
  Ainv <- sim$precision
  if (identical(provider, "spatial")) {
    return(drmTMB::drmTMB(
      drmTMB::bf(count ~ x + spatial(1 + x | p | site, coords = coords)),
      family = stats::poisson(link = "log"), data = sim$data,
      control = list(eval.max = 800, iter.max = 800)
    ))
  }
  if (identical(provider, "relmat")) {
    return(drmTMB::drmTMB(
      drmTMB::bf(count ~ x + relmat(1 + x | p | site, Q = Q)),
      family = stats::poisson(link = "log"), data = sim$data,
      control = list(eval.max = 800, iter.max = 800)
    ))
  }
  drmTMB::drmTMB(
    drmTMB::bf(count ~ x + animal(1 + x | p | site, Ainv = Ainv)),
    family = stats::poisson(link = "log"), data = sim$data,
    control = list(eval.max = 800, iter.max = 800)
  )
}

result_template <- function(source_sha, runner_sha, attempt_id, seed) {
  data.frame(
    fixture_id = paste0("lane_c_c2_", provider, "_poisson_q2_local"),
    source_sha, runner_sha, attempt_id, seed,
    r_version = R.version.string,
    drmTMB_version = as.character(utils::packageVersion("drmTMB")),
    tmb_version = as.character(utils::packageVersion("TMB")),
    provider, n_level = 64L, n_each = 8L, n_obs = 512L,
    formula = provider_formula(provider),
    beta0_truth = 1.00, beta1_truth = 0.35,
    tau0_truth = 0.60, tau1_truth = 0.50, rho_truth = 0.50,
    dgp_digest = NA_character_, fit_status = NA_character_,
    error_stage = NA_character_, warning = NA_character_,
    convergence = NA_integer_, pdHess = NA, objective = NA_real_,
    max_gradient = NA_real_, boundary_hit = NA,
    beta0_hat = NA_real_, beta1_hat = NA_real_, tau0_hat = NA_real_,
    tau1_hat = NA_real_, rho_hat = NA_real_, elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

run_one <- function(source_sha, runner_sha, attempt_id, seed) {
  out <- result_template(source_sha, runner_sha, attempt_id, seed)
  warnings <- character()
  sim <- tryCatch(new_fixture_data(seed, provider), error = identity)
  if (inherits(sim, "error")) {
    out$fit_status <- "fit_error"
    out$error_stage <- "dgp"
    out$warning <- clean_text(conditionMessage(sim))
    return(out)
  }
  out$dgp_digest <- sim$dgp_digest
  elapsed <- system.time(fit <- tryCatch(withCallingHandlers(
    fit_fixture(sim, provider),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  ), error = identity))
  out$elapsed_sec <- unname(elapsed[["elapsed"]])
  if (inherits(fit, "error")) {
    out$fit_status <- "fit_error"
    out$error_stage <- "fit"
    out$warning <- clean_text(c(warnings, conditionMessage(fit)))
    return(out)
  }
  gradient <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  rho_name <- "cor(mu:(Intercept),mu:x | p | site)"
  out$fit_status <- "fit_ok"
  out$error_stage <- "none"
  out$warning <- clean_text(warnings)
  out$convergence <- fit$opt$convergence
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$objective <- unname(fit$opt$objective)
  out$max_gradient <- if (all(is.finite(gradient))) max(abs(gradient)) else NA_real_
  out$beta0_hat <- unname(fit$coefficients$mu[["(Intercept)"]])
  out$beta1_hat <- unname(fit$coefficients$mu[["x"]])
  out$tau0_hat <- unname(fit$sdpars$mu[[paste0(provider, "(1 | p | site)")]])
  out$tau1_hat <- unname(fit$sdpars$mu[[paste0(provider, "(0 + x | p | site)")]])
  out$rho_hat <- unname(fit$corpars[[provider]][[rho_name]])
  finite <- all(is.finite(unlist(out[c(
    "beta0_hat", "beta1_hat", "tau0_hat", "tau1_hat", "rho_hat"
  )])))
  out$boundary_hit <- !finite || abs(out$rho_hat) >= 0.95 ||
    any(unlist(out[c("tau0_hat", "tau1_hat")]) <= 0.05)
  out
}

summarise_attempts <- function(x) {
  estimates <- c("beta0_hat", "beta1_hat", "tau0_hat", "tau1_hat", "rho_hat")
  valid <- x$fit_status == "fit_ok" & x$convergence == 0L & x$pdHess &
    !x$boundary_hit & stats::complete.cases(x[, estimates])
  means <- if (any(valid)) {
    colMeans(x[valid, estimates, drop = FALSE])
  } else {
    stats::setNames(rep(NA_real_, length(estimates)), estimates)
  }
  pass <- length(valid) == 3L && all(valid) &&
    abs(means[["beta0_hat"]] - 1.00) <= 0.20 &&
    abs(means[["beta1_hat"]] - 0.35) <= 0.20 &&
    abs(means[["tau0_hat"]] / 0.60 - 1) <= 0.40 &&
    abs(means[["tau1_hat"]] / 0.50 - 1) <= 0.40 &&
    abs(means[["rho_hat"]] - 0.50) <= 0.25
  data.frame(
    fixture_id = paste0("lane_c_c2_", provider, "_poisson_q2_local"),
    planned_attempts = 3L, attempted_attempts = nrow(x),
    fit_ok = sum(x$fit_status == "fit_ok"),
    fit_error = sum(x$fit_status == "fit_error"),
    nonconverged = sum(x$fit_status == "fit_ok" & x$convergence != 0L),
    pdhess_false = sum(x$fit_status == "fit_ok" & !x$pdHess),
    boundary_hits = sum(x$fit_status == "fit_ok" & x$boundary_hit),
    mean_beta0_hat = means[["beta0_hat"]], mean_beta1_hat = means[["beta1_hat"]],
    mean_tau0_hat = means[["tau0_hat"]], mean_tau1_hat = means[["tau1_hat"]],
    mean_rho_hat = means[["rho_hat"]],
    decision = if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"
  )
}

run_iid_control <- function(source_sha, seed = 2026072999L, n_draw = 8192L) {
  set.seed(seed)
  tau <- c(intercept = 0.60, slope = 0.50)
  rho <- 0.50
  sigma <- diag(tau) %*% matrix(c(1, rho, rho, 1), 2L) %*% diag(tau)
  field <- matrix(stats::rnorm(2L * n_draw), nrow = n_draw) %*% chol(sigma)
  empirical <- stats::cov(field)
  empirical_tau <- sqrt(diag(empirical))
  empirical_rho <- empirical[[1L, 2L]] / prod(empirical_tau)
  pass <- all(abs(empirical_tau / tau - 1) <= .04) &&
    abs(empirical_rho - rho) <= .04
  data.frame(
    control_id = paste0("lane_c_c2_", provider, "_poisson_q2_iid_dgp"),
    source_sha, seed, n_draw, precision = "identity",
    tau0_truth = tau[[1L]], tau1_truth = tau[[2L]], rho_truth = rho,
    tau0_empirical = empirical_tau[[1L]], tau1_empirical = empirical_tau[[2L]],
    rho_empirical = empirical_rho,
    decision = if (pass) "PASS_IID_DGP_CONTROL" else "BLOCKED_IID_DGP_CONTROL"
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]])
repo_root <- normalizePath(file.path(dirname(script), ".."))
setwd(repo_root)
pkgload::load_all(repo_root, quiet = TRUE, export_all = FALSE)
artifact_dir <- file.path(
  repo_root, "docs", "dev-log", "implementation-recovery",
  paste0("2026-07-29-lane-c-c2-", provider, "-poisson-q2-local")
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
head <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
dirty <- length(system2(
  "git", c("status", "--porcelain", "--untracked-files=no"), stdout = TRUE
)) > 0L
source_sha <- paste0(head, if (dirty) "-dirty" else "")
runner_sha <- unname(tools::md5sum(script))
if ("--iid-control-only" %in% commandArgs(TRUE)) {
  write_tsv(run_iid_control(source_sha), file.path(artifact_dir, "iid-dgp-control.tsv"))
  quit(status = 0L)
}
seeds <- 2026072901:2026072903
attempts <- vector("list", length(seeds))
attempt_path <- file.path(artifact_dir, "raw-attempts.tsv")
for (i in seq_along(seeds)) {
  attempts[[i]] <- run_one(source_sha, runner_sha, i, seeds[[i]])
  write_tsv(do.call(rbind, attempts[seq_len(i)]), attempt_path)
}
attempts <- do.call(rbind, attempts)
write_tsv(attempts, attempt_path)
write_tsv(summarise_attempts(attempts), file.path(artifact_dir, "summary.tsv"))
message("Wrote retained local receipt: ", artifact_dir)
