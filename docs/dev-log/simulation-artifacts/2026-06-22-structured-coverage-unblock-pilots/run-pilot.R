#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
})

out_dir <- file.path(
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-22-structured-coverage-unblock-pilots",
  "tables"
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

mcse_coverage <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n == 0L) {
    return(NA_real_)
  }
  p <- mean(x)
  sqrt(p * (1 - p) / n)
}

ci_estimate <- function(ci) {
  if ("estimate" %in% names(ci)) {
    return(ci$estimate)
  }
  rep(NA_real_, nrow(ci))
}

coverage_summary <- function(rows) {
  split_rows <- split(rows, rows$cell)
  pieces <- lapply(split_rows, function(x) {
    finite_interval <- is.finite(x$lower) & is.finite(x$upper)
    data.frame(
      cell = x$cell[[1L]],
      n_replicate = length(unique(x$replicate)),
      n_target_rows = nrow(x),
      n_fit_ok = sum(x$fit_ok),
      n_converged = sum(x$converged),
      n_pdhess = sum(x$pdHess),
      n_interval_rows = sum(!is.na(x$conf_status)),
      n_finite_intervals = sum(finite_interval),
      coverage = if (any(finite_interval)) {
        mean(x$covered[finite_interval])
      } else {
        NA_real_
      },
      coverage_mcse = mcse_coverage(x$covered[finite_interval]),
      claim_status = "pilot_only",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, pieces)
}

empty_row <- function(cell, replicate, target, truth, error_message) {
  data.frame(
    cell = cell,
    replicate = replicate,
    target = target,
    truth = truth,
    estimate = NA_real_,
    lower = NA_real_,
    upper = NA_real_,
    covered = NA,
    conf_status = NA_character_,
    fit_ok = FALSE,
    converged = FALSE,
    pdHess = FALSE,
    error_message = error_message,
    stringsAsFactors = FALSE
  )
}

fit_q1 <- function(replicate) {
  set.seed(202606220L + replicate)
  n_tip <- 12L
  tree <- ape::rcoal(n_tip)
  species <- tree$tip.label
  C <- ape::vcv(tree, corr = TRUE)
  sd_phylo <- 0.45
  sigma <- 0.55
  u <- as.numeric(t(chol(C)) %*% stats::rnorm(n_tip, sd = sd_phylo))
  y <- 0.2 + u + stats::rnorm(n_tip, sd = sigma)
  dat <- data.frame(species = species, y = y, stringsAsFactors = FALSE)
  form <- bf(y ~ 1 + phylo(1 | species, tree = tree), sigma ~ 1)
  target <- "sd:mu:phylo(1 | species)"

  fit <- try(drmTMB(form, family = gaussian(), data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(empty_row("q1_phylo_mu", replicate, target, sd_phylo, as.character(fit)))
  }
  ci <- try(stats::confint(fit, parm = target, method = "wald"), silent = TRUE)
  if (inherits(ci, "try-error")) {
    return(empty_row("q1_phylo_mu", replicate, target, sd_phylo, as.character(ci)))
  }
  data.frame(
    cell = "q1_phylo_mu",
    replicate = replicate,
    target = target,
    truth = sd_phylo,
    estimate = ci_estimate(ci),
    lower = ci$lower,
    upper = ci$upper,
    covered = is.finite(ci$lower) & is.finite(ci$upper) &
      ci$lower <= sd_phylo & sd_phylo <= ci$upper,
    conf_status = ci$conf.status,
    fit_ok = TRUE,
    converged = isTRUE(is_converged(fit)),
    pdHess = isTRUE(fit$sdr$pdHess),
    error_message = NA_character_,
    stringsAsFactors = FALSE
  )
}

fit_q2 <- function(replicate) {
  set.seed(202606320L + replicate)
  n_tip <- 16L
  m <- 2L
  tree <- ape::rcoal(n_tip)
  species <- tree$tip.label
  C <- ape::vcv(tree, corr = TRUE)
  Sigma <- matrix(c(0.45^2, 0.08, 0.08, 0.40^2), 2L, 2L)
  A <- t(chol(C)) %*% matrix(stats::rnorm(n_tip * 2L), n_tip, 2L) %*%
    t(chol(Sigma))
  rows <- rep(seq_len(n_tip), each = m)
  y1 <- 0.2 + A[rows, 1L] + stats::rnorm(length(rows), sd = 0.55)
  y2 <- -0.1 + A[rows, 2L] + stats::rnorm(length(rows), sd = 0.60)
  dat <- data.frame(species = species[rows], y1 = y1, y2 = y2)
  form <- bf(
    mu1 = y1 ~ 1 + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ 1 + phylo(1 | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  targets <- c(
    "sd:mu:mu1:phylo(1 | p | species)",
    "sd:mu:mu2:phylo(1 | p | species)"
  )
  truths <- c(0.45, 0.40)

  fit <- try(drmTMB(form, family = biv_gaussian(), data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(do.call(rbind, Map(
      function(target, truth) {
        empty_row("q2_phylo_mu", replicate, target, truth, as.character(fit))
      },
      targets,
      truths
    )))
  }
  ci <- try(stats::confint(fit, parm = targets, method = "wald"), silent = TRUE)
  if (inherits(ci, "try-error")) {
    return(do.call(rbind, Map(
      function(target, truth) {
        empty_row("q2_phylo_mu", replicate, target, truth, as.character(ci))
      },
      targets,
      truths
    )))
  }
  data.frame(
    cell = "q2_phylo_mu",
    replicate = replicate,
    target = targets,
    truth = truths,
    estimate = ci_estimate(ci),
    lower = ci$lower,
    upper = ci$upper,
    covered = is.finite(ci$lower) & is.finite(ci$upper) &
      ci$lower <= truths & truths <= ci$upper,
    conf_status = ci$conf.status,
    fit_ok = TRUE,
    converged = isTRUE(is_converged(fit)),
    pdHess = isTRUE(fit$sdr$pdHess),
    error_message = NA_character_,
    stringsAsFactors = FALSE
  )
}

fit_q4 <- function(replicate) {
  set.seed(202606420L + replicate)
  n_tip <- 10L
  m <- 2L
  tree <- ape::rcoal(n_tip)
  species <- tree$tip.label
  C <- ape::vcv(tree, corr = TRUE)
  truths <- c(0.40, 0.35, 0.20, 0.20)
  Sigma <- diag(truths^2)
  A <- t(chol(C)) %*% matrix(stats::rnorm(n_tip * 4L), n_tip, 4L) %*%
    t(chol(Sigma))
  rows <- rep(seq_len(n_tip), each = m)
  x <- stats::rnorm(length(rows))
  y1 <- 0.2 + 0.2 * x + A[rows, 1L] +
    stats::rnorm(length(rows), sd = exp(-0.3 + A[rows, 3L]))
  y2 <- -0.1 + 0.1 * x + A[rows, 2L] +
    stats::rnorm(length(rows), sd = exp(-0.4 + A[rows, 4L]))
  dat <- data.frame(species = species[rows], x = x, y1 = y1, y2 = y2)
  form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  targets <- c(
    "sd:mu:mu1:phylo(1 | p | species)",
    "sd:mu:mu2:phylo(1 | p | species)",
    "sd:mu:sigma1:phylo(1 | p | species)",
    "sd:mu:sigma2:phylo(1 | p | species)"
  )

  fit <- try(drmTMB(form, family = biv_gaussian(), data = dat), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(do.call(rbind, Map(
      function(target, truth) {
        empty_row("q4_phylo_all_four", replicate, target, truth, as.character(fit))
      },
      targets,
      truths
    )))
  }
  ci <- try(stats::confint(fit, parm = targets, method = "wald"), silent = TRUE)
  if (inherits(ci, "try-error")) {
    return(do.call(rbind, Map(
      function(target, truth) {
        empty_row("q4_phylo_all_four", replicate, target, truth, as.character(ci))
      },
      targets,
      truths
    )))
  }
  data.frame(
    cell = "q4_phylo_all_four",
    replicate = replicate,
    target = targets,
    truth = truths,
    estimate = ci_estimate(ci),
    lower = ci$lower,
    upper = ci$upper,
    covered = is.finite(ci$lower) & is.finite(ci$upper) &
      ci$lower <= truths & truths <= ci$upper,
    conf_status = ci$conf.status,
    fit_ok = TRUE,
    converged = isTRUE(is_converged(fit)),
    pdHess = isTRUE(fit$sdr$pdHess),
    error_message = NA_character_,
    stringsAsFactors = FALSE
  )
}

rows <- do.call(
  rbind,
  c(
    lapply(seq_len(3L), fit_q1),
    lapply(seq_len(3L), fit_q2),
    lapply(seq_len(2L), fit_q4)
  )
)
summary <- coverage_summary(rows)

write.csv(
  rows,
  file.path(out_dir, "structured-coverage-pilot-rows.csv"),
  row.names = FALSE
)
write.csv(
  summary,
  file.path(out_dir, "structured-coverage-pilot-summary.csv"),
  row.names = FALSE
)

print(summary)
