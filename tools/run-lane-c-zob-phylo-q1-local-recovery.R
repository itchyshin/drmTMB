#!/usr/bin/env Rscript

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

digest_object <- function(x) {
  path <- tempfile("c16-dgp-", fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 2L)
  unname(tools::md5sum(path))
}

new_data <- function(seed, n_tip = 32L, n_each = 30L, tau = .55) {
  set.seed(seed)
  tree <- ape::stree(n_tip, type = "balanced")
  tree$edge.length <- rep(1, nrow(tree$edge))
  tree$tip.label <- paste0("sp", seq_len(n_tip))
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  field <- as.numeric(t(chol(covariance)) %*% stats::rnorm(n_tip, sd = tau))
  names(field) <- tree$tip.label
  data <- data.frame(species = rep(tree$tip.label, each = n_each), x = stats::rnorm(n_tip * n_each))
  mu <- stats::plogis(-.10 + .35 * data$x + field[data$species])
  boundary <- stats::rbinom(nrow(data), 1L, .12)
  data$y <- ifelse(boundary == 1L, stats::rbinom(nrow(data), 1L, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, tree = tree, field = field, digest = digest_object(list(tree = tree, data = data, field = field, tau = tau)))
}
out_dir <- Sys.getenv("DRMTMB_RECOVERY_OUT", unset = "docs/dev-log/implementation-recovery/2026-07-29-lane-c-zob-phylo-q1-local")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
source_sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_md5 <- unname(tools::md5sum(script))
out <- lapply(2026072901:2026072904, function(seed) {
  sim <- new_data(seed); tree <- sim$tree
  started <- proc.time()[[3L]]
  fit <- tryCatch(drmTMB::drmTMB(
    drmTMB::bf(y ~ x + phylo(1 | species, tree = tree)),
    family = drmTMB::zero_one_beta(), data = sim$data
  ), error = identity)
  if (inherits(fit, "error")) return(data.frame(cell_id = "mc-0583", dpar = "mu", seed, source_sha, runner_md5, dgp_digest = sim$digest, formula = "y ~ x + phylo(1 | species, tree = tree)", status = "fit_error", convergence = NA, pdHess = NA, max_gradient = NA_real_, tau_hat = NA, mode_correlation = NA_real_, log_sigma_min = NA_real_, log_sigma_max = NA_real_, boundary_hit = NA, beta0_hat = NA, beta1_hat = NA, elapsed_sec = proc.time()[[3L]] - started, message = conditionMessage(fit)))
  mode <- ranef(fit, "phylo_mu")$terms[["phylo(1 | species)"]]
  log_sigma <- fit$obj$report()$log_sigma
  tau_hat <- fit$sdpars$mu[["phylo(1 | species)"]]
  data.frame(cell_id = "mc-0583", dpar = "mu", seed, source_sha, runner_md5, dgp_digest = sim$digest, formula = "y ~ x + phylo(1 | species, tree = tree)", status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), max_gradient = max(abs(fit$obj$gr(fit$opt$par))), tau_hat, mode_correlation = cor(mode[names(sim$field)], sim$field), log_sigma_min = min(log_sigma), log_sigma_max = max(log_sigma), boundary_hit = !is.finite(tau_hat) || tau_hat <= .05 || tau_hat >= 2.5, beta0_hat = fit$coefficients$mu[["(Intercept)"]], beta1_hat = fit$coefficients$mu[["x"]], elapsed_sec = proc.time()[[3L]] - started, message = "")
})
out <- do.call(rbind, out)
utils::write.table(out, file.path(out_dir, "raw-attempts.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
ok <- out$status == "fit_ok" & out$convergence == 0 & out$pdHess & out$max_gradient <= .01 & !out$boundary_hit & out$mode_correlation > .45 & is.finite(out$tau_hat) & out$tau_hat > .1 & out$tau_hat < 1.5
summary <- data.frame(attempted = nrow(out), passed = sum(ok), mean_tau_hat = mean(out$tau_hat[ok]), decision = if (all(ok) && abs(mean(out$tau_hat[ok])/.55-1) <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE")
utils::write.table(summary, file.path(out_dir, "summary.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
