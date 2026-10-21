# Internal profile evaluator for the reference-selection CJS likelihood.
# Each quadrature order is held fixed for the constrained nuisance fit.
.cmr_cjs_selection_profile_point <- function(object, process, index, value,
                                             zero_sd = NULL,
                                             parameter_tolerance = 1e-5,
                                             likelihood_tolerance = 1e-8) {
  if (!inherits(object, "drm_cjs") || !isTRUE(object$obj$env$data$cmr_selection != 0))
    stop("selection profile points require a reference-selection CJS fit.", call. = FALSE)
  if (!process %in% c("phi", "p") || length(index) != 1L || is.na(index) ||
      index < 1L || index != as.integer(index) || length(value) != 1L || !is.finite(value))
    stop("selection profile target must identify one finite `phi` or `p` coefficient.", call. = FALSE)
  orders <- as.integer(object$random_effects$integration$orders)
  tryCatch(.cmr_validate_quadrature_orders(orders), error = function(e)
    stop("selection profile requires valid fitted quadrature orders: ",
         conditionMessage(e), call. = FALSE))
  data0 <- object$obj$env$data
  parameters <- object$obj$env$parList(object$optimizer$par)
  beta_name <- paste0("beta_", process)
  if (is.null(parameters[[beta_name]]) || index > length(parameters[[beta_name]]))
    stop("selection profile coefficient index is outside the fitted design.", call. = FALSE)
  parameters[[beta_name]][[index]] <- value
  map <- list()
  beta_map <- seq_along(parameters[[beta_name]])
  beta_map[[index]] <- NA_integer_
  map[[beta_name]] <- factor(beta_map)
  sd_name <- NULL
  other_effect <- NA
  if (!is.null(zero_sd)) {
    if (length(zero_sd) != 1L || !zero_sd %in% c("phi", "p"))
      stop("`zero_sd` must name `phi` or `p`.", call. = FALSE)
    flag <- paste0("cmr_has_individual_", zero_sd)
    if (!is.null(data0[[flag]])) data0[[flag]] <- 0.0
    other <- setdiff(c("phi", "p"), zero_sd)
    other_effect <- isTRUE(data0[[paste0("cmr_has_individual_", other)]] != 0)
    sd_name <- paste0("log_sd_", zero_sd)
    if (is.null(parameters[[sd_name]])) sd_name <- paste0("log_sigma_", zero_sd)
    if (!is.null(parameters[[sd_name]])) {
      map[[sd_name]] <- factor(rep(NA_integer_, length(parameters[[sd_name]])))
      parameters[[sd_name]][] <- 0
    }
  }
  previous <- NULL
  previous_report <- NULL
  for (order in orders) {
    gh <- .cmr_gauss_hermite(order)
    data <- data0
    data$cmr_gh_nodes <- gh$nodes
    data$cmr_gh_weights <- gh$weights
    obj <- tryCatch(TMB::MakeADFun(data = data, parameters = parameters,
      map = map, random = NULL, DLL = "drmTMB", silent = TRUE), error = identity)
    if (inherits(obj, "error")) return(list(status = "optimizer", refined = FALSE,
      order = order, message = conditionMessage(obj)))
    start <- obj$par
    if (!is.null(previous)) {
      common <- intersect(names(start), names(previous))
      start[common] <- previous[common]
    }
    opt <- tryCatch(stats::nlminb(start = start, objective = obj$fn,
      gradient = obj$gr, control = list(iter.max = 500L, eval.max = 700L)), error = identity)
    if (inherits(opt, "error")) return(list(status = "optimizer", refined = FALSE,
      order = order, message = conditionMessage(opt)))
    gradient <- tryCatch(as.numeric(obj$gr(opt$par)), error = function(e) NA_real_)
    if (opt$convergence != 0L || !is.finite(opt$objective) || any(!is.finite(opt$par)) ||
        any(!is.finite(gradient)) || (length(gradient) && max(abs(gradient)) > 1e-4))
      return(list(status = "optimizer", refined = FALSE, order = order,
        message = "constrained nuisance optimization did not converge with a small gradient."))
    report <- obj$report(opt$par)
    history <- as.numeric(report$cmr_individual_loglik)
    numerator <- as.numeric(report$cmr_selection_log_num)
    denominator <- as.numeric(report$cmr_selection_log_den)
    objective <- sum(as.numeric(data$cmr_frequency) * (numerator - denominator))
    if (any(!is.finite(c(history, numerator, denominator, objective))))
      return(list(status = "optimizer", refined = FALSE, order = order,
        message = "selection integrals or objective are non-finite."))
    if (!is.null(previous_report)) {
      change <- function(x, y) if (length(x) != length(y)) Inf else if (length(x)) max(abs(x-y)) else 0
      if (change(opt$par, previous) <= parameter_tolerance &&
          max(change(history, previous_report$history),
              change(numerator, previous_report$numerator),
              change(denominator, previous_report$denominator),
              abs(objective - previous_report$objective)) <= likelihood_tolerance)
        return(list(status = "refined", refined = TRUE, order = order,
          objective = objective, report = report, nuisance = opt$par,
          selection_normalization_retained = TRUE,
          other_process_effect_retained = other_effect))
    }
    previous <- opt$par
    previous_report <- list(history = history, numerator = numerator,
      denominator = denominator, objective = objective)
    parameters <- obj$env$parList(opt$par)
    parameters[[beta_name]][[index]] <- value
    if (!is.null(sd_name) && !is.null(parameters[[sd_name]])) parameters[[sd_name]][] <- 0
  }
  list(status = "integration_cap", refined = FALSE, order = utils::tail(orders, 1L),
       message = paste0("selection profile did not refine by quadrature order ",
                        max(orders), "."))
}

.cmr_cjs_selection_profile <- function(object, process, index, level = 0.95,
                                        zero_sd = NULL) {
  if (length(level) != 1L || !is.finite(level) || level <= 0 || level >= 1)
    stop("`level` must be one number strictly between zero and one.", call. = FALSE)
  if (!is.null(zero_sd))
    stop("selection profile intervals with `zero_sd` require a separately fitted reduced-model reference; use the constrained-point helper until that interval route is implemented.", call. = FALSE)
  estimate <- unname(object$coefficients[[process]][[index]])
  baseline <- .cmr_cjs_selection_profile_point(object, process, index, estimate,
                                                zero_sd = zero_sd)
  if (!isTRUE(baseline$refined)) return(list(baseline = baseline, points = list(),
    lower = list(estimate = NA_real_, status = baseline$status),
    upper = list(estimate = NA_real_, status = baseline$status)))
  cutoff <- stats::qchisq(level, df = 1)
  fitted_loglik <- as.numeric(stats::logLik(object))
  baseline$fitted_loglik <- fitted_loglik
  baseline$likelihood_ratio <- 2 * (fitted_loglik - baseline$objective)
  points <- list(baseline)
  improvement_tolerance <- 1e-8 * max(1, abs(fitted_loglik))
  if (baseline$likelihood_ratio < -improvement_tolerance) {
    status <- "profile_improves_on_fit"
    return(list(baseline = baseline, points = points,
      lower = list(estimate = NA_real_, status = status),
      upper = list(estimate = NA_real_, status = status)))
  }
  if (baseline$likelihood_ratio > cutoff + improvement_tolerance) {
    status <- "center_outside_cutoff"
    return(list(baseline = baseline, points = points,
      lower = list(estimate = NA_real_, status = status),
      upper = list(estimate = NA_real_, status = status)))
  }
  evaluate <- function(x) {
    point <- .cmr_cjs_selection_profile_point(object, process, index, x, zero_sd = zero_sd)
    points[[length(points) + 1L]] <<- point
    if (!isTRUE(point$refined)) return(NA_real_)
    lr <- 2 * (fitted_loglik - point$objective)
    point$likelihood_ratio <- lr
    points[[length(points)]] <<- point
    if (lr < -improvement_tolerance) return(NA_real_)
    lr - cutoff
  }
  endpoint <- function(direction) {
    inner <- estimate
    step <- max(.25, abs(estimate) * .25)
    for (iteration in seq_len(20L)) {
      outer <- estimate + direction * step
      q <- evaluate(outer)
      if (!is.finite(q)) {
        last <- points[[length(points)]]
        status <- if (isTRUE(last$refined)) "profile_improves_on_fit" else last$status
        return(list(estimate = NA_real_, status = status))
      }
      if (q >= 0) {
        lo <- min(inner, outer)
        hi <- max(inner, outer)
        for (bisect in seq_len(40L)) {
          mid <- lo + (hi - lo) / 2
          qmid <- evaluate(mid)
          if (!is.finite(qmid)) {
            last <- points[[length(points)]]
            status <- if (isTRUE(last$refined)) "profile_improves_on_fit" else last$status
            return(list(estimate = NA_real_, status = status))
          }
          if (direction * qmid < 0) lo <- mid else hi <- mid
          if (abs(hi - lo) <= 1e-5)
            return(list(estimate = lo + (hi - lo) / 2, status = "available"))
        }
        return(list(estimate = NA_real_, status = "optimizer"))
      }
      inner <- outer
      step <- step * 1.7
    }
    list(estimate = NA_real_, status = "non_crossing")
  }
  lower <- endpoint(-1)
  upper <- if (identical(lower$status, "profile_improves_on_fit"))
    list(estimate = NA_real_, status = "not_attempted") else endpoint(1)
  if (any(c(lower$status, upper$status) == "profile_improves_on_fit")) {
    lower$estimate <- NA_real_
    upper$estimate <- NA_real_
  }
  list(baseline = baseline, points = points, lower = lower, upper = upper)
}
