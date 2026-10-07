# Methods for the fixed-effects conditional CJS route. These remain deliberately
# separate from the core fit implementation so inference and prediction can be
# reviewed without changing the likelihood contract.

#' Coefficients from a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param ... Unused.
#' @return A named numeric vector on the link scale.
#' @export
coef.drm_cjs <- function(object, ...) {
  .cmr_methods_dots(list(...), "coef.drm_cjs")
  setNames(c(object$coefficients$phi, object$coefficients$p),
           names(object$optimizer$par))
}

#' Predict process-specific quantities from a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param newdata `NULL` for contributing training rows, or a list with `phi`,
#'   `p`, and `units` keyed data frames.
#' @param type Return link-scale linear predictors or response-scale probabilities.
#' @param ... Unused.
#' @return A list containing keyed `phi` and `p` data frames.
#' @export
predict.drm_cjs <- function(object, newdata = NULL,
                            type = c("response", "link"), ...) {
  .cmr_methods_dots(list(...), "predict.drm_cjs")
  type <- match.arg(type)
  .cmr_methods_validate_fit(object)
  if (is.null(newdata)) {
    phi_i <- which(object$phi_active)
    p_i <- which(object$p_active)
    n <- nrow(object$data$y)
    nt <- ncol(object$data$y)
    phi_keys <- object$training_phi_data[phi_i, c("id", "interval_start", "interval_end"), drop = FALSE]
    phi_keys$interval_length <- as.numeric(t(object$data$delta))[phi_i]
    p_keys <- object$training_p_data[p_i, c("id", "occasion"), drop = FALSE]
    eta_phi <- as.numeric(object$phi$X[phi_i, , drop = FALSE] %*%
                            object$coefficients$phi + object$phi$offset[phi_i])
    eta_p <- as.numeric(object$p$X[p_i, , drop = FALSE] %*%
                          object$coefficients$p + object$p$offset[p_i])
  } else {
    if (!is.list(newdata) || !setequal(names(newdata), c("phi", "p", "units")) ||
        length(newdata) != 3L)
      stop("`newdata` must be a list containing exactly `phi`, `p`, and `units`.", call. = FALSE)
    if (!identical(newdata$units, object$data$units))
      stop("prediction `units` must exactly match the fitted interval units (`", object$data$units, "`).", call. = FALSE)
    phi_input <- .cmr_prediction_keys(newdata$phi, "phi", object)
    p_input <- .cmr_prediction_keys(newdata$p, "p", object)
    phi_keys <- phi_input$x
    p_keys <- p_input$x
    eta_phi <- .cmr_prediction_eta(object$phi, object$coefficients$phi,
                                   phi_input$.frame, "phi", object)
    eta_p <- .cmr_prediction_eta(object$p, object$coefficients$p,
                                 p_input$.frame, "p", object)
  }
  if (type == "link") {
    phi_out <- phi_keys
    phi_out$eta <- eta_phi
    p_out <- p_keys
    p_out$eta <- eta_p
  } else {
    phi_out <- phi_keys
    phi_out$phi_unit <- stats::plogis(eta_phi)
    phi_out$phi_interval <- phi_out$phi_unit ^ phi_out$interval_length
    p_out <- p_keys
    p_out$p <- stats::plogis(eta_p)
  }
  list(phi = phi_out, p = p_out)
}

#' Simulate conditional capture histories from a CJS fit
#' @param object A `drm_cjs` fit.
#' @param nsim Number of simulated data sets.
#' @param seed Optional seed. A supplied seed leaves the caller's RNG unchanged.
#' @param ... Unused.
#' @return A list of `cmr_simulation` records that can be refitted.
#' @export
simulate.drm_cjs <- function(object, nsim = 1L, seed = NULL, ...) {
  .cmr_methods_dots(list(...), "simulate.drm_cjs")
  .cmr_methods_validate_fit(object)
  nsim <- .cmr_validate_count(nsim, "nsim")
  if (!is.null(seed) && (length(seed) != 1L || !is.numeric(seed) ||
                         is.na(seed) || !is.finite(seed) ||
                         abs(seed) > .Machine$integer.max || seed != as.integer(seed)))
    stop("`seed` must be `NULL` or one finite integer in the supported range.", call. = FALSE)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (!is.null(seed) && had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  if (!is.null(seed)) on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  if (!is.null(seed)) set.seed(as.integer(seed))

  n <- nrow(object$data$y)
  nt <- ncol(object$data$y)
  phi_eta <- matrix(as.numeric(object$phi$X %*% object$coefficients$phi + object$phi$offset),
                    nrow = n, byrow = TRUE)
  p_eta <- matrix(as.numeric(object$p$X %*% object$coefficients$p + object$p$offset),
                  nrow = n, byrow = TRUE)
  phi_interval <- stats::plogis(phi_eta) ^ object$data$delta
  p_prob <- stats::plogis(p_eta)
  copies <- rep(seq_len(n), times = object$data$frequency)
  new_ids <- make.unique(paste0(as.character(object$data$id[copies]), "__sim", seq_along(copies)),
                         sep = "__")
  observed <- object$data$observed[copies, , drop = FALSE]
  first <- object$data$first[copies]
  end <- object$data$end[copies]
  replicate_data <- function(frame, keys) {
    result <- frame[rep(seq_len(nrow(frame)), times = 1L), , drop = FALSE]
    out <- vector("list", length(copies))
    for (j in seq_along(copies)) {
      rows <- which(frame$id == object$data$id[copies[[j]]])
      part <- frame[rows, , drop = FALSE]
      part$id <- new_ids[[j]]
      out[[j]] <- part
    }
    result <- do.call(rbind, out)
    rownames(result) <- NULL
    if (anyDuplicated(result[keys])) stop("internal simulation produced duplicate keyed predictor rows.", call. = FALSE)
    result
  }
  phi_data <- replicate_data(object$training_phi_data,
                             c("id", "interval_start", "interval_end"))
  p_data <- replicate_data(object$training_p_data, c("id", "occasion"))
  intervals <- if (nt > 1L) as.numeric(object$data$delta[1L, ]) else numeric()
  lapply(seq_len(nsim), function(s) {
    y <- matrix(0L, nrow = length(copies), ncol = nt)
    y[!observed] <- NA_integer_
    for (j in seq_along(copies)) {
      i <- copies[[j]]
      alive <- TRUE
      y[j, first[[j]]] <- 1L
      if (first[[j]] < end[[j]]) for (t in seq.int(first[[j]] + 1L, end[[j]])) {
        if (alive) alive <- stats::rbinom(1L, 1L, phi_interval[i, t - 1L]) == 1L
        y[j, t] <- if (!observed[j, t]) NA_integer_ else if (!alive) 0L else
          stats::rbinom(1L, 1L, p_prob[i, t])
      }
    }
    sim_data <- cmr_data(y, id = new_ids, observed = observed,
                         occasions = object$data$occasions, intervals = intervals,
                         units = object$data$units, end = end, frequency = 1L)
    structure(list(data = sim_data, phi_data = phi_data, p_data = p_data,
                   replicate = s), class = "cmr_simulation")
  })
}

#' Covariance matrix for a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param ... Unused.
#' @return The inverse observed negative-log-likelihood Hessian.
#' @export
vcov.drm_cjs <- function(object, ...) {
  .cmr_methods_dots(list(...), "vcov.drm_cjs")
  .cmr_methods_validate_fit(object, require_curvature = TRUE)
  nm <- names(coef.drm_cjs(object))
  if (!length(nm)) return(matrix(numeric(), 0L, 0L, dimnames = list(character(), character())))
  ans <- solve(object$hessian)
  dimnames(ans) <- list(nm, nm)
  ans
}

#' Wald, profile, or parametric-bootstrap intervals for a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param parm Optional coefficient names or indices.
#' @param level Confidence level.
#' @param method `"wald"`, `"profile"`, or `"bootstrap"`.
#' @param nsim Bootstrap attempts.
#' @param seed Optional bootstrap seed.
#' @param min_usable Minimum usable bootstrap fits before percentile intervals are returned.
#' @param ... Unused.
#' @return A coefficient-scale interval matrix with method diagnostics in attributes.
#' @export
confint.drm_cjs <- function(object, parm, level = 0.95,
                            method = c("wald", "profile", "bootstrap"),
                            nsim = 200L, seed = NULL, min_usable = 100L, ...) {
  .cmr_methods_dots(list(...), "confint.drm_cjs")
  method <- match.arg(method)
  if (length(level) != 1L || is.na(level) || !is.finite(level) || level <= 0 || level >= 1)
    stop("`level` must be one number strictly between zero and one.", call. = FALSE)
  estimates <- coef.drm_cjs(object)
  if (missing(parm)) parm <- names(estimates)
  if (is.numeric(parm)) {
    if (anyNA(parm) || any(parm != as.integer(parm)) || any(parm < 1L) || any(parm > length(estimates)))
      stop("`parm` contains an invalid coefficient index.", call. = FALSE)
    parm <- names(estimates)[as.integer(parm)]
  }
  if (!is.character(parm) || anyNA(parm) || any(!parm %in% names(estimates)))
    stop("`parm` must name fitted CJS coefficients.", call. = FALSE)
  parm <- unique(parm)
  z <- stats::qnorm(1 - (1 - level) / 2)
  ans <- matrix(NA_real_, length(parm), 2L,
                dimnames = list(parm, c("lower", "upper")))
  if (method == "wald") {
    variance <- tryCatch(vcov.drm_cjs(object), error = function(e) e)
    target_status <- setNames(rep("ok", length(parm)), parm)
    if (inherits(variance, "error")) {
      target_status[] <- paste0("unavailable: ", conditionMessage(variance))
    } else {
      se <- sqrt(diag(variance)[parm])
      ans[,] <- cbind(estimates[parm] - z * se, estimates[parm] + z * se)
    }
    attr(ans, "method") <- "wald"
    attr(ans, "target_status") <- target_status
    return(ans)
  }
  .cmr_methods_validate_fit(object)
  if (method == "profile") {
    variance <- tryCatch(vcov.drm_cjs(object), error = function(e) NULL)
    profile_se <- if (is.null(variance)) rep(.5, length(estimates)) else
      sqrt(diag(variance))
    statuses <- matrix("not_attempted", length(parm), 2L,
                       dimnames = list(parm, c("lower", "upper")))
    for (nm in parm) {
      j <- match(nm, names(estimates))
      prof <- .cmr_profile_endpoint(object, j, estimates[[nm]],
                                    profile_se[[j]], level)
      ans[nm, ] <- prof$limits
      statuses[nm, ] <- prof$status
    }
    attr(ans, "method") <- "profile"
    attr(ans, "endpoint_status") <- statuses
    attr(ans, "target_status") <- setNames(apply(statuses, 1L, function(x) {
      if (all(x == "ok")) "ok" else if (any(x == "ok")) "partial" else "unavailable"
    }), parm)
    return(ans)
  }
  nsim <- .cmr_validate_count(nsim, "nsim")
  min_usable <- .cmr_validate_count(min_usable, "min_usable")
  draws <- .cmr_bootstrap_coefficients(object, nsim, seed)
  usable <- vapply(draws$attempts$coefficients, function(x) !is.null(x), logical(1))
  sample <- if (any(usable)) do.call(rbind, draws$attempts$coefficients[usable]) else NULL
  target_status <- setNames(rep("insufficient_usable", length(parm)), parm)
  n_usable_target <- setNames(integer(length(parm)), parm)
  for (nm in parm) {
    values <- if (is.null(sample)) numeric() else sample[, nm]
    values <- values[is.finite(values)]
    n_usable_target[[nm]] <- length(values)
    if (length(values) >= min_usable) {
      ans[nm, ] <- stats::quantile(values,
                                   probs = c((1 - level) / 2, 1 - (1 - level) / 2),
                                   names = FALSE, type = 7)
      target_status[[nm]] <- "ok"
    }
  }
  attr(ans, "method") <- "bootstrap"
  attr(ans, "status") <- if (all(target_status == "ok")) "usable" else "insufficient_usable"
  attr(ans, "target_status") <- target_status
  attr(ans, "n_usable_target") <- n_usable_target
  attr(ans, "attempts") <- draws$attempts
  attr(ans, "n_usable") <- sum(usable)
  ans
}

.cmr_methods_dots <- function(dots, method) {
  if (length(dots)) stop("`...` is not used by ", method, ".", call. = FALSE)
  invisible(NULL)
}

.cmr_validate_count <- function(x, name) {
  if (length(x) != 1L || is.na(x) || !is.numeric(x) || !is.finite(x) ||
      x < 1 || x != as.integer(x))
    stop("`", name, "` must be one positive integer.", call. = FALSE)
  as.integer(x)
}

.cmr_methods_validate_fit <- function(object, require_curvature = FALSE) {
  if (!inherits(object, "drm_cjs")) stop("`object` must be a `drm_cjs` fit.", call. = FALSE)
  if (!identical(object$convergence, 0L) || !is.finite(object$gradient_norm) ||
      object$gradient_norm > 1e-4)
    stop("CJS inference requires a converged fit with a small gradient.", call. = FALSE)
  if (!require_curvature) return(invisible(TRUE))
  h <- object$hessian
  if (!is.matrix(h) || any(!is.finite(h)))
    stop("CJS Wald inference requires a finite model-specific observed Hessian.", call. = FALSE)
  if (!length(h)) return(invisible(TRUE))
  eig <- eigen((h + t(h)) / 2, symmetric = TRUE, only.values = TRUE)$values
  if (any(!is.finite(eig)) || min(eig) <= max(eig) * 1e-10)
    stop("CJS Wald inference requires a positive-definite, nonsingular observed Hessian.", call. = FALSE)
  eta_phi <- as.numeric(object$phi$X %*% object$coefficients$phi + object$phi$offset)
  eta_p <- as.numeric(object$p$X %*% object$coefficients$p + object$p$offset)
  probability <- c(stats::plogis(eta_phi[object$phi_active]),
                   (stats::plogis(eta_phi) ^ object$data$delta)[object$phi_active],
                   stats::plogis(eta_p[object$p_active]))
  if (any(!is.finite(probability)) || any(probability <= 1e-8 | probability >= 1 - 1e-8))
    stop("CJS Wald inference is unavailable because a fitted probability is at the boundary.", call. = FALSE)
  invisible(TRUE)
}

.cmr_prediction_keys <- function(x, process, object) {
  keys <- if (process == "phi") c("id", "interval_start", "interval_end", "interval_length") else
    c("id", "occasion")
  if (!is.data.frame(x) || !all(keys %in% names(x)))
    stop("`newdata$", process, "` must be a data frame with keys ",
         paste(keys, collapse = ", "), ".", call. = FALSE)
  unique_keys <- if (process == "phi") keys[1:3] else keys
  if (anyNA(x[keys]) || anyDuplicated(x[unique_keys]))
    stop("`newdata$", process, "` keys must be complete and unique.", call. = FALSE)
  if (process == "phi" && (!is.numeric(x$interval_length) ||
                            any(!is.finite(x$interval_length)) || any(x$interval_length <= 0)))
    stop("`newdata$phi$interval_length` must contain positive finite values.", call. = FALSE)
  design <- object[[process]]
  vars <- all.vars(design$terms)
  if (!all(vars %in% names(x)))
    stop("`newdata$", process, "` is missing formula/schema columns: ",
         paste(setdiff(vars, names(x)), collapse = ", "), ".", call. = FALSE)
  allowed <- unique(c(keys, vars))
  if (!setequal(names(x), allowed))
    stop("`newdata$", process, "` does not match the fitted predictor schema.", call. = FALSE)
  if (any(vapply(x[vars], function(v) anyNA(v), logical(1))))
    stop("`newdata$", process, "` predictors must not be missing.", call. = FALSE)
  frame <- x
  list(x = x[keys], .frame = frame)
}

.cmr_prediction_eta <- function(design, beta, frame, process, object) {
  tr <- design$terms
  mf <- tryCatch(stats::model.frame(tr, data = frame, na.action = stats::na.fail,
                                    xlev = design$xlevels), error = function(e) {
    stop("cannot build the fitted ", process, " prediction schema: ", conditionMessage(e), call. = FALSE)
  })
  mm <- tryCatch(stats::model.matrix(tr, mf, contrasts.arg = design$contrasts), error = function(e) {
    stop("cannot build the fitted ", process, " model matrix: ", conditionMessage(e), call. = FALSE)
  })
  if (any(!is.finite(mm)) || !all(design$columns %in% colnames(mm)))
    stop("prediction model matrix is non-finite or incompatible with fitted ", process, " coefficients.", call. = FALSE)
  mm <- mm[, design$columns, drop = FALSE]
  if (!identical(colnames(mm), names(beta)))
    stop("prediction coefficient columns do not match the fitted ", process, " design.", call. = FALSE)
  offset <- stats::model.offset(mf)
  if (is.null(offset)) offset <- rep(0, nrow(mm))
  if (any(!is.finite(offset))) stop("prediction offsets must be finite.", call. = FALSE)
  eta <- as.numeric(mm %*% beta + offset)
  constraint <- object$terminal_constraint[[process]]
  if (!is.null(constraint)) {
    terminal <- if (process == "phi") frame$interval_end == max(object$data$occasions) else
      frame$occasion == tail(object$data$occasions, 1L)
    eta[terminal] <- stats::qlogis(constraint)
  }
  if (any(!is.finite(eta))) stop("prediction linear predictors must be finite.", call. = FALSE)
  eta
}

.cmr_profile_value <- function(object, j, value, start = object$optimizer$par) {
  free <- start[-j]
  objective <- function(other) {
    full <- start
    full[j] <- value
    full[-j] <- other
    object$obj$fn(full)
  }
  if (!length(free)) {
    result <- tryCatch(objective(numeric()), error = function(e) NA_real_)
    return(if (is.finite(result)) result else NA_real_)
  }
  opt <- tryCatch(stats::nlminb(free, objective,
                                control = list(iter.max = 300L, eval.max = 400L)),
                  error = function(e) NULL)
  if (is.null(opt) || opt$convergence != 0L || !is.finite(opt$objective)) return(NA_real_)
  full <- start
  full[j] <- value
  full[-j] <- opt$par
  gradient <- tryCatch(object$obj$gr(full)[-j], error = function(e) NA_real_)
  if (!length(gradient) || any(!is.finite(gradient)) || max(abs(gradient)) > 1e-4)
    return(NA_real_)
  opt$objective
}

.cmr_profile_endpoint <- function(object, j, estimate, se, level) {
  parhat <- object$optimizer$par
  cutoff <- stats::qchisq(level, df = 1L)
  center <- object$obj$fn(parhat)
  fn_at <- function(value, start) 2 * (.cmr_profile_value(object, j, value, start) - center)
  limits <- c(NA_real_, NA_real_)
  status <- c("failed", "failed")
  for (side in seq_len(2L)) {
    sign <- if (side == 1L) -1 else 1
    step <- max(se, .05)
    inner <- estimate
    outer <- estimate + sign * step
    f_outer <- fn_at(outer, parhat) - cutoff
    tries <- 0L
    while (is.finite(f_outer) && f_outer < 0 && tries < 12L) {
      inner <- outer
      step <- step * 1.7
      outer <- estimate + sign * step
      f_outer <- fn_at(outer, parhat) - cutoff
      tries <- tries + 1L
    }
    if (!is.finite(f_outer)) {
      status[[side]] <- "failed_profile"
    } else if (f_outer < 0) {
      status[[side]] <- "no_crossing"
    } else {
      root <- tryCatch(stats::uniroot(function(value) fn_at(value, parhat) - cutoff,
                                      sort(c(inner, outer)), tol = 1e-5)$root,
                       error = function(e) NA_real_)
      if (is.finite(root)) {
        limits[[side]] <- root
        status[[side]] <- "ok"
      } else status[[side]] <- "failed_root"
    }
  }
  list(limits = limits, status = status)
}

.cmr_bootstrap_coefficients <- function(object, nsim, seed) {
  simulations <- simulate.drm_cjs(object, nsim = nsim, seed = seed)
  records <- vector("list", nsim)
  for (i in seq_len(nsim)) {
    sim <- simulations[[i]]
    result <- tryCatch(drm_cjs(sim$data,
                               phi = stats::formula(object$phi$terms),
                               p = stats::formula(object$p$terms),
                               phi_data = sim$phi_data, p_data = sim$p_data,
                               terminal_constraint = object$terminal_constraint,
                               contrasts = list(phi = object$phi$contrasts,
                                                p = object$p$contrasts)),
                      error = function(e) e)
    if (inherits(result, "error")) {
      records[[i]] <- list(replicate = i, status = "failed", converged = FALSE,
                           usable = FALSE, message = conditionMessage(result),
                           coefficients = NULL, fit = NULL)
    } else if (result$convergence != 0L) {
      records[[i]] <- list(replicate = i, status = "nonconverged", converged = FALSE,
                           usable = FALSE, message = result$message,
                           coefficients = NULL, fit = result)
    } else {
      usable <- tryCatch({ .cmr_methods_validate_fit(result, require_curvature = TRUE); TRUE },
                         error = function(e) FALSE)
      records[[i]] <- list(replicate = i, status = if (usable) "usable" else "unusable",
                           converged = TRUE, usable = usable,
                           message = if (usable) result$message else "singular, boundary, or invalid curvature",
                           coefficients = if (usable) coef.drm_cjs(result) else NULL,
                           fit = result)
    }
  }
  ledger <- data.frame(replicate = vapply(records, `[[`, integer(1), "replicate"),
                       status = vapply(records, `[[`, character(1), "status"),
                       converged = vapply(records, `[[`, logical(1), "converged"),
                       usable = vapply(records, `[[`, logical(1), "usable"),
                       message = vapply(records, `[[`, character(1), "message"),
                       stringsAsFactors = FALSE)
  ledger$coefficients <- I(lapply(records, `[[`, "coefficients"))
  ledger$fit <- I(lapply(records, `[[`, "fit"))
  list(attempts = ledger)
}
