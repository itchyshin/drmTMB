#!/usr/bin/env Rscript

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

new_data <- function(seed, n_tip = 32L, n_each = 30L) {
  set.seed(seed)
  tree <- ape::stree(n_tip, type = "balanced")
  tree$edge.length <- rep(1, nrow(tree$edge))
  tree$tip.label <- paste0("sp", seq_len(n_tip))
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  field <- as.numeric(t(chol(covariance)) %*% stats::rnorm(n_tip, sd = .55))
  names(field) <- tree$tip.label
  data <- data.frame(species = rep(tree$tip.label, each = n_each), x = stats::rnorm(n_tip * n_each))
  mu <- stats::plogis(-.10 + .35 * data$x + field[data$species])
  boundary <- stats::rbinom(nrow(data), 1L, .12)
  data$y <- ifelse(boundary == 1L, stats::rbinom(nrow(data), 1L, .45), stats::rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, tree = tree)
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
  if (inherits(fit, "error")) return(data.frame(cell_id = "mc-0583", dpar = "mu", seed, source_sha, runner_md5, status = "fit_error", convergence = NA, pdHess = NA, tau_hat = NA, beta0_hat = NA, beta1_hat = NA, elapsed_sec = proc.time()[[3L]] - started, message = conditionMessage(fit)))
  data.frame(cell_id = "mc-0583", dpar = "mu", seed, source_sha, runner_md5, status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), tau_hat = fit$sdpars$mu[["phylo(1 | species)"]], beta0_hat = fit$coefficients$mu[["(Intercept)"]], beta1_hat = fit$coefficients$mu[["x"]], elapsed_sec = proc.time()[[3L]] - started, message = "")
})
out <- do.call(rbind, out)
utils::write.table(out, file.path(out_dir, "raw-attempts.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
ok <- out$status == "fit_ok" & out$convergence == 0 & out$pdHess & is.finite(out$tau_hat) & out$tau_hat > .1 & out$tau_hat < 1.5
summary <- data.frame(attempted = nrow(out), passed = sum(ok), mean_tau_hat = mean(out$tau_hat[ok]), decision = if (all(ok) && abs(mean(out$tau_hat[ok])/.55-1) <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE")
utils::write.table(summary, file.path(out_dir, "summary.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
