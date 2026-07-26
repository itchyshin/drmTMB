#!/usr/bin/env Rscript
# Deterministic external oracle for the paired scalar A1 ML-REML diagnostic.
# It is deliberately a fixture gate, not a simulation campaign.

suppressPackageStartupMessages({
  library(drmTMB)
  library(lme4)
})

file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_path <- if (length(file_arg)) normalizePath(sub("^--file=", "", file_arg[[1L]])) else NA_character_
script_dir <- Sys.getenv("A1_ML_REML_ARTIFACT_DIR", unset = if (is.na(script_path)) getwd() else dirname(script_path))
source(file.path(script_dir, "a1_ml_reml_common.R"))

a1_ml_reml_lme4_profile <- function(fit) {
  ci <- suppressWarnings(try(stats::confint(fit, method = "profile"), silent = TRUE))
  if (inherits(ci, "try-error") || !is.matrix(ci)) return(c(lower = NA_real_, upper = NA_real_, status = "error"))
  row <- grep("^\\.sig01$|^sd_\\(Intercept\\)\\|g$", rownames(ci), value = TRUE)
  if (length(row) != 1L) return(c(lower = NA_real_, upper = NA_real_, status = "target_missing"))
  c(lower = unname(ci[row, 1L]), upper = unname(ci[row, 2L]), status = "valid")
}

# Dense Gaussian restricted likelihood for the scalar iid random-intercept
# model.  This is the REML endpoint oracle because lme4 2.0.1's profile() path
# returns the ML .sig01 curve even when the fitted merMod has REML = TRUE.
a1_ml_reml_direct_reml_nll <- function(log_par, y, X, Z) {
  tau <- exp(log_par[[1L]])
  sigma <- exp(log_par[[2L]])
  V <- tcrossprod(Z) * tau^2 + diag(sigma^2, nrow(Z))
  L <- chol(V)
  V_inv_X <- backsolve(L, forwardsolve(t(L), X))
  V_inv_y <- backsolve(L, forwardsolve(t(L), y))
  XtVinvX <- crossprod(X, V_inv_X)
  beta <- solve(XtVinvX, crossprod(X, V_inv_y))
  residual <- y - X %*% beta
  V_inv_residual <- backsolve(L, forwardsolve(t(L), residual))
  0.5 * (
    2 * sum(log(diag(L))) +
      as.numeric(determinant(XtVinvX, logarithm = TRUE)$modulus) +
      sum(residual * V_inv_residual) +
      (length(y) - ncol(X)) * log(2 * pi)
  )
}

a1_ml_reml_direct_profile <- function(y, X, Z, start_tau, start_sigma) {
  optimum <- nlminb(
    log(c(start_tau, start_sigma)), a1_ml_reml_direct_reml_nll,
    y = y, X = X, Z = Z
  )
  if (optimum$convergence != 0L) return(c(lower = NA_real_, upper = NA_real_, status = "opt_error"))
  cut <- optimum$objective + stats::qchisq(0.95, 1L) / 2
  profile_nll <- function(log_tau) {
    stats::optimize(
      function(log_sigma) a1_ml_reml_direct_reml_nll(c(log_tau, log_sigma), y, X, Z),
      interval = c(log(0.01), log(4))
    )$objective
  }
  lower <- try(stats::uniroot(function(z) profile_nll(z) - cut, c(log(0.001), optimum$par[[1L]]))$root, silent = TRUE)
  upper <- try(stats::uniroot(function(z) profile_nll(z) - cut, c(optimum$par[[1L]], log(5)))$root, silent = TRUE)
  if (inherits(lower, "try-error") || inherits(upper, "try-error")) {
    return(c(lower = NA_real_, upper = NA_real_, status = "endpoint_error"))
  }
  c(lower = exp(lower), upper = exp(upper), status = "valid")
}

a1_ml_reml_oracle <- function() {
  cells <- a1_ml_reml_cells()
  out <- vector("list", nrow(cells) * 2L)
  k <- 0L
  for (i in seq_len(nrow(cells))) {
    cell <- cells[i, , drop = FALSE]
    set.seed(202607290L + i)
    g <- factor(rep(seq_len(cell$n_groups), each = cell$n_per_group))
    x <- rnorm(length(g))
    u <- rnorm(cell$n_groups, 0, cell$truth_sd)
    y <- 1 + 0.5 * x + u[as.integer(g)] + rnorm(length(g), 0, 0.7)
    dat <- data.frame(y = y, x = x, g = g)
    for (estimator in c("ML", "REML")) {
      k <- k + 1L
      reml <- identical(estimator, "REML")
      drm <- suppressWarnings(try(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), gaussian(), dat, REML = reml), silent = TRUE))
      lme <- suppressWarnings(try(lme4::lmer(y ~ x + (1 | g), data = dat, REML = reml), silent = TRUE))
      base <- list(cell_id = cell$cell_id, n_groups = cell$n_groups, estimator = estimator)
      if (inherits(drm, "try-error") || inherits(lme, "try-error")) {
        out[[k]] <- as.data.frame(c(base, list(oracle_status = "fit_error", drm_logLik = NA_real_, lme4_logLik = NA_real_, drm_estimate = NA_real_, lme4_estimate = NA_real_, drm_lower = NA_real_, drm_upper = NA_real_, lme4_lower = NA_real_, lme4_upper = NA_real_, logLik_delta = NA_real_, estimate_delta = NA_real_, profile_lower_delta = NA_real_, profile_upper_delta = NA_real_, endpoint_tolerance = NA_real_)), stringsAsFactors = FALSE)
        next
      }
      drm_est <- summary(drm)$parameters
      drm_est <- drm_est$estimate[drm_est$parm == "sd:mu:(1 | g)"]
      drm_ci <- a1_ml_reml_interval_row(suppressWarnings(try(stats::confint(drm, parm = "variance_components", method = "profile", profile_engine = "auto"), silent = TRUE)), "sd:mu:(1 | g)", cell$truth_sd, "profile")
      lme_ci <- a1_ml_reml_lme4_profile(lme)
      lme_est <- unname(attr(lme4::VarCorr(lme)$g, "stddev")[[1L]])
      if (reml) {
        lme_ml <- suppressWarnings(try(lme4::lmer(y ~ x + (1 | g), data = dat, REML = FALSE), silent = TRUE))
        lme_ml_ci <- if (inherits(lme_ml, "try-error")) c(lower = NA_real_, upper = NA_real_, status = "error") else a1_ml_reml_lme4_profile(lme_ml)
        lme4_reml_profile_ml_endpoint_delta <- max(
          abs(as.numeric(lme_ci[["lower"]]) - as.numeric(lme_ml_ci[["lower"]])),
          abs(as.numeric(lme_ci[["upper"]]) - as.numeric(lme_ml_ci[["upper"]]))
        )
        lme4_reml_profile_incompatible <- identical(lme_ci[["status"]], "valid") &&
          identical(lme_ml_ci[["status"]], "valid") && is.finite(lme4_reml_profile_ml_endpoint_delta) &&
          lme4_reml_profile_ml_endpoint_delta <= 1e-8
        X <- stats::model.matrix(~ x, dat)
        Z <- stats::model.matrix(~ 0 + g, dat)
        sigma_est <- summary(drm)$parameters
        sigma_est <- sigma_est$estimate[sigma_est$parm == "sigma"]
        endpoint_ref <- a1_ml_reml_direct_profile(dat$y, X, Z, as.numeric(drm_est), as.numeric(sigma_est))
        endpoint_reference <- "direct_reml"
        endpoint_tol <- 2e-4
      } else {
        lme4_reml_profile_ml_endpoint_delta <- NA_real_
        lme4_reml_profile_incompatible <- NA
        endpoint_ref <- lme_ci
        endpoint_reference <- "lme4_ml_profile"
        endpoint_tol <- if (identical(lme_ci[["status"]], "valid")) max(0.01, 0.02 * (as.numeric(lme_ci[["upper"]]) - as.numeric(lme_ci[["lower"]]))) else NA_real_
      }
      ll_delta <- abs(as.numeric(stats::logLik(drm)) - as.numeric(stats::logLik(lme)))
      est_delta <- abs(as.numeric(drm_est) - lme_est)
      lo_delta <- abs(drm_ci$lower - as.numeric(endpoint_ref[["lower"]]))
      hi_delta <- abs(drm_ci$upper - as.numeric(endpoint_ref[["upper"]]))
      passed <- identical(drm_ci$status, "valid") && identical(endpoint_ref[["status"]], "valid") &&
        is.finite(ll_delta) && is.finite(est_delta) && is.finite(lo_delta) && is.finite(hi_delta) &&
        ll_delta <= 1e-5 && est_delta <= 1e-5 && lo_delta <= endpoint_tol && hi_delta <= endpoint_tol
      out[[k]] <- as.data.frame(c(base, list(
        oracle_status = if (passed) "pass" else "fail", drm_logLik = as.numeric(stats::logLik(drm)), lme4_logLik = as.numeric(stats::logLik(lme)),
        drm_estimate = as.numeric(drm_est), lme4_estimate = lme_est,
        endpoint_reference = endpoint_reference,
        lme4_reml_profile_incompatible = lme4_reml_profile_incompatible,
        lme4_reml_profile_ml_endpoint_delta = lme4_reml_profile_ml_endpoint_delta,
        drm_lower = drm_ci$lower, drm_upper = drm_ci$upper,
        reference_lower = as.numeric(endpoint_ref[["lower"]]), reference_upper = as.numeric(endpoint_ref[["upper"]]),
        logLik_delta = ll_delta, estimate_delta = est_delta, profile_lower_delta = lo_delta,
        profile_upper_delta = hi_delta, endpoint_tolerance = endpoint_tol
      )), stringsAsFactors = FALSE)
    }
  }
  ans <- do.call(rbind, out)
  rownames(ans) <- NULL
  ans
}

if (identical(environment(), globalenv()) && !interactive()) {
  result <- a1_ml_reml_oracle()
  print(result, row.names = FALSE)
  if (!a1_ml_reml_oracle_gate_pass(result$oracle_status)) stop("A1 ML-REML oracle gate failed.", call. = FALSE)
}
