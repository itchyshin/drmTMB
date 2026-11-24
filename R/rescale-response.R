# Internal response rescaling for the log-sigma clamp (#1751, #936).
#
# The soft clamp on log(sigma) acts on an ABSOLUTE band, so a fit whose response
# is measured in other units (y -> c * y shifts log(sigma) by log(c)) saw a
# different, clamped problem. First slice: for the simple Gaussian and Student-t
# location-scale path only, the optimizer runs on y / s (s = sd(y)), where the
# clamp is inactive at any sane optimum, and the optimum is mapped back to the
# original units. The final TMB object, standard errors, logLik, predictions,
# simulations and residuals are then computed on the ORIGINAL data, so no
# accessor needs a back-transform. See docs/design/03-likelihoods.md.
#
# Back-transform (y = s * y*, offsets o = s * o*):
#   beta_mu      = s * beta_mu*
#   beta_sigma_0 = beta_sigma_0* + log(s)   (intercept column only)
#   beta_sigma_j = beta_sigma_j*            (other columns)
#   log_sd_mu    = log_sd_mu* + log(s)      (ordinary (1 | g) intercepts)
#   u_mu         = s * u_mu*                (re-solved by the inner problem)
#   beta_nu      = beta_nu*                 (Student df is unit-free)
#   logLik       = logLik* - sum(w) * log(s) (original-scale density; equals the
#                  value an un-rescaled fit with an inactive clamp reports)

# Rescale only when the response scale could matter for the absolute clamp band
# or optimizer tolerances; other fits stay bit-for-bit unchanged.
drm_rescale_window <- c(1e-2, 1e2)

drm_rescale_plan <- function(spec, control, REML, estimator, priors, penalty) {
  if (!spec$model_type %in% c("gaussian", "student")) return(NULL)
  if (isTRUE(REML) || !identical(toupper(spec$estimator), "ML")) return(NULL)
  if (!is.null(priors) || !is.null(penalty)) return(NULL)
  if (is.null(control$logsigma_clamp)) return(NULL)
  if (length(control$start) > 0L || (if (is.data.frame(spec$start_override)) nrow(spec$start_override) else length(spec$start_override)) > 0L) {
    return(NULL)
  }
  td <- spec$tmb_data
  if (!identical(as.integer(td$use_logsigma_clamp), 1L)) return(NULL)
  if (!is.numeric(spec$y) || length(spec$y) < 3L || !all(is.finite(spec$y))) return(NULL)
  if (length(td$y) != length(spec$y)) return(NULL)  # aggregation etc.
  if (!is.null(spec$aggregation) && isTRUE(spec$aggregation$gaussian$enabled)) return(NULL)
  if (isTRUE(spec$has_known_v) || !identical(spec$V_known_type, "none")) return(NULL)
  md <- spec$missing_data
  if (is.list(md) && isTRUE(md$enabled)) return(NULL)
  if (is.list(spec$missing_predictor) && isTRUE(spec$missing_predictor$enabled)) return(NULL)
  if (isTRUE(spec$sparse_fixed$mu)) return(NULL)
  if (isTRUE(td$has_phylo_mu) || td$has_sd_mu_model > 0L || td$has_sd_phylo_model > 0L) return(NULL)
  if (td$n_sigma_re_terms > 0L || td$n_mu_re_cors > 0L || td$n_sigma_re_cors > 0L) return(NULL)
  if (td$n_mu_re_terms > 0L && !all(td$mu_re_value == 1)) return(NULL)  # intercept-only
  if (!is.null(spec$structured) &&
      any(vapply(spec$structured, function(z) is.list(z) && isTRUE(z$has), logical(1)))) return(NULL)
  sigma_cols <- colnames(spec$X$sigma)
  if (!"(Intercept)" %in% sigma_cols) return(NULL)
  w <- if (is.null(spec$weights)) rep(1, length(spec$y)) else spec$weights
  keep <- is.finite(w) & w > 0
  s <- stats::sd(spec$y[keep])
  if (!is.finite(s) || s <= 0) return(NULL)
  if (s >= drm_rescale_window[[1L]] && s <= drm_rescale_window[[2L]]) return(NULL)
  list(scale = s, sigma_intercept = match("(Intercept)", sigma_cols))
}

# Map a named parameter list (start values or the optimum) between the
# standardised (`to = "internal"`) and original units.
drm_rescale_map_par <- function(par, plan, to = c("original", "internal")) {
  to <- match.arg(to)
  s <- plan$scale
  f <- if (identical(to, "original")) 1 else -1
  out <- par
  nm <- if (is.list(par)) names(par) else names(par)
  pick <- function(name) which(nm == name)
  if (is.list(par)) {
    if (!is.null(out$beta_mu)) out$beta_mu <- if (f > 0) out$beta_mu * s else out$beta_mu / s
    if (!is.null(out$u_mu)) out$u_mu <- if (f > 0) out$u_mu * s else out$u_mu / s
    if (!is.null(out$beta_sigma)) out$beta_sigma[plan$sigma_intercept] <-
      out$beta_sigma[plan$sigma_intercept] + f * log(s)
    if (!is.null(out$log_sd_mu)) out$log_sd_mu <- out$log_sd_mu + f * log(s)
  } else {
    i <- pick("beta_mu"); out[i] <- if (f > 0) out[i] * s else out[i] / s
    i <- pick("beta_sigma")[plan$sigma_intercept]; out[i] <- out[i] + f * log(s)
    i <- pick("log_sd_mu"); out[i] <- out[i] + f * log(s)
  }
  out
}

# Fit on y / s. Returns NULL (caller keeps the ordinary path) when the plan does
# not apply, anything errors, or the clamp is active even on the standardised
# scale (then the original path reproduces today's behaviour exactly).
drm_rescale_prefit <- function(spec, control, plan) {
  allowed <- c("beta_mu", "beta_sigma", "log_sd_mu", "beta_nu")
  s <- plan$scale
  spec_s <- spec
  spec_s$tmb_data$y <- spec_s$tmb_data$y / s
  spec_s$tmb_data$offset_mu <- spec_s$tmb_data$offset_mu / s
  spec_s$start <- drm_rescale_map_par(spec_s$start, plan, to = "internal")
  res <- tryCatch({
    obj <- TMB::MakeADFun(
      data = spec_s$tmb_data, parameters = spec_s$start, map = spec_s$map,
      random = spec_s$tmb_random_names, DLL = "drmTMB", silent = TRUE
    )
    if (!all(names(obj$par) %in% allowed)) return(NULL)
    optimizer <- drm_optimize_with_preset_retry(obj, control, warn = FALSE)
    opt <- optimizer$opt
    if (isTRUE(control$newton_polish)) {
      opt <- drm_newton_polish(opt, obj$fn, obj$gr)
      optimizer$opt <- opt
      optimizer$selected$convergence <- opt$convergence
      optimizer$selected$message <- opt$message
    }
    restarted <- drm_restart_false_convergence(
      opt, obj, control = optimizer$selected$control, method = control$optimizer_method
    )
    if (!identical(restarted, opt)) {
      opt <- restarted
      optimizer$opt <- opt
      optimizer$selected$convergence <- opt$convergence
      optimizer$selected$message <- opt$message
    }
    drm_pin_tmb_object_to_optimum(obj, opt)
    fields <- drm_active_logsigma_clamp_fields(spec_s)
    if (length(fields) > 0L) {
      info <- drm_logsigma_clamp_active(obj$report(), spec_s$tmb_data, fields = fields)
      if (!is.null(info)) return(NULL)
    }
    fit_gradient <- drm_fit_gradient(obj, opt)
    # The finite-difference Hessian is not unit-free (absolute step sizes), so
    # take it on the standardised scale and map it to the original parameters.
    hessian <- NULL
    if (!identical(control$se, FALSE)) {
      h_int <- tryCatch(stats::optimHess(opt$par, obj$fn, obj$gr), error = function(e) NULL)
      if (!is.null(h_int)) {
        d <- ifelse(names(opt$par) == "beta_mu", 1 / s, 1)
        hessian <- h_int * outer(d, d)
      }
    }
    list(optimizer = optimizer, opt = opt, gradient = fit_gradient, plan = plan,
         hessian = hessian)
  }, error = function(e) NULL)
  res
}

# Rebuild the optimum on the original units, with the objective evaluated on the
# ORIGINAL data by the final (clamp-off) object so logLik is the original-scale
# value. The clamp is off in the final object: it was inactive at the optimum on
# the standardised scale, where it is meaningful.
drm_rescale_finish <- function(pre, obj) {
  opt <- pre$opt
  optimizer <- pre$optimizer
  par <- drm_rescale_map_par(opt$par, pre$plan, to = "original")
  opt$par <- par
  opt$objective <- as.numeric(obj$fn(par))
  optimizer$opt <- opt
  optimizer$selected$objective <- opt$objective
  optimizer$attempts$objective[which(optimizer$attempts$selected)] <- opt$objective
  pre$opt <- opt
  pre$optimizer <- optimizer
  pre
}
