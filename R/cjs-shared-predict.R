# Shared CJS prediction uses the fitted reference normal law, not the fitted
# conditional latent modes.  The public S3 method dispatch remains in
# cjs-methods.R so fixed and individual prediction keep their existing path.

.cmr_shared_methods_validate <- function(object) {
  fail <- function(what) stop("shared CJS methods require ", what, ".", call. = FALSE)
  if (!inherits(object, "drm_cjs")) fail("a `drm_cjs` fit")
  re <- object$random_effects
  route <- re$route
  allowed <- c("site_phi", "site_p", "site_pair", "year_vector")
  if (!is.character(route) || length(route) != 1L || is.na(route) || !route %in% allowed)
    fail("an ordinary shared route (`site_phi`, `site_p`, `site_pair`, or `year_vector`)")
  pc <- object$prediction_contract
  if (!is.list(pc) || !identical(pc$version, 1L) ||
      !identical(pc$selection_enabled, FALSE) ||
      !is.logical(pc$sd_formula_present) ||
      !identical(names(pc$sd_formula_present), c("phi", "p")) ||
      length(pc$sd_formula_present) != 2L || anyNA(pc$sd_formula_present))
    fail("normalized version-one prediction provenance")
  if (isTRUE(pc$selection_enabled)) fail("selection-disabled provenance")
  if (!identical(re$laplace, TRUE)) fail("native CJS Laplace provenance")
  model_type <- tryCatch(object$obj$env$data$model_type, error = function(e) NULL)
  model_type_valid <- typeof(model_type) %in% c("integer", "double") &&
    length(model_type) == 1L && is.finite(model_type) && model_type %in% c(1001, 1003)
  if (!model_type_valid) fail("retained native CJS model_type 1001 or 1003")
  shared_sd <- model_type == 1003
  if (shared_sd != any(pc$sd_formula_present)) fail("model type consistent with SD formula provenance")
  if (!identical(object$convergence, 0L) || !is.numeric(object$logLik) ||
      length(object$logLik) != 1L || any(!is.finite(object$logLik)) ||
      !is.numeric(object$gradient_norm) || length(object$gradient_norm) != 1L ||
      !is.finite(object$gradient_norm) || object$gradient_norm < 0 || object$gradient_norm > 1e-4)
    fail("a finite converged fit with outer gradient norm in [0, 1e-4]")
  if (!is.list(object$coefficients) || !is.numeric(object$coefficients$phi) ||
      !is.numeric(object$coefficients$p) || any(!is.finite(object$coefficients$phi)) ||
      any(!is.finite(object$coefficients$p))) fail("finite fitted process coefficients")
  n <- nrow(object$data$y); nt <- ncol(object$data$y)
  for (s in c("phi", "p")) {
    design <- object[[s]]
    nr <- if (s == "phi") n * max(nt - 1L, 0L) else n * nt
    beta <- object$coefficients[[s]]
    active <- object[[paste0(s, "_active")]]
    if (!is.matrix(design$X) || !is.numeric(design$X) || nrow(design$X) != nr ||
        ncol(design$X) != length(beta) || any(!is.finite(design$X)) ||
        !identical(colnames(design$X), names(beta)) || !is.numeric(design$offset) ||
        length(design$offset) != nr || any(!is.finite(design$offset)) ||
        !is.logical(active) || length(active) != nr || anyNA(active))
      fail(paste("finite", s, "fixed design, offset, and active-row dimensions"))
  }
  params <- re$parameters
  if (!is.list(params) || !is.numeric(params$u_phi) || !is.numeric(params$u_p) ||
      any(!is.finite(params$u_phi)) || any(!is.finite(params$u_p)))
    fail("finite standardized latent modes")
  expected <- switch(route,
    site_phi = c(phi = TRUE, p = FALSE),
    site_p = c(phi = FALSE, p = TRUE),
    site_pair = c(phi = TRUE, p = TRUE),
    year_vector = c(phi = !is.null(re$phi), p = !is.null(re$p)))
  if (!identical(!vapply(c("phi", "p"), function(s) is.null(re[[s]]), logical(1)), expected))
    fail("active-process metadata consistent with the route")
  if (route == "site_pair" && (!identical(re$phi$group, re$p$group) ||
      !identical(re$phi$levels, re$p$levels)))
    fail("paired site processes using the same grouping variable and ordered levels")
  mode_n <- length(params$u_phi) + length(params$u_p)
  if (!identical(as.integer(re$inner_hessian_dimension), as.integer(mode_n)))
    fail("inner CJS curvature evidence with the matching latent dimension")
  if (!identical(re$mode_status, "finite_mode") ||
      !identical(re$inner_diagnostics_status, "stationary_positive_curvature") ||
      !identical(re$laplace_status, "outer_converged_inner_stationary_pd") ||
      !is.numeric(re$inner_gradient_norm) || length(re$inner_gradient_norm) != 1L ||
      !is.finite(re$inner_gradient_norm) || re$inner_gradient_norm < 0 || re$inner_gradient_norm > 1e-4 ||
      !identical(re$inner_hessian_positive_definite, TRUE) ||
      !is.numeric(re$inner_hessian_min_eigenvalue) || length(re$inner_hessian_min_eigenvalue) != 1L ||
      !is.finite(re$inner_hessian_min_eigenvalue) || re$inner_hessian_min_eigenvalue <= 0)
    fail("stationary positive-definite model-specific inner CJS curvature diagnostics")
  for (s in c("phi", "p")) {
    d <- re[[s]]
    if (is.null(d)) {
      if (length(params[[paste0("u_", s)]]) != 0L) fail(paste("an empty inactive", s, "mode"))
      next
    }
    nr <- if (s == "phi") n * max(nt - 1L, 0L) else n * nt
    if (!is.matrix(d$Z) || !is.numeric(d$Z) || nrow(d$Z) != nr ||
        ncol(d$Z) != length(d$levels) || any(!is.finite(d$Z)) ||
        !is.character(d$levels) || anyNA(d$levels) || any(!nzchar(d$levels)) ||
        anyDuplicated(d$levels) || !identical(colnames(d$Z), d$levels) ||
        !is.numeric(d$row_index) || length(d$row_index) != nr ||
        anyNA(d$row_index) || any(d$row_index != seq_len(nr)) ||
        !is.logical(d$active) || length(d$active) != nr || anyNA(d$active) ||
        !is.character(d$values) || length(d$values) != nr ||
        length(params[[paste0("u_", s)]]) != ncol(d$Z))
      fail(paste("finite", s, "incidence dimensions, ordered levels, row indices, and latent mode"))
    sd <- re$sd[[s]]
    if (shared_sd) {
      design <- re$sd_design[[s]]
      if (!is.list(design) || !identical(design$levels, d$levels) ||
          !is.numeric(sd) || length(sd) != length(d$levels) ||
          !identical(names(sd), d$levels) || any(!is.finite(sd)) || any(sd <= 0))
        fail(paste("aligned finite", s, "unit SD provenance"))
      expected_sd <- .cmr_shared_sd_profile(object, s, design$unit_data, design$levels)
      if (any(abs(sd - expected_sd) > 1e-10 * pmax(1, sd)))
        fail(paste("fitted", s, "unit SDs matching their formula"))
    } else {
    log_sd <- params[[paste0("log_sigma_", s)]]
    log_sd_valid <- is.numeric(log_sd) && length(log_sd) == 1L &&
      (is.finite(log_sd) || (identical(log_sd, -Inf) && sd == 0))
    if (!is.numeric(sd) || length(sd) != 1L || !is.finite(sd) || sd < 0 ||
        !log_sd_valid || abs(sd - exp(log_sd)) > 1e-10 * max(1, sd))
      fail(paste("a finite nonnegative", s, "SD matching its fitted log SD"))
    }
    active <- which(d$active)
    if (length(active) && (anyNA(d$values[active]) || any(!nzchar(d$values[active])) ||
        any(!d$values[active] %in% d$levels)))
      fail(paste("valid contributing", s, "group labels"))
    if (any(d$Z < 0) || any(d$Z > 1) || any(rowSums(d$Z) > 1))
      fail(paste("a valid", s, "random incidence design"))
    frame <- object[[paste0("training_", s, "_data")]]
    if (!is.character(d$group) || length(d$group) != 1L || is.na(d$group) ||
        !nzchar(d$group) || !d$group %in% names(frame) ||
        !identical(as.character(frame[[d$group]]), d$values))
      fail(paste("key-aligned training", s, "group labels"))
    terminal <- if (s == "phi") {
      if (is.null(object$terminal_constraint$phi)) rep(FALSE, nr) else
        frame$interval_end == max(object$data$occasions)
    } else {
      if (is.null(object$terminal_constraint$p)) rep(FALSE, nr) else
        frame$occasion == utils::tail(object$data$occasions, 1L)
    }
    contributing <- d$active & !terminal
    sums <- rowSums(d$Z)
    if (any(sums[contributing] != 1) || any(sums[!contributing] != 0))
      fail(paste("contributing versus inactive/terminal", s, "incidence rows"))
    expected_col <- match(d$values[contributing], d$levels)
    actual_col <- max.col(d$Z[contributing, , drop = FALSE], ties.method = "first")
    if (length(expected_col) && any(expected_col != actual_col))
      fail(paste("key-aligned", s, "group incidence"))
    if (startsWith(route, "site_")) {
      id <- as.character(frame$id[contributing])
      by_id <- split(d$values[contributing], id)
      if (any(vapply(by_id, function(z) length(unique(z)) != 1L, logical(1))))
        fail(paste("one site label per training history for", s))
    }
  }
  if (route == "site_pair") {
    phi <- re$phi; p <- re$p
    id_phi <- as.character(object$training_phi_data$id)
    id_p <- as.character(object$training_p_data$id)
    keep_phi <- phi$active & rowSums(phi$Z) > 0
    keep_p <- p$active & rowSums(p$Z) > 0
    phi_by_id <- tapply(phi$values[keep_phi], id_phi[keep_phi], function(x) unique(x)[1L])
    p_by_id <- tapply(p$values[keep_p], id_p[keep_p], function(x) unique(x)[1L])
    common <- intersect(names(phi_by_id), names(p_by_id))
    if (length(common) && any(phi_by_id[common] != p_by_id[common]))
      fail("matching survival and detection site labels within each training history")
  }
  invisible(TRUE)
}

.cmr_shared_process_sd <- function(object, process) {
  if (is.null(object$random_effects[[process]])) return(0)
  value <- object$random_effects$sd[[process]]
  expected <- if (!is.null(object$random_effects$sd_design)) length(object$random_effects[[process]]$levels) else 1L
  if (!is.numeric(value) || length(value) != expected || any(!is.finite(value)) || any(value < 0))
    stop("shared prediction requires a finite nonnegative scalar ", process, " SD.", call. = FALSE)
  unname(value)
}

.cmr_shared_training_groups <- function(object, process, rows = NULL) {
  random <- object$random_effects[[process]]
  n <- if (process == "phi") nrow(object$data$y) * max(ncol(object$data$y) - 1L, 0L) else
    nrow(object$data$y) * ncol(object$data$y)
  if (is.null(rows)) rows <- seq_len(n)
  out <- rep(NA_character_, n)
  if (!is.null(random)) out[random$row_index] <- random$values
  out[rows]
}

.cmr_predict_shared <- function(object, newdata = NULL,
                                type = c("response", "link"),
                                target = NULL) {
  type <- match.arg(type)
  if (is.null(target))
    stop("shared-effect prediction requires an explicit `target`: `zero_effect` or `integrated`.", call. = FALSE)
  if (!is.character(target) || length(target) != 1L || is.na(target) ||
      !target %in% c("zero_effect", "integrated"))
    stop("`target` must be `zero_effect` or `integrated`.", call. = FALSE)
  .cmr_shared_methods_validate(object)
  if (target == "integrated" && type == "link")
    stop("integrated shared-effect prediction is available on the response scale only.", call. = FALSE)

  if (is.null(newdata)) {
    phi_rows <- which(object$phi_active)
    p_rows <- which(object$p_active)
    phi_frame <- object$training_phi_data
    p_frame <- object$training_p_data
    phi_keys <- phi_frame[phi_rows, c("id", "interval_start", "interval_end"), drop = FALSE]
    p_keys <- p_frame[p_rows, c("id", "occasion"), drop = FALSE]
    phi_keys$interval_length <- as.numeric(t(object$data$delta))[phi_rows]
    eta_phi <- as.numeric(object$phi$X[phi_rows, , drop = FALSE] %*%
      object$coefficients$phi + object$phi$offset[phi_rows])
    eta_p <- as.numeric(object$p$X[p_rows, , drop = FALSE] %*%
      object$coefficients$p + object$p$offset[p_rows])
    group_phi <- .cmr_shared_training_groups(object, "phi", phi_rows)
    group_p <- .cmr_shared_training_groups(object, "p", p_rows)
  } else {
    if (!is.list(newdata) || length(newdata) != 3L ||
        !setequal(names(newdata), c("phi", "p", "units")))
      stop("`newdata` must be a list containing exactly `phi`, `p`, and `units`.", call. = FALSE)
    if (!identical(newdata$units, object$data$units))
      stop("prediction `units` must exactly match the fitted interval units (`", object$data$units, "`).", call. = FALSE)
    phi_input <- .cmr_shared_prediction_input(newdata$phi, "phi", object)
    p_input <- .cmr_shared_prediction_input(newdata$p, "p", object)
    phi_keys <- phi_input$keys
    p_keys <- p_input$keys
    eta_phi <- .cmr_shared_prediction_eta(object$phi, object$coefficients$phi,
      phi_input$frame, "phi")
    eta_p <- .cmr_shared_prediction_eta(object$p, object$coefficients$p,
      p_input$frame, "p")
    group_phi <- phi_input$group
    group_p <- p_input$group
    .cmr_shared_check_new_groups(object, phi_keys, group_phi, p_keys, group_p)
  }
  if (!is.null(object$terminal_constraint$phi)) {
    terminal <- phi_keys$interval_end == max(object$data$occasions)
    eta_phi[terminal] <- stats::qlogis(object$terminal_constraint$phi)
  }
  if (!is.null(object$terminal_constraint$p)) {
    terminal <- p_keys$occasion == utils::tail(object$data$occasions, 1L)
    eta_p[terminal] <- stats::qlogis(object$terminal_constraint$p)
  }
  if (any(!is.finite(eta_phi)) || any(!is.finite(eta_p)))
    stop("shared-effect prediction requires finite prediction linear predictors.", call. = FALSE)

  terminal_phi <- !is.null(object$terminal_constraint$phi) &
    phi_keys$interval_end == max(object$data$occasions)
  terminal_p <- !is.null(object$terminal_constraint$p) &
    p_keys$occasion == utils::tail(object$data$occasions, 1L)
  sigma_phi <- .cmr_shared_prediction_sd(object, "phi",
    if (is.null(newdata)) phi_frame else phi_input$frame, group_phi, terminal_phi)
  sigma_p <- .cmr_shared_prediction_sd(object, "p",
    if (is.null(newdata)) p_frame else p_input$frame, group_p, terminal_p)
  integration_refinement <- "not_applicable_for_link_output"
  if (type == "link") {
    phi_out <- phi_keys; phi_out$eta <- eta_phi
    p_out <- p_keys; p_out$eta <- eta_p
  } else {
    if (target == "integrated") {
      means <- .cmr_shared_integrated_means(eta_phi, sigma_phi,
        phi_keys$interval_length, terminal_phi, object$terminal_constraint$phi,
        eta_p, sigma_p, terminal_p, object$terminal_constraint$p)
      phi_unit <- means$phi_unit
      phi_interval <- means$phi_interval
      p_value <- means$p
      integration_refinement <- means$refinement
    } else {
      phi_unit <- .cmr_shared_normal_mean(eta_phi, sigma_phi, 1, target,
        terminal_phi, object$terminal_constraint$phi)
      phi_interval <- .cmr_shared_normal_mean(eta_phi, sigma_phi,
        phi_keys$interval_length, target, terminal_phi,
        object$terminal_constraint$phi)
      p_value <- .cmr_shared_normal_mean(eta_p, sigma_p, 1, target,
        terminal_p, object$terminal_constraint$p)
      phi_unit <- as.numeric(phi_unit); phi_interval <- as.numeric(phi_interval)
      p_value <- as.numeric(p_value)
      integration_refinement <- "not_required_for_zero_effect"
    }
    phi_out <- phi_keys
    phi_out$phi_unit <- phi_unit
    phi_out$phi_interval <- phi_interval
    p_out <- p_keys; p_out$p <- p_value
  }
  out <- list(phi = phi_out, p = p_out)
  attr(out, "prediction") <- list(
    target = target,
    route = object$random_effects$route,
    groups = c(phi = if (is.null(object$random_effects$phi)) NA_character_ else object$random_effects$phi$group,
               p = if (is.null(object$random_effects$p)) NA_character_ else object$random_effects$p$group),
    mixing = "independent process-specific fitted normal reference laws",
    parameters = "fitted parameters held fixed",
    integration = if (target == "integrated") integration_refinement else "not used",
    limitations = "Process means at supplied profiles; not joint-history prediction, uncertainty calibration, or a population average.")
  out
}

# Normalize an SD at each integration row or shared latent coordinate.
.cmr_shared_sd_vector <- function(sigma, n) {
  if (!is.numeric(sigma) || !(length(sigma) %in% c(1L, n)) ||
      any(!is.finite(sigma)) || any(sigma < 0))
    stop("shared SDs must be finite nonnegative values, scalar or one per unit/row.", call. = FALSE)
  rep_len(as.numeric(sigma), n)
}

.cmr_shared_normal_mean <- function(eta, sigma, power, target,
                                    terminal = rep(FALSE, length(eta)),
                                    constraint = NULL) {
  eta <- as.numeric(eta)
  sigma <- .cmr_shared_sd_vector(sigma, length(eta))
  if (!is.numeric(power) || !(length(power) %in% c(1L, length(eta))) ||
      any(!is.finite(power)) || any(power <= 0))
    stop("prediction powers must be positive finite values, scalar or one per row.", call. = FALSE)
  if (!is.logical(terminal) || length(terminal) != length(eta) || anyNA(terminal))
    stop("terminal flags must be complete logical values, one per row.", call. = FALSE)
  power <- rep_len(as.numeric(power), length(eta))
  ans <- stats::plogis(eta)^power
  used <- 0L
  refinement <- "not_required_zero_sd_or_no_unconstrained_rows"
  active <- which(!terminal & sigma > 0)
  if (target == "integrated" && length(active)) {
    previous <- NULL
    converged <- FALSE
    for (order in c(25L, 41L, 65L, 97L)) {
      gh <- .cmr_gauss_hermite(order)
      current <- vapply(active, function(i)
        sum(gh$weights * stats::plogis(eta[[i]] + sigma[[i]] * gh$nodes)^power[[i]]),
        numeric(1))
      used <- order
      if (!is.null(previous) && max(abs(current - previous)) <= 1e-8) {
        ans[active] <- current
        converged <- TRUE
        refinement <- list(status = "refined", selected_order = order,
                           max_change = max(abs(current - previous)))
        break
      }
      previous <- current
      ans[active] <- current
    }
    if (!converged)
      stop("shared prediction quadrature is unrefined at order 97; no prediction was returned.", call. = FALSE)
  }
  if (any(terminal) && !is.null(constraint)) ans[terminal] <- constraint^power[terminal]
  attr(ans, "integration_refinement") <- if (is.list(refinement)) refinement else
    list(status = refinement, selected_order = used, max_change = NA_real_)
  ans
}

.cmr_shared_integrated_means <- function(eta_phi, sigma_phi, delta,
    terminal_phi, constraint_phi, eta_p, sigma_p, terminal_p, constraint_p) {
  sigma_phi <- .cmr_shared_sd_vector(sigma_phi, length(eta_phi))
  sigma_p <- .cmr_shared_sd_vector(sigma_p, length(eta_p))
  phi_unit <- stats::plogis(eta_phi)
  phi_interval <- phi_unit^delta
  p <- stats::plogis(eta_p)
  active <- list(phi_unit = which(!terminal_phi & sigma_phi > 0),
    phi_interval = which(!terminal_phi & sigma_phi > 0),
    p = which(!terminal_p & sigma_p > 0))
  if (!any(lengths(active))) {
    if (any(terminal_phi) && !is.null(constraint_phi)) {
      phi_unit[terminal_phi] <- constraint_phi
      phi_interval[terminal_phi] <- constraint_phi^delta[terminal_phi]
    }
    if (any(terminal_p) && !is.null(constraint_p)) p[terminal_p] <- constraint_p
    return(list(phi_unit = phi_unit, phi_interval = phi_interval, p = p,
      refinement = list(status = "not_required_zero_sd_or_constrained",
                        selected_order = NA_integer_, max_change = NA_real_)))
  }
  for (order in c(25L, 41L, 65L, 97L)) {
    gh <- .cmr_gauss_hermite(order)
    current <- list(phi_unit = phi_unit, phi_interval = phi_interval, p = p)
    if (length(active$phi_unit)) current$phi_unit[active$phi_unit] <- vapply(
      active$phi_unit, function(i) sum(gh$weights *
        stats::plogis(eta_phi[[i]] + sigma_phi[[i]] * gh$nodes)), numeric(1))
    if (length(active$phi_interval)) current$phi_interval[active$phi_interval] <- vapply(
      active$phi_interval, function(i) sum(gh$weights *
        stats::plogis(eta_phi[[i]] + sigma_phi[[i]] * gh$nodes)^delta[[i]]), numeric(1))
    if (length(active$p)) current$p[active$p] <- vapply(active$p, function(i)
      sum(gh$weights * stats::plogis(eta_p[[i]] + sigma_p[[i]] * gh$nodes)), numeric(1))
    if (order == 25L) {
      previous <- current
      next
    }
    changes <- unlist(lapply(names(active), function(nm) {
      ix <- active[[nm]]
      if (!length(ix)) return(numeric())
      abs(current[[nm]][ix] - previous[[nm]][ix])
    }), use.names = FALSE)
    max_change <- if (length(changes)) max(changes) else 0
    if (max_change <= 1e-8) {
      phi_unit <- current$phi_unit
      phi_interval <- current$phi_interval
      p <- current$p
      if (length(terminal_phi) && any(terminal_phi) && !is.null(constraint_phi)) {
        phi_unit[terminal_phi] <- constraint_phi
        phi_interval[terminal_phi] <- constraint_phi^delta[terminal_phi]
      }
      if (any(terminal_p) && !is.null(constraint_p)) p[terminal_p] <- constraint_p
      return(list(phi_unit = phi_unit, phi_interval = phi_interval, p = p,
        refinement = list(status = "refined", selected_order = order,
                          max_change = max_change)))
    }
    previous <- current
  }
  stop("shared prediction quadrature is unrefined at order 97; no prediction was returned.", call. = FALSE)
}

.cmr_shared_prediction_input <- function(x, process, object) {
  keys <- if (process == "phi") c("id", "interval_start", "interval_end", "interval_length") else c("id", "occasion")
  if (!is.data.frame(x) || !nrow(x) || !all(keys %in% names(x)))
    stop("`newdata$", process, "` must be a non-empty data frame with keys ", paste(keys, collapse = ", "), ".", call. = FALSE)
  key_unique <- if (process == "phi") keys[1:3] else keys
  if (anyNA(x[keys]) || anyDuplicated(x[key_unique]))
    stop("`newdata$", process, "` keys must be complete and unique.", call. = FALSE)
  if (process == "phi" && (!is.numeric(x$interval_length) || any(!is.finite(x$interval_length)) || any(x$interval_length <= 0)))
    stop("`newdata$phi$interval_length` must contain positive finite values.", call. = FALSE)
  random <- object$random_effects[[process]]
  group_name <- if (is.null(random)) NULL else random$group
  vars <- all.vars(object[[process]]$terms)
  sd_design <- object$random_effects$sd_design[[process]]
  sd_vars <- if (is.null(sd_design)) character() else all.vars(sd_design$terms)
  required <- unique(c(keys, vars, sd_vars, group_name))
  if (!all(required %in% names(x)))
    stop("`newdata$", process, "` is missing formula/schema columns: ", paste(setdiff(required, names(x)), collapse = ", "), ".", call. = FALSE)
  if (!setequal(names(x), required))
    stop("`newdata$", process, "` does not match the fitted predictor schema.", call. = FALSE)
  if (any(vapply(x[vars], function(v) anyNA(v), logical(1))))
    stop("`newdata$", process, " predictors must not be missing.", call. = FALSE)
  group <- NULL
  if (!is.null(group_name)) {
    group <- as.character(x[[group_name]])
    if (anyNA(group) || any(!nzchar(trimws(group))))
      stop("`newdata$", process, "` random grouping labels must be non-missing and non-empty.", call. = FALSE)
  }
  list(keys = x[keys], frame = x, group = group)
}

.cmr_shared_prediction_eta <- function(design, beta, frame, process) {
  mf <- tryCatch(stats::model.frame(design$terms, data = frame,
    na.action = stats::na.fail, xlev = design$xlevels), error = function(e)
      stop("cannot build the fitted ", process, " prediction schema: ", conditionMessage(e), call. = FALSE))
  mm <- tryCatch(stats::model.matrix(design$terms, data = mf,
    contrasts.arg = design$contrasts), error = function(e)
      stop("cannot build the fitted ", process, " model matrix: ", conditionMessage(e), call. = FALSE))
  if (any(!is.finite(mm)) || !all(design$columns %in% colnames(mm)))
    stop("prediction model matrix is non-finite or incompatible with fitted ", process, " coefficients.", call. = FALSE)
  mm <- mm[, design$columns, drop = FALSE]
  if (!identical(colnames(mm), names(beta)))
    stop("prediction coefficient columns do not match the fitted ", process, " design.", call. = FALSE)
  offset <- stats::model.offset(mf)
  if (is.null(offset)) offset <- rep(0, nrow(mm))
  eta <- as.numeric(mm %*% beta + offset)
  if (any(!is.finite(eta))) stop("prediction linear predictors must be finite.", call. = FALSE)
  eta
}

.cmr_shared_check_new_groups <- function(object, phi_keys, phi_group, p_keys, p_group) {
  if (!grepl("^site_", object$random_effects$route)) return(invisible(TRUE))
  check_one <- function(keys, labels, process) {
    if (is.null(labels)) return(NULL)
    by_id <- split(labels, as.character(keys$id))
    bad <- names(by_id)[!vapply(by_id, function(z) length(unique(z)) == 1L, logical(1))]
    if (length(bad)) stop("newdata assigns multiple ", process, " site labels to id ", bad[[1L]], ".", call. = FALSE)
    stats::setNames(vapply(by_id, `[[`, character(1), 1L), names(by_id))
  }
  a <- check_one(phi_keys, phi_group, "survival")
  b <- check_one(p_keys, p_group, "detection")
  if (identical(object$random_effects$route, "site_pair") && length(intersect(names(a), names(b)))) {
    common <- intersect(names(a), names(b))
    bad <- common[a[common] != b[common]]
    if (length(bad)) stop("newdata survival and detection site labels disagree for id ", bad[[1L]], ".", call. = FALSE)
  }
  invisible(TRUE)
}

# Build one declared SD covariate profile per supplied latent unit using the
# fitted schema. Missing repetitions are allowed only when that same unit has
# one unambiguous nonmissing declaration. Mean predictors are never filled.
.cmr_shared_sd_profile <- function(object, process, frame, groups) {
  if (is.null(object$random_effects[[process]])) return(numeric(nrow(frame)))
  if (!is.data.frame(frame) || length(groups) != nrow(frame) ||
      anyNA(groups) || any(!nzchar(as.character(groups))))
    stop("shared SD prediction requires complete aligned group labels.", call. = FALSE)
  design <- object$random_effects$sd_design[[process]]
  gamma <- object$random_effects$parameters[[paste0("log_sd_", process)]]
  if (!is.list(design) || !inherits(design$terms, "terms") ||
      !is.character(design$columns) || !is.numeric(gamma) ||
      length(gamma) != length(design$columns) || any(!is.finite(gamma)))
    stop("shared SD prediction requires fitted SD schema and coefficients.", call. = FALSE)
  groups <- as.character(groups);units <- unique(groups)
  rows <- lapply(units, function(g) which(groups == g))
  unit <- data.frame(.cmr_unit = units)
  for (name in all.vars(design$terms)) {
    if (!name %in% names(frame))
      stop("shared SD predictor or offset is absent: ", name, call. = FALSE)
    source <- frame[[name]]
    values <- lapply(rows, function(ix) {
      v <- source[ix];v <- v[!is.na(v)]
      if (!length(v)) stop("shared SD profile has no nonmissing declaration: ", name, call. = FALSE)
      if (length(unique(v)) != 1L)
        stop("shared SD predictors and offsets must be constant within group: ", name, call. = FALSE)
      v[1L]
    })
    unit[[name]] <- if (is.factor(source))
      factor(vapply(values, as.character, ""), levels = levels(source)) else do.call(c, values)
  }
  mf <- stats::model.frame(design$terms, unit, na.action = stats::na.fail,
    xlev = design$xlevels)
  mm <- stats::model.matrix(design$terms, mf, contrasts.arg = design$contrasts)
  if (!all(design$columns %in% colnames(mm)))
    stop("shared SD prediction matrix does not match fitted columns.", call. = FALSE)
  offset <- stats::model.offset(mf)
  if (is.null(offset)) offset <- numeric(nrow(mm))
  sigma <- exp(as.numeric(mm[, design$columns, drop = FALSE] %*% gamma + offset))
  if (any(!is.finite(sigma)) || any(sigma <= 0))
    stop("shared SD profiles must yield finite positive SDs.", call. = FALSE)
  sigma[match(groups, units)]
}


.cmr_shared_prediction_sd <- function(object, process, frame, groups, terminal) {
  if (is.null(object$random_effects[[process]])) return(numeric(length(terminal)))
  if (is.null(object$random_effects$sd_design))
    return(rep(.cmr_shared_process_sd(object, process), length(groups)))
  out <- numeric(length(groups));wanted <- which(!terminal)
  if (!length(wanted)) return(out)
  column <- object$random_effects[[process]]$group
  source_groups <- as.character(frame[[column]])
  if (length(source_groups) != nrow(frame))
    stop("shared SD prediction requires its grouping column.", call. = FALSE)
  rows <- which(source_groups %in% groups[wanted])
  profile <- .cmr_shared_sd_profile(object, process, frame[rows, , drop = FALSE], source_groups[rows])
  ix <- match(groups[wanted], source_groups[rows])
  if (anyNA(ix)) stop("shared SD prediction group has no profile declaration.", call. = FALSE)
  out[wanted] <- profile[ix]
  out
}
