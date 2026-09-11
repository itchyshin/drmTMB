#!/usr/bin/env Rscript

# Independent dense marginal profile for the current-source C1 seed that still
# has unavailable full-Hessian Wald covariance (seed 2026091101).

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) stop("This diagnostic takes no arguments.", call. = FALSE)
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("Run from the drmTMB root.", call. = FALSE)
out_dir <- file.path(root, "docs/dev-log/simulation-artifacts/2026-09-09-temporal-ar1-c1-current-boundary")
required <- file.path(out_dir, c("profile-attempts.csv", "profile-summary.csv", "free-attempts.csv", "provenance.csv", "results.rds", "session-info.txt", "RESULTS.md"))
if (any(file.exists(required))) stop("Current-source C1 boundary evidence already exists; do not overwrite it.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

seed <- 2026091101L
set.seed(seed)
n_id <- 80L; n_time <- 6L; phi_truth <- 0.4
time <- seq.int(0L, length.out = n_time)
id <- rep(seq_len(n_id), each = n_time)
occasion <- rep(time, n_id)
between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = n_time)
within <- unlist(lapply(seq_len(n_id), function(i) sample(rep(c(-0.5, 0.5), length.out = n_time))), use.names = FALSE)
R <- phi_truth ^ abs(outer(time, time, "-"))
temporal <- unlist(lapply(seq_len(n_id), function(i) as.vector(t(chol(R)) %*% rnorm(n_time, sd = 0.8))), use.names = FALSE)
stable <- rep(rnorm(n_id, sd = 0.6), each = n_time)
y <- 0.5 * between + 0.5 * within + stable + temporal + rnorm(n_id * n_time, sd = 0.4)
X <- model.matrix(~ between + within)
groups <- split(seq_along(y), id)

profile_nll <- function(log_sd_ordinary, log_sd_temporal, theta, sigma) {
  sd_ordinary <- exp(log_sd_ordinary); sd_temporal <- exp(log_sd_temporal); phi <- tanh(theta)
  xt_vinv_x <- matrix(0, ncol(X), ncol(X)); xt_vinv_y <- numeric(ncol(X)); blocks <- vector("list", length(groups))
  for (g in seq_along(groups)) {
    idx <- groups[[g]]; Ri <- phi ^ abs(outer(occasion[idx], occasion[idx], "-")); V <- sd_ordinary^2 + sd_temporal^2 * Ri + diag(sigma^2, length(idx))
    L <- tryCatch(chol(V), error = function(e) NULL); if (is.null(L)) return(Inf)
    Xi <- X[idx, , drop = FALSE]; yi <- y[idx]
    vinv_x <- backsolve(L, forwardsolve(t(L), Xi)); vinv_y <- backsolve(L, forwardsolve(t(L), yi))
    xt_vinv_x <- xt_vinv_x + crossprod(Xi, vinv_x); xt_vinv_y <- xt_vinv_y + crossprod(Xi, vinv_y); blocks[[g]] <- list(idx = idx, L = L)
  }
  beta <- tryCatch(solve(xt_vinv_x, xt_vinv_y), error = function(e) NULL); if (is.null(beta)) return(Inf)
  quadratic <- 0; logdet <- 0
  for (block in blocks) { z <- forwardsolve(t(block$L), y[block$idx] - X[block$idx, , drop = FALSE] %*% beta); quadratic <- quadratic + sum(z^2); logdet <- logdet + 2 * sum(log(diag(block$L))) }
  0.5 * (length(y) * log(2 * pi) + logdet + quadratic)
}

starts <- c(-0.8, -0.3, 0.3, 0.8)
run_fixed <- function(sigma, phi_start) {
  fit <- tryCatch(nlminb(c(log(0.6), log(0.8), atanh(phi_start)), function(p) profile_nll(p[[1]], p[[2]], p[[3]], sigma)), error = function(e) e)
  if (inherits(fit, "error")) return(data.frame(sigma_fixed = sigma, phi_start, convergence = NA_integer_, objective = NA_real_, sd_ordinary = NA_real_, sd_temporal = NA_real_, phi = NA_real_, error = conditionMessage(fit)))
  data.frame(sigma_fixed = sigma, phi_start, convergence = fit$convergence, objective = fit$objective, sd_ordinary = exp(fit$par[[1]]), sd_temporal = exp(fit$par[[2]]), phi = tanh(fit$par[[3]]), error = NA_character_)
}
run_free <- function(phi_start) {
  fit <- tryCatch(nlminb(c(log(0.6), log(0.8), log(0.4), atanh(phi_start)), function(p) profile_nll(p[[1]], p[[2]], p[[4]], exp(p[[3]]))), error = function(e) e)
  if (inherits(fit, "error")) return(data.frame(phi_start, convergence = NA_integer_, objective = NA_real_, sd_ordinary = NA_real_, sd_temporal = NA_real_, sigma = NA_real_, phi = NA_real_, error = conditionMessage(fit)))
  data.frame(phi_start, convergence = fit$convergence, objective = fit$objective, sd_ordinary = exp(fit$par[[1]]), sd_temporal = exp(fit$par[[2]]), sigma = exp(fit$par[[3]]), phi = tanh(fit$par[[4]]), error = NA_character_)
}

sigma_grid <- c(1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 0.05, 0.1, 0.2, 0.4)
attempts <- do.call(rbind, lapply(sigma_grid, function(sigma) do.call(rbind, lapply(starts, function(phi_start) run_fixed(sigma, phi_start)))))
selected <- do.call(rbind, lapply(split(attempts, attempts$sigma_fixed), function(x) { good <- x[is.finite(x$objective) & x$convergence == 0L, , drop = FALSE]; if (!nrow(good)) return(x[0, , drop = FALSE]); good[which.min(good$objective), , drop = FALSE] }))
selected <- selected[order(selected$sigma_fixed), , drop = FALSE]; selected$delta_nll <- selected$objective - min(selected$objective)
free <- do.call(rbind, lapply(starts, run_free))
write.csv(attempts, file.path(out_dir, "profile-attempts.csv"), row.names = FALSE); write.csv(selected, file.path(out_dir, "profile-summary.csv"), row.names = FALSE); write.csv(free, file.path(out_dir, "free-attempts.csv"), row.names = FALSE)
provenance <- data.frame(key = c("source_commit", "runner_md5", "seed", "n_profile_attempts", "n_free_attempts", "run_utc"), value = c(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), unname(tools::md5sum(file.path(root, "tools/diagnose-temporal-ar1-c1-current-boundary.R"))), seed, nrow(attempts), nrow(free), format(Sys.time(), tz = "UTC", usetz = TRUE)), stringsAsFactors = FALSE)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE); saveRDS(list(profile_attempts = attempts, profile_summary = selected, free_attempts = free, provenance = provenance), file.path(out_dir, "results.rds")); capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))
writeLines(c("# Current-source C1 dense marginal profile", "", "This profile independently marginalizes the ordinary intercept and AR1 field through `s_b^2 11^T + s_a^2 R(phi) + sigma^2 I`, profiles the three mean coefficients by GLS, and optimizes the remaining variance and persistence coordinates. It is a fixed-seed diagnostic, not a coverage campaign.", "", "The grid and four signed persistence starts match the earlier C1 dense diagnostic. It determines whether the current-source unavailable covariance case has likelihood geometry that reaches the residual-variance boundary."), file.path(out_dir, "RESULTS.md"))
if (nrow(attempts) != length(sigma_grid) * length(starts) || nrow(selected) != length(sigma_grid) || any(!is.finite(selected$objective))) stop("Current-source C1 dense profile did not retain a finite selected fit at every grid point.", call. = FALSE)
cat("TEMPORAL_AR1_C1_CURRENT_BOUNDARY_PASS\n")
