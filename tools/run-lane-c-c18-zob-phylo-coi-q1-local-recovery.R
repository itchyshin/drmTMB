#!/usr/bin/env Rscript

# C18 structured zero-one-beta atom recovery: mc-0613, provider `phylo`, q1
# (one unlabelled structured intercept on `coi`'s linear predictor).
#
# DGP per docs/dev-log/implementation-recovery/2026-08-02-c18-atom-dgp-feasibility:
# zoi = 0.50, n_each = 50, coi = 0.50, tau = 0.55, n_tip = 32 -- the only
# setting that cleared the full bar for both atoms in the 28,800-fit Totoro
# feasibility campaign. `zoi` stays fixed (unstructured) here; the phylo field
# rides on `coi`'s linear predictor around the coi = 0.50 baseline.
#
# Structured zoi/coi routing does not exist yet (design doc 248 SS3.3-3.4).
# This script authors the recovery harness ahead of that implementation; it
# is expected to fail with a routing/parse error today, not to pass.
#
# `coi` is only informed by boundary observations (design doc 248 SS2.2), so
# a group whose boundary rows all fall on one side is completely separated:
# it contributes nothing to `coi` even though the GMRF prior lets the fit
# converge cleanly. n_separated_groups / min_boundary_per_group make that
# failure mode visible instead of letting a clean convergence hide it.

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)

simulate_one <- function(seed, tau = .55) {
  set.seed(seed); n_tip <- 32L; n_each <- 50L
  tree <- ape::stree(n_tip, type = "balanced"); tree$edge.length <- rep(1, nrow(tree$edge)); tree$tip.label <- paste0("sp", seq_len(n_tip))
  V <- drmTMB:::drm_phylo_tip_covariance(tree); b <- as.numeric(t(chol(V)) %*% rnorm(n_tip, sd = tau)); names(b) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each); x <- rnorm(length(species)); mu <- plogis(-.15 + .35 * x); sigma <- exp(-1)
  zoi <- .50; coi <- plogis(qlogis(.50) + b[species])
  boundary <- rbinom(length(x), 1L, zoi); y <- rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2); y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi[boundary == 1L])
  n0 <- tapply(y == 0, species, sum); n1 <- tapply(y == 1, species, sum)
  list(
    data = data.frame(y, x, species), tree = tree, b = b,
    min_group_zero = min(n0), min_group_one = min(n1),
    min_group_interior = min(tapply(y > 0 & y < 1, species, sum)),
    n_separated_groups = sum(n0 == 0 | n1 == 0), min_boundary_per_group = min(n0 + n1)
  )
}

fit_one <- function(seed, sha, md5) {
  sim <- simulate_one(seed)
  tree <- sim$tree
  fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ drmTMB::phylo(1 | species, tree = tree)), family = drmTMB::zero_one_beta(), data = sim$data, control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))), error = identity)
  if (inherits(fit, "error")) return(data.frame(cell_id = "mc-0613", dpar = "coi", seed, source_sha = sha, runner_md5 = md5, status = "fit_error", error = conditionMessage(fit)))
  tau_hat <- unname(fit$sdpars$coi[["phylo(1 | species)"]]); u_hat <- ranef(fit, "phylo_coi")$terms[["phylo(1 | species)"]]
  data.frame(cell_id = "mc-0613", dpar = "coi", seed, source_sha = sha, runner_md5 = md5, status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), max_gradient = max(abs(fit$obj$gr(fit$opt$par)), na.rm = TRUE), tau_truth = .55, tau_hat, mode_correlation = cor(u_hat[names(sim$b)], sim$b), min_group_zero = sim$min_group_zero, min_group_one = sim$min_group_one, min_group_interior = sim$min_group_interior, n_separated_groups = sim$n_separated_groups, min_boundary_per_group = sim$min_boundary_per_group, clamp_active = any(abs(fit$obj$report()$log_sigma) > 11.99), boundary_hit = !is.finite(tau_hat) || tau_hat <= .05 || tau_hat >= 2.5)
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L]); root <- normalizePath(file.path(dirname(script), "..")); setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
out <- Sys.getenv("DRMTMB_RECOVERY_OUT", unset = file.path(root, "docs/dev-log/implementation-recovery/2026-08-02-lane-c-c18-zob-phylo-coi-q1-local-recovery")); dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)); md5 <- unname(tools::md5sum(script)); attempts <- do.call(rbind, lapply(2026080211:2026080214, fit_one, sha = sha, md5 = md5)); write_tsv(attempts, file.path(out, "raw-attempts.tsv"))
ok <- if (all(c("convergence", "pdHess", "max_gradient", "boundary_hit", "mode_correlation", "min_group_zero", "min_group_one", "min_group_interior", "n_separated_groups") %in% names(attempts))) with(attempts, status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= .01 & !boundary_hit & mode_correlation > .45 & min_group_zero > 0L & min_group_one > 0L & min_group_interior > 0L & n_separated_groups == 0L) else rep(FALSE, nrow(attempts))
err <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / .55 - 1)) else NA_real_
decision <- if (all(ok) && is.finite(err) && err <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"
write_tsv(data.frame(planned_attempts = 4L, attempted_attempts = nrow(attempts), passed_attempts = sum(ok), mean_tau_relative_error = err, decision), file.path(out, "summary.tsv"))
fixed <- simulate_one(2026080298L, tau = 0); tree <- fixed$tree; fixed_fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ drmTMB::phylo(1 | species, tree = tree)), family = drmTMB::zero_one_beta(), data = fixed$data, control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))), error = identity)
fixed_record <- if (inherits(fixed_fit, "error")) data.frame(source_sha = sha, runner_md5 = md5, status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY") else data.frame(source_sha = sha, runner_md5 = md5, status = "fit_ok", convergence = fixed_fit$opt$convergence, pdHess = isTRUE(fixed_fit$sdr$pdHess), tau_hat = unname(fixed_fit$sdpars$coi[["phylo(1 | species)"]]), decision = "BOUNDARY_DIAGNOSTIC_ONLY")
write_tsv(fixed_record, file.path(out, "fixed-coi-phylo-boundary-diagnostic.tsv"))
