#!/usr/bin/env Rscript

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)

simulate_one <- function(seed, tau = .45) {
  set.seed(seed); ng <- 32L; ne <- 50L
  id <- factor(rep(paste0("g", seq_len(ng)), each = ne)); x <- rnorm(ng * ne)
  x <- x - ave(x, id, FUN = mean); x <- x / sd(x)
  b <- rnorm(ng, sd = tau); names(b) <- levels(id)
  mu <- plogis(-.15 + .35 * x); sigma <- exp(-1); zoi <- plogis(-1.15 + b[as.character(id)] * x); coi <- plogis(.1)
  boundary <- rbinom(length(x), 1L, zoi); y <- rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi)
  list(data = data.frame(y, x, id), b = b, n_zero = sum(y == 0), n_one = sum(y == 1), min_group_boundary = min(tapply(y %in% c(0, 1), id, sum)), min_group_interior = min(tapply(y > 0 & y < 1, id, sum)))
}

fit_one <- function(seed, sha, md5) {
  sim <- simulate_one(seed)
  fit <- tryCatch(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ x + (0 + x | id), coi ~ 1), family = drmTMB::zero_one_beta(), data = sim$data, control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))), error = identity)
  if (inherits(fit, "error")) return(data.frame(seed, source_sha = sha, runner_md5 = md5, status = "fit_error", error = conditionMessage(fit)))
  tau_hat <- unname(fit$sdpars$zoi[["(0 + x | id)"]]); u_hat <- ranef(fit, "zoi")$terms[["(0 + x | id)"]]
  data.frame(seed, source_sha = sha, runner_md5 = md5, status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), max_gradient = max(abs(fit$obj$gr(fit$opt$par)), na.rm = TRUE), tau_truth = .45, tau_hat, mode_correlation = cor(u_hat[names(sim$b)], sim$b), n_zero = sim$n_zero, n_one = sim$n_one, min_group_boundary = sim$min_group_boundary, min_group_interior = sim$min_group_interior, boundary_hit = !is.finite(tau_hat) || tau_hat <= .05 || tau_hat >= 2.5)
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L]); root <- normalizePath(file.path(dirname(script), "..")); setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
out <- file.path(root, "docs/dev-log/implementation-recovery/2026-07-30-lane-c-z6-zob-zoi-slope-local-run-1"); dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)); md5 <- unname(tools::md5sum(script)); attempts <- do.call(rbind, lapply(2026073801:2026073804, fit_one, sha = sha, md5 = md5)); write_tsv(attempts, file.path(out, "raw-attempts.tsv"))
ok <- if (all(c("convergence", "pdHess", "max_gradient", "boundary_hit", "mode_correlation", "min_group_boundary", "min_group_interior") %in% names(attempts))) with(attempts, status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= .01 & !boundary_hit & mode_correlation > .45 & min_group_boundary > 0L & min_group_interior > 0L) else rep(FALSE, nrow(attempts)); err <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / .45 - 1)) else NA_real_; decision <- if (all(ok) && is.finite(err) && err <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"; write_tsv(data.frame(planned_attempts = 4L, attempted_attempts = nrow(attempts), passed_attempts = sum(ok), mean_tau_relative_error = err, decision), file.path(out, "summary.tsv"))
