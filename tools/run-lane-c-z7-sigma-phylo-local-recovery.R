#!/usr/bin/env Rscript

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)

simulate_one <- function(seed, tau = .45) {
  set.seed(seed); n_tip <- 32L; n_each <- 50L
  tree <- ape::stree(n_tip, type = "balanced"); tree$edge.length <- rep(1, nrow(tree$edge)); tree$tip.label <- paste0("sp", seq_len(n_tip))
  V <- drmTMB:::drm_phylo_tip_covariance(tree); b <- as.numeric(t(chol(V)) %*% rnorm(n_tip, sd = tau)); names(b) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each); x <- rnorm(length(species)); mu <- plogis(-.15 + .35 * x); sigma <- exp(-1 + b[species]); zoi <- plogis(-1.1); coi <- plogis(.1)
  boundary <- rbinom(length(x), 1L, zoi); y <- rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi)
  list(data = data.frame(y, x, species), tree = tree, b = b, n_zero = sum(y == 0), n_one = sum(y == 1), min_group_zero = min(tapply(y == 0, species, sum)), min_group_one = min(tapply(y == 1, species, sum)), min_group_interior = min(tapply(y > 0 & y < 1, species, sum)))
}

fit_one <- function(seed, sha, md5) {
  sim <- simulate_one(seed)
  tree <- sim$tree
  fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ drmTMB::phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1), family = drmTMB::zero_one_beta(), data = sim$data, control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))), error = identity)
  if (inherits(fit, "error")) return(data.frame(seed, source_sha = sha, runner_md5 = md5, status = "fit_error", error = conditionMessage(fit)))
  tau_hat <- unname(fit$sdpars$sigma[["phylo(1 | species)"]]); u_hat <- ranef(fit, "phylo_sigma")$terms[["phylo(1 | species)"]]
  data.frame(seed, source_sha = sha, runner_md5 = md5, status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), max_gradient = max(abs(fit$obj$gr(fit$opt$par)), na.rm = TRUE), tau_truth = .45, tau_hat, mode_correlation = cor(u_hat[names(sim$b)], sim$b), n_zero = sim$n_zero, n_one = sim$n_one, min_group_zero = sim$min_group_zero, min_group_one = sim$min_group_one, min_group_interior = sim$min_group_interior, clamp_active = any(abs(fit$obj$report()$log_sigma) > 11.99), boundary_hit = !is.finite(tau_hat) || tau_hat <= .05 || tau_hat >= 2.5)
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L]); root <- normalizePath(file.path(dirname(script), "..")); setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
out <- file.path(root, "docs/dev-log/implementation-recovery/2026-07-30-lane-c-z7-zob-sigma-phylo-local-run-3"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)); md5 <- unname(tools::md5sum(script)); attempts <- do.call(rbind, lapply(2026074001:2026074004, fit_one, sha = sha, md5 = md5)); write_tsv(attempts, file.path(out, "raw-attempts.tsv"))
ok <- if (all(c("convergence", "pdHess", "max_gradient", "boundary_hit", "mode_correlation", "min_group_zero", "min_group_one", "min_group_interior", "clamp_active") %in% names(attempts))) with(attempts, status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= .01 & !boundary_hit & !clamp_active & mode_correlation > .45 & min_group_zero > 0L & min_group_one > 0L & min_group_interior > 0L) else rep(FALSE, nrow(attempts)); err <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / .45 - 1)) else NA_real_; decision <- if (all(ok) && is.finite(err) && err <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"; write_tsv(data.frame(planned_attempts = 4L, attempted_attempts = nrow(attempts), passed_attempts = sum(ok), mean_tau_relative_error = err, decision), file.path(out, "summary.tsv"))
fixed <- simulate_one(2026074099L, tau = 0); tree <- fixed$tree; fixed_fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ drmTMB::phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1), family = drmTMB::zero_one_beta(), data = fixed$data, control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))), error = identity)
fixed_record <- if (inherits(fixed_fit, "error")) data.frame(source_sha = sha, runner_md5 = md5, status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY") else data.frame(source_sha = sha, runner_md5 = md5, status = "fit_ok", convergence = fixed_fit$opt$convergence, pdHess = isTRUE(fixed_fit$sdr$pdHess), tau_hat = unname(fixed_fit$sdpars$sigma[["phylo(1 | species)"]]), decision = "BOUNDARY_DIAGNOSTIC_ONLY")
write_tsv(fixed_record, file.path(out, "fixed-sigma-phylo-boundary-diagnostic.tsv"))
