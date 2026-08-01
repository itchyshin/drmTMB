#!/usr/bin/env Rscript

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")

simulate_one <- function(seed, endpoint, n_group = 32L, n_each = 50L, tau = .55) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(n_group)), each = n_each))
  x <- stats::rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  field <- stats::rnorm(n_group, sd = tau)
  names(field) <- levels(id)
  eta_mu <- -.10 + .35 * x
  log_sigma <- rep(log(.45), length(id))
  if (identical(endpoint, "mu")) eta_mu <- eta_mu + field[as.character(id)]
  if (identical(endpoint, "sigma")) log_sigma <- log_sigma + field[as.character(id)]
  mu <- 1e-12 + (1 - 2e-12) * stats::plogis(eta_mu)
  sigma <- exp(log_sigma)
  boundary <- stats::rbinom(length(id), 1L, .12)
  y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(sum(boundary == 1L), 1L, .45)
  list(data = data.frame(y, x, id), field = field)
}

fit_one <- function(seed, endpoint, sha, runner_md5) {
  sim <- simulate_one(seed, endpoint)
  form <- if (identical(endpoint, "mu")) {
    drmTMB::bf(y ~ x + (1 | id), sigma ~ 1, zoi ~ 1, coi ~ 1)
  } else {
    drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1)
  }
  fit <- tryCatch(
    drmTMB::drmTMB(form, family = drmTMB::zero_one_beta(), data = sim$data,
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))),
    error = identity
  )
  out <- data.frame(endpoint, seed, source_sha = sha, runner_md5, status = "fit_error",
    convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_, tau_truth = .55,
    tau_hat = NA_real_, mode_correlation = NA_real_, boundary_hit = NA)
  if (inherits(fit, "error")) return(out)
  key <- if (identical(endpoint, "mu")) "mu" else "sigma"
  term <- "(1 | id)"
  mode <- ranef(fit, paste0("iid_", key))$terms[[term]]
  out$status <- "fit_ok"
  out$convergence <- fit$opt$convergence
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$max_gradient <- max(abs(fit$obj$gr(fit$opt$par)))
  out$tau_hat <- fit$sdpars[[key]][[term]]
  out$mode_correlation <- stats::cor(mode[names(sim$field)], sim$field)
  out$boundary_hit <- !is.finite(out$tau_hat) || out$tau_hat <= .05 || out$tau_hat >= 2.5
  out
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
out <- Sys.getenv("DRMTMB_RECOVERY_OUT", unset = file.path(root, "docs/dev-log/implementation-recovery/2026-08-01-lane-c-c16-zob-iid-controls"))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_md5 <- unname(tools::md5sum(script))
attempts <- do.call(rbind, c(
  lapply(2026080101:2026080104, fit_one, endpoint = "mu", sha = sha, runner_md5 = runner_md5),
  lapply(2026080111:2026080114, fit_one, endpoint = "sigma", sha = sha, runner_md5 = runner_md5)
))
write_tsv(attempts, file.path(out, "raw-attempts.tsv"))
pass <- with(attempts, status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= .01 & !boundary_hit & mode_correlation > .45)
summary <- aggregate(pass, list(endpoint = attempts$endpoint), function(x) sum(x))
names(summary)[2L] <- "passed_attempts"
summary$planned_attempts <- 4L
summary$decision <- ifelse(summary$passed_attempts == 4L, "PASS_IID_FIT_CONTROL", "BLOCKED_IID_FIT_CONTROL")
write_tsv(summary, file.path(out, "summary.tsv"))
