#!/usr/bin/env Rscript

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

utc_now <- function() format(Sys.time(), tz = "UTC", usetz = TRUE)

git_output <- function(args) {
  trimws(system2("git", args, stdout = TRUE, stderr = TRUE))
}

git_blob <- function(path) {
  value <- git_output(c("hash-object", path))
  if (length(value) != 1L || !nzchar(value)) stop("Could not hash ", path)
  value
}

sha256_file <- function(path) {
  value <- trimws(system2(
    "shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE
  ))
  if (length(value) != 1L || !nzchar(value)) stop("Could not hash ", path)
  strsplit(value, "[[:space:]]+")[[1L]][[1L]]
}

simulate_one <- function(M, seed, tau = 0.45) {
  set.seed(seed)
  n_each <- 50L
  group_levels <- paste0("g", seq_len(M))
  id <- factor(rep(group_levels, each = n_each), levels = group_levels)
  stopifnot(identical(levels(id), group_levels))
  x <- stats::rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  x <- x / stats::sd(x)
  b <- stats::rnorm(M, sd = tau)
  names(b) <- levels(id)

  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(-1.0)
  zoi <- stats::plogis(-0.40)
  coi <- stats::plogis(0.10 + b[as.character(id)])
  boundary <- stats::rbinom(length(id), 1L, zoi)
  y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(
    sum(boundary), 1L, coi[boundary == 1L]
  )

  list(
    data = data.frame(y = y, x = x, id = id),
    b = b,
    min_group_zero = min(tapply(y == 0, id, sum)),
    min_group_one = min(tapply(y == 1, id, sum)),
    min_group_interior = min(tapply(y > 0 & y < 1, id, sum))
  )
}

fit_one <- function(M, seed, source_sha, runner_sha256) {
  sim <- simulate_one(M, seed)
  fit <- tryCatch(
    drmTMB::drmTMB(
      drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id)),
      family = drmTMB::zero_one_beta(),
      data = sim$data,
      control = drmTMB::drm_control(
        se = TRUE,
        optimizer = list(eval.max = 3000L, iter.max = 3000L)
      )
    ),
    error = identity
  )

  empty <- function(status, error) data.frame(
    M = M, seed = seed, source_sha = source_sha,
    runner_sha256 = runner_sha256, status = status,
    convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_,
    tau_truth = 0.45, tau_hat = NA_real_, mode_correlation = NA_real_,
    beta_mu0_error = NA_real_, beta_mu1_error = NA_real_,
    beta_zoi0_error = NA_real_, beta_coi0_error = NA_real_,
    log_sigma_error = NA_real_, tau_relative_error = NA_real_,
    min_group_zero = sim$min_group_zero,
    min_group_one = sim$min_group_one,
    min_group_interior = sim$min_group_interior,
    support_gate = sim$min_group_zero >= 2L &&
      sim$min_group_one >= 2L && sim$min_group_interior >= 10L,
    boundary_hit = NA,
    glmer_beta_coi0 = NA_real_, glmer_tau = NA_real_,
    glmer_beta_difference = NA_real_, glmer_tau_difference = NA_real_,
    error = error
  )
  if (inherits(fit, "error")) {
    return(empty("fit_error", conditionMessage(fit)))
  }

  tau_hat <- unname(fit$sdpars$coi[["(1 | id)"]])
  modes <- ranef(fit, "coi")$terms[["(1 | id)"]]
  beta_mu <- coef(fit, "mu")
  beta_zoi <- coef(fit, "zoi")
  beta_coi <- coef(fit, "coi")
  beta_sigma <- coef(fit, "sigma")

  boundary_data <- droplevels(sim$data[sim$data$y %in% c(0, 1), ])
  boundary_data$one <- as.integer(boundary_data$y == 1)
  glmer_fit <- tryCatch(
    lme4::glmer(
      one ~ 1 + (1 | id),
      data = boundary_data,
      family = stats::binomial(),
      control = lme4::glmerControl(
        optimizer = "bobyqa", optCtrl = list(maxfun = 200000L)
      )
    ),
    error = identity
  )
  if (inherits(glmer_fit, "error")) {
    return(empty("comparator_error", conditionMessage(glmer_fit)))
  }
  glmer_beta <- unname(lme4::fixef(glmer_fit)[[1L]])
  glmer_tau <- unname(attr(lme4::VarCorr(glmer_fit)$id, "stddev")[[1L]])

  data.frame(
    M = M, seed = seed, source_sha = source_sha,
    runner_sha256 = runner_sha256, status = "fit_ok",
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par)), na.rm = TRUE),
    tau_truth = 0.45, tau_hat = tau_hat,
    mode_correlation = stats::cor(modes[names(sim$b)], sim$b),
    beta_mu0_error = abs(unname(beta_mu[[1L]]) - (-0.15)),
    beta_mu1_error = abs(unname(beta_mu[["x"]]) - 0.35),
    beta_zoi0_error = abs(unname(beta_zoi[[1L]]) - (-0.40)),
    beta_coi0_error = abs(unname(beta_coi[[1L]]) - 0.10),
    log_sigma_error = abs(unname(beta_sigma[[1L]]) - (-1.0)),
    tau_relative_error = abs(tau_hat / 0.45 - 1),
    min_group_zero = sim$min_group_zero,
    min_group_one = sim$min_group_one,
    min_group_interior = sim$min_group_interior,
    support_gate = sim$min_group_zero >= 2L &&
      sim$min_group_one >= 2L && sim$min_group_interior >= 10L,
    boundary_hit = !is.finite(tau_hat) || tau_hat <= 0.05 || tau_hat >= 2.5,
    glmer_beta_coi0 = glmer_beta, glmer_tau = glmer_tau,
    glmer_beta_difference = abs(unname(beta_coi[[1L]]) - glmer_beta),
    glmer_tau_difference = abs(tau_hat - glmer_tau),
    error = "none"
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
run_id <- Sys.getenv(
  "C17_RUN_ID",
  "2026-08-01-lane-c-c17c1-zob-coi-intercept-recovery-run-1"
)
out <- file.path(root, "docs/dev-log/implementation-recovery", run_id)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

started_utc <- utc_now()
source_sha <- git_output(c("rev-parse", "HEAD"))
runner_sha256 <- sha256_file(script)
source_files <- c(
  "R/drmTMB.R", "R/methods.R", "R/profile.R", "src/drmTMB.cpp",
  "tests/testthat/test-zero-one-beta.R", basename(script)
)
source_files[[length(source_files)]] <- file.path("tools", basename(script))
source_blobs <- vapply(source_files, git_blob, character(1L))
dirty_state <- git_output(c("status", "--porcelain=v1", "--untracked-files=all"))
if (length(dirty_state) == 0L || identical(dirty_state, "")) dirty_state <- "<clean>"
writeLines(dirty_state, file.path(out, "dirty-state.txt"))

pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
if (!requireNamespace("lme4", quietly = TRUE)) {
  stop("C17-C1 requires lme4 for the boundary-only comparator")
}
namespace_path <- normalizePath(
  getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = FALSE
)
exact_command <- paste(
  "R_PROFILE_USER=/dev/null Rscript --no-init-file",
  "tools/run-lane-c-c17c1-zob-coi-intercept-recovery.R"
)
provenance <- data.frame(
  key = c(
    "run_status", "source_sha", "runner_sha256",
    paste0("git_blob:", source_files), "loaded_namespace_path",
    "utc_start", "utc_finish", "exact_command", "command_args",
    "dirty_state_path"
  ),
  value = c(
    "RUNNING", source_sha, runner_sha256, unname(source_blobs), namespace_path,
    started_utc, "", exact_command, paste(commandArgs(FALSE), collapse = " "),
    "dirty-state.txt"
  )
)
write_tsv(provenance, file.path(out, "provenance.tsv"))

heartbeat <- file(file.path(out, "progress.log"), open = "at")
on.exit(close(heartbeat), add = TRUE)
writeLines(paste(utc_now(), "START", source_sha, runner_sha256), heartbeat)
flush(heartbeat)
smoke_only <- identical(Sys.getenv("C17_SMOKE", "0"), "1")
grid <- expand.grid(
  M = if (smoke_only) 16L else c(16L, 32L, 64L),
  seed = if (smoke_only) 2026081701L else 2026081701:2026081704,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
attempts <- vector("list", nrow(grid))
for (i in seq_len(nrow(grid))) {
  attempts[[i]] <- fit_one(
    grid$M[[i]], grid$seed[[i]], source_sha, runner_sha256
  )
  writeLines(
    paste(
      utc_now(), "FIT", grid$M[[i]], grid$seed[[i]],
      attempts[[i]]$status
    ),
    heartbeat
  )
  flush(heartbeat)
}
attempts <- do.call(rbind, attempts)
write_tsv(attempts, file.path(out, "raw-attempts.tsv"))

summary_rows <- do.call(rbind, lapply(split(attempts, attempts$M), function(x) {
  diagnostics_pass <- with(
    x,
    status == "fit_ok" & convergence == 0L & pdHess &
      max_gradient <= 0.01 & !boundary_hit & mode_correlation > 0.45
  )
  data.frame(
    M = x$M[[1L]], attempts = nrow(x), diagnostics_pass = sum(diagnostics_pass),
    support_pass = sum(x$support_gate),
    mean_beta_mu0_error = mean(x$beta_mu0_error),
    mean_beta_mu1_error = mean(x$beta_mu1_error),
    mean_beta_zoi0_error = mean(x$beta_zoi0_error),
    mean_beta_coi0_error = mean(x$beta_coi0_error),
    mean_log_sigma_error = mean(x$log_sigma_error),
    mean_tau_relative_error = mean(x$tau_relative_error),
    max_glmer_difference = max(
      x$glmer_beta_difference, x$glmer_tau_difference, na.rm = TRUE
    )
  )
}))

if (smoke_only) {
  claim_pass <- NA
  summary_rows$role <- "local_smoke"
  summary_rows$decision <- "LOCAL_SMOKE_ONLY"
} else {
  claim <- summary_rows[summary_rows$M == 64L, , drop = FALSE]
  claim_pass <- with(
    claim,
    diagnostics_pass == 4L && support_pass == 4L &&
      mean_beta_mu0_error <= 0.20 && mean_beta_mu1_error <= 0.20 &&
      mean_beta_zoi0_error <= 0.20 && mean_beta_coi0_error <= 0.20 &&
      mean_log_sigma_error <= 0.15 && mean_tau_relative_error <= 0.40 &&
      max_glmer_difference <= 1e-3
  )
  summary_rows$role <- ifelse(
    summary_rows$M == 64L, "claim_rung", "diagnostic_rung"
  )
  summary_rows$decision <- ifelse(
    summary_rows$M == 64L,
    ifelse(claim_pass, "PASS_POINT_RECOVERY", "BLOCKED_POINT_RECOVERY"),
    "DIAGNOSTIC_ONLY"
  )
}
write_tsv(summary_rows, file.path(out, "summary.tsv"))

finished_utc <- utc_now()
provenance$value[provenance$key == "run_status"] <- "COMPLETE"
provenance$value[provenance$key == "utc_finish"] <- finished_utc
write_tsv(provenance, file.path(out, "provenance.tsv"))
writeLines(
  paste(
    finished_utc, "FINISH",
    if (smoke_only) {
      "LOCAL_SMOKE_ONLY"
    } else if (claim_pass) {
      "PASS_POINT_RECOVERY"
    } else {
      "BLOCKED_POINT_RECOVERY"
    }
  ),
  heartbeat
)
flush(heartbeat)
