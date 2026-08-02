#!/usr/bin/env Rscript

# C18 exact q1 leaf: mc-0614 -- one unlabelled structured `coi` intercept,
# provider `animal`, on a zero_one_beta() fit. See
# docs/dev-log/implementation-recovery/2026-08-02-c18-atom-dgp-feasibility/README.md
# for the DGP justification (zoi = .50, n_each = 50, coi = .50, tau = .55,
# n_tip = 32 is the only setting that clears the full bar for both atoms).
#
# NOTE: the structured zoi/coi routing this script exercises does not exist
# in the package yet (it is being implemented concurrently). This script is
# authored to PARSE and to encode the gate; it is not expected to fit_ok
# until that routing lands.
#
# The per-group separation check matters most for THIS atom: a group whose
# boundary observations are all 0 or all 1 is completely separated for coi
# -- it contributes nothing to the coi likelihood even though the GMRF prior
# on the animal field supplies curvature and lets the fit converge cleanly.

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
clean <- function(x) trimws(gsub("[\r\n\t]+", " ", paste(x, collapse = "; ")))

new_data <- function(seed, n_group = 32L, n_each = 50L, tau = .55) {
  set.seed(seed); labels <- paste0("sp", seq_len(n_group))
  Ainv <- diag(2, n_group); Ainv[cbind(seq_len(n_group - 1L), 2:n_group)] <- -.5; Ainv[cbind(2:n_group, seq_len(n_group - 1L))] <- -.5
  rownames(Ainv) <- colnames(Ainv) <- rev(labels)
  # `Ainv` is deliberately labelled in REVERSE order, so that the fit has to
  # align the field by name rather than by position. The draw below therefore
  # has to be named `rownames(Ainv)` -- naming it `labels` would silently
  # permute the simulated field relative to the matrix that generated it,
  # leaving tau recoverable (variance is permutation-invariant) while the
  # mode correlation collapses to noise.
  u <- as.numeric(t(chol(solve(Ainv))) %*% rnorm(n_group, sd = tau)); names(u) <- rownames(Ainv)
  data <- data.frame(species = rep(labels, each = n_each), x = rnorm(n_group * n_each))
  data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / sd(data$x)
  mu <- plogis(-.15 + .35 * data$x); sigma <- exp(-1.0)
  zoi <- plogis(0); coi <- plogis(0 + u[data$species])
  boundary <- rbinom(nrow(data), 1, zoi)
  data$y <- ifelse(boundary == 1, rbinom(nrow(data), 1, coi[data$species]), rbeta(nrow(data), mu / sigma^2, (1 - mu) / sigma^2))
  species_f <- factor(data$species, levels = labels)
  n_zero <- tapply(data$y == 0, species_f, sum); n_one <- tapply(data$y == 1, species_f, sum)
  n_interior <- tapply(data$y > 0 & data$y < 1, species_f, sum); n_boundary <- n_zero + n_one
  separated <- (n_zero == 0) | (n_one == 0)
  list(data = data, Ainv = Ainv, u = u,
    min_group_zero = min(n_zero), min_group_one = min(n_one), min_group_interior = min(n_interior),
    n_separated_groups = sum(separated), min_boundary_per_group = min(n_boundary),
    digest = digest::digest(list(Ainv = Ainv, x = data$x, y = data$y)))
}

run_one <- function(seed, source_sha, runner_sha, tau = .55) {
  out <- data.frame(cell_id = "mc-0614", dpar = "coi", provider = "animal", seed, source_sha, runner_sha,
    formula = "y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + animal(1 | species, Ainv = Ainv)",
    tau_truth = tau, mu0_truth = -.15, mu1_truth = .35, log_sigma_truth = -1.0, zoi_truth = .50, coi_truth = .50,
    dgp_digest = NA_character_, status = NA_character_, warning = NA_character_, convergence = NA_integer_,
    pdHess = NA, max_gradient = NA_real_, mode_correlation = NA_real_, eta_coi_min = NA_real_, eta_coi_max = NA_real_,
    clamp_active = FALSE, boundary_hit = NA,
    min_group_zero = NA_integer_, min_group_one = NA_integer_, min_group_interior = NA_integer_,
    n_separated_groups = NA_integer_, min_boundary_per_group = NA_integer_,
    mu0_hat = NA_real_, mu1_hat = NA_real_, sigma_hat = NA_real_, zoi_hat = NA_real_, tau_hat = NA_real_)
  sim <- new_data(seed, tau = tau); out$dgp_digest <- sim$digest; Ainv <- sim$Ainv
  out$min_group_zero <- sim$min_group_zero; out$min_group_one <- sim$min_group_one
  out$min_group_interior <- sim$min_group_interior; out$n_separated_groups <- sim$n_separated_groups
  out$min_boundary_per_group <- sim$min_boundary_per_group
  warnings <- character()
  fit <- tryCatch(withCallingHandlers(
    drmTMB::drmTMB(
      drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + animal(1 | species, Ainv = Ainv)),
      family = drmTMB::zero_one_beta(), data = sim$data,
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))
    ),
    warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }
  ), error = identity)
  if (inherits(fit, "error")) { out$status <- "fit_error"; out$warning <- clean(c(warnings, conditionMessage(fit))); return(out) }
  grad <- fit$obj$gr(fit$opt$par); report <- fit$obj$report()
  mode <- as.numeric(ranef(fit, "animal_coi")$terms[["animal(1 | species)"]])
  names(mode) <- names(sim$u)
  eta_coi <- as.numeric(report$eta_coi)
  out$status <- "fit_ok"; out$warning <- clean(warnings); out$convergence <- fit$opt$convergence
  out$pdHess <- isTRUE(fit$sdr$pdHess); out$max_gradient <- max(abs(grad))
  out$mode_correlation <- suppressWarnings(stats::cor(mode[names(sim$u)], sim$u))
  out$eta_coi_min <- min(eta_coi); out$eta_coi_max <- max(eta_coi)
  out$mu0_hat <- fit$coefficients$mu[["(Intercept)"]]; out$mu1_hat <- fit$coefficients$mu[["x"]]
  out$sigma_hat <- exp(fit$coefficients$sigma[["(Intercept)"]]); out$zoi_hat <- plogis(fit$coefficients$zoi[["(Intercept)"]])
  out$tau_hat <- fit$sdpars$coi[["animal(1 | species)"]]
  out$boundary_hit <- !all(is.finite(unlist(out[c("mu0_hat", "mu1_hat", "sigma_hat", "zoi_hat", "tau_hat")]))) || out$tau_hat <= .05 || out$tau_hat >= 2.5
  out
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]); root <- normalizePath(file.path(dirname(script), "..")); setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
dir <- Sys.getenv("DRMTMB_RECOVERY_OUT", unset = file.path(root, "docs/dev-log/implementation-recovery/2026-08-02-lane-c-c18-mc-0614-zob-animal-coi-q1-local-recovery")); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)); runner_sha <- unname(tools::md5sum(script))
attempts <- do.call(rbind, lapply(2026080211:2026080214, run_one, source_sha = sha, runner_sha = runner_sha)); write_tsv(attempts, file.path(dir, "raw-attempts.tsv"))

ok <- if (all(c("convergence", "pdHess", "max_gradient", "mode_correlation", "min_group_zero", "min_group_one", "min_group_interior", "n_separated_groups", "boundary_hit") %in% names(attempts))) with(
  attempts,
  status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= .01 & !boundary_hit &
    mode_correlation > .45 & min_group_zero > 0L & min_group_one > 0L & min_group_interior > 0L &
    n_separated_groups == 0L
) else rep(FALSE, nrow(attempts))
err <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / .55 - 1)) else NA_real_
decision <- if (all(ok) && sum(ok) == 4L && is.finite(err) && err <= .40) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"
write_tsv(data.frame(planned_attempts = 4L, attempted_attempts = nrow(attempts), passed_attempts = sum(ok), mean_tau_relative_error = err, decision), file.path(dir, "summary.tsv"))

fixed <- new_data(2026080219L, tau = 0); Ainv <- fixed$Ainv
fixed_fit <- tryCatch(
  drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + animal(1 | species, Ainv = Ainv)),
    family = drmTMB::zero_one_beta(), data = fixed$data,
    control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))
  ),
  error = identity
)
fixed_record <- if (inherits(fixed_fit, "error")) {
  data.frame(source_sha = sha, runner_sha = runner_sha, status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY")
} else {
  data.frame(source_sha = sha, runner_sha = runner_sha, status = "fit_ok", convergence = fixed_fit$opt$convergence,
    pdHess = isTRUE(fixed_fit$sdr$pdHess), tau_hat = unname(fixed_fit$sdpars$coi[["animal(1 | species)"]]),
    decision = "BOUNDARY_DIAGNOSTIC_ONLY")
}
write_tsv(fixed_record, file.path(dir, "fixed-coi-animal-boundary-diagnostic.tsv"))
