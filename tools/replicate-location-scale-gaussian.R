#!/usr/bin/env Rscript

# Optional local harness for Gaussian location-scale comparator checks.
# It uses simulated paper-shaped examples so the harness remains reproducible
# without bundling external tutorial data.

usage <- function() {
  cat(
    paste(
      "Usage: Rscript tools/replicate-location-scale-gaussian.R [options]",
      "",
      "Options:",
      "  --output PATH      CSV result table path.",
      "                     Default: docs/dev-log/comparator-results/gaussian-location-scale-glmmtmb-current.csv",
      "  --tolerance VALUE  Numeric tolerance for implemented comparator rows.",
      "                     Default: 1e-4",
      "  --help             Show this help message.",
      "",
      "The output table contains implemented comparator rows plus blocked future",
      "individual-difference rows so the harness records both evidence and scope.",
      sep = "\n"
    ),
    "\n"
  )
}

parse_args <- function(args) {
  out <- list(
    output = "docs/dev-log/comparator-results/gaussian-location-scale-glmmtmb-current.csv",
    tolerance = 1e-4,
    help = FALSE
  )
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (identical(arg, "--help") || identical(arg, "-h")) {
      out$help <- TRUE
      i <- i + 1L
      next
    }
    if (identical(arg, "--output")) {
      if (i == length(args)) {
        stop("--output requires a path.", call. = FALSE)
      }
      out$output <- args[[i + 1L]]
      i <- i + 2L
      next
    }
    if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
      i <- i + 1L
      next
    }
    if (identical(arg, "--tolerance")) {
      if (i == length(args)) {
        stop("--tolerance requires a numeric value.", call. = FALSE)
      }
      out$tolerance <- as.numeric(args[[i + 1L]])
      i <- i + 2L
      next
    }
    if (startsWith(arg, "--tolerance=")) {
      out$tolerance <- as.numeric(sub("^--tolerance=", "", arg))
      i <- i + 1L
      next
    }
    stop("Unknown argument: ", arg, call. = FALSE)
  }
  if (
    !is.character(out$output) || length(out$output) != 1L || !nzchar(out$output)
  ) {
    stop("--output must be a non-empty path.", call. = FALSE)
  }
  if (!is.finite(out$tolerance) || out$tolerance <= 0) {
    stop("--tolerance must be a positive finite number.", call. = FALSE)
  }
  out
}

load_drmTMB <- function() {
  if (
    file.exists("DESCRIPTION") &&
      dir.exists("R") &&
      requireNamespace("devtools", quietly = TRUE)
  ) {
    devtools::load_all(quiet = TRUE)
    return(invisible(TRUE))
  }
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(invisible(TRUE))
  }
  stop(
    "Install drmTMB or run this script from the package root with devtools available.",
    call. = FALSE
  )
}

require_glmmTMB <- function() {
  ok <- suppressWarnings(requireNamespace("glmmTMB", quietly = TRUE))
  if (!ok) {
    stop(
      "Package glmmTMB is required for this optional comparator harness.",
      call. = FALSE
    )
  }
}

simulate_fixed_location_scale <- function(seed = 20260522, n = 360) {
  set.seed(seed)
  dat <- data.frame(
    sex = factor(rep(c("female", "male"), length.out = n)),
    treatment = factor(rep(c("control", "treated"), each = 2L, length.out = n))
  )
  X <- stats::model.matrix(~ sex * treatment, dat)
  beta_mu <- c(
    `(Intercept)` = 0.20,
    sexmale = 0.12,
    treatmenttreated = -0.18,
    `sexmale:treatmenttreated` = 0.30
  )
  beta_sigma <- c(
    `(Intercept)` = log(0.45),
    sexmale = 0.10,
    treatmenttreated = 0.25,
    `sexmale:treatmenttreated` = -0.12
  )
  mu <- as.vector(X %*% beta_mu)
  sigma <- exp(as.vector(X %*% beta_sigma))
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)
  dat
}

simulate_random_intercept_location_scale <- function(seed = 20260523) {
  set.seed(seed)
  n_nest <- 28
  n_each <- 8
  n <- n_nest * n_each
  dat <- data.frame(
    nest = factor(rep(seq_len(n_nest), each = n_each)),
    rank = factor(rep(c("low", "high"), length.out = n))
  )
  beta_mu <- c(`(Intercept)` = 0.15, rankhigh = 0.35)
  beta_sigma <- c(`(Intercept)` = log(0.40), rankhigh = -0.18)
  u_nest <- stats::rnorm(n_nest, sd = 0.32)
  X <- stats::model.matrix(~rank, dat)
  mu <- as.vector(X %*% beta_mu) + u_nest[dat$nest]
  sigma <- exp(as.vector(X %*% beta_sigma))
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)
  dat
}

compare_fixed_case <- function() {
  dat <- simulate_fixed_location_scale()
  fit_drm <- drmTMB(
    bf(y ~ sex * treatment, sigma ~ sex * treatment),
    family = gaussian(),
    data = dat
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ sex * treatment,
    dispformula = ~ sex * treatment,
    family = gaussian(),
    data = dat
  ))
  summarize_comparison("fixed_location_scale", fit_drm, fit_glmm)
}

compare_random_case <- function() {
  dat <- simulate_random_intercept_location_scale()
  fit_drm <- drmTMB(
    bf(y ~ rank + (1 | nest), sigma ~ rank),
    family = gaussian(),
    data = dat
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ rank + (1 | nest),
    dispformula = ~rank,
    family = gaussian(),
    data = dat
  ))
  summarize_comparison("random_intercept_location_scale", fit_drm, fit_glmm)
}

summarize_comparison <- function(case, fit_drm, fit_glmm) {
  vc <- glmmTMB::VarCorr(fit_glmm)$cond
  sd_diff <- NA_real_
  if (length(vc) > 0L && length(fit_drm$sdpars$mu) > 0L) {
    sd_diff <- max(abs(
      unname(fit_drm$sdpars$mu) -
        unname(unlist(lapply(vc, attr, "stddev")))
    ))
  }
  data.frame(
    case = case,
    comparison_status = "implemented",
    comparator = "glmmTMB",
    blocked_by = NA_character_,
    scale_note = "drmTMB sigma coefficients match glmmTMB dispersion coefficients on the log-SD scale; variance-facing summaries should square response-scale sigma.",
    max_abs_mu_coef_diff = max(abs(
      unname(coef(fit_drm, "mu")) -
        unname(glmmTMB::fixef(fit_glmm)$cond)
    )),
    max_abs_sigma_coef_diff = max(abs(
      unname(coef(fit_drm, "sigma")) -
        unname(glmmTMB::fixef(fit_glmm)$disp)
    )),
    max_abs_mu_sd_diff = sd_diff,
    abs_loglik_diff = abs(
      as.numeric(stats::logLik(fit_drm)) -
        as.numeric(stats::logLik(fit_glmm))
    ),
    stringsAsFactors = FALSE
  )
}

blocked_comparisons <- function() {
  data.frame(
    case = c(
      "shared_mu_sigma_covariance_block",
      "bivariate_group_level_covariance_block",
      "non_gaussian_location_scale_random_effects"
    ),
    comparison_status = c("blocked", "blocked", "blocked"),
    comparator = c(NA_character_, NA_character_, NA_character_),
    blocked_by = c(
      "cross-formula labelled covariance blocks are planned in issue #5",
      "bivariate group-level random effects are planned in issue #5",
      "non-Gaussian random-effect location-scale paths are not implemented yet"
    ),
    scale_note = c(
      "would compare correlations among individual mean and residual-scale effects",
      "would compare group-level correlations separately from residual rho12",
      "would require family-specific random-effect likelihoods before comparators"
    ),
    max_abs_mu_coef_diff = NA_real_,
    max_abs_sigma_coef_diff = NA_real_,
    max_abs_mu_sd_diff = NA_real_,
    abs_loglik_diff = NA_real_,
    stringsAsFactors = FALSE
  )
}

write_results <- function(out, output) {
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(out, output, row.names = FALSE)
  message("Wrote comparator result table to ", output)
}

main <- function(tolerance = 1e-4, output = NULL) {
  load_drmTMB()
  require_glmmTMB()
  implemented <- rbind(compare_fixed_case(), compare_random_case())
  implemented$passed <- with(
    implemented,
    max_abs_mu_coef_diff < tolerance &
      max_abs_sigma_coef_diff < tolerance &
      (is.na(max_abs_mu_sd_diff) | max_abs_mu_sd_diff < tolerance) &
      abs_loglik_diff < tolerance
  )
  blocked <- blocked_comparisons()
  blocked$passed <- NA
  out <- rbind(implemented, blocked)
  print(out, row.names = FALSE)
  if (!is.null(output)) {
    write_results(out, output)
  }
  if (!all(implemented$passed)) {
    stop(
      "One or more Gaussian location-scale comparator checks failed.",
      call. = FALSE
    )
  }
  invisible(out)
}

if (identical(environment(), globalenv())) {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  if (isTRUE(args$help)) {
    usage()
    quit(status = 0L)
  }
  main(tolerance = args$tolerance, output = args$output)
}
