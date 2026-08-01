#!/usr/bin/env Rscript

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
clean <- function(x) trimws(gsub("[\r\n\t]+", " ", paste(x, collapse = "; ")))

new_data <- function(seed, n_group = 32L, n_each = 30L) {
  set.seed(seed); labels <- paste0("sp", seq_len(n_group))
  Q <- diag(2, n_group); Q[cbind(seq_len(n_group - 1L), 2:n_group)] <- -.5; Q[cbind(2:n_group, seq_len(n_group - 1L))] <- -.5
  rownames(Q) <- colnames(Q) <- rev(labels); K <- solve(Q)
  u <- as.numeric(t(chol(K)) %*% rnorm(n_group, sd = .55)); names(u) <- rownames(K)
  data <- data.frame(species = rep(labels, each = n_each), x = rnorm(n_group * n_each))
  data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / sd(data$x)
  mu <- plogis(-.10 + .35 * data$x + u[data$species]); boundary <- rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, rbinom(nrow(data), 1, .45), rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, K = K, u = u,
    digest = digest::digest(list(K = K, x = data$x, y = data$y)))
}

run_one <- function(seed, source_sha, runner_sha) {
  out <- data.frame(cell_id = "mc-0585", dpar = "mu", seed, source_sha, runner_sha, formula = "y ~ x + relmat(1 | species, K = K)", tau_truth = .55, beta0_truth = -.10, beta1_truth = .35, sigma_truth = .45, zoi_truth = .12, coi_truth = .45, dgp_digest = NA_character_, status = NA_character_, warning = NA_character_, convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_, mode_correlation = NA_real_, log_sigma_min = NA_real_, log_sigma_max = NA_real_, clamp_active = NA, boundary_hit = NA, beta0_hat = NA_real_, beta1_hat = NA_real_, sigma_hat = NA_real_, zoi_hat = NA_real_, coi_hat = NA_real_, tau_hat = NA_real_)
  sim <- new_data(seed); out$dgp_digest <- sim$digest; warnings <- character(); K <- sim$K
  fit <- tryCatch(withCallingHandlers(drmTMB::drmTMB(drmTMB::bf(y ~ x + relmat(1 | species, K = K)), family = drmTMB::zero_one_beta(), data = sim$data, control = list(eval.max = 1000, iter.max = 1000)), warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }), error = identity)
  if (inherits(fit, "error")) { out$status <- "fit_error"; out$warning <- clean(c(warnings, conditionMessage(fit))); return(out) }
  grad <- fit$obj$gr(fit$opt$par); report <- fit$obj$report()
  mode <- as.numeric(ranef(fit, "relmat_mu")$terms[["relmat(1 | species)"]])
  names(mode) <- fit$model$structured$phylo_mu$node_labels
  log_sigma <- as.numeric(report$log_sigma)
  out$status <- "fit_ok"; out$warning <- clean(warnings); out$convergence <- fit$opt$convergence; out$pdHess <- isTRUE(fit$sdr$pdHess); out$max_gradient <- max(abs(grad))
  out$mode_correlation <- suppressWarnings(stats::cor(mode[names(sim$u)], sim$u))
  out$log_sigma_min <- min(log_sigma); out$log_sigma_max <- max(log_sigma)
  out$clamp_active <- any(log_sigma <= -12 | log_sigma >= 12)
  out$beta0_hat <- fit$coefficients$mu[["(Intercept)"]]; out$beta1_hat <- fit$coefficients$mu[["x"]]; out$sigma_hat <- exp(fit$coefficients$sigma[["(Intercept)"]]); out$zoi_hat <- plogis(fit$coefficients$zoi[["(Intercept)"]]); out$coi_hat <- plogis(fit$coefficients$coi[["(Intercept)"]]); out$tau_hat <- fit$sdpars$mu[["relmat(1 | species)"]]
  estimate <- unlist(out[c("beta0_hat", "beta1_hat", "sigma_hat", "zoi_hat", "coi_hat", "tau_hat")])
  out$boundary_hit <- !all(is.finite(estimate)) || out$tau_hat <= .05 || out$tau_hat >= 2.5
  out
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]); root <- normalizePath(file.path(dirname(script), "..")); setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
dir <- Sys.getenv("DRMTMB_RECOVERY_OUT", unset = file.path(root, "docs/dev-log/implementation-recovery/2026-07-29-lane-c-zob-relmat-q1-local-run-3")); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)); runner_sha <- unname(tools::md5sum(script)); attempts <- do.call(rbind, lapply(2026073101:2026073104, run_one, source_sha = sha, runner_sha = runner_sha)); write_tsv(attempts, file.path(dir, "raw-attempts.tsv"))
valid <- with(attempts, status == "fit_ok" & convergence == 0L & pdHess &
  is.finite(max_gradient) & max_gradient <= .01 & mode_correlation > .45 &
  !clamp_active & !boundary_hit)
means <- if (any(valid)) colMeans(attempts[valid, c("beta0_hat", "beta1_hat", "sigma_hat", "zoi_hat", "coi_hat", "tau_hat")]) else rep(NA_real_, 6)
pass <- all(valid) && sum(valid) == 4L && abs(means[1] + .10) <= .20 && abs(means[2] - .35) <= .20 && abs(means[3] - .45) <= .12 && abs(means[4] - .12) <= .08 && abs(means[5] - .45) <= .15 && abs(means[6] / .55 - 1) <= .40
write_tsv(data.frame(planned_attempts = 4L, attempted_attempts = nrow(attempts), passed_attempts = sum(valid), decision = if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE", mean_tau_hat = means[6]), file.path(dir, "summary.tsv"))
set.seed(2026073199L); group <- factor(rep(paste0("g", 1:32), each = 30L)); x <- rnorm(length(group)); x <- x - ave(x, group, FUN = mean); x <- x / sd(x); u <- rnorm(32, sd = .55); names(u) <- levels(group); mu <- plogis(-.10 + .35 * x + u[as.character(group)]); boundary <- rbinom(length(group), 1, .12)
iid_data <- data.frame(y = ifelse(boundary == 1, rbinom(length(group), 1, .45), rbeta(length(group), mu / .45^2, (1 - mu) / .45^2)), x = x, group = group)
iid_fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x + (1 | group)), family = drmTMB::zero_one_beta(), data = iid_data, control = list(eval.max = 1000, iter.max = 1000)), error = identity)
if (inherits(iid_fit, "error")) iid <- data.frame(seed = 2026073199L, status = "fit_error", tau_truth = .55, tau_hat = NA_real_, convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_, boundary_hit = NA, decision = "BLOCKED_IID_FIT_CONTROL") else { tau <- iid_fit$sdpars$mu[["(1 | group)"]]; grad <- max(abs(iid_fit$obj$gr(iid_fit$opt$par))); iid_boundary <- !is.finite(tau) || tau <= .05 || tau >= 2.5; iid <- data.frame(seed = 2026073199L, status = "fit_ok", tau_truth = .55, tau_hat = tau, convergence = iid_fit$opt$convergence, pdHess = isTRUE(iid_fit$sdr$pdHess), max_gradient = grad, boundary_hit = iid_boundary, decision = if (iid_fit$opt$convergence == 0L && isTRUE(iid_fit$sdr$pdHess) && is.finite(grad) && grad <= .01 && !iid_boundary && abs(tau / .55 - 1) <= .40) "PASS_IID_FIT_CONTROL" else "BLOCKED_IID_FIT_CONTROL") }
write_tsv(iid, file.path(dir, "iid-fit-control.tsv"))
