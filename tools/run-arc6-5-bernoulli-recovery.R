#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out_dir <- sub("^--out-dir=", "", args[grepl("^--out-dir=", args)])
replicates <- as.integer(sub("^--replicates=", "", args[grepl("^--replicates=", args)]))
if (length(out_dir) != 1L || !nzchar(out_dir) || length(replicates) != 1L || is.na(replicates) || replicates < 1L) stop("Supply --out-dir=PATH and --replicates=INTEGER.", call. = FALSE)
if (dir.exists(out_dir) && length(list.files(out_dir, all.files = FALSE))) stop("Refusing to overwrite a non-empty recovery directory.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
devtools::load_all(quiet = TRUE)

conditions <- expand.grid(n = c(120L, 300L, 600L), prevalence = c("balanced", "asymmetric"), eta_truth = c(-0.5, 0, 0.5), replicate = seq_len(replicates), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
hold <- expand.grid(n = 120L, prevalence = "rare_hold", eta_truth = c(-0.7, 0.7), replicate = seq_len(max(20L, ceiling(replicates / 4))), KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
conditions <- rbind(transform(conditions, gate = "interior"), transform(hold, gate = "hold"))
conditions$seed <- 650000L + seq_len(nrow(conditions))

run_one <- function(condition) {
  set.seed(condition$seed)
  x <- stats::rnorm(condition$n)
  intercepts <- switch(condition$prevalence, balanced = c(stats::qlogis(0.4), stats::qlogis(0.6)), asymmetric = c(stats::qlogis(0.2), stats::qlogis(0.7)), rare_hold = c(stats::qlogis(0.04), stats::qlogis(0.5)))
  p_1 <- stats::plogis(intercepts[[1L]] + 0.35 * x)
  p_2 <- stats::plogis(intercepts[[2L]] - 0.30 * x)
  z_1 <- stats::rnorm(condition$n)
  z_2 <- condition$eta_truth * z_1 + sqrt(1 - condition$eta_truth^2) * stats::rnorm(condition$n)
  dat <- data.frame(x = x, y_1 = as.integer(z_1 > stats::qnorm(p_1, lower.tail = FALSE)), y_2 = as.integer(z_2 > stats::qnorm(p_2, lower.tail = FALSE)))
  started <- Sys.time()
  result <- tryCatch({
    fit_1 <- drmTMB(bf(mu = y_1 ~ x), binomial(), dat)
    fit_2 <- drmTMB(bf(mu = y_2 ~ x), binomial(), dat)
    association_fit <- associate_pairs(fit_1, fit_2, kernel = latent_normal(), association = ~1)
    list(stage_1 = "ok", status = association_fit$status, eta = association_fit$eta, alpha = association_fit$alpha, min_rectangle_mass = association_fit$diagnostics$response_patterns$min_rectangle_mass, message = "")
  }, error = function(e) list(stage_1 = "error", status = "error", eta = NA_real_, alpha = NA_real_, min_rectangle_mass = NA_real_, message = conditionMessage(e)))
  cbind(condition, as.data.frame(result, stringsAsFactors = FALSE), elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")), stringsAsFactors = FALSE)
}

attempts <- do.call(rbind, lapply(split(conditions, seq_len(nrow(conditions))), run_one))
attempts$eta_error <- attempts$eta - attempts$eta_truth
utils::write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
interior <- subset(attempts, gate == "interior")
groups <- split(interior, interaction(interior$n, interior$prevalence, interior$eta_truth, drop = TRUE))
summary <- do.call(rbind, lapply(groups, function(cell) {
  returned <- is.finite(cell$eta)
  data.frame(
    n = cell$n[[1L]], prevalence = cell$prevalence[[1L]], eta_truth = cell$eta_truth[[1L]],
    attempts = nrow(cell), returned = sum(returned),
    bias = if (any(returned)) mean(cell$eta_error[returned]) else NA_real_
  )
}))
summary$pass <- summary$returned == summary$attempts & abs(summary$bias) <= 0.10
utils::write.csv(summary, file.path(out_dir, "summary.csv"), row.names = FALSE)
utils::write.csv(hold, file.path(out_dir, "hold-design.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
writeLines(system("git rev-parse HEAD", intern = TRUE), file.path(out_dir, "git-sha.txt"))
if (!all(summary$pass)) quit(status = 1L)
