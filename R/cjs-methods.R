# Methods for conditional CJS fits. These remain deliberately separate from the
# core fit implementation so inference and prediction can be reviewed without
# changing the likelihood contract.

#' Coefficients from a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param process Mean-process coefficients by default; `phi`, `p`, `sd_phi`,
#'   `sd_p`, or `all` selects explicit parameter blocks. SD coefficients
#'   describe log random-effect standard deviation.
#' @param ... Unused.
#' @return A named numeric vector on the link scale.
#' @export
coef.drm_cjs <- function(object, process = c("mean", "phi", "p", "sd_phi", "sd_p", "all"), ...) {
  .cmr_methods_dots(list(...), "coef.drm_cjs")
  process <- match.arg(process)
  selected <- switch(process, mean = c("phi", "p"),
    all = c("phi", "p", "sd_phi", "sd_p"), process)
  values <- lapply(selected, function(s) {
    beta <- object$coefficients[[s]]
    # Individual fits retain SD coefficients in integration parameters.
    if (is.null(beta) && startsWith(s, "sd_")) {
      parameter <- paste0("log_", s)
      beta <- object$random_effects$parameters[[parameter]]
      design <- object$random_effects$sd_design[[sub("sd_", "", s, fixed = TRUE)]]
      if (length(beta) && !is.null(design$columns)) names(beta) <- design$columns
    }
    if (!length(beta)) return(stats::setNames(numeric(), character()))
    stats::setNames(beta, paste0(s, ":", names(beta)))
  })
  unlist(values, use.names = TRUE)
}

#' Log likelihood for a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param ... Unused.
#' @return A `logLik` object with coefficient count and enrolled histories.
#' @export
logLik.drm_cjs <- function(object, ...) {
  .cmr_methods_dots(list(...), "logLik.drm_cjs")
  random_parameters <- object$random_effects$parameters
  random_df <- 0L
  if (!is.null(random_parameters)) for (process in c("phi", "p")) {
    if (!is.null(object$random_effects[[process]])) {
      prefix <- if (!is.null(random_parameters[[paste0("log_sd_", process)]]))
        "log_sd_" else "log_sigma_"
      random_df <- random_df + length(random_parameters[[paste0(prefix, process)]])
    }
  }
  structure(object$logLik, df = length(coef.drm_cjs(object)) + random_df,
            nobs = sum(object$data$frequency), class = "logLik")
}

#' Predict process-specific quantities from a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param newdata `NULL` for contributing training rows, or a list with `phi`,
#'   `p`, and `units` keyed data frames. For integrated prediction from a
#'   reference-selection fit, include `selection`: a list with `first` (columns
#'   `id`, `first_index`, and `eligibility_index`), `phi` (all pre-capture
#'   intervals), and `p` (all pre-capture occasions plus logical `observed` and
#'   binary `capture` columns). Occasion indices are 1-based positions in the
#'   fitted schedule; prehistory predictors must use the fitted schemas.
#' @param type Return link-scale linear predictors or response-scale probabilities.
#' @param target For individual-effect fits, `"zero_effect"` predicts at a zero
#'   random effect; `"integrated"` averages probabilities over the fitted
#'   marked-cohort reference mixing law, using fitted predictor-dependent SDs
#'   when present. For reference-selection fits, integrated prediction is
#'   conditioned on the supplied first-capture event. New profiles must include
#'   complete prehistory in `newdata$selection`. Integrated prediction is
#'   response-scale only and reports process averages at the supplied profiles.
#' @param ... Unused.
#' @return A list containing keyed `phi` and `p` data frames.
#' @export
predict.drm_cjs <- function(object, newdata = NULL,
                            type = c("response", "link"),
                            target = NULL, ...) {
  .cmr_methods_dots(list(...), "predict.drm_cjs")
  type <- match.arg(type)
  if (inherits(object, "drm_cjs") &&
      object$random_effects$route %in% c("site_phi", "site_p", "site_pair", "year_vector"))
    return(.cmr_predict_shared(object, newdata = newdata, type = type, target = target))
  individual <- inherits(object, "drm_cjs") &&
    startsWith(object$random_effects$route %||% "", "individual_")
  if (is.null(target)) {
    if (individual) stop("individual-effect prediction requires an explicit `target`: `zero_effect` or `integrated`.", call. = FALSE)
    target <- "zero_effect"
  }
  if (!is.character(target) || length(target) != 1L || is.na(target) ||
      !target %in% c("zero_effect", "integrated"))
    stop("`target` must be `zero_effect` or `integrated`.", call. = FALSE)
  if (individual) .cmr_prediction_validate_individual(object, target, type,
    allow_sd_formula = TRUE, allow_selection = TRUE) else
    .cmr_methods_validate_fit(object)
  selection_tilt <- individual && target == "integrated" &&
    isTRUE(object$prediction_contract$selection_enabled)
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
    expected_names <- c("phi", "p", "units", if (selection_tilt) "selection")
    if (!is.list(newdata) || !setequal(names(newdata), expected_names) ||
        length(newdata) != length(expected_names))
      stop("`newdata` must contain exactly `phi`, `p`, and `units`",
           if (selection_tilt) " plus `selection` prehistory." else ".", call. = FALSE)
    if (!identical(newdata$units, object$data$units))
      stop("prediction `units` must exactly match the fitted interval units (`", object$data$units, "`).", call. = FALSE)
    phi_input <- .cmr_prediction_keys(newdata$phi, "phi", object, target)
    p_input <- .cmr_prediction_keys(newdata$p, "p", object, target)
    phi_keys <- phi_input$x
    p_keys <- p_input$x
    eta_phi <- .cmr_prediction_eta(object$phi, object$coefficients$phi,
                                   phi_input$.frame, "phi", object)
    eta_p <- .cmr_prediction_eta(object$p, object$coefficients$p,
                                 p_input$.frame, "p", object)
  }
  selection_input <- NULL
  if (selection_tilt) {
    selection_input <- if (is.null(newdata)) .cmr_selection_training_input(object) else
      .cmr_selection_newdata_input(newdata$selection, object, phi_keys, p_keys)
    selection_input$phi$eta <- .cmr_prediction_eta(object$phi,
      object$coefficients$phi, selection_input$phi, "phi", object)
    selection_input$p$eta <- 0
    if (!is.null(selection_input$p_observed)) {
      selection_input$p$observed <- selection_input$p_observed
      selection_input$p$capture <- selection_input$p_capture
    }
    observed_p <- which(selection_input$p$observed)
    if (length(observed_p)) selection_input$p$eta[observed_p] <-
      .cmr_prediction_eta(object$p, object$coefficients$p,
        selection_input$p[observed_p, , drop = FALSE], "p", object)
  }
  if (individual && (any(!is.finite(eta_phi)) || any(!is.finite(eta_p))))
    stop("individual-effect prediction requires finite prediction linear predictors.", call. = FALSE)
  if (individual) {
    if (target == "integrated" && type == "link")
      stop("integrated individual-effect prediction is available on the response scale only.", call. = FALSE)
    phi_frame <- if (is.null(newdata)) object$training_phi_data[phi_i, , drop = FALSE] else phi_input$.frame
    p_frame <- if (is.null(newdata)) object$training_p_data[p_i, , drop = FALSE] else p_input$.frame
    sd_phi <- if (target == "integrated") .cmr_prediction_sd_rows(object, "phi", phi_frame, phi_keys$id) else 0
    sd_p <- if (target == "integrated") .cmr_prediction_sd_rows(object, "p", p_frame, p_keys$id) else 0
    if (selection_tilt) {
      .cmr_selection_validate_sd_history(object, "phi", phi_frame, phi_keys$id,
        sd_phi, selection_input$phi)
      .cmr_selection_validate_sd_history(object, "p", p_frame, p_keys$id,
        sd_p, selection_input$p[selection_input$p$observed, , drop = FALSE])
    }
    phi_terminal <- !is.null(object$terminal_constraint$phi) &
      phi_keys$interval_end == max(object$data$occasions)
    p_terminal <- !is.null(object$terminal_constraint$p) &
      p_keys$occasion == utils::tail(object$data$occasions, 1L)
    phi_power <- if (is.null(newdata)) phi_keys$interval_length else newdata$phi$interval_length
    if (selection_tilt) {
      phi_unit <- .cmr_selection_prediction_rows(object, "phi", phi_keys,
        eta_phi, sd_phi, rep(1, length(eta_phi)), phi_terminal, selection_input)
      phi_interval <- .cmr_selection_prediction_rows(object, "phi", phi_keys,
        eta_phi, sd_phi, phi_power, phi_terminal, selection_input)
      p_value <- .cmr_selection_prediction_rows(object, "p", p_keys,
        eta_p, sd_p, rep(1, length(eta_p)), p_terminal, selection_input)
    } else {
      orders <- object$random_effects$integration$orders
      phi_unit <- .cmr_individual_mean(eta_phi, sd_phi, target, 1, phi_terminal,
                                      object$terminal_constraint$phi, orders = orders)
      phi_interval <- .cmr_individual_mean(eta_phi, sd_phi, target, phi_power,
                                         phi_terminal, object$terminal_constraint$phi,
                                         orders = orders)
      p_value <- .cmr_individual_mean(eta_p, sd_p, target, 1, p_terminal,
                                     object$terminal_constraint$p, orders = orders)
    }
    phi_out <- phi_keys
    p_out <- p_keys
    if (type == "link") {
      phi_out$eta <- eta_phi
      p_out$eta <- eta_p
    } else {
      phi_out$phi_unit <- phi_unit
      phi_out$phi_interval <- phi_interval
      p_out$p <- p_value
    }
    out <- list(phi = phi_out, p = p_out)
    attr(out, "prediction") <- list(target = target,
      mixing = if (selection_tilt) "reference-cohort random-effect distribution conditioned on each supplied first-capture event; independent process effects" else if (target == "integrated") "fitted marked-cohort reference mixing law; independent process effects" else "zero random effect")
    if (selection_tilt) attr(out, "prediction")$target <- "reference_selection_integrated"
    return(out)
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

.cmr_prediction_validate_individual <- function(object, target, type,
                                                allow_sd_formula = FALSE,
                                                allow_selection = FALSE) {
  route <- object$random_effects$route
  valid_routes <- c("individual_phi", "individual_p", "individual_pair")
  if (!is.character(route) || length(route) != 1L || is.na(route) ||
      !route %in% valid_routes)
    stop("individual-effect prediction requires a supported individual route.", call. = FALSE)
  contract <- object$prediction_contract
  if (!is.list(contract) || !identical(contract$version, 1L) ||
      !is.logical(contract$selection_enabled) || length(contract$selection_enabled) != 1L ||
      is.na(contract$selection_enabled) || !is.logical(contract$sd_formula_present) ||
      !identical(names(contract$sd_formula_present), c("phi", "p")) ||
      length(contract$sd_formula_present) != 2L || anyNA(contract$sd_formula_present))
    stop("individual-effect prediction requires valid fit prediction provenance.", call. = FALSE)
  if (contract$selection_enabled && !isTRUE(allow_selection))
    stop("individual-effect prediction with reference selection is unsupported.", call. = FALSE)
  if (any(contract$sd_formula_present) && !isTRUE(allow_sd_formula))
    stop("individual-effect prediction with an SD formula is unsupported.", call. = FALSE)
  if (!identical(object$random_effects$laplace, FALSE))
    stop("individual-effect prediction requires an ordinary individual-effect fit.", call. = FALSE)
  if (!identical(object$convergence, 0L) || !is.numeric(object$logLik) ||
      length(object$logLik) != 1L || !is.finite(object$logLik) ||
      !is.numeric(object$gradient_norm) || length(object$gradient_norm) != 1L ||
      !is.finite(object$gradient_norm) || object$gradient_norm < 0 || object$gradient_norm > 1e-4)
    stop("individual-effect prediction requires a converged fit with finite objective and small gradient.", call. = FALSE)
  if (!is.list(object$coefficients) || !is.numeric(object$coefficients$phi) ||
      !is.numeric(object$coefficients$p) ||
      any(!is.finite(object$coefficients$phi)) ||
      any(!is.finite(object$coefficients$p)))
    stop("individual-effect prediction requires finite fitted coefficients.", call. = FALSE)
  integration <- object$random_effects$integration
  if (!is.list(integration) || !identical(integration$status, "refined") ||
      !is.numeric(integration$selected_order) ||
      length(integration$selected_order) != 1L ||
      !is.finite(integration$selected_order) ||
      !integration$selected_order %in% .cmr_validate_quadrature_orders(integration$orders))
    stop("individual-effect prediction requires refined fitting quadrature.", call. = FALSE)
  if (!target %in% c("zero_effect", "integrated"))
    stop("unsupported individual-effect prediction target.", call. = FALSE)
  invisible(TRUE)
}

.cmr_prediction_sd <- function(object, process) {
  active <- !is.null(object$random_effects[[process]])
  if (!active) return(0)
  value <- object$random_effects$sd[[process]]
  if (!is.numeric(value) || !length(value) || any(!is.finite(value)) ||
      any(value < 0) || max(value) - min(value) > 1e-10 * max(1, max(value)))
    stop("individual-effect prediction requires a finite constant process SD.", call. = FALSE)
  unname(value[[1L]])
}

.cmr_prediction_sd_rows <- function(object, process, frame, ids) {
  if (is.null(object$random_effects[[process]])) return(rep(0, nrow(frame)))
  has_formula <- isTRUE(object$prediction_contract$sd_formula_present[[process]])
  if (!has_formula) return(rep(.cmr_prediction_sd(object, process), nrow(frame)))
  design <- object$random_effects$sd_design[[process]]
  gamma <- object$random_effects$parameters[[paste0("log_sd_", process)]]
  if (!is.list(design) || !inherits(design$terms, "terms") ||
      !is.character(design$columns) || !is.numeric(gamma) ||
      length(gamma) != length(design$columns) || any(!is.finite(gamma)))
    stop("individual-effect prediction requires valid fitted SD-design provenance.", call. = FALSE)
  mf <- tryCatch(stats::model.frame(design$terms, data = frame,
    na.action = stats::na.fail, xlev = design$xlevels), error = function(e)
      stop("cannot build the fitted ", process, " SD prediction schema: ", conditionMessage(e), call. = FALSE))
  mm <- tryCatch(stats::model.matrix(design$terms, mf, contrasts.arg = design$contrasts),
    error = function(e) stop("cannot build the fitted ", process, " SD model matrix: ", conditionMessage(e), call. = FALSE))
  if (!all(design$columns %in% colnames(mm)) || any(!is.finite(mm)))
    stop("prediction SD model matrix is non-finite or incompatible with fitted ", process, " SD coefficients.", call. = FALSE)
  mm <- mm[, design$columns, drop = FALSE]
  if (length(ids) != nrow(mm) || anyNA(ids)) stop("SD prediction IDs must be complete and aligned.", call. = FALSE)
  if (nrow(mm) > 1L) for (id in unique(ids)) {
    rows <- which(ids == id)
    if (length(rows) > 1L && any(apply(mm[rows, , drop = FALSE], 2L, function(z) max(z) - min(z) > 1e-10)))
      stop("SD-formula predictors must be constant within each prediction individual.", call. = FALSE)
  }
  offset <- stats::model.offset(mf)
  if (is.null(offset)) offset <- rep(0, nrow(mm))
  if (length(offset) != nrow(mm) || any(!is.finite(offset)))
    stop("SD prediction offsets must be finite and aligned.", call. = FALSE)
  if (length(offset) > 1L) for (id in unique(ids)) {
    rows <- which(ids == id)
    if (length(rows) > 1L && max(offset[rows]) - min(offset[rows]) > 1e-10)
      stop("SD-formula offsets must be constant within each prediction individual.", call. = FALSE)
  }
  value <- exp(as.numeric(mm %*% gamma + offset))
  if (any(!is.finite(value))) stop("predicted random-effect SDs must be finite.", call. = FALSE)
  value
}

.cmr_validate_quadrature_orders <- function(orders) {
  if (!is.numeric(orders) || !length(orders) || anyNA(orders) ||
      any(!is.finite(orders)) || any(orders < 1) ||
      any(orders != as.integer(orders)) || is.unsorted(orders, strictly = TRUE))
    stop("fitted individual-effect quadrature orders must be strictly increasing positive integers.", call. = FALSE)
  as.integer(orders)
}

.cmr_individual_mean <- function(eta, sigma, target, power, terminal, constraint,
                                 orders = c(25L, 41L, 65L, 97L)) {
  eta <- as.numeric(eta)
  if (!is.numeric(power) || !length(power) ||
      !(length(power) == 1L || length(power) == length(eta)) ||
      any(!is.finite(power)) || any(power <= 0))
    stop("prediction powers must be positive finite values, scalar or one per row.", call. = FALSE)
  if (!is.logical(terminal) || !length(terminal) ||
      !(length(terminal) == 1L || length(terminal) == length(eta)) || anyNA(terminal))
    stop("terminal flags must be complete logical values, scalar or one per row.", call. = FALSE)
  if (!is.numeric(sigma) || !(length(sigma) == 1L || length(sigma) == length(eta)) ||
      any(!is.finite(sigma)) || any(sigma < 0))
    stop("prediction SD must be one finite nonnegative value or one per row.", call. = FALSE)
  if (!is.character(target) || length(target) != 1L || is.na(target) ||
      !target %in% c("zero_effect", "integrated"))
    stop("unsupported individual-effect prediction target.", call. = FALSE)
  power <- rep_len(as.numeric(power), length(eta))
  sigma <- rep_len(as.numeric(sigma), length(eta))
  terminal <- rep_len(terminal, length(eta))
  orders <- .cmr_validate_quadrature_orders(orders)
  ans <- stats::plogis(eta)^power
  if (target == "integrated" && any(sigma > 0)) {
    active <- which(!terminal & sigma > 0)
    if (length(active)) {
      previous <- NULL
      converged <- FALSE
      for (order in orders) {
        gh <- .cmr_gauss_hermite(order)
        current <- vapply(active, function(i) sum(gh$weights *
          stats::plogis(eta[[i]] + sigma[[i]] * gh$nodes)^power[[i]]), numeric(1))
        if (!is.null(previous) && max(abs(current - previous)) <= 1e-8) {
          ans[active] <- current
          converged <- TRUE
          break
        }
        previous <- current
        ans[active] <- current
      }
      if (!converged)
        stop("individual-effect prediction quadrature is unrefined at order ",
             max(orders), ".", call. = FALSE)
    }
  }
  if (any(terminal) && !is.null(constraint))
    ans[terminal] <- constraint^power[terminal]
  ans
}

.cmr_simulation_probabilities <- function(eta_phi, eta_p, delta,
                                          z_phi, z_p, sigma_phi, sigma_p,
                                          phi_terminal, p_terminal,
                                          terminal_constraint = NULL) {
  if (!is.matrix(eta_phi) || !is.numeric(eta_phi) ||
      !is.matrix(eta_p) || !is.numeric(eta_p) ||
      !is.matrix(delta) || !is.numeric(delta) ||
      !identical(dim(delta), dim(eta_phi)) || any(!is.finite(eta_phi)) ||
      any(!is.finite(eta_p)) || any(!is.finite(delta)) || any(delta <= 0))
    stop("simulation linear predictors and interval lengths must be finite matrices with matching survival dimensions.", call. = FALSE)
  n <- nrow(eta_phi)
  if (nrow(eta_p) != n || !is.numeric(z_phi) || length(z_phi) != n ||
      !is.numeric(z_p) || length(z_p) != n || any(!is.finite(z_phi)) ||
      any(!is.finite(z_p)))
    stop("simulation latent draws must contain one finite value per expanded history.", call. = FALSE)
  for (item in list(sigma_phi, sigma_p)) if (!is.numeric(item) ||
      !length(item) %in% c(1L, n) || any(!is.finite(item)) || any(item < 0))
    stop("simulation process SDs must be finite nonnegative scalars or one value per history.", call. = FALSE)
  if (!is.logical(phi_terminal) || !identical(dim(phi_terminal), dim(eta_phi)) ||
      anyNA(phi_terminal) || !is.logical(p_terminal) ||
      !identical(dim(p_terminal), dim(eta_p)) || anyNA(p_terminal))
    stop("simulation terminal masks must be complete logical matrices matching their processes.", call. = FALSE)
  if (!is.null(terminal_constraint) && (!is.list(terminal_constraint) ||
      is.null(names(terminal_constraint)) ||
      any(!names(terminal_constraint) %in% c("phi", "p"))))
    stop("simulation terminal constraints must be a named list for `phi` or `p`.", call. = FALSE)

  for (value in terminal_constraint) if (!is.numeric(value) || length(value) != 1L ||
      !is.finite(value) || value < 0 || value > 1)
    stop("simulation terminal constraints must be finite scalar probabilities in [0, 1].", call. = FALSE)

  phi_unit <- stats::plogis(sweep(eta_phi, 1L, rep_len(sigma_phi, n) * z_phi, "+"))
  p <- stats::plogis(sweep(eta_p, 1L, rep_len(sigma_p, n) * z_p, "+"))
  phi_fixed <- terminal_constraint$phi
  p_fixed <- terminal_constraint$p
  if (any(phi_terminal) && !is.null(phi_fixed)) phi_unit[phi_terminal] <- phi_fixed
  if (any(p_terminal) && !is.null(p_fixed)) p[p_terminal] <- p_fixed
  list(phi_interval = phi_unit^delta, p = p)
}

#' Simulate conditional capture histories from a CJS fit
#' @param object A `drm_cjs` fit.
#' @param nsim Number of simulated data sets.
#' @param seed Optional seed. A supplied seed leaves the caller's RNG unchanged.
#' @param max_selection_attempts Maximum reference-law draws per individual
#'   while simulating a requested first-capture event.
#' @param ... Unused.
#' @return A list of `cmr_simulation` records that can be refitted. Individual-
#'   effect records carry a `simulation` attribute naming the target and effect
#'   draw rule; selection-conditioned records also carry aligned IDs and
#'   eligibility provenance.
#' @details For ordinary individual-effect fits, each history receives fresh
#'   independent process effects that persist across that complete simulated
#'   history. These are conditional marked-cohort replicates given first capture.
#'   Reference-selection fits draw persistent effects from the reference normal
#'   law, simulate from eligibility, and retain draws whose first capture occurs
#'   at each fitted occasion. The maximum attempts are bounded per individual.
#'   SD formulas are evaluated per individual when their predictors are
#'   constant across that individual's fitted history.
#' @export
simulate.drm_cjs <- function(object, nsim = 1L, seed = NULL,
                             max_selection_attempts = 100000L, ...) {
  .cmr_methods_dots(list(...), "simulate.drm_cjs")
  if (!inherits(object, "drm_cjs"))
    stop("`object` must be a `drm_cjs` fit.", call. = FALSE)
  route <- object$random_effects$route %||% ""
  if (route %in% c("site_phi", "site_p", "site_pair", "year_vector"))
    return(.cmr_simulate_shared(object, nsim = nsim, seed = seed))
  individual <- is.character(route) && length(route) == 1L &&
    !is.na(route) && startsWith(route, "individual_")
  selection_tilt <- individual && isTRUE(object$prediction_contract$selection_enabled)
  if (individual) {
    .cmr_prediction_validate_individual(object, "integrated", "response",
      allow_sd_formula = TRUE, allow_selection = TRUE)
  } else if (identical(route, "fixed")) {
    .cmr_methods_validate_fit(object)
  } else {
    .cmr_methods_validate_fit(object)
    stop("`simulate.drm_cjs` supports fixed effects and ordinary individual-effect CJS fits only.", call. = FALSE)
  }
  nsim <- .cmr_validate_count(nsim, "nsim")
  if (selection_tilt && (!is.numeric(max_selection_attempts) ||
      length(max_selection_attempts) != 1L || is.na(max_selection_attempts) ||
      !is.finite(max_selection_attempts) || max_selection_attempts < 1L ||
      max_selection_attempts != as.integer(max_selection_attempts)))
    stop("`max_selection_attempts` must be one positive integer.", call. = FALSE)
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

  simulation_sd <- function(process, copied_ids) {
    frame <- object[[paste0("training_", process, "_data")]]
    row_sd <- .cmr_prediction_sd_rows(object, process, frame, frame$id)
    key <- as.character(frame$id)
    first <- match(unique(key), key)
    values <- row_sd[first]
    names(values) <- unique(key)
    unname(values[match(as.character(copied_ids), names(values))])
  }

  n <- nrow(object$data$y)
  nt <- ncol(object$data$y)
  copies <- rep(seq_len(n), times = object$data$frequency)
  selection_history <- NULL
  if (selection_tilt) {
    if (!is.list(object$selection) || !identical(object$selection$assumption, "alive_available"))
      stop("reference selection simulation requires retained eligibility and assumption provenance.", call. = FALSE)
    selection_history <- .cmr_selection_training_input(object)
    selection_history$phi$eta <- .cmr_prediction_eta(object$phi,
      object$coefficients$phi, selection_history$phi, "phi", object)
    selection_history$p$observed <- selection_history$p$observed
    selection_history$p$eta <- 0
    use_p <- which(selection_history$p$observed)
    if (length(use_p)) selection_history$p$eta[use_p] <- .cmr_prediction_eta(
      object$p, object$coefficients$p,
      selection_history$p[use_p, , drop = FALSE], "p", object)
  }
  if (individual) {
    phi_eta <- matrix(as.numeric(object$phi$X %*% object$coefficients$phi + object$phi$offset),
                      nrow = n, byrow = TRUE)[copies, , drop = FALSE]
    p_eta <- matrix(as.numeric(object$p$X %*% object$coefficients$p + object$p$offset),
                    nrow = n, byrow = TRUE)[copies, , drop = FALSE]
    delta <- object$data$delta[copies, , drop = FALSE]
    sigma_phi <- simulation_sd("phi", object$data$id[copies])
    sigma_p <- simulation_sd("p", object$data$id[copies])
    phi_terminal <- matrix(FALSE, nrow = length(copies), ncol = nt - 1L)
    p_terminal <- matrix(FALSE, nrow = length(copies), ncol = nt)
    if (!is.null(object$terminal_constraint$phi) && nt > 1L)
      phi_terminal[, nt - 1L] <- TRUE
    if (!is.null(object$terminal_constraint$p)) p_terminal[, nt] <- TRUE
  } else {
    phi_eta <- matrix(as.numeric(object$phi$X %*% object$coefficients$phi + object$phi$offset),
                      nrow = n, byrow = TRUE)
    p_eta <- matrix(as.numeric(object$p$X %*% object$coefficients$p + object$p$offset),
                    nrow = n, byrow = TRUE)
    phi_unit <- stats::plogis(phi_eta)
    p_prob <- stats::plogis(p_eta)
    if (!is.null(object$terminal_constraint$phi) && nt > 1L)
      phi_unit[, nt - 1L] <- object$terminal_constraint$phi
    if (!is.null(object$terminal_constraint$p))
      p_prob[, nt] <- object$terminal_constraint$p
    phi_interval <- phi_unit ^ object$data$delta
  }
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
    selection_draw <- if (selection_tilt) .cmr_selection_forward_draw(
      object, selection_history, object$data$id[copies], sigma_phi, sigma_p,
      max_selection_attempts) else NULL
    if (individual) {
      if (selection_tilt) {
        z_phi <- selection_draw$z_phi
        z_p <- selection_draw$z_p
      } else {
        z_phi <- numeric(length(copies))
        z_p <- numeric(length(copies))
        active_phi <- which(sigma_phi > 0)
        active_p <- which(sigma_p > 0)
        if (length(active_phi)) z_phi[active_phi] <- stats::rnorm(length(active_phi))
        if (length(active_p)) z_p[active_p] <- stats::rnorm(length(active_p))
      }
      probability <- .cmr_simulation_probabilities(phi_eta, p_eta, delta,
        z_phi = z_phi, z_p = z_p, sigma_phi = sigma_phi, sigma_p = sigma_p,
        phi_terminal = phi_terminal, p_terminal = p_terminal,
        terminal_constraint = object$terminal_constraint)
      phi_draw <- probability$phi_interval
      p_draw <- probability$p
    } else {
      phi_draw <- phi_interval[copies, , drop = FALSE]
      p_draw <- p_prob[copies, , drop = FALSE]
    }
    y <- matrix(0L, nrow = length(copies), ncol = nt)
    y[!observed] <- NA_integer_
    for (j in seq_along(copies)) {
      alive <- TRUE
      if (selection_tilt) {
        eligibility <- object$selection$eligibility[copies[[j]]]
        if (eligibility > 1L)
          y[j, seq_len(eligibility - 1L)] <-
            object$data$y[copies[[j]], seq_len(eligibility - 1L)]
        y[j, seq.int(eligibility, first[[j]])] <-
          selection_draw$prehistory[j, seq.int(eligibility, first[[j]])]
      } else {
        y[j, first[[j]]] <- 1L
      }
      if (first[[j]] < end[[j]]) for (t in seq.int(first[[j]] + 1L, end[[j]])) {
        if (alive) alive <- stats::rbinom(1L, 1L, phi_draw[j, t - 1L]) == 1L
        y[j, t] <- if (!observed[j, t]) NA_integer_ else if (!alive) 0L else
          stats::rbinom(1L, 1L, p_draw[j, t])
      }
    }
    sim_data <- cmr_data(y, id = new_ids, observed = observed,
                         occasions = object$data$occasions, intervals = intervals,
                         units = object$data$units, end = end, frequency = 1L)
    record <- structure(list(data = sim_data, phi_data = phi_data, p_data = p_data,
                             replicate = s), class = "cmr_simulation")
    if (individual) attr(record, "simulation") <- list(
      target = if (selection_tilt) "reference_selection_marked_cohort" else
        "conditional_first_capture_marked_cohort",
      effects = if (selection_tilt) "persistent_reference_normal_effects_forward_rejection_selected" else
        "persistent_independent_individual_effects",
      selection = if (selection_tilt) list(
        id = new_ids,
        eligibility = object$selection$eligibility[copies],
        assumption = object$selection$assumption,
        random_effect_draw = "reference_normal_forward_rejection_at_first_capture") else NULL)
    record
  })
}

#' Covariance matrix for a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param ... Unused.
#' @return The fixed-coefficient block of the inverse observed negative-log-
#'   likelihood Hessian. Wald covariance requires converged fits with finite,
#'   nonsingular interior curvature. Individual-effect fits at variance
#'   boundaries and shared-effect fits are not eligible.
#' @export
vcov.drm_cjs <- function(object, ...) {
  .cmr_methods_dots(list(...), "vcov.drm_cjs")
  .cmr_methods_validate_fit(object, require_curvature = TRUE)
  nm <- names(coef.drm_cjs(object))
  if (!length(nm)) return(matrix(numeric(), 0L, 0L, dimnames = list(character(), character())))
  full <- solve(object$hessian)
  idx <- seq_along(nm)
  if (nrow(full) < length(idx))
    stop("the observed Hessian does not contain all fitted CJS coefficients.", call. = FALSE)
  ans <- full[idx, idx, drop = FALSE]
  dimnames(ans) <- list(nm, nm)
  ans
}

#' Wald, profile, or parametric-bootstrap intervals for a conditional CJS fit
#' @param object A `drm_cjs` fit.
#' @param parm Optional coefficient names or indices. For constant individual or shared
#'   SD profiles, use `"sd:phi"` or `"sd:p"`. For an individual or shared SD
#'   formula, use a fitted coefficient name such as `"sd_phi:z"` or `"sd_p:z"`.
#' @param level Confidence level.
#' @param method `"wald"`, `"profile"`, or `"bootstrap"`.
#' @param nsim Bootstrap attempts.
#' @param seed Optional bootstrap seed.
#' @param min_usable Minimum usable bootstrap fits before percentile intervals are returned.
#' @param ... Unused.
#' @return An interval matrix with method diagnostics in
#'   attributes. The bootstrap `attempts` attribute retains convergence,
#'   quadrature, curvature, and numerical zero-SD diagnostics separately.
#'   Profile and parametric-bootstrap intervals are available for
#'   native integrated individual-effect fits. Wald intervals additionally
#'   require nonsingular interior curvature. Bootstrap eligibility is recorded
#'   separately from Wald curvature and requires finite converged estimates
#'   with accepted quadrature refinement for integrated fits. Bootstrap
#'   intervals require at least `min_usable` refits; availability does not
#'   establish calibration. Constant shared SD limits exponentiate finite interior
#'   log-SD profile endpoints and do not evaluate an exact-zero model. Shared-effect
#'   fixed-coefficient and SD-formula
#'   profile intervals require a stationary positive-curvature latent mode;
#'   shared-effect Wald and bootstrap intervals remain unavailable.
#'   Fixed-effect rows are on the
#'   coefficient scale. Ordinary individual coefficient profiles require refined
#'   fitted integration, rebuild and refine each constrained point over the saved
#'   quadrature ladder, and withhold limits when the refitted center disagrees
#'   with or improves on the fitted likelihood, any constrained point improves
#'   on the fitted likelihood, or an endpoint fails its numerical check. If any
#'   constrained point improves on the fit, both endpoint limits are withheld.
#'   Availability does not establish calibration.
#'   Individual `sd:phi` and `sd:p` profile rows are on the
#'   SD scale. Their exact-zero endpoint is
#'   evaluated with the selected effect removed and the remaining CJS model
#'   reoptimized. A constrained endpoint is withheld when its optimizer fails
#'   or quadrature does not refine. SD-formula coefficients can also be profiled
#'   by their `sd_phi:<column>` or `sd_p:<column>` names for individual or
#'   shared effects; shared profile points re-solve the latent mode. Those
#'   limits use the log-SD coefficient scale. Profile availability does not
#'   establish calibration.
#' @export
confint.drm_cjs <- function(object, parm, level = 0.95,
                            method = c("wald", "profile", "bootstrap"),
                            nsim = 200L, seed = NULL, min_usable = 100L, ...) {
  .cmr_methods_dots(list(...), "confint.drm_cjs")
  method <- match.arg(method)
  if (identical(object$engine, "julia") && method != "wald")
    stop("the Julia CJS bridge currently provides local Wald curvature only; profile and bootstrap intervals remain on the native TMB route.", call. = FALSE)
  if (length(level) != 1L || is.na(level) || !is.finite(level) || level <= 0 || level >= 1)
    stop("`level` must be one number strictly between zero and one.", call. = FALSE)
  estimates <- coef.drm_cjs(object)
  if (missing(parm)) parm <- names(estimates)
  variance_targets <- if (is.character(parm) && !anyNA(parm))
    grep("^sd:(phi|p)$", parm, value = TRUE) else character()
  sd_formula_targets <- if (is.character(parm) && !anyNA(parm))
    intersect(parm, .cmr_sd_formula_profile_targets(object)) else character()
  if (is.numeric(parm)) {
    if (anyNA(parm) || any(parm != as.integer(parm)) || any(parm < 1L) || any(parm > length(estimates)))
      stop("`parm` contains an invalid coefficient index.", call. = FALSE)
    parm <- names(estimates)[as.integer(parm)]
  }
  if (!is.character(parm) || anyNA(parm) ||
      any(!parm %in% c(names(estimates), variance_targets,
                       .cmr_sd_formula_profile_targets(object))))
    stop("`parm` must name fitted CJS coefficients, constant individual or shared SD targets (`sd:phi`, `sd:p`), or random-effect SD-formula coefficients (`sd_phi:<column>`, `sd_p:<column>`).", call. = FALSE)
  parm <- unique(parm)
  variance_targets <- intersect(parm, variance_targets)
  sd_formula_targets <- intersect(parm, sd_formula_targets)
  if (length(variance_targets) && method != "profile")
    stop("constant SD targets are currently available only with `method = \"profile\"`.", call. = FALSE)
  if (length(sd_formula_targets) && method != "profile")
    stop("individual SD-formula coefficients are currently available only with `method = \"profile\"`.", call. = FALSE)
  z <- stats::qnorm(1 - (1 - level) / 2)
  ans <- matrix(NA_real_, length(parm), 2L,
                dimnames = list(parm, c("lower", "upper")))
  if (method == "wald") {
    variance <- tryCatch(vcov.drm_cjs(object), error = function(e) e)
    target_status <- stats::setNames(rep("ok", length(parm)), parm)
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
  .cmr_methods_validate_fit(
    object,
    allow_individual = method %in% c("profile", "bootstrap"),
    allow_shared_profile = method == "profile"
  )
  if (method == "profile") {
    variance <- tryCatch(vcov.drm_cjs(object), error = function(e) NULL)
    profile_se <- if (is.null(variance)) rep(.5, length(estimates)) else
      sqrt(diag(variance))
    statuses <- matrix("not_attempted", length(parm), 2L,
                       dimnames = list(parm, c("lower", "upper")))
    coefficient_targets <- setdiff(parm, c(variance_targets, sd_formula_targets))
    coefficient_profiles <- list()
    selection_profiles <- list()
    selected <- isTRUE(object$obj$env$data$cmr_selection != 0)
    invalid_profile_target <- NULL
    for (nm in coefficient_targets) {
      if (selected) {
        process <- if (startsWith(nm, "phi:")) "phi" else "p"
        index <- match(nm, names(coef.drm_cjs(object, process = process)))
        prof <- .cmr_cjs_selection_profile(object, process, index, level)
        ans[nm, ] <- c(prof$lower$estimate, prof$upper$estimate)
        endpoint <- c(prof$lower$status, prof$upper$status)
        statuses[nm, ] <- ifelse(endpoint == "available", "ok", endpoint)
        selection_profiles[[nm]] <- prof
      } else {
        if (startsWith(object$random_effects$route, "individual_") &&
            !identical(object$random_effects$integration$status, "refined"))
          stop("CJS coefficient profiles require refined individual-effect quadrature.",
               call. = FALSE)
        j <- match(nm, names(estimates))
        process <- if (startsWith(nm, "phi:")) "phi" else "p"
        process_index <- match(nm, names(coef.drm_cjs(object, process = process)))
        prof <- if (startsWith(object$random_effects$route, "individual_"))
          .cmr_profile_individual_beta(object, process, process_index,
                                       estimates[[nm]], profile_se[[j]], level) else
          .cmr_profile_endpoint(object, j, estimates[[nm]],
                                profile_se[[j]], level)
        ans[nm, ] <- prof$limits
        statuses[nm, ] <- prof$status
        if (!is.null(prof$diagnostic))
          coefficient_profiles[[nm]] <- prof$diagnostic
      }
      if (any(statuses[nm, ] == "profile_improves_on_fit")) {
        invalid_profile_target <- nm
        break
      }
    }
    variance_profiles <- list()
    for (nm in if (is.null(invalid_profile_target)) variance_targets else character()) {
      process <- sub("^sd:", "", nm)
      prof <- if (isTRUE(object$random_effects$laplace))
        .cmr_profile_shared_sd(object, process, level) else
          .cmr_profile_individual_sd(object, process, level)
      ans[nm, ] <- prof$limits
      statuses[nm, ] <- prof$status
      variance_profiles[[nm]] <- prof$diagnostic
      if (any(statuses[nm, ] == "profile_improves_on_fit")) {
        invalid_profile_target <- nm
        break
      }
    }
    sd_formula_profiles <- list()
    for (nm in if (is.null(invalid_profile_target)) sd_formula_targets else character()) {
      process <- if (startsWith(nm, "sd_phi:")) "phi" else "p"
      prefix <- paste0("sd_", process, ":")
      column <- substring(nm, nchar(prefix) + 1L)
      design <- object$random_effects$sd_design[[process]]
      index <- match(column, design$columns)
      if (is.na(index)) stop("the requested SD-formula coefficient is absent from the fitted design.", call. = FALSE)
      prof <- .cmr_profile_sd_formula_coefficient(object, process, index, level)
      ans[nm, ] <- prof$limits
      statuses[nm, ] <- prof$status
      sd_formula_profiles[[nm]] <- prof$diagnostic
      if (any(statuses[nm, ] == "profile_improves_on_fit")) {
        invalid_profile_target <- nm
        break
      }
    }
    if (!is.null(invalid_profile_target)) {
      invalid_rows <- rownames(statuses)[apply(statuses == "profile_improves_on_fit", 1L, any)]
      attempted_rows <- rownames(statuses)[apply(statuses != "not_attempted", 1L, any)]
      prior_rows <- setdiff(attempted_rows, invalid_rows)
      if (length(prior_rows)) statuses[prior_rows, ] <- "fit_invalidated"
      statuses[invalid_rows, ] <- ifelse(
        statuses[invalid_rows, , drop = FALSE] == "not_attempted",
        "not_attempted", "profile_improves_on_fit"
      )
      ans[,] <- NA_real_
    }
    attr(ans, "method") <- "profile"
    attr(ans, "endpoint_status") <- statuses
    if (!is.null(invalid_profile_target))
      attr(ans, "profile_fit_status") <- "profile_improved_on_fit"
    if (length(selection_profiles)) {
      attr(ans, "selection_profile") <- selection_profiles
      attr(ans, "calibrated") <- FALSE
    }
    if (length(coefficient_profiles))
      attr(ans, "coefficient_profile") <- coefficient_profiles
    if (length(variance_profiles)) {
      attr(ans, "variance_profile") <- variance_profiles
      if (isTRUE(object$random_effects$laplace)) attr(ans, "calibrated") <- FALSE
    }
    if (length(sd_formula_profiles)) {
      attr(ans, "sd_formula_profile") <- sd_formula_profiles
      if (isTRUE(object$random_effects$laplace)) attr(ans, "calibrated") <- FALSE
    }
    attr(ans, "target_status") <- stats::setNames(apply(statuses, 1L, function(x) {
      available <- x %in% c("ok", "boundary_included")
      if (all(available)) "ok" else if (any(available)) "partial" else "unavailable"
    }), parm)
    return(ans)
  }
  nsim <- .cmr_validate_count(nsim, "nsim")
  min_usable <- .cmr_validate_count(min_usable, "min_usable")
  draws <- .cmr_bootstrap_coefficients(object, nsim, seed)
  usable <- vapply(draws$attempts$coefficients, function(x) !is.null(x), logical(1))
  sample <- if (any(usable)) do.call(rbind, draws$attempts$coefficients[usable]) else NULL
  target_status <- stats::setNames(rep("insufficient_usable", length(parm)), parm)
  n_usable_target <- stats::setNames(integer(length(parm)), parm)
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

.cmr_sd_formula_profile_targets <- function(object) {
  route <- object$random_effects$route
  individual <- is.character(route) && length(route) == 1L &&
    startsWith(route, "individual_")
  if (!individual && !isTRUE(object$random_effects$laplace)) return(character())
  unlist(lapply(c("phi", "p"), function(process) {
    if (is.null(object$random_effects[[process]])) return(character())
    design <- object$random_effects$sd_design[[process]]
    if (!is.list(design) || !length(design$columns)) return(character())
    paste0("sd_", process, ":", design$columns)
  }), use.names = FALSE)
}

.cmr_profile_sd_formula_coefficient <- function(object, process, index, level,
    parameter = paste0("log_sd_", process), coefficient_name = NULL,
    retain_points = FALSE) {
  if (is.null(coefficient_name))
    coefficient_name <- object$random_effects$sd_design[[process]]$columns[[index]]
  profile_nll <- if (identical(parameter, paste0("log_sd_", process)))
    function(value) .cmr_cjs_profile_sd_coefficient_nll(object, process, index, value) else
      function(value) .cmr_cjs_shared_profile_sd_coefficient_nll(
        object, process, index, value, parameter = parameter)
  estimate <- unname(object$random_effects$parameters[[parameter]][[index]])
  center <- as.numeric(object$obj$fn(object$optimizer$par))
  baseline <- profile_nll(estimate)
  points <- list(list(value = estimate, point = baseline))
  state <- new.env(parent = emptyenv())
  state$last_status <- baseline$status
  state$last_message <- baseline$message
  state$evaluations <- 1L
  state$unrefined <- identical(baseline$status, "unrefined_at_order_cap")
  state$improves <- FALSE
  improvement_tolerance <- 1e-5 * if (retain_points) 1 else max(1, abs(center))
  cutoff <- stats::qchisq(level, df = 1L)
  profile_q <- function(value) {
    if (state$improves) return(NA_real_)
    point <- profile_nll(value)
    if (retain_points) points[[length(points) + 1L]] <<- list(value = value, point = point)
    state$evaluations <- state$evaluations + 1L
    state$last_status <- point$status
    state$last_message <- point$message
    if (!point$status %in% c("refined", "shared_laplace")) {
      if (identical(point$status, "unrefined_at_order_cap")) state$unrefined <- TRUE
      return(NA_real_)
    }
    if (point$status %in% c("refined", "shared_laplace") &&
        is.finite(point$nll) && point$nll < center - improvement_tolerance) {
      state$improves <- TRUE
      state$last_status <- "profile_improves_on_fit"
      if (retain_points) {
        point$status <- "profile_improves_on_fit"
        points[[length(points)]] <<- list(value = value, point = point)
      }
      return(NA_real_)
    }
    2 * (point$nll - center) - cutoff
  }
  limits <- c(NA_real_, NA_real_)
  statuses <- rep("failed_profile", 2L)
  baseline_ok <- baseline$status %in% c("refined", "shared_laplace") &&
    abs(baseline$nll - center) <= 1e-5 * if (retain_points) 1 else max(1, abs(center))
  if (baseline_ok) {
    for (j in seq_along(limits)) {
      direction <- if (j == 1L) -1 else 1
      limits[[j]] <- .cmr_profile_sd_crossing(profile_q, estimate, direction)
      if (state$improves) {
        statuses[] <- "profile_improves_on_fit"
        limits[] <- NA_real_
        break
      }
      statuses[[j]] <- if (is.finite(limits[[j]])) "ok" else
        if (state$unrefined) "integration_unrefined" else
          if (!state$last_status %in% c("refined", "shared_laplace")) "profile_fit_unusable" else "non_crossing"
    }
  } else {
    baseline_difference <- baseline$nll - center
    statuses[] <- if (state$unrefined) "integration_unrefined" else
      if (!baseline$status %in% c("refined", "shared_laplace") ||
          !is.finite(baseline_difference)) "profile_fit_unusable" else
        if (baseline_difference < -improvement_tolerance) "profile_improves_on_fit" else
          "profile_center_mismatch"
  }
  endpoints <- vector("list", 2L)
  if (retain_points) for (j in seq_along(limits)) {
    if (!is.finite(limits[[j]])) next
    point <- profile_nll(limits[[j]])
    state$evaluations <- state$evaluations + 1L
    state$last_status <- point$status
    state$last_message <- point$message
    endpoints[[j]] <- list(value = limits[[j]], point = point)
    points[[length(points) + 1L]] <- endpoints[[j]]
    residual <- 2 * (point$nll - center) - cutoff
    if (point$status %in% c("refined", "shared_laplace") &&
        is.finite(point$nll) && point$nll < center - improvement_tolerance) {
      state$improves <- TRUE
      state$last_status <- "profile_improves_on_fit"
      point$status <- "profile_improves_on_fit"
      endpoints[[j]]$point$status <- "profile_improves_on_fit"
      points[[length(points)]] <- endpoints[[j]]
      limits[] <- NA_real_
      statuses[] <- "profile_improves_on_fit"
      next
    }
    if (!point$status %in% c("refined", "shared_laplace") ||
        !is.finite(residual) || abs(residual) > 2e-4) {
      limits[[j]] <- NA_real_
      statuses[[j]] <- "endpoint_unverified"
    }
  }
  result <- list(limits = limits, status = statuses,
       diagnostic = list(estimate = estimate,
         coefficient_name = coefficient_name,
         profile_scale = "log_sd_coefficient",
         integration = if (identical(baseline$status, "shared_laplace"))
           "shared_laplace" else "individual_gauss_hermite",
         baseline_nll = baseline$nll,
         baseline_objective_difference = baseline$nll - center,
         selection_normalization_retained =
           isTRUE(object$obj$env$data$cmr_selection != 0),
         profile_quadrature_status = if (state$unrefined)
           "unrefined_at_order_cap" else state$last_status,
         profile_evaluations = state$evaluations,
         profile_last_status = state$last_status,
         profile_last_message = state$last_message))
  if (retain_points) {
    result$diagnostic$points <- points
    result$diagnostic$endpoints <- endpoints
    result$diagnostic$cutoff <- cutoff
  }
  result
}

.cmr_profile_shared_sd <- function(object, process, level) {
  re <- object$random_effects
  if (!isTRUE(re$laplace) || is.null(re[[process]]))
    stop("SD profile targets require an estimated shared effect on that process.", call. = FALSE)
  model_type <- object$obj$env$data$model_type
  parameter <- if (identical(as.integer(model_type), 1001L))
    paste0("log_sigma_", process) else paste0("log_sd_", process)
  values <- re$parameters[[parameter]]
  design <- re$sd_design[[process]]
  if (!model_type %in% c(1001L, 1003L) || length(values) != 1L ||
      (model_type == 1003L && (!is.list(design) ||
       !identical(design$columns, "(Intercept)") || !is.matrix(design$X) ||
       ncol(design$X) != 1L || any(design$X != 1) || any(design$offset != 0))))
    stop("SD profile targets require a constant shared SD (one intercept, no SD offset); profile SD-formula coefficients by name.", call. = FALSE)
  log_sd <- unname(values[[1L]])
  sd <- exp(log_sd)
  if (!is.finite(sd) || sd <= 1e-8)
    return(list(limits = c(NA_real_, NA_real_),
      status = rep(if (!is.finite(sd)) "transform_unavailable" else "variance_boundary", 2L),
      diagnostic = list(estimate = sd, profile_scale = "sd", interval_scale = "sd", coordinate = parameter,
        integration = "shared_laplace", zero_model = "not_evaluated",
        log_limits = c(NA_real_, NA_real_), points = list(), endpoints = list(),
        calibrated = FALSE)))
  prof <- .cmr_profile_sd_formula_coefficient(object, process, 1L, level,
    parameter = parameter, coefficient_name = "(Intercept)", retain_points = TRUE)
  # A constant random-effect SD has a real zero boundary at log(SD) = -Inf.
  # When the lower profile search reaches a stable, refined zero-SD plateau
  # below the likelihood-ratio cutoff, include that boundary in the interval
  # instead of reporting a missing `non_crossing` endpoint.
  if (identical(prof$status[[1L]], "non_crossing")) {
    points <- prof$diagnostic$points
    zero_plateau <- Filter(function(x) {
      is.finite(x$value) && x$value <= log(1e-6) &&
        x$point$status %in% c("refined", "shared_laplace") &&
        is.finite(x$point$nll)
    }, points)
    if (length(zero_plateau) >= 2L) {
      tail_points <- utils::tail(zero_plateau, 2L)
      boundary_lr <- 2 * (tail_points[[2L]]$point$nll -
                            prof$diagnostic$baseline_nll)
      plateau_change <- 2 * abs(tail_points[[2L]]$point$nll -
                                  tail_points[[1L]]$point$nll)
      if (is.finite(boundary_lr) && boundary_lr <= prof$diagnostic$cutoff &&
          is.finite(plateau_change) && plateau_change <= 2e-4) {
        prof$limits[[1L]] <- -Inf
        prof$status[[1L]] <- "boundary_included"
        prof$diagnostic$zero_boundary_lr <- boundary_lr
        prof$diagnostic$zero_boundary_plateau_change <- plateau_change
      }
    }
  }
  prof$diagnostic$log_limits <- prof$limits
  limits <- exp(prof$limits)
  invalid <- is.finite(prof$limits) & (!is.finite(limits) | limits <= 0)
  prof$status[invalid] <- "transform_unavailable"
  limits[invalid | !prof$status %in% c("ok", "boundary_included")] <- NA_real_
  prof$limits <- limits
  prof$diagnostic$estimate <- sd
  prof$diagnostic$profile_scale <- "sd"
  prof$diagnostic$interval_scale <- "sd"
  prof$diagnostic$integration <- "shared_laplace"
  prof$diagnostic$coordinate <- parameter
  prof$diagnostic$zero_model <- "not_evaluated"
  prof$diagnostic$calibrated <- FALSE
  prof
}

.cmr_profile_individual_sd <- function(object, process, level) {
  route <- object$random_effects$route
  if (!startsWith(route, "individual_") || is.null(object$random_effects[[process]]))
    stop("SD profile targets require an estimated individual effect on that process.", call. = FALSE)
  if (!identical(object$random_effects$integration$status, "refined"))
    stop("SD profile targets require refined individual-effect quadrature.", call. = FALSE)
  parameter <- paste0("log_sd_", process)
  values <- object$random_effects$parameters[[parameter]]
  design <- object$random_effects$sd_design[[process]]
  if (length(values) != 1L || !is.list(design) ||
      !identical(design$columns, "(Intercept)") ||
      !is.matrix(design$X) || ncol(design$X) != 1L ||
      any(design$X != 1) || any(design$offset != 0))
    stop("SD profile targets currently require a constant individual SD (one intercept, no SD offset).", call. = FALSE)
  j <- match(parameter, names(object$optimizer$par))
  if (is.na(j)) stop("the fitted CJS optimizer does not expose the constant SD parameter.", call. = FALSE)

  parhat <- object$optimizer$par
  log_sd_hat <- unname(parhat[[j]])
  sd_hat <- exp(log_sd_hat)
  center <- object$obj$fn(parhat)
  zero_fit <- .cmr_cjs_zero_sd_nll(object, process)
  zero_nll <- zero_fit$nll
  zero_lr <- 2 * (zero_nll - center)
  if (!is.finite(zero_lr) || zero_lr < -1e-5)
    stop("the exact-zero reduced CJS fit is not comparable with the fitted integrated likelihood.", call. = FALSE)
  zero_lr <- max(0, zero_lr)
  cutoff <- stats::qchisq(level, df = 1L)
  profile_state <- new.env(parent = emptyenv())
  profile_state$unrefined <- FALSE
  profile_state$evaluations <- 0L
  profile_state$max_order <- NA_integer_
  profile_state$last_status <- "not_attempted"
  profile_state$improves <- FALSE
  profile_q <- function(log_sd) {
    if (profile_state$improves) return(NA_real_)
    value <- .cmr_cjs_profile_sd_nll(object, process, log_sd)
    profile_state$evaluations <- profile_state$evaluations + 1L
    profile_state$last_status <- value$status
    profile_state$max_order <- if (is.na(profile_state$max_order)) value$order else
      max(profile_state$max_order, value$order)
    if (!identical(value$status, "refined")) {
      if (identical(value$status, "unrefined_at_order_cap"))
        profile_state$unrefined <- TRUE
      return(NA_real_)
    }
    if (is.finite(value$nll) && value$nll < center - 1e-5) {
      profile_state$improves <- TRUE
      profile_state$last_status <- "profile_improves_on_fit"
      return(NA_real_)
    }
    2 * (value$nll - center) - cutoff
  }
  limits <- c(NA_real_, NA_real_)
  status <- c("failed_profile", "failed_profile")
  lower_status <- if (zero_lr <= cutoff) "boundary_included" else "positive_crossing"
  if (zero_lr <= cutoff) {
    limits[[1L]] <- 0
    status[[1L]] <- "boundary_included"
  } else {
    limits[[1L]] <- .cmr_profile_sd_crossing(profile_q, log_sd_hat, -1)
    if (profile_state$improves) {
      limits[] <- NA_real_
      status[] <- "profile_improves_on_fit"
      lower_status <- "profile_improves_on_fit"
    }
    status[[1L]] <- if (is.finite(limits[[1L]])) "ok" else
      if (profile_state$improves) "profile_improves_on_fit" else if (profile_state$unrefined) "integration_unrefined" else
        if (profile_state$last_status != "not_attempted") "profile_fit_unusable" else "failed_profile"
    if (is.finite(limits[[1L]])) {
      limits[[1L]] <- exp(limits[[1L]])
      if (!is.finite(limits[[1L]]) || limits[[1L]] <= 0) {
        limits[[1L]] <- NA_real_
        status[[1L]] <- "transform_unavailable"
      }
    }
  }
  if (!profile_state$improves) limits[[2L]] <- .cmr_profile_sd_crossing(profile_q, log_sd_hat, 1)
  if (profile_state$improves) {
    limits[] <- NA_real_
    status[] <- "profile_improves_on_fit"
  }
  status[[2L]] <- if (is.finite(limits[[2L]])) "ok" else
    if (profile_state$improves) "profile_improves_on_fit" else if (profile_state$unrefined) "integration_unrefined" else
      if (profile_state$last_status != "not_attempted") "profile_fit_unusable" else "failed_profile"
  if (is.finite(limits[[2L]])) {
    limits[[2L]] <- exp(limits[[2L]])
    if (!is.finite(limits[[2L]]) || limits[[2L]] <= 0) {
      limits[[2L]] <- NA_real_
      status[[2L]] <- "transform_unavailable"
    }
  }
  list(limits = limits, status = status,
       diagnostic = list(estimate = sd_hat, zero_nll = zero_nll,
                         zero_lr = zero_lr, cutoff = cutoff,
                         lower_status = lower_status,
                         zero_model = "exact_reduced_model",
                         selection_normalization_retained = zero_fit$selection_normalization_retained,
                         other_process_effect_retained = zero_fit$other_process_effect_retained,
                         quadrature_order = zero_fit$quadrature_order,
                         quadrature_status = zero_fit$quadrature_status,
                         profile_quadrature_status = if (profile_state$unrefined)
                           "unrefined_at_order_cap" else if (profile_state$last_status != "refined")
                             "profile_fit_unusable" else "refined_at_each_profile_point",
                         profile_last_status = profile_state$last_status,
                         profile_evaluations = profile_state$evaluations,
                         profile_max_order = profile_state$max_order))
}

.cmr_cjs_profile_bfgs_continuation <- function(objective, gradient, start,
                                               reference_objective) {
  continuation <- tryCatch(
    stats::optim(start, objective, gr = gradient, method = "BFGS",
                 control = list(maxit = 5000L, reltol = 1e-14)),
    error = identity
  )
  if (inherits(continuation, "error"))
    return(list(usable = FALSE, convergence = NA_integer_, value = NA_real_,
                par = start, gradient_norm = Inf))

  continuation_gradient <- gradient(continuation$par)
  gradient_norm <- if (length(continuation_gradient) &&
                       all(is.finite(continuation_gradient))) {
    max(abs(continuation_gradient))
  } else if (!length(continuation_gradient)) {
    0
  } else {
    Inf
  }
  usable <- continuation$convergence == 0L &&
    is.finite(continuation$value) && all(is.finite(continuation$par)) &&
    is.finite(gradient_norm) && gradient_norm <= 1e-4 &&
    continuation$value <= reference_objective + 1e-8
  list(usable = usable, convergence = continuation$convergence,
       value = continuation$value, par = continuation$par,
       gradient_norm = gradient_norm)
}

.cmr_cjs_profile_newton_continuation <- function(
    objective, gradient, hessian, start, reference_objective,
    gradient_tolerance = 1e-4, max_iterations = 12L,
    condition_limit = 1e12, max_backtracks = 24L) {
  par <- as.numeric(start)
  value <- tryCatch(as.numeric(objective(par)), error = function(e) NA_real_)
  reference_objective <- as.numeric(reference_objective)
  fail <- function(reason, iterations = 0L, gradient_norm = Inf) {
    list(usable = FALSE, convergence = 1L, value = value, par = par,
         gradient_norm = gradient_norm, iterations = as.integer(iterations),
         reason = reason)
  }
  if (!length(par) || any(!is.finite(par)) || !is.finite(value) ||
      length(reference_objective) != 1L || !is.finite(reference_objective))
    return(fail("invalid_start_or_objective"))

  for (iteration in 0L:max_iterations) {
    score <- tryCatch(as.numeric(gradient(par)), error = function(e) NA_real_)
    if (length(score) != length(par) || any(!is.finite(score)))
      return(fail("invalid_gradient", iteration))
    gradient_norm <- if (length(score)) max(abs(score)) else 0
    if (gradient_norm <= gradient_tolerance) {
      usable <- value <= reference_objective + 1e-8
      return(list(usable = usable, convergence = if (usable) 0L else 1L,
        value = value, par = par, gradient_norm = gradient_norm,
        iterations = as.integer(iteration),
        reason = if (usable) "gradient_tolerance" else "reference_objective_exceeded"))
    }
    if (iteration == max_iterations)
      return(fail("iteration_limit", iteration, gradient_norm))

    observed_hessian <- tryCatch(as.matrix(hessian(par)), error = function(e) NULL)
    if (is.null(observed_hessian) || !identical(dim(observed_hessian),
        c(length(par), length(par))) || any(!is.finite(observed_hessian)))
      return(fail("invalid_hessian", iteration, gradient_norm))
    hessian_asymmetry <- max(abs(observed_hessian - t(observed_hessian)))
    if (!is.finite(hessian_asymmetry) || hessian_asymmetry >
        1e-8 * max(1, max(abs(observed_hessian))))
      return(fail("asymmetric_hessian", iteration, gradient_norm))
    observed_hessian <- (observed_hessian + t(observed_hessian)) / 2
    eigenvalues <- tryCatch(eigen(observed_hessian, symmetric = TRUE,
      only.values = TRUE)$values, error = function(e) NA_real_)
    if (length(eigenvalues) != length(par) || any(!is.finite(eigenvalues)) ||
        min(eigenvalues) <= 0)
      return(fail("nonpositive_curvature", iteration, gradient_norm))
    condition_number <- max(eigenvalues) / min(eigenvalues)
    if (!is.finite(condition_number) || condition_number >= condition_limit)
      return(fail("ill_conditioned_curvature", iteration, gradient_norm))

    diagonal_scale <- sqrt(diag(observed_hessian))
    if (any(!is.finite(diagonal_scale)) || any(diagonal_scale <= 0))
      return(fail("invalid_hessian_scale", iteration, gradient_norm))
    scaled_hessian <- observed_hessian / outer(diagonal_scale, diagonal_scale)
    scaled_gradient <- score / diagonal_scale
    scaled_direction <- tryCatch(base::solve(scaled_hessian, scaled_gradient),
      error = function(e) NULL)
    if (is.null(scaled_direction) || any(!is.finite(scaled_direction)))
      return(fail("newton_solve_failed", iteration, gradient_norm))
    direction <- as.numeric(scaled_direction / diagonal_scale)
    directional_product <- sum(score * direction)
    if (!is.finite(directional_product) || directional_product <= 0)
      return(fail("newton_direction_not_descent", iteration, gradient_norm))

    accepted <- FALSE
    alpha <- 1
    for (backtrack in 0L:max_backtracks) {
      candidate <- par - alpha * direction
      candidate_value <- tryCatch(as.numeric(objective(candidate)),
        error = function(e) NA_real_)
      armijo_bound <- value - 1e-4 * alpha * directional_product
      if (length(candidate_value) == 1L && is.finite(candidate_value) &&
          candidate_value <= armijo_bound) {
        par <- candidate
        value <- candidate_value
        accepted <- TRUE
        break
      }
      alpha <- alpha / 2
    }
    if (!accepted)
      return(fail("armijo_failed", iteration, gradient_norm))
  }
  fail("iteration_limit", max_iterations)
}

.cmr_cjs_profile_sd_nll <- function(object, process, log_sd,
                                    coefficient_index = NULL) {
  base_data <- object$obj$env$data
  parameters <- object$obj$env$parList(object$optimizer$par)
  parameter <- paste0("log_sd_", process)
  if (is.null(coefficient_index)) {
    parameters[[parameter]][] <- log_sd
    map_index <- rep(NA_integer_, length(parameters[[parameter]]))
  } else {
    if (length(coefficient_index) != 1L || is.na(coefficient_index) ||
        coefficient_index < 1L || coefficient_index != as.integer(coefficient_index) ||
        coefficient_index > length(parameters[[parameter]]))
      stop("`coefficient_index` must identify one fitted SD-formula coefficient.",
           call. = FALSE)
    parameters[[parameter]][[coefficient_index]] <- log_sd
    map_index <- seq_along(parameters[[parameter]])
    map_index[[coefficient_index]] <- NA_integer_
  }
  map <- stats::setNames(list(factor(map_index)), parameter)
  orders <- object$random_effects$integration$orders
  if (is.null(coefficient_index) &&
      startsWith(object$random_effects$route, "individual_")) {
    # The retained order-97 gate can be too low for the upper tail of a
    # constant individual-SD profile. Extend only that profile point, and only
    # when adjacent-order history/selection reports have not yet stabilized.
    # Typical points still stop at the first accepted adjacent-order pair.
    orders <- unique(c(orders, 129L, 161L, 193L, 257L))
  }
  previous <- NULL
  previous_report <- NULL
  accepted <- NULL
  for (order in orders) {
    data <- base_data
    gh <- .cmr_gauss_hermite(order)
    data$cmr_gh_nodes <- gh$nodes
    data$cmr_gh_weights <- gh$weights
    objective <- tryCatch(TMB::MakeADFun(data = data, parameters = parameters,
                                         map = map, random = NULL, DLL = "drmTMB",
                                         silent = TRUE), error = identity)
    if (inherits(objective, "error"))
      return(list(nll = NA_real_, order = as.integer(order), status = "objective_error"))
    start <- if (is.null(previous)) objective$par else {
      common <- intersect(names(previous), names(objective$par))
      value <- objective$par
      value[common] <- previous[common]
      value
    }
    if (length(objective$par)) {
      opt <- tryCatch(stats::nlminb(start = start, objective = objective$fn,
                                    gradient = objective$gr,
                                    control = list(iter.max = 500L, eval.max = 700L)),
                      error = identity)
      if (inherits(opt, "error"))
        return(list(nll = NA_real_, order = as.integer(order), status = "optimizer_error"))
      gradient <- objective$gr(opt$par)
      usable <- opt$convergence == 0L && is.finite(opt$objective) &&
        all(is.finite(opt$par)) && all(is.finite(gradient)) &&
        (!length(gradient) || max(abs(gradient)) <= 1e-4)
      if (!usable) {
        # Continue from nlminb's last iterate when its relative-function
        # stopping rule leaves a score just above the profile-fit tolerance.
        # The objective, analytic gradient, and strict score gate are shared.
        continuation <- .cmr_cjs_profile_bfgs_continuation(
          objective$fn, objective$gr, opt$par, opt$objective
        )
        if (!continuation$usable) {
          reference_objective <- if (is.finite(continuation$value))
            min(opt$objective, continuation$value) else opt$objective
          newton <- .cmr_cjs_profile_newton_continuation(
            objective$fn, objective$gr, objective$he, continuation$par,
            reference_objective
          )
          if (newton$usable) continuation <- newton
        }
        if (continuation$usable) {
          opt$par <- continuation$par
          opt$objective <- continuation$value
          opt$convergence <- continuation$convergence
          gradient <- objective$gr(continuation$par)
          usable <- TRUE
        }
      }
      if (!usable)
        return(list(nll = NA_real_, order = as.integer(order), status = "optimizer_unusable"))
      value <- opt$par
      nll <- as.numeric(opt$objective)
    } else {
      value <- objective$par
      nll <- as.numeric(objective$fn(value))
    }
    report <- objective$report(value)
    if (!is.null(previous)) {
      vector_change <- function(x, y) {
        if (length(x) != length(y) || any(!is.finite(x)) || any(!is.finite(y))) return(Inf)
        if (!length(x)) return(0)
        max(abs(x - y))
      }
      parameter_change <- vector_change(value, previous)
      history_change <- vector_change(report$cmr_individual_loglik,
                                      previous_report$cmr_individual_loglik)
      numerator_change <- vector_change(report$cmr_selection_log_num,
                                        previous_report$cmr_selection_log_num)
      denominator_change <- vector_change(report$cmr_selection_log_den,
                                          previous_report$cmr_selection_log_den)
      if (parameter_change <= 1e-5 && history_change <= 1e-8 &&
          numerator_change <= 1e-8 && denominator_change <= 1e-8) {
        accepted <- list(nll = nll, order = as.integer(order), status = "refined",
                         report = report,
                         parameters = objective$env$parList(value),
                         selection_normalization_retained =
                           isTRUE(base_data$cmr_selection != 0))
        break
      }
    }
    previous <- value
    previous_report <- report
    parameters <- objective$env$parList(value)
    if (is.null(coefficient_index)) parameters[[parameter]][] <- log_sd else
      parameters[[parameter]][[coefficient_index]] <- log_sd
  }
  if (is.null(accepted))
    return(list(nll = NA_real_, order = as.integer(utils::tail(orders, 1L)),
                status = "unrefined_at_order_cap"))
  accepted
}

.cmr_cjs_shared_profile_sd_coefficient_nll <- function(object, process,
    index, value, parameter = paste0("log_sd_", process)) {
  if (!isTRUE(object$random_effects$laplace) ||
      is.null(object$random_effects[[process]]))
    stop("shared SD-formula profiles require an estimated shared effect on that process.",
         call. = FALSE)
  if (!identical(object$random_effects$inner_diagnostics_status,
                 "stationary_positive_curvature"))
    return(list(nll = NA_real_, status = "inner_mode_unverified"))
  if (!parameter %in% c(paste0("log_sd_", process), paste0("log_sigma_", process)))
    stop("the shared SD profile parameter must match the requested process.", call. = FALSE)
  parameters <- .cmr_laplace_par_list(object$obj, object$optimizer)
  values <- parameters[[parameter]]
  if (length(index) != 1L || is.na(index) || index < 1L ||
      index != as.integer(index) || index > length(values) ||
      length(value) != 1L || !is.finite(value))
    stop("the shared SD-formula profile target must identify one finite fitted coefficient.",
         call. = FALSE)
  values[[index]] <- value
  parameters[[parameter]] <- values
  map_index <- seq_along(values)
  map_index[[index]] <- NA_integer_
  map <- stats::setNames(list(factor(map_index)), parameter)
  for (s in c("phi", "p")) if (is.null(object$random_effects[[s]])) {
    inactive <- paste0("log_sigma_", s)
    if (length(parameters[[inactive]])) map[[inactive]] <- factor(NA_integer_)
  }
  if (!ncol(object$phi$X)) map$beta_phi <- factor(NA_integer_)
  if (!ncol(object$p$X)) map$beta_p <- factor(NA_integer_)
  random_parameters <- intersect(c("u_phi", "u_p"), names(parameters))
  random_parameters <- random_parameters[vapply(
    parameters[random_parameters], length, integer(1)
  ) > 0L]
  objective <- tryCatch(TMB::MakeADFun(
    data = object$obj$env$data,
    parameters = parameters,
    map = map,
    random = random_parameters,
    DLL = "drmTMB",
    silent = TRUE
  ), error = identity)
  if (inherits(objective, "error"))
    return(list(nll = NA_real_, status = "objective_error"))
  if (length(objective$par)) {
    opt <- tryCatch(stats::nlminb(
      start = objective$par,
      objective = objective$fn,
      gradient = objective$gr,
      control = list(iter.max = 500L, eval.max = 700L,
                     rel.tol = 1e-14, x.tol = 1e-12)
    ), error = identity)
    if (inherits(opt, "error"))
      return(list(nll = NA_real_, status = "optimizer_error",
                  message = conditionMessage(opt)))
    opt <- tryCatch(.cmr_finish_shared_opt(objective, opt), error = identity)
    if (inherits(opt, "error"))
      return(list(nll = NA_real_, status = "optimizer_error",
                  message = conditionMessage(opt)))
  } else {
    opt <- list(par = objective$par,
                objective = as.numeric(objective$fn(objective$par)),
                convergence = 0L,
                message = "No free outer parameters at this profile point.")
  }
  gradient <- tryCatch(as.numeric(objective$gr(opt$par)), error = identity)
  nll <- tryCatch(as.numeric(objective$fn(opt$par)), error = identity)
  if (inherits(gradient, "error") || inherits(nll, "error") ||
      length(nll) != 1L || !is.finite(nll) ||
      !identical(opt$convergence, 0L) ||
      any(!is.finite(gradient)) ||
      (length(gradient) && max(abs(gradient)) > 1e-4))
    return(list(nll = NA_real_, status = "optimizer_unusable"))
  fitted_parameters <- tryCatch(
    .cmr_laplace_par_list(objective, opt), error = identity
  )
  if (inherits(fitted_parameters, "error"))
    return(list(nll = NA_real_, status = "inner_mode_unverified"))
  if (!isTRUE(all.equal(unname(fitted_parameters[[parameter]][[index]]),
                        unname(value), tolerance = 1e-12)))
    return(list(nll = NA_real_, status = "constraint_mismatch"))
  diagnostics <- tryCatch(.cmr_shared_mode_diagnostics(
    data = object$obj$env$data,
    parameters = fitted_parameters,
    random_parameters = random_parameters
  ), error = identity)
  if (inherits(diagnostics, "error") ||
      !identical(diagnostics$status, "stationary_positive_curvature"))
    return(list(nll = NA_real_, status = "inner_mode_unverified"))
  list(nll = nll, status = "shared_laplace", parameters = fitted_parameters,
       gradient_norm = if (length(gradient)) max(abs(gradient)) else 0,
       inner_gradient_norm = diagnostics$gradient_norm,
       inner_hessian_min_eigenvalue = diagnostics$hessian_min_eigenvalue)
}

.cmr_cjs_profile_sd_coefficient_nll <- function(object, process, index, value) {
  if (!inherits(object, "drm_cjs") || is.null(object$random_effects[[process]]))
    stop("SD-formula coefficient profiles require an estimated random effect on that process.",
         call. = FALSE)
  design <- object$random_effects$sd_design[[process]]
  parameter <- paste0("log_sd_", process)
  values <- object$random_effects$parameters[[parameter]]
  if (!is.list(design) || !length(values) ||
      length(design$columns) != length(values) ||
      !is.matrix(design$X) || ncol(design$X) != length(values))
    stop("the fitted CJS object does not retain a matching SD-formula design.",
         call. = FALSE)
  if (length(index) != 1L || is.na(index) || index < 1L ||
      index != as.integer(index) || index > length(values) ||
      length(value) != 1L || !is.finite(value))
    stop("the SD-formula profile target must identify one finite fitted coefficient.",
         call. = FALSE)
  if (startsWith(object$random_effects$route, "individual_")) {
    if (!identical(object$random_effects$integration$status, "refined"))
      stop("SD-formula coefficient profiles require refined individual-effect quadrature.",
           call. = FALSE)
    return(.cmr_cjs_profile_sd_nll(object, process, value,
                                   coefficient_index = as.integer(index)))
  }
  .cmr_cjs_shared_profile_sd_coefficient_nll(
    object, process, as.integer(index), value
  )
}

.cmr_profile_sd_crossing <- function(profile_q, estimate, direction) {
  inner <- estimate
  step <- 0.5
  outer <- estimate + direction * step
  q_outer <- profile_q(outer)
  tries <- 0L
  while (!is.finite(q_outer) && tries < 10L) {
    step <- step / 2
    outer <- estimate + direction * step
    q_outer <- profile_q(outer)
    tries <- tries + 1L
  }
  if (!is.finite(q_outer)) return(NA_real_)
  while (is.finite(q_outer) && q_outer < 0 && tries < 20L) {
    inner <- outer
    step <- step * 1.7
    outer <- estimate + direction * step
    q_outer <- profile_q(outer)
    tries <- tries + 1L
  }
  if (!is.finite(q_outer) || q_outer < 0) return(NA_real_)
  root <- tryCatch(stats::uniroot(function(value) profile_q(value),
                                  sort(c(inner, outer)), tol = 1e-5)$root,
                   error = function(e) NA_real_)
  root
}

.cmr_cjs_zero_sd_nll <- function(object, process) {
  base_data <- object$obj$env$data
  parameters <- object$obj$env$parList(object$optimizer$par)
  flag <- paste0("cmr_has_individual_", process)
  base_data[[flag]] <- 0.0
  parameter <- paste0("log_sd_", process)
  map <- stats::setNames(list(factor(rep(NA_integer_, length(parameters[[parameter]])))), parameter)
  other <- setdiff(c("phi", "p"), process)
  other_effect <- isTRUE(base_data[[paste0("cmr_has_individual_", other)]] != 0)
  orders <- if (other_effect) object$random_effects$integration$orders else
    object$random_effects$integration$orders[[1L]]
  previous <- NULL
  previous_report <- NULL
  accepted <- NULL
  for (order in orders) {
    data <- base_data
    gh <- .cmr_gauss_hermite(order)
    data$cmr_gh_nodes <- gh$nodes
    data$cmr_gh_weights <- gh$weights
    reduced <- tryCatch(TMB::MakeADFun(data = data, parameters = parameters,
                                       map = map, random = NULL, DLL = "drmTMB",
                                       silent = TRUE), error = identity)
    if (inherits(reduced, "error"))
      stop("cannot construct the exact-zero reduced CJS objective: ",
           conditionMessage(reduced), call. = FALSE)
    start <- if (is.null(previous)) reduced$par else {
      common <- intersect(names(previous), names(reduced$par))
      value <- reduced$par
      value[common] <- previous[common]
      value
    }
    if (length(reduced$par)) {
      opt <- tryCatch(stats::nlminb(start = start, objective = reduced$fn,
                                    gradient = reduced$gr,
                                    control = list(iter.max = 500L, eval.max = 700L)),
                      error = identity)
      if (inherits(opt, "error"))
        stop("the exact-zero reduced CJS profile fit failed: ",
             conditionMessage(opt), call. = FALSE)
      gradient <- reduced$gr(opt$par)
      usable <- opt$convergence == 0L && is.finite(opt$objective) &&
        all(is.finite(gradient)) && max(abs(gradient)) <= 1e-4
      if (!usable) {
        # nlminb can declare relative-function convergence while the score is
        # still too large for this reduced profile fit. Continue from its last
        # iterate with the same objective and analytic gradient; the strict
        # score gate below remains the acceptance criterion.
        continuation <- tryCatch(
          stats::optim(opt$par, reduced$fn, gr = reduced$gr, method = "BFGS",
                       control = list(maxit = 2000L, reltol = 1e-12)),
          error = identity
        )
        if (!inherits(continuation, "error")) {
          continuation_gradient <- reduced$gr(continuation$par)
          continuation_usable <- continuation$convergence == 0L &&
            is.finite(continuation$value) && all(is.finite(continuation_gradient)) &&
            max(abs(continuation_gradient)) <= 1e-4 &&
            continuation$value <= opt$objective + 1e-8
          if (continuation_usable) {
            opt$par <- continuation$par
            opt$objective <- continuation$value
            opt$convergence <- continuation$convergence
            gradient <- continuation_gradient
            usable <- TRUE
          }
        }
      }
      if (!usable)
        stop("the exact-zero reduced CJS profile fit did not converge with a small gradient.", call. = FALSE)
      value <- opt$par
      nll <- as.numeric(opt$objective)
    } else {
      value <- reduced$par
      nll <- as.numeric(reduced$fn(reduced$par))
      opt <- list(par = value)
    }
    report <- reduced$report(value)
    if (!other_effect) {
      accepted <- list(nll = nll, order = as.integer(order), status = "exact_no_remaining_effect")
      break
    }
    if (!is.null(previous)) {
      current_history <- report$cmr_individual_loglik
      prior_history <- previous_report$cmr_individual_loglik
      history_change <- max(abs(current_history - prior_history))
      numerator_change <- max(abs(report$cmr_selection_log_num - previous_report$cmr_selection_log_num))
      denominator_change <- max(abs(report$cmr_selection_log_den - previous_report$cmr_selection_log_den))
      parameter_change <- max(abs(value - previous))
      if (parameter_change <= 1e-5 && history_change <= 1e-8 &&
          numerator_change <= 1e-8 && denominator_change <= 1e-8) {
        accepted <- list(nll = nll, order = as.integer(order), status = "refined")
        break
      }
    }
    previous <- value
    previous_report <- report
    parameters <- reduced$env$parList(value)
  }
  if (is.null(accepted))
    stop("the exact-zero reduced CJS profile failed quadrature refinement at its order cap.", call. = FALSE)
  list(nll = accepted$nll,
       selection_normalization_retained = isTRUE(base_data$cmr_selection != 0),
       other_process_effect_retained = other_effect,
       quadrature_order = accepted$order,
       quadrature_status = accepted$status)
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

.cmr_methods_validate_fit <- function(object, require_curvature = FALSE,
                                      allow_individual = FALSE,
                                      allow_shared_profile = FALSE) {
  if (!inherits(object, "drm_cjs")) stop("`object` must be a `drm_cjs` fit.", call. = FALSE)
  individual <- startsWith(object$random_effects$route, "individual_")
  if (individual && !allow_individual && !require_curvature)
    stop("this interval method is unavailable for integrated individual-effect fits.", call. = FALSE)
  shared_laplace <- isTRUE(object$random_effects$laplace)
  if (shared_laplace && !allow_shared_profile)
    stop("shared-effect covariance remains unavailable for CJS fits.", call. = FALSE)
  if (shared_laplace && allow_shared_profile &&
      !identical(object$random_effects$inner_diagnostics_status,
                 "stationary_positive_curvature"))
    stop("shared-effect profiles require a stationary positive-curvature latent mode.",
         call. = FALSE)
  if (!identical(object$convergence, 0L) || !is.finite(object$gradient_norm) ||
      object$gradient_norm > 1e-4)
    stop("CJS inference requires a converged fit with a small gradient.", call. = FALSE)
  if (!require_curvature) return(invisible(TRUE))
  h <- object$hessian
  if (!is.matrix(h) || any(!is.finite(h)))
    stop("CJS Wald inference requires a finite model-specific observed Hessian.", call. = FALSE)
  if (individual) for (process in c("phi", "p")) {
    if (!is.null(object$random_effects[[process]])) {
      sigma <- object$random_effects$sd[[process]]
      if (!is.numeric(sigma) || !length(sigma) || any(!is.finite(sigma)) || any(sigma <= 1e-8))
        stop("CJS Wald coefficient inference is unavailable at an individual-variance boundary.", call. = FALSE)
    }
  }
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

.cmr_prediction_keys <- function(x, process, object, target = "zero_effect", active = NULL) {
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
  sd_design <- object$random_effects$sd_design[[process]]
  sd_vars <- if (target == "integrated" && isTRUE(object$prediction_contract$sd_formula_present[[process]]) &&
                 is.list(sd_design) && inherits(sd_design$terms, "terms")) all.vars(sd_design$terms) else character()
  if (!all(sd_vars %in% names(x)))
    stop("`newdata$", process, "` is missing SD-formula columns: ",
         paste(setdiff(sd_vars, names(x)), collapse = ", "), ".", call. = FALSE)
  allowed <- unique(c(keys, vars, sd_vars))
  if (!setequal(names(x), allowed))
    stop("`newdata$", process, "` does not match the fitted predictor schema.", call. = FALSE)
  active <- if (is.null(active)) rep(TRUE, nrow(x)) else as.logical(active)
  if (length(active) != nrow(x) || anyNA(active))
    stop("prediction activity mask must match the supplied rows.", call. = FALSE)
  if (any(vapply(x[unique(c(vars, sd_vars))], function(v) anyNA(v[active]), logical(1))))
    stop("`newdata$", process, "` predictors must not be missing on active rows.", call. = FALSE)
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
      frame$occasion == utils::tail(object$data$occasions, 1L)
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
  gradient <- function(other) {
    full <- start
    full[j] <- value
    full[-j] <- other
    object$obj$gr(full)[-j]
  }
  if (!length(free)) {
    result <- tryCatch(objective(numeric()), error = function(e) NA_real_)
    return(if (is.finite(result)) result else NA_real_)
  }
  opt <- tryCatch(stats::nlminb(free, objective, gradient = gradient,
                                control = list(iter.max = 300L, eval.max = 400L)),
                  error = function(e) NULL)
  if (is.null(opt) || opt$convergence != 0L || !is.finite(opt$objective)) return(NA_real_)
  nuisance_gradient <- function(par) {
    full <- start
    full[j] <- value
    full[-j] <- par
    tryCatch(object$obj$gr(full)[-j], error = function(e) rep(NA_real_, length(par)))
  }
  grad <- nuisance_gradient(opt$par)
  if (length(grad) && all(is.finite(grad)) && max(abs(grad)) > 1e-4) {
    # nlminb can report relative convergence before reaching the profile
    # nuisance-gradient gate. Polish that same constrained point with BFGS;
    # retain the strict gate and the nlminb result if polishing is worse.
    polish <- tryCatch(stats::optim(
      opt$par, objective, gr = gradient, method = "BFGS",
      control = list(maxit = 300L, reltol = 1e-12)
    ), error = function(e) NULL)
    if (!is.null(polish) && polish$convergence == 0L &&
        is.finite(polish$value) && polish$value <= opt$objective +
          200 * .Machine$double.eps * max(1, abs(opt$objective))) {
      polished_gradient <- nuisance_gradient(polish$par)
      if (length(polished_gradient) && all(is.finite(polished_gradient)) &&
          max(abs(polished_gradient)) <= 1e-4) {
        opt$par <- polish$par
        opt$objective <- polish$value
        grad <- polished_gradient
      }
    }
  }
  full <- start
  full[j] <- value
  full[-j] <- opt$par
  if (!length(grad) || any(!is.finite(grad)) || max(abs(grad)) > 1e-4)
    return(NA_real_)
  opt$objective
}

.cmr_profile_endpoint <- function(object, j, estimate, se, level) {
  parhat <- object$optimizer$par
  cutoff <- stats::qchisq(level, df = 1L)
  center <- object$obj$fn(parhat)
  improvement_tolerance <- 200 * .Machine$double.eps * max(1, abs(center))
  state <- new.env(parent = emptyenv())
  state$improves <- FALSE
  fn_at <- function(value, start) {
    nll <- .cmr_profile_value(object, j, value, start)
    if (is.finite(nll) && nll < center - improvement_tolerance) {
      state$improves <- TRUE
      return(NA_real_)
    }
    if (is.finite(nll)) 2 * (nll - center) else NA_real_
  }
  limits <- c(NA_real_, NA_real_)
  status <- c("failed", "failed")
  for (side in seq_len(2L)) {
    sign <- if (side == 1L) -1 else 1
    step <- max(se, .05)
    inner <- estimate
    outer <- estimate + sign * step
    f_outer <- fn_at(outer, parhat) - cutoff
    if (state$improves) {
      limits[] <- NA_real_
      status[] <- "profile_improves_on_fit"
      return(list(limits = limits, status = status))
    }
    tries <- 0L
    while (is.finite(f_outer) && f_outer < 0 && tries < 12L) {
      inner <- outer
      step <- step * 1.7
      outer <- estimate + sign * step
      f_outer <- fn_at(outer, parhat) - cutoff
      tries <- tries + 1L
      if (state$improves) {
        limits[] <- NA_real_
        status[] <- "profile_improves_on_fit"
        return(list(limits = limits, status = status))
      }
    }
    if (!is.finite(f_outer)) {
      status[[side]] <- "failed_profile"
    } else if (f_outer < 0) {
      status[[side]] <- "no_crossing"
    } else {
      root_value <- function(value) {
        residual <- fn_at(value, parhat) - cutoff
        if (!is.finite(residual))
          stop("profile likelihood is unavailable inside the endpoint bracket.", call. = FALSE)
        residual
      }
      root <- tryCatch(stats::uniroot(root_value,
                                      sort(c(inner, outer)), tol = 1e-5)$root,
                       error = function(e) NA_real_)
      if (state$improves) {
        limits[] <- NA_real_
        status[] <- "profile_improves_on_fit"
        return(list(limits = limits, status = status))
      }
      if (is.finite(root)) {
        limits[[side]] <- root
        status[[side]] <- "ok"
      } else status[[side]] <- "failed_root"
    }
  }
  list(limits = limits, status = status)
}

# Rebuild an ordinary individual-beta profile point at every retained GH order.
# This is deliberately separate from selected profiles and SD profiles: their
# normalisation and parameterisation have distinct contracts.
.cmr_cjs_profile_beta_nll <- function(object, process, coefficient_index, value) {
  if (length(process) != 1L || is.na(process) ||
      !process %in% c("phi", "p") || length(value) != 1L ||
      !is.finite(value))
    stop("the individual beta profile target must be one finite fitted coefficient.",
         call. = FALSE)
  parameter <- paste0("beta_", process)
  base_data <- object$obj$env$data
  parameters <- object$obj$env$parList(object$optimizer$par)
  if (length(coefficient_index) != 1L || is.na(coefficient_index) ||
      !is.finite(coefficient_index) ||
      coefficient_index < 1L || coefficient_index != as.integer(coefficient_index) ||
      coefficient_index > length(parameters[[parameter]]))
    stop("`coefficient_index` must identify one fitted beta coefficient.", call. = FALSE)
  parameters[[parameter]][[coefficient_index]] <- value
  map_index <- seq_along(parameters[[parameter]])
  map_index[[coefficient_index]] <- NA_integer_
  map <- stats::setNames(list(factor(map_index)), parameter)
  orders <- as.integer(object$random_effects$integration$orders)
  attempts <- vector("list", length(orders))
  previous <- NULL
  previous_report <- NULL
  accepted <- NULL
  for (k in seq_along(orders)) {
    order <- orders[[k]]
    data <- base_data
    gh <- .cmr_gauss_hermite(order)
    data$cmr_gh_nodes <- gh$nodes
    data$cmr_gh_weights <- gh$weights
    objective <- tryCatch(TMB::MakeADFun(data = data, parameters = parameters,
      map = map, random = NULL, DLL = "drmTMB", silent = TRUE),
      error = function(e) e)
    if (inherits(objective, "interrupt")) stop(objective)
    if (inherits(objective, "error")) {
      attempts[[k]] <- list(order = order, status = "objective_error",
                            message = conditionMessage(objective),
                            fixed_parameters = parameters)
      break
    }
    # `parameters` already contains the full parList from the preceding order.
    # Do not copy by intersecting TMB names: duplicated coefficient labels can
    # map distinct model blocks onto the wrong warm-start entry.
    start <- objective$par
    opt <- if (length(start)) tryCatch(stats::nlminb(start, objective$fn,
      gradient = objective$gr,
      control = list(iter.max = 500L, eval.max = 700L)), error = function(e) e) else NULL
    if (inherits(opt, "interrupt")) stop(opt)
    if (inherits(opt, "error")) {
      attempts[[k]] <- list(order = order, status = "optimizer_error",
                            message = conditionMessage(opt), start = start,
                            fixed_parameters = parameters)
      break
    }
    candidate <- if (is.null(opt)) start else opt$par
    optimizer_method <- if (is.null(opt)) "fixed" else "nlminb"
    nll_result <- if (is.null(opt)) tryCatch(as.numeric(objective$fn(candidate)),
      error = identity) else as.numeric(opt$objective)
    if (inherits(nll_result, "interrupt")) stop(nll_result)
    if (inherits(nll_result, "error")) {
      attempts[[k]] <- list(order = order, status = "objective_error",
        reason = conditionMessage(nll_result), start = start, solution = candidate,
        fixed_parameters = parameters,
        full_parameters = tryCatch(objective$env$parList(candidate), error = function(e) NULL))
      break
    }
    nll <- nll_result
    gradient_result <- if (length(candidate)) tryCatch(objective$gr(candidate),
      error = identity) else numeric()
    if (inherits(gradient_result, "interrupt")) stop(gradient_result)
    if (inherits(gradient_result, "error")) {
      attempts[[k]] <- list(order = order, status = "gradient_error",
        reason = conditionMessage(gradient_result), start = start, solution = candidate,
        objective = nll, fixed_parameters = parameters,
        full_parameters = tryCatch(objective$env$parList(candidate), error = function(e) NULL))
      break
    }
    gradient <- gradient_result
    usable <- (is.null(opt) || opt$convergence == 0L) && is.finite(nll) &&
      all(is.finite(candidate)) && all(is.finite(gradient)) &&
      (!length(gradient) || max(abs(gradient)) <= 1e-4)
    if (!usable && !is.null(opt) && is.finite(nll) &&
        all(is.finite(candidate)) && all(is.finite(gradient))) {
      # Continue from a relative-convergence iterate when the analytic score
      # still exceeds the profile gate. Do not relax the gate or accept a
      # worse constrained objective.
      continuation <- tryCatch(
        stats::optim(candidate, objective$fn, gr = objective$gr,
                     method = "BFGS",
                     control = list(maxit = 2000L, reltol = 1e-12)),
        error = identity
      )
      if (!inherits(continuation, "error")) {
        continued_gradient <- objective$gr(continuation$par)
        continuation_usable <- continuation$convergence == 0L &&
          is.finite(continuation$value) && all(is.finite(continuation$par)) &&
          all(is.finite(continued_gradient)) &&
          (!length(continued_gradient) || max(abs(continued_gradient)) <= 1e-4) &&
          continuation$value <= nll + 1e-8
        if (continuation_usable) {
          candidate <- continuation$par
          nll <- continuation$value
          gradient <- continued_gradient
          optimizer_method <- "BFGS_continuation"
          usable <- TRUE
        }
      }
    }
    if (!usable) {
      failures <- c(if (!is.null(opt) && opt$convergence != 0L) "nonzero_convergence",
        if (!is.finite(nll)) "nonfinite_objective",
        if (any(!is.finite(candidate))) "nonfinite_solution",
        if (any(!is.finite(gradient))) "nonfinite_gradient",
        if (length(gradient) && all(is.finite(gradient)) && max(abs(gradient)) > 1e-4)
          "gradient_above_tolerance")
      attempts[[k]] <- list(order = order, status = "optimizer_unusable",
        start = start, solution = candidate, objective = nll,
        optimizer = optimizer_method,
        convergence = if (is.null(opt)) 0L else opt$convergence,
        failure_reasons = failures,
        gradient = gradient,
        gradient_max = if (length(gradient) && all(is.finite(gradient)))
          max(abs(gradient)) else Inf,
        fixed_parameters = parameters)
      break
    }
    report <- tryCatch(objective$report(candidate), error = identity)
    if (inherits(report, "interrupt")) stop(report)
    if (inherits(report, "error")) {
      attempts[[k]] <- list(order = order, status = "report_error",
        reason = conditionMessage(report), start = start, solution = candidate,
        objective = nll, gradient = gradient,
        gradient_max = if (length(gradient)) max(abs(gradient)) else 0,
        fixed_parameters = parameters,
        full_parameters = tryCatch(objective$env$parList(candidate), error = function(e) NULL))
      break
    }
    attempts[[k]] <- list(order = order, status = "not_refined", nll = nll,
      optimizer = optimizer_method,
      start = start, solution = candidate,
      full_parameters = objective$env$parList(candidate),
      gradient = gradient, gradient_max = if (length(gradient)) max(abs(gradient)) else 0,
      convergence = if (is.null(opt)) 0L else opt$convergence,
      fixed_parameters = parameters)
    if (!is.null(previous)) {
      change <- function(x, y) {
        if (length(x) != length(y) || any(!is.finite(x)) || any(!is.finite(y))) return(Inf)
        if (!length(x)) return(0)
        max(abs(x - y))
      }
      pchange <- change(candidate, previous)
      hchange <- change(report$cmr_individual_loglik,
                        previous_report$cmr_individual_loglik)
      nchange <- change(report$cmr_selection_log_num,
                        previous_report$cmr_selection_log_num)
      dchange <- change(report$cmr_selection_log_den,
                        previous_report$cmr_selection_log_den)
      attempts[[k]]$parameter_change <- pchange
      attempts[[k]]$history_change <- hchange
      if (pchange <= 1e-5 && hchange <= 1e-8 &&
          nchange <= 1e-8 && dchange <= 1e-8) {
        attempts[[k]]$status <- "refined"
        accepted <- list(nll = nll, order = order, status = "refined",
                         attempts = attempts[seq_len(k)], report = report,
                         parameters = objective$env$parList(candidate),
                         attempted_orders = orders[seq_len(k)],
                         cap_order = max(orders))
        break
      }
    }
    attempts[[k]]$status <- "completed_not_refined"
    previous <- candidate
    previous_report <- report
    parameters <- objective$env$parList(candidate)
    parameters[[parameter]][[coefficient_index]] <- value
  }
  if (is.null(accepted)) {
    completed_attempts <- attempts[!vapply(attempts, is.null, logical(1))]
    last_order <- if (length(completed_attempts))
      completed_attempts[[length(completed_attempts)]]$order else NA_integer_
    list(nll = NA_real_, order = last_order,
    status = if (any(vapply(attempts, function(x) !is.null(x) &&
      x$status %in% c("objective_error", "gradient_error", "report_error",
                      "optimizer_error", "optimizer_unusable"), logical(1))))
        "profile_fit_unusable" else "unrefined_at_order_cap",
    attempts = attempts[!vapply(attempts, is.null, logical(1))],
    attempted_orders = vapply(attempts[!vapply(attempts, is.null, logical(1))],
                               `[[`, integer(1), "order"),
    cap_order = max(orders))
  } else accepted
}

.cmr_profile_individual_beta <- function(object, process, j, estimate, se, level) {
  cutoff <- stats::qchisq(level, df = 1L)
  center <- as.numeric(object$obj$fn(object$optimizer$par))
  baseline <- .cmr_cjs_profile_beta_nll(object, process, j, estimate)
  fitted_report <- object$obj$report(object$optimizer$par)
  fitted_history <- as.numeric(fitted_report$cmr_individual_loglik)
  baseline_history <- if (is.null(baseline$report)) numeric() else
    as.numeric(baseline$report$cmr_individual_loglik)
  frequency <- as.numeric(object$obj$env$data$cmr_frequency)
  history_delta <- if (length(fitted_history) == length(baseline_history) &&
                       length(frequency) == length(fitted_history) &&
                       all(is.finite(fitted_history)) &&
                       all(is.finite(baseline_history)) && all(is.finite(frequency)))
    sum(abs(baseline_history - fitted_history) * frequency) else Inf
  center_tolerance <- 1e-8 * sum(frequency) +
    32 * .Machine$double.eps * max(1, abs(center))
  objective_delta <- baseline$nll - center
  diagnostic <- list(estimate = estimate, process = process,
    baseline_status = baseline$status, baseline_nll = baseline$nll,
    baseline_objective_difference = objective_delta,
    baseline_weighted_history_difference = history_delta,
    baseline_center_tolerance = center_tolerance,
    attempts = list(baseline = baseline$attempts), cutoff = cutoff,
    order_cap = max(object$random_effects$integration$orders))
  limits <- c(NA_real_, NA_real_)
  status <- rep("profile_center_mismatch", 2L)
  history_tolerance <- 1e-8 * sum(frequency)
  history_matches <- is.finite(history_delta) && history_delta <= history_tolerance
  if (!identical(baseline$status, "refined") || !is.finite(baseline$nll) ||
      !history_matches || !is.finite(objective_delta) ||
      abs(objective_delta) > center_tolerance) {
    if (!identical(baseline$status, "refined")) status[] <- baseline$status
    if (identical(baseline$status, "refined") && is.finite(objective_delta) &&
        objective_delta < -center_tolerance)
      status[] <- "profile_improves_on_fit"
    diagnostic$baseline_status <- if (identical(status[[1L]], "profile_improves_on_fit"))
      "refined_but_improves_on_fit" else diagnostic$baseline_status
    diagnostic$center_tolerance <- center_tolerance
    return(list(limits = limits, status = status, diagnostic = diagnostic))
  }
  point <- function(x) .cmr_cjs_profile_beta_nll(object, process, j, x)
  side_states <- list(lower = new.env(parent = emptyenv()),
                      upper = new.env(parent = emptyenv()))
  for (s in side_states) {
    s$attempts <- list()
    s$unrefined <- FALSE
    s$improves <- FALSE
    s$last_status <- "not_attempted"
  }
  prof <- function(x, state) {
    p <- point(x)
    state$attempts[[length(state$attempts) + 1L]] <- list(value = x, point = p)
    state$last_status <- p$status
    if (identical(p$status, "unrefined_at_order_cap")) state$unrefined <- TRUE
    if (!identical(p$status, "refined") || !is.finite(p$nll)) return(NA_real_)
    if (p$nll < center - center_tolerance) {
      state$improves <- TRUE
      state$last_status <- "profile_improves_on_fit"
      state$attempts[[length(state$attempts)]]$status <- "profile_improves_on_fit"
      return(NA_real_)
    }
    2 * (p$nll - center) - cutoff
  }
  endpoint_status <- rep("failed_profile", 2L)
  for (side in seq_len(2L)) {
    # Once any constrained point is better than the fitted center, neither
    # endpoint belongs to a valid interval centered on that fit.
    if (any(vapply(side_states, `[[`, logical(1), "improves"))) break
    side_name <- if (side == 1L) "lower" else "upper"
    state <- side_states[[side_name]]
    direction <- if (side == 1L) -1 else 1
    step <- max(se, .05)
    inner <- estimate
    outer <- estimate + direction * step
    fouter <- prof(outer, state)
    tries <- 0L
    while (is.finite(fouter) && fouter < 0 && tries < 12L) {
      inner <- outer
      step <- step * 1.7
      outer <- estimate + direction * step
      fouter <- prof(outer, state)
      tries <- tries + 1L
    }
    if (!is.finite(fouter)) {
      endpoint_status[[side]] <- if (state$improves) "profile_improves_on_fit" else
        if (state$unrefined) "integration_unrefined" else
        "profile_fit_unusable"
      next
    }
    if (fouter < 0) {
      endpoint_status[[side]] <- "no_crossing"
      next
    }
    root <- tryCatch(stats::uniroot(function(x) {
      y <- prof(x, state)
      if (!is.finite(y)) stop("profile point failed refinement.", call. = FALSE)
      y
    }, sort(c(inner, outer)), tol = 1e-5)$root, error = function(e) {
      if (inherits(e, "interrupt")) stop(e)
      NA_real_
    })
    if (!is.finite(root)) {
      endpoint_status[[side]] <- if (state$improves) "profile_improves_on_fit" else
        if (state$unrefined) "integration_unrefined" else
        "failed_root"
      next
    }
    final <- point(root)
    residual <- if (identical(final$status, "refined"))
      2 * (final$nll - center) - cutoff else NA_real_
    state$attempts[[length(state$attempts) + 1L]] <-
      list(value = root, point = final, endpoint = TRUE, residual = residual)
    if (identical(final$status, "refined") &&
        final$nll < center - center_tolerance) {
      state$improves <- TRUE
      state$last_status <- "profile_improves_on_fit"
      state$attempts[[length(state$attempts)]]$status <- "profile_improves_on_fit"
      endpoint_status[[side]] <- "profile_improves_on_fit"
      next
    }
    if (!identical(final$status, "refined")) {
      endpoint_status[[side]] <- if (identical(final$status, "unrefined_at_order_cap"))
        "integration_unrefined" else "profile_fit_unusable"
      next
    }
    if (!is.finite(residual) || abs(residual) > 2e-4) {
      endpoint_status[[side]] <- "endpoint_unverified"
      next
    }
    limits[[side]] <- root
    endpoint_status[[side]] <- "ok"
  }
  if (any(vapply(side_states, `[[`, logical(1), "improves"))) {
    limits[] <- NA_real_
    endpoint_status[] <- "profile_improves_on_fit"
  }
  diagnostic$attempts$endpoints <- unlist(lapply(side_states, `[[`, "attempts"),
                                           recursive = FALSE)
  diagnostic$endpoint_states <- lapply(side_states, function(x)
    list(status = x$last_status, unrefined = x$unrefined, improves = x$improves))
  diagnostic$endpoint_residual_tolerance <- 2e-4
  list(limits = limits, status = endpoint_status, diagnostic = diagnostic)
}

.cmr_bootstrap_coefficients <- function(object, nsim, seed) {
  simulations <- simulate.drm_cjs(object, nsim = nsim, seed = seed)
  records <- vector("list", nsim)
  fit_formula <- function(process) {
    formula <- stats::formula(object[[process]]$terms)
    if (!is.null(object$random_effects[[process]]))
      formula <- stats::update(formula, ~ . + (1 | id))
    formula
  }
  for (i in seq_len(nsim)) {
    sim <- simulations[[i]]
    simulation_metadata <- attr(sim, "simulation")
    selection_metadata <- simulation_metadata$selection
    selection <- if (is.list(selection_metadata)) list(
      eligibility = selection_metadata$eligibility,
      assumption = selection_metadata$assumption) else NULL
    sd_formula <- function(process) {
      if (!isTRUE(object$prediction_contract$sd_formula_present[[process]])) return(NULL)
      design <- object$random_effects$sd_design[[process]]
      if (!is.list(design) || !inherits(design$terms, "terms"))
        stop("bootstrap cannot recover the fitted ", process, " SD formula.", call. = FALSE)
      stats::formula(design$terms)
    }
    result <- tryCatch(drm_cjs(sim$data,
                               phi = fit_formula("phi"),
                               p = fit_formula("p"),
                               phi_data = sim$phi_data, p_data = sim$p_data,
                               selection = selection,
                               sd_phi = sd_formula("phi"), sd_p = sd_formula("p"),
                               terminal_constraint = object$terminal_constraint,
                               contrasts = list(phi = object$phi$contrasts,
                                                p = object$p$contrasts)),
                      error = function(e) e)
    if (inherits(result, "error")) {
      records[[i]] <- list(replicate = i, status = "failed", converged = FALSE,
                           usable = FALSE, message = conditionMessage(result),
                           gradient_norm = NA_real_, integration_status = "fit_error",
                           curvature_eligible = FALSE,
                           sd_numerically_zero = NA,
                           curvature_message = conditionMessage(result),
                           coefficients = NULL, fit = NULL)
    } else {
      diagnostics <- .cmr_bootstrap_fit_diagnostics(result)
      records[[i]] <- list(replicate = i, status = diagnostics$status,
                           converged = identical(result$convergence, 0L),
                           usable = diagnostics$usable,
                           message = diagnostics$message,
                           gradient_norm = diagnostics$gradient_norm,
                           integration_status = diagnostics$integration_status,
                           curvature_eligible = diagnostics$curvature_eligible,
                           sd_numerically_zero = diagnostics$sd_numerically_zero,
                           curvature_message = diagnostics$curvature_message,
                           coefficients = if (diagnostics$usable) coef.drm_cjs(result) else NULL,
                           fit = result)
    }
  }
  ledger <- data.frame(replicate = vapply(records, `[[`, integer(1), "replicate"),
                       status = vapply(records, `[[`, character(1), "status"),
                       converged = vapply(records, `[[`, logical(1), "converged"),
                       usable = vapply(records, `[[`, logical(1), "usable"),
                       gradient_norm = vapply(records, `[[`, numeric(1), "gradient_norm"),
                       integration_status = vapply(records, `[[`, character(1), "integration_status"),
                       curvature_eligible = vapply(records, `[[`, logical(1), "curvature_eligible"),
                       sd_numerically_zero = vapply(records, `[[`, logical(1), "sd_numerically_zero"),
                       curvature_message = vapply(records, `[[`, character(1), "curvature_message"),
                       message = vapply(records, `[[`, character(1), "message"),
                       stringsAsFactors = FALSE)
  ledger$coefficients <- I(lapply(records, `[[`, "coefficients"))
  ledger$fit <- I(lapply(records, `[[`, "fit"))
  list(attempts = ledger)
}

.cmr_bootstrap_fit_diagnostics <- function(object) {
  gradient <- object$gradient_norm
  integration_status <- if (startsWith(object$random_effects$route, "individual_"))
    object$random_effects$integration$status else "not_applicable"
  base <- list(usable = FALSE, status = "unusable", message = "invalid fitted estimates",
               gradient_norm = if (is.numeric(gradient) && length(gradient) == 1L &&
                                   is.finite(gradient)) gradient else NA_real_,
               integration_status = if (is.character(integration_status) &&
                                        length(integration_status) == 1L) integration_status else "invalid",
               curvature_eligible = FALSE, sd_numerically_zero = FALSE,
               curvature_message = "not assessed")
  if (!identical(object$convergence, 0L)) {
    base$status <- "nonconverged"
    base$message <- object$message %||% "optimizer did not converge"
    return(base)
  }
  if (!is.finite(object$logLik) || !is.finite(base$gradient_norm) ||
      base$gradient_norm > 1e-4 ||
      any(!is.finite(c(object$coefficients$phi, object$coefficients$p)))) {
    base$message <- "non-finite objective, coefficient, or gradient; or gradient exceeds 1e-4"
    return(base)
  }
  if (startsWith(object$random_effects$route, "individual_") &&
      !identical(integration_status, "refined")) {
    base$status <- "integration_unrefined"
    base$message <- "individual-effect quadrature did not meet its refinement criterion"
    return(base)
  }
  sd_parameters <- object$random_effects$parameters
  if (is.list(sd_parameters)) {
    sd_values <- unlist(sd_parameters[intersect(names(sd_parameters),
                                                c("log_sd_phi", "log_sd_p"))],
                        use.names = FALSE)
    if (length(sd_values) && any(!is.finite(sd_values))) {
      base$message <- "non-finite fitted log-SD coefficient"
      return(base)
    }
  }
  sd_values <- if (startsWith(object$random_effects$route, "individual_"))
    unlist(object$random_effects$sd[c("phi", "p")], use.names = FALSE) else numeric()
  if (length(sd_values) && any(!is.finite(sd_values) | sd_values < 0)) {
    base$message <- "non-finite or negative fitted random-effect SD"
    return(base)
  }
  base$sd_numerically_zero <- length(sd_values) > 0L && any(sd_values == 0)
  base$usable <- TRUE
  base$status <- "usable"
  base$message <- "finite converged estimate with accepted quadrature state"
  curvature <- tryCatch({
    .cmr_methods_validate_fit(object, require_curvature = TRUE, allow_individual = TRUE)
    NULL
  }, error = identity)
  base$curvature_eligible <- is.null(curvature)
  base$curvature_message <- if (is.null(curvature)) "eligible" else conditionMessage(curvature)
  base
}
