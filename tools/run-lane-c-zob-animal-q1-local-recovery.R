#!/usr/bin/env Rscript

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
clean <- function(x) trimws(gsub("[\r\n\t]+", " ", paste(x, collapse = "; ")))

new_data <- function(seed, n_group = 32L, n_each = 30L) {
  set.seed(seed); labels <- paste0("sp", seq_len(n_group))
  Ainv <- diag(2, n_group); Ainv[cbind(seq_len(n_group - 1L), 2:n_group)] <- -.5; Ainv[cbind(2:n_group, seq_len(n_group - 1L))] <- -.5
  rownames(Ainv) <- colnames(Ainv) <- rev(labels)
  u <- as.numeric(t(chol(solve(Ainv))) %*% rnorm(n_group, sd = .55)); names(u) <- labels
  data <- data.frame(species = rep(labels, each = n_each), x = rnorm(n_group * n_each))
  data$x <- data$x - ave(data$x, data$species, FUN = mean); data$x <- data$x / sd(data$x)
  mu <- plogis(-.10 + .35 * data$x + u[data$species]); boundary <- rbinom(nrow(data), 1, .12)
  data$y <- ifelse(boundary == 1, rbinom(nrow(data), 1, .45), rbeta(nrow(data), mu / .45^2, (1 - mu) / .45^2))
  list(data = data, Ainv = Ainv, digest = digest::digest(list(Ainv = Ainv, x = data$x, y = data$y)))
}

run_one <- function(seed, source_sha, runner_sha) {
  out <- data.frame(seed, source_sha, runner_sha, formula = "y ~ x + animal(1 | species, Ainv = Ainv)", tau_truth = .55, beta0_truth = -.10, beta1_truth = .35, sigma_truth = .45, zoi_truth = .12, coi_truth = .45, dgp_digest = NA_character_, status = NA_character_, warning = NA_character_, convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_, boundary_hit = NA, beta0_hat = NA_real_, beta1_hat = NA_real_, sigma_hat = NA_real_, zoi_hat = NA_real_, coi_hat = NA_real_, tau_hat = NA_real_)
  sim <- new_data(seed); out$dgp_digest <- sim$digest; warnings <- character()
  fit <- tryCatch(withCallingHandlers(drmTMB::drmTMB(drmTMB::bf(y ~ x + animal(1 | species, Ainv = sim$Ainv)), family = drmTMB::zero_one_beta(), data = sim$data, control = list(eval.max = 1000, iter.max = 1000)), warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }), error = identity)
  if (inherits(fit, "error")) { out$status <- "fit_error"; out$warning <- clean(c(warnings, conditionMessage(fit))); return(out) }
  grad <- fit$obj$gr(fit$opt$par); out$status <- "fit_ok"; out$warning <- clean(warnings); out$convergence <- fit$opt$convergence; out$pdHess <- isTRUE(fit$sdr$pdHess); out$max_gradient <- max(abs(grad))
  out$beta0_hat <- fit$coefficients$mu[["(Intercept)"]]; out$beta1_hat <- fit$coefficients$mu[["x"]]; out$sigma_hat <- exp(fit$coefficients$sigma[["(Intercept)"]]); out$zoi_hat <- plogis(fit$coefficients$zoi[["(Intercept)"]]); out$coi_hat <- plogis(fit$coefficients$coi[["(Intercept)"]]); out$tau_hat <- fit$sdpars$mu[["animal(1 | species)"]]
  out$boundary_hit <- !all(is.finite(unlist(out[c("beta0_hat", "beta1_hat", "sigma_hat", "zoi_hat", "coi_hat", "tau_hat")]))) || out$tau_hat <= .05 || out$tau_hat >= 2.5
  out
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]); root <- normalizePath(file.path(dirname(script), "..")); setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
dir <- Sys.getenv("DRMTMB_RECOVERY_OUT", unset = file.path(root, "docs/dev-log/implementation-recovery/2026-07-29-lane-c-zob-animal-q1-local-run-1")); dir.create(dir, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE)); runner_sha <- unname(tools::md5sum(script)); attempts <- do.call(rbind, lapply(2026073001:2026073004, run_one, source_sha = sha, runner_sha = runner_sha)); write_tsv(attempts, file.path(dir, "raw-attempts.tsv"))
valid <- with(attempts, status == "fit_ok" & convergence == 0L & pdHess & !boundary_hit)
means <- if (any(valid)) colMeans(attempts[valid, c("beta0_hat", "beta1_hat", "sigma_hat", "zoi_hat", "coi_hat", "tau_hat")]) else rep(NA_real_, 6)
pass <- all(valid) && sum(valid) == 4L && abs(means[1] + .10) <= .20 && abs(means[2] - .35) <= .20 && abs(means[3] - .45) <= .12 && abs(means[4] - .12) <= .08 && abs(means[5] - .45) <= .15 && abs(means[6] / .55 - 1) <= .40
write_tsv(data.frame(planned_attempts = 4L, attempted_attempts = nrow(attempts), passed_attempts = sum(valid), decision = if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE", mean_tau_hat = means[6]), file.path(dir, "summary.tsv"))
