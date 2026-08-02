#!/usr/bin/env Rscript
#
# C18 (mc-0615): structured `relmat` q1 unlabelled intercept on the `coi` atom's
# linear predictor, zero_one_beta family. Precision (Q) is supplied directly to
# `relmat()` -- NOT a covariance K -- because the existing q1 templates that
# pass K trigger a dense K -> Q inversion inside the structured-term builder;
# supplying Q avoids that path. See the provider note in the dispatch brief.
#
# DGP constants come from the 28,800-fit Totoro feasibility campaign at
# docs/dev-log/implementation-recovery/2026-08-02-c18-atom-dgp-feasibility/:
# zoi = 0.50, n_each = 50, coi = 0.50, tau = 0.55, n_tip = 32 is the only cell
# that clears the full recovery bar for BOTH atoms simultaneously.
#
# This is the coi arm and carries the C18-specific separation requirement: coi
# is informed only by boundary observations (unlike zoi, which every row
# informs), so a group whose boundary observations fall entirely on one side
# is completely separated -- it contributes nothing to coi, yet the GMRF prior
# supplies curvature so the fit still converges cleanly. n_separated_groups
# must be zero for the gate to mean anything here.
#
# NOTE: the structured zoi/coi routing this script exercises does not exist in
# the package yet (implementation in progress concurrently). This script is
# expected to fail with a validation or routing error today; its job is to be
# syntactically correct and to encode the gate correctly for when the route
# lands.

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}

# ---- DGP: relmat AR1-precision field placed on coi's linear predictor ------

new_data <- function(seed, n_group = 32L, n_each = 50L, tau = .55,
                      zoi_truth = .5, coi_truth = .5,
                      mu0 = -.15, mu1 = .35, log_sigma = -1) {
  set.seed(seed)
  labels <- paste0("sp", seq_len(n_group))

  # Tri-diagonal AR1-style precision matrix, matching the construction already
  # used by tools/run-lane-c-z7-sigma-relmat-local-recovery.R. K is only used
  # here, at DGP time, to draw the latent field; the FIT below is given Q
  # directly and never sees K.
  Q <- diag(2, n_group)
  Q[cbind(seq_len(n_group - 1L), 2:n_group)] <- -.5
  Q[cbind(2:n_group, seq_len(n_group - 1L))] <- -.5
  rownames(Q) <- colnames(Q) <- rev(labels)
  K <- solve(Q)

  field <- as.numeric(t(chol(K)) %*% rnorm(n_group, sd = tau))
  names(field) <- rownames(K)

  species <- factor(rep(labels, each = n_each), levels = labels)
  x <- rnorm(n_group * n_each)
  mu <- plogis(mu0 + mu1 * x)
  sigma <- exp(log_sigma)

  zoi_full <- rep(zoi_truth, length(species))
  coi_full <- plogis(qlogis(coi_truth) + field[as.character(species)])

  boundary <- rbinom(length(species), 1L, zoi_full)
  y <- rbeta(length(species), mu / sigma^2, (1 - mu) / sigma^2)
  n_bd <- sum(boundary)
  if (n_bd > 0L) y[boundary == 1L] <- rbinom(n_bd, 1L, coi_full[boundary == 1L])

  data <- data.frame(y = y, x = x, species = species)
  list(
    data = data, Q = Q, K = K, field = field,
    digest = digest::digest(list(Q = Q, x = x, y = y, seed = seed))
  )
}

group_diag <- function(y, species, n_group) {
  n_zero <- tabulate(as.integer(species[y == 0]), nbins = n_group)
  n_one <- tabulate(as.integer(species[y == 1]), nbins = n_group)
  n_interior <- tabulate(as.integer(species[y > 0 & y < 1]), nbins = n_group)
  list(
    min_group_zero = min(n_zero), min_group_one = min(n_one),
    min_group_interior = min(n_interior),
    min_boundary_per_group = min(n_zero + n_one),
    n_separated_groups = sum(n_zero == 0L | n_one == 0L)
  )
}

# ---- fit one attempt --------------------------------------------------------

run_one <- function(seed, source_sha, runner_sha) {
  sim <- new_data(seed)
  gd <- group_diag(sim$data$y, sim$data$species, 32L)
  Q <- sim$Q

  out <- data.frame(
    cell_id = "mc-0615", dpar = "coi", seed, source_sha, runner_sha,
    formula = "bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ relmat(1 | species, Q = Q))",
    tau_truth = .55, beta0_truth = -.15, beta1_truth = .35, log_sigma_truth = -1,
    zoi_truth = .5, coi_truth = .5, dgp_digest = sim$digest,
    min_group_zero = gd$min_group_zero, min_group_one = gd$min_group_one,
    min_group_interior = gd$min_group_interior,
    min_boundary_per_group = gd$min_boundary_per_group,
    n_separated_groups = gd$n_separated_groups,
    status = NA_character_, error = NA_character_, convergence = NA_integer_,
    pdHess = NA, max_gradient = NA_real_, mode_correlation = NA_real_,
    clamp_active = NA, boundary_hit = NA,
    beta0_hat = NA_real_, beta1_hat = NA_real_, log_sigma_hat = NA_real_,
    zoi_hat = NA_real_, coi_hat = NA_real_, tau_hat = NA_real_,
    stringsAsFactors = FALSE
  )

  fit <- tryCatch(
    drmTMB::drmTMB(
      drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ drmTMB::relmat(1 | species, Q = Q)),
      family = drmTMB::zero_one_beta(), data = sim$data,
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
    ),
    error = identity
  )
  if (inherits(fit, "error")) {
    out$status <- "fit_error"
    out$error <- conditionMessage(fit)
    return(out)
  }

  grad <- max(abs(fit$obj$gr(fit$opt$par)))
  log_sigma <- as.numeric(fit$obj$report()$log_sigma)
  tau_hat <- unname(fit$sdpars$coi[["relmat(1 | species)"]])
  u_hat <- ranef(fit, "relmat_coi")$terms[["relmat(1 | species)"]]

  out$status <- "fit_ok"
  out$error <- "none"
  out$convergence <- fit$opt$convergence
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$max_gradient <- grad
  out$mode_correlation <- suppressWarnings(stats::cor(u_hat[names(sim$field)], sim$field))
  out$clamp_active <- any(abs(log_sigma) > 11.99)
  out$beta0_hat <- fit$coefficients$mu[["(Intercept)"]]
  out$beta1_hat <- fit$coefficients$mu[["x"]]
  out$log_sigma_hat <- unname(fit$coefficients$sigma[["(Intercept)"]])
  out$zoi_hat <- plogis(fit$coefficients$zoi[["(Intercept)"]])
  out$coi_hat <- plogis(fit$coefficients$coi[["(Intercept)"]])
  out$tau_hat <- tau_hat
  out$boundary_hit <- !is.finite(tau_hat) || tau_hat <= .05 || tau_hat >= 2.5
  out
}

# ---- entry point -------------------------------------------------------------

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

dir <- Sys.getenv(
  "DRMTMB_RECOVERY_OUT",
  unset = file.path(root, "docs/dev-log/implementation-recovery/2026-08-02-lane-c-c18-zob-relmat-coi-q1-local-recovery")
)
dir.create(dir, recursive = TRUE, showWarnings = FALSE)

sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_sha <- unname(tools::md5sum(script))

seeds <- 2026080621:2026080624
attempts <- do.call(rbind, lapply(seeds, run_one, source_sha = sha, runner_sha = runner_sha))
write_tsv(attempts, file.path(dir, "raw-attempts.tsv"))

ok <- with(
  attempts,
  status == "fit_ok" & convergence == 0L & pdHess &
    is.finite(max_gradient) & max_gradient <= .01 & !boundary_hit &
    mode_correlation > .45 &
    min_group_zero > 0L & min_group_one > 0L & min_group_interior > 0L &
    n_separated_groups == 0L
)
mean_err <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / .55 - 1)) else NA_real_
pass <- all(ok) && sum(ok) == length(seeds) && is.finite(mean_err) && mean_err <= .40
decision <- if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"

write_tsv(
  data.frame(
    planned_attempts = length(seeds), attempted_attempts = nrow(attempts),
    passed_attempts = sum(ok), mean_tau_relative_error = mean_err, decision
  ),
  file.path(dir, "summary.tsv")
)

# ---- tau = 0 boundary diagnostic (NOT part of the gate) ---------------------

fixed <- new_data(2026080699L, tau = 0)
Q <- fixed$Q
fixed_fit <- tryCatch(
  drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ drmTMB::relmat(1 | species, Q = Q)),
    family = drmTMB::zero_one_beta(), data = fixed$data,
    control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
  ),
  error = identity
)
fixed_record <- if (inherits(fixed_fit, "error")) {
  data.frame(source_sha = sha, runner_sha, status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY")
} else {
  data.frame(
    source_sha = sha, runner_sha, status = "fit_ok",
    convergence = fixed_fit$opt$convergence, pdHess = isTRUE(fixed_fit$sdr$pdHess),
    tau_hat = unname(fixed_fit$sdpars$coi[["relmat(1 | species)"]]),
    decision = "BOUNDARY_DIAGNOSTIC_ONLY"
  )
}
write_tsv(fixed_record, file.path(dir, "fixed-coi-relmat-boundary-diagnostic.tsv"))
