#!/usr/bin/env Rscript

# Fixed-residual-SD likelihood profile for the retained C1 AR1 boundary case.
# This is a finite diagnostic on one frozen pilot seed, not a recovery or
# interval-calibration campaign. It never overwrites existing retained output.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) {
  stop("This diagnostic takes no arguments.", call. = FALSE)
}

root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}
pkgload::load_all(root, quiet = TRUE)

out_dir <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-c1-boundary-profile"
)
required <- file.path(out_dir, c(
  "profile-attempts.csv", "profile-summary.csv", "provenance.csv",
  "profile-results.rds", "session-info.txt", "RESULTS.md"
))
if (any(file.exists(required))) {
  stop("C1 boundary-profile evidence already exists; do not overwrite it.", call. = FALSE)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)
simulate_c1 <- function(seed = 2026091002L) {
  set.seed(seed)
  n_id <- 80L
  n_time <- 6L
  phi <- 0.4
  time <- seq.int(0L, length.out = n_time)
  id_levels <- sprintf("id_%03d", seq_len(n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  occasion <- rep(time, n_id)
  between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = n_time))
  }), use.names = FALSE)
  R <- phi ^ abs(outer(time, time, "-"))
  temporal <- unlist(lapply(seq_len(n_id), function(i) {
    as.vector(t(chol(R)) %*% rnorm(n_time, sd = 0.8))
  }), use.names = FALSE)
  stable <- rep(rnorm(n_id, sd = 0.6), each = n_time)
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between +
      truth[["within"]] * within + stable + temporal +
      rnorm(n_id * n_time, sd = 0.4),
    id = id, occasion = occasion, between = between, within = within
  )
}

dat <- simulate_c1()
template <- suppressWarnings(drmTMB(
  bf(y ~ between + within + (1 | id) +
       temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
  data = dat, family = gaussian(), REML = FALSE,
  control = drm_control(newton_polish = FALSE)
))

sigma_grid <- c(1e-7, 1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 0.05, 0.1, 0.2, 0.4)
persistence_starts <- c(-0.3, 0.3)

fit_fixed_sigma <- function(sigma, persistence_start) {
  parameters <- template$model$start
  parameters$beta_sigma <- log(sigma)
  parameters$theta_temporal <- atanh(persistence_start)
  parameters$u_temporal <- numeric(length(parameters$u_temporal))
  map <- template$model$map
  map$beta_sigma <- factor(NA)
  obj <- TMB::MakeADFun(
    data = template$model$tmb_data,
    parameters = parameters,
    map = map,
    random = template$model$tmb_random_names,
    DLL = "drmTMB",
    silent = TRUE
  )
  warning_text <- character()
  opt <- withCallingHandlers(
    tryCatch(
      stats::nlminb(obj$par, obj$fn, obj$gr),
      error = function(e) e
    ),
    warning = function(w) {
      warning_text <<- c(warning_text, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(opt, "error")) {
    return(data.frame(
      sigma_fixed = sigma, persistence_start = persistence_start,
      convergence = NA_integer_, objective = NA_real_, gradient_max = NA_real_,
      pd_hessian = NA, beta_intercept = NA_real_, beta_between = NA_real_,
      beta_within = NA_real_, sd_ordinary = NA_real_, sd_temporal = NA_real_,
      phi = NA_real_, warning = paste(warning_text, collapse = " | "),
      error = conditionMessage(opt), stringsAsFactors = FALSE
    ))
  }
  par <- obj$env$parList(opt$par)
  sdr <- tryCatch(
    TMB::sdreport(obj, par.fixed = opt$par, getJointPrecision = FALSE),
    error = function(e) e
  )
  data.frame(
    sigma_fixed = sigma, persistence_start = persistence_start,
    convergence = as.integer(opt$convergence), objective = opt$objective,
    gradient_max = max(abs(obj$gr(opt$par))),
    pd_hessian = !inherits(sdr, "error") && isTRUE(sdr$pdHess),
    beta_intercept = unname(par$beta_mu[[1L]]),
    beta_between = unname(par$beta_mu[[2L]]),
    beta_within = unname(par$beta_mu[[3L]]),
    sd_ordinary = exp(unname(par$log_sd_mu[[1L]])),
    sd_temporal = exp(unname(par$log_sd_temporal[[1L]])),
    phi = tanh(unname(par$theta_temporal[[1L]])),
    warning = paste(warning_text, collapse = " | "),
    error = if (inherits(sdr, "error")) conditionMessage(sdr) else NA_character_,
    stringsAsFactors = FALSE
  )
}

attempts <- do.call(rbind, lapply(sigma_grid, function(sigma) {
  do.call(rbind, lapply(persistence_starts, function(start) {
    fit_fixed_sigma(sigma, start)
  }))
}))
selected <- do.call(rbind, lapply(split(attempts, attempts$sigma_fixed), function(rows) {
  rows <- rows[is.finite(rows$objective), , drop = FALSE]
  if (nrow(rows) == 0L) {
    return(rows)
  }
  rows[which.min(rows$objective), , drop = FALSE]
}))
selected <- selected[order(selected$sigma_fixed), , drop = FALSE]
selected$delta_nll <- selected$objective - min(selected$objective)

write.csv(attempts, file.path(out_dir, "profile-attempts.csv"), row.names = FALSE)
write.csv(selected, file.path(out_dir, "profile-summary.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "seed", "n_sigma", "n_attempts", "run_utc"),
  value = c(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools/diagnose-temporal-ar1-c1-boundary.R"))),
    2026091002L, length(sigma_grid), nrow(attempts),
    format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(
  list(data = dat, sigma_grid = sigma_grid, attempts = attempts, selected = selected,
       provenance = provenance),
  file.path(out_dir, "profile-results.rds")
)
writeLines(
  sub("[[:space:]]+$", "", capture.output(sessionInfo())),
  file.path(out_dir, "session-info.txt")
)

writeLines(c(
  "# C1 fixed-residual-SD likelihood profile",
  "",
  "This diagnostic fixes the residual SD over a predeclared grid and re-optimizes all other AR1 model parameters from both signed persistence starts. It uses the immutable C1 seed 2026091002 and does not alter the pilot or start a campaign.",
  "",
  "The CSV files retain both starts and the selected objective at each fixed residual SD. `delta_nll` is relative to the smallest selected objective on this finite grid. Conditional Hessian status applies only to the model with residual SD fixed; it is not a Wald qualification for the original free-sigma model."
), file.path(out_dir, "RESULTS.md"))

if (nrow(attempts) != length(sigma_grid) * length(persistence_starts) ||
    !all(is.finite(selected$objective))) {
  stop("C1 profile did not retain a finite selected fit at every declared residual SD.", call. = FALSE)
}
cat("TEMPORAL_AR1_C1_PROFILE_PASS\n")
