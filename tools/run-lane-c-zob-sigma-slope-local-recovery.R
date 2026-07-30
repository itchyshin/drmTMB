#!/usr/bin/env Rscript

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

simulate_zoib_sigma_slope <- function(seed, tau = 0.45, n_group = 32L, n_each = 50L) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(n_group)), each = n_each))
  x <- rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  x <- x / stats::sd(x)
  b <- rnorm(n_group, sd = tau)
  names(b) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(-1 + b[as.character(id)] * x)
  zoi <- stats::plogis(-0.7)
  coi <- stats::plogis(0.1)
  boundary <- stats::rbinom(length(id), 1L, zoi)
  y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(sum(boundary), 1L, coi)
  data <- data.frame(y, x, id)
  list(
    data = data,
    b = b,
    n_zero = sum(y == 0),
    n_one = sum(y == 1),
    min_group_boundary = min(tapply(y %in% c(0, 1), id, sum)),
    min_group_interior = min(tapply(y > 0 & y < 1, id, sum))
  )
}

fit_sigma_slope <- function(data) {
  drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1),
    data = data,
    family = drmTMB::zero_one_beta(),
    control = drmTMB::drm_control(
      se = TRUE,
      optimizer = list(eval.max = 2000L, iter.max = 2000L)
    )
  )
}

fit_one <- function(seed, source_sha, runner_md5) {
  sim <- simulate_zoib_sigma_slope(seed)
  fit <- tryCatch(fit_sigma_slope(sim$data), error = identity)
  if (inherits(fit, "error")) {
    return(data.frame(seed, source_sha, runner_md5, status = "fit_error", error = conditionMessage(fit)))
  }
  tau_hat <- unname(fit$sdpars$sigma[["(0 + x | id)"]])
  u_hat <- ranef(fit, "sigma")$terms[["(0 + x | id)"]]
  report <- fit$obj$report()
  log_sigma <- as.numeric(report$log_sigma)
  data.frame(
    seed, source_sha, runner_md5, status = "fit_ok",
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
    tau_truth = 0.45, tau_hat,
    mode_correlation = suppressWarnings(stats::cor(u_hat[names(sim$b)], sim$b)),
    n_zero = sim$n_zero, n_one = sim$n_one,
    min_group_boundary = sim$min_group_boundary,
    min_group_interior = sim$min_group_interior,
    log_sigma_min = min(log_sigma), log_sigma_max = max(log_sigma),
    clamp_active = any(log_sigma <= -12 | log_sigma >= 12),
    boundary_hit = !is.finite(tau_hat) || tau_hat <= 0.05 || tau_hat >= 2.5
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

out <- file.path(root, "docs/dev-log/implementation-recovery/2026-07-30-lane-c-z5-zob-sigma-slope-local-run-1")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source_sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_md5 <- unname(tools::md5sum(script))
attempts <- do.call(rbind, lapply(2026073701:2026073704, fit_one, source_sha = source_sha, runner_md5 = runner_md5))
write_tsv(attempts, file.path(out, "raw-attempts.tsv"))

ok <- with(
  attempts,
  status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= 0.01 &
    !boundary_hit & !clamp_active & mode_correlation > 0.45 &
    min_group_boundary > 0L & min_group_interior > 0L
)
mean_relative_error <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / 0.45 - 1)) else NA_real_
decision <- if (all(ok) && is.finite(mean_relative_error) && mean_relative_error <= 0.40) {
  "PASS_POINT_RECOVERY_LOCAL"
} else {
  "BLOCKED_LOCAL_FIXTURE"
}
write_tsv(
  data.frame(
    planned_attempts = 4L,
    attempted_attempts = nrow(attempts),
    passed_attempts = sum(ok),
    mean_tau_relative_error = mean_relative_error,
    decision
  ),
  file.path(out, "summary.tsv")
)

fixed <- simulate_zoib_sigma_slope(2026073799L, tau = 0)
fixed_fit <- tryCatch(fit_sigma_slope(fixed$data), error = identity)
fixed_record <- if (inherits(fixed_fit, "error")) {
  data.frame(status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY")
} else {
  data.frame(
    status = "fit_ok",
    convergence = fixed_fit$opt$convergence,
    pdHess = isTRUE(fixed_fit$sdr$pdHess),
    tau_hat = unname(fixed_fit$sdpars$sigma[["(0 + x | id)"]]),
    decision = "BOUNDARY_DIAGNOSTIC_ONLY"
  )
}
write_tsv(fixed_record, file.path(out, "fixed-sigma-boundary-diagnostic.tsv"))
