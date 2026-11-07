#!/usr/bin/env Rscript
# Candidate-only adapter. The independent oracle owns reference calculations.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("usage: r-native.R fixture.json output.json")
if (identical(Sys.getenv("DRM_PRIOR_USE_INSTALLED"), "1")) {
  lib <- Sys.getenv("DRM_PRIOR_R_LIB")
  if (!nzchar(lib)) stop("DRM_PRIOR_R_LIB must identify the isolated package library")
  dep_lib <- Sys.getenv("DRM_PRIOR_DEP_LIB")
  .libPaths(c(lib, if (nzchar(dep_lib)) dep_lib, .libPaths()))
  suppressPackageStartupMessages(library(drmTMB, lib.loc = lib))
  if (!identical(normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path")),
                 normalizePath(file.path(lib, "drmTMB")))) stop("wrong drmTMB namespace")
} else {
  suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
}
f <- jsonlite::fromJSON(args[[1]], simplifyVector = TRUE)
d <- as.data.frame(f$raw_data)
d$f <- factor(d$f, levels = c("A", "B"))
d$group <- factor(d$group)
x <- model.matrix(as.formula(f$formula$mean), d)
w <- model.matrix(as.formula(f$formula$scale), d)
same_matrix <- function(a, b) identical(dim(a), dim(b)) &&
  isTRUE(all.equal(as.numeric(a), as.numeric(b), tolerance = 1e-14))
if (!same_matrix(x, f$X) || !same_matrix(w, f$W)) stop("fixture model-matrix mismatch")
mean_expr <- paste0(f$formula$mean, " + ", f$formula$random_intercept)
fm <- eval(parse(text = sprintf("bf(mu = %s, sigma = %s)", mean_expr, f$formula$scale)))
pr <- lapply(seq_len(if (is.data.frame(f$priors)) nrow(f$priors) else 0L), function(i) {
  p <- f$priors[i, ]
  block <- if (p$block == "beta") "mu" else "sigma"
  col <- if (block == "mu") colnames(x)[p$index + 1L] else colnames(w)[p$index + 1L]
  if (p$kind == "normal") drm_prior_normal(block, col, mean = p$mean, sd = p$sd)
  else drm_prior_ridge(block, col, lambda = p$lam)
})
priors <- if (length(pr)) do.call(drm_priors, pr) else NULL
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(777)
fit <- drmTMB(fm, data = d, priors = priors,
              control = drm_control(se = FALSE, logsigma_clamp = NULL, multi_start = 5))
par <- fit$opt$par
idx <- c(which(names(par) == "beta_mu"), which(names(par) == "beta_sigma"), which(names(par) == "log_sd_mu"))
if (length(idx) != ncol(x) + ncol(w) + 1L || length(idx) != length(par)) stop(paste("unexpected parameters", paste(names(par), collapse = ",")))
dll <- getLoadedDLLs()[["drmTMB"]][["path"]]
result <- list(schema_version = 1, id = f$id, engine = "R/TMB",
  dll = dll, dll_sha256 = strsplit(system2("shasum", c("-a", "256", shQuote(dll)), stdout = TRUE), "[[:space:]]+")[[1]][1],
  solver_configuration = list(multi_start = 5L, caller_seed = 777L,
    internal_perturbation_seed = 20260616L,
    individual_attempt_diagnostics = "unavailable_from_ordinary_route",
    rng_kind = I(RNGkind()), seed_reset = "before_each_fixture_fit"),
  r_version = R.version.string, tmb_version = as.character(packageVersion("TMB")),
  git_head = Sys.getenv("DRM_PRIOR_SOURCE_HEAD", unset = "unrecorded"),
  X_columns = I(colnames(x)), W_columns = I(colnames(w)),
  coordinate_order = c(paste0("beta:", colnames(x)), paste0("gamma:", colnames(w)), "tau"),
  native_order = names(par)[idx], tau = f$point$tau,
  fit = list(objective = fit$opt$objective, theta_native = unname(par[idx]),
             theta = c(unname(par[idx[-length(idx)]]), exp(par[idx[length(idx)]])),
             convergence = fit$opt$convergence, message = fit$opt$message,
             data_nll = -as.numeric(fit$logLik), prior = fit$fixed_prior_penalty))
if (f$point$tau == 0) {
  fm0 <- eval(parse(text = sprintf("bf(mu = %s, sigma = %s)", f$formula$mean, f$formula$scale)))
  fit0 <- drmTMB(fm0, data = d, priors = priors,
                 control = drm_control(se = FALSE, logsigma_clamp = NULL))
  p0 <- fit0$opt$par
  i0 <- c(which(names(p0) == "beta_mu"), which(names(p0) == "beta_sigma"))
  if (length(i0) != length(p0)) stop("unexpected boundary model parameters")
  p0[i0] <- c(f$point$beta, f$point$gamma)
  objective0 <- fit0$obj$fn(p0)
  prior0 <- as.numeric(fit0$obj$report(fit0$obj$env$last.par)$fixed_prior_penalty)
  result$point <- list(status = "boundary_fixed_only_value",
    theta = c(f$point$beta, f$point$gamma, 0), data_nll = objective0 - prior0,
    prior = prior0, objective = objective0,
    derivative_status = "unavailable_at_log_tau_boundary")
} else {
  theta <- c(f$point$beta, f$point$gamma, log(f$point$tau))
  point <- par; point[idx] <- theta
  objective <- fit$obj$fn(point)
  native_gradient <- fit$obj$gr(point)[idx]
  native_hessian <- numDeriv::jacobian(function(v) {
    pp <- point; pp[idx] <- v; fit$obj$gr(pp)[idx]
  }, theta)
  # Restore the exact point after derivative perturbations before REPORT.
  fit$obj$fn(point)
  prior <- as.numeric(fit$obj$report(fit$obj$env$last.par)$fixed_prior_penalty)
  tau <- f$point$tau
  grad <- native_gradient; grad[length(grad)] <- native_gradient[length(grad)] / tau
  hess <- native_hessian
  k <- length(grad)
  hess[k, -k] <- native_hessian[k, -k] / tau
  hess[-k, k] <- native_hessian[-k, k] / tau
  hess[k, k] <- (native_hessian[k, k] - native_gradient[k]) / tau^2
  result$point <- list(status = "evaluated", theta = c(f$point$beta, f$point$gamma, tau),
    data_nll = objective - prior, prior = prior, objective = objective,
    gradient = unname(grad), hessian = unname(hess))
}
jsonlite::write_json(result, args[[2]], auto_unbox = TRUE, digits = 16, pretty = TRUE, na = "null")
