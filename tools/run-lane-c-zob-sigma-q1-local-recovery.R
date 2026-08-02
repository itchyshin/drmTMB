#!/usr/bin/env Rscript

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

simulate_zoib_sigma_re <- function(seed, tau = 0.45, n_group = 32L, n_each = 30L) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(n_group)), each = n_each))
  x <- rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  x <- x / stats::sd(x)
  b <- rnorm(n_group, sd = tau)
  names(b) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(log(0.45) + b[as.character(id)])
  zoi <- 0.14
  coi <- 0.40
  boundary <- stats::rbinom(length(id), 1L, zoi)
  y <- ifelse(
    boundary == 1L,
    stats::rbinom(length(id), 1L, coi),
    stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  )
  list(data = data.frame(y = y, x = x, id = id), b = b)
}

fit_one <- function(seed, source_sha, runner_md5) {
  sim <- simulate_zoib_sigma_re(seed)
  fit <- tryCatch(
    drmTMB::drmTMB(
      drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
      family = drmTMB::zero_one_beta(),
      data = sim$data,
      control = drmTMB::drm_control(
        se = TRUE,
        optimizer = list(eval.max = 2000L, iter.max = 2000L)
      )
    ),
    error = identity
  )
  if (inherits(fit, "error")) {
    return(data.frame(seed, source_sha, runner_md5, status = "fit_error", error = conditionMessage(fit)))
  }
  tau_hat <- unname(fit$sdpars$sigma[["(1 | id)"]])
  u_hat <- ranef(fit, "sigma")$terms[["(1 | id)"]]
  mode_cor <- suppressWarnings(stats::cor(u_hat[names(sim$b)], sim$b))
  gradient <- max(abs(fit$obj$gr(fit$opt$par)))
  report <- fit$obj$report()
  log_sigma <- as.numeric(report$log_sigma)
  data.frame(
    seed, source_sha, runner_md5, status = "fit_ok",
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess), max_gradient = gradient,
    tau_truth = 0.45, tau_hat, mode_correlation = mode_cor,
    n_zero = sum(sim$data$y == 0), n_one = sum(sim$data$y == 1),
    log_sigma_min = min(log_sigma), log_sigma_max = max(log_sigma),
    clamp_active = any(log_sigma <= -12 | log_sigma >= 12),
    boundary_hit = !is.finite(tau_hat) || tau_hat <= 0.05 || tau_hat >= 2.5
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)

out <- file.path(root, "docs/dev-log/implementation-recovery/2026-07-29-lane-c-z3-zob-sigma-q1-local-run-1")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source_sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_md5 <- unname(tools::md5sum(script))
attempts <- do.call(rbind, lapply(2026073401:2026073404, fit_one, source_sha = source_sha, runner_md5 = runner_md5))
write_tsv(attempts, file.path(out, "raw-attempts.tsv"))

ok <- with(
  attempts,
  status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= 0.01 &
    !boundary_hit & !clamp_active & mode_correlation > 0.45
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

fixed <- simulate_zoib_sigma_re(2026073499L, tau = 0)
fixed_fit <- tryCatch(
  drmTMB::drmTMB(
    drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
    family = drmTMB::zero_one_beta(), data = fixed$data,
    control = drmTMB::drm_control(
      se = TRUE,
      optimizer = list(eval.max = 2000L, iter.max = 2000L)
    )
  ),
  error = identity
)
fixed_record <- if (inherits(fixed_fit, "error")) {
  data.frame(status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY")
} else {
  data.frame(
    status = "fit_ok", convergence = fixed_fit$opt$convergence,
    pdHess = isTRUE(fixed_fit$sdr$pdHess),
    tau_hat = unname(fixed_fit$sdpars$sigma[["(1 | id)"]]),
    decision = "BOUNDARY_DIAGNOSTIC_ONLY"
  )
}
write_tsv(fixed_record, file.path(out, "fixed-sigma-boundary-diagnostic.tsv"))
