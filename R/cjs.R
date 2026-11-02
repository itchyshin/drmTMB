#' Fit a first-capture-conditional CJS model
#'
#' @param data A `cmr_data` object.
#' @param phi Survival formula, with logit unit-time apparent survival. M3
#'   accepts at most one shared random intercept, such as `(1 | site)`.
#' @param p Detection formula, with logit detection conditional on alive. M3
#'   accepts at most one shared random intercept, such as `(1 | site)`.
#' @param phi_data Optional interval predictor table keyed by `id`,
#'   `interval_start`, and `interval_end`.
#' @param p_data Optional detection predictor table keyed by `id` and `occasion`.
#' @param terminal_constraint Optional named list fixing exactly one common
#'   final-process probability, for example `list(phi = 0.8)` (unit-time
#'   survival) or `list(p = 0.4)` (final-occasion detection). Values must be
#'   strictly between zero and one. It applies at the final declared interval
#'   or occasion, not at each individual's administrative endpoint.
#' @param contrasts Optional named list of process-specific contrast specifications,
#'   `list(phi = ..., p = ...)`. The fitted coding is retained for prediction and
#'   bootstrap refits.
#' @param selection Optional `list(eligibility = occasion_indices,
#'   assumption = "alive_available")`. Conditions each individual's likelihood
#'   on first capture at the realized occasion under an alive-and-available
#'   reference cohort. Shared-effect selection is unsupported.
#' @param sd_phi,sd_p Optional one-sided formulas for log SD of the persistent
#'   individual survival or detection effect. Predictors must be constant
#'   within individual.
#' @param control Options passed to [stats::nlminb()].
#' @param engine Computational engine: native TMB or native DRModels.jl. The
#'   Julia bridge currently admits fixed-effects CJS only.
#' @return A `drm_cjs` fit containing the optimizer and TMB objective.
#'   Individual-effect fits also report quadrature refinement status and an
#'   `order_timings` table with setup/optimization time, optimizer status,
#'   iterations, and function and gradient evaluation counts. These timings
#'   describe the fit that ran; they do not establish parameter recovery or
#'   inference calibration.
#' @export
drm_cjs <- function(data, phi = ~1, p = ~1, phi_data = NULL, p_data = NULL,
                    selection = NULL, sd_phi = NULL, sd_p = NULL,
                    terminal_constraint = NULL, control = list(),
                    contrasts = list(phi = NULL, p = NULL),
                    engine = c("tmb", "julia")) {
  engine <- match.arg(engine)
  if (!inherits(data, "cmr_data")) stop("`data` must be made by cmr_data().", call. = FALSE)
  for (nm in c("sd_phi", "sd_p")) if (!is.null(get(nm))) {
    f <- get(nm)
    if (!inherits(f, "formula") || length(f) != 2L)
      stop("`", nm, "` must be a one-sided formula such as `~ habitat`.", call. = FALSE)
  }
  if (!inherits(phi, "formula") || !inherits(p, "formula"))
    stop("`phi` and `p` must be one-sided formulas.", call. = FALSE)
  if (length(phi) != 2L || length(p) != 2L) stop("`phi` and `p` must be one-sided formulas.", call. = FALSE)
  phi_formula <- .cmr_split_random_intercept(phi, "phi")
  p_formula <- .cmr_split_random_intercept(p, "p")
  if (!is.null(sd_phi) && is.null(phi_formula$group))
    stop("`sd_phi` requires an individual or shared survival effect.", call. = FALSE)
  if (!is.null(sd_p) && is.null(p_formula$group))
    stop("`sd_p` requires an individual or shared detection effect.", call. = FALSE)
  n <- nrow(data$y); nt <- ncol(data$y)
  if (!any(data$first < data$end))
    stop("CJS fitting needs at least one post-capture transition; final-first histories are retained with likelihood one when other histories inform the fit.", call. = FALSE)
  p_rows <- data.frame(i = rep(seq_len(n), each = nt), t = rep(seq_len(nt), n))
  phi_rows <- data.frame(i = rep(seq_len(n), each = max(nt - 1L, 0L)),
                         t = rep(seq_len(max(nt - 1L, 0L)), n))
  p_frame <- .cmr_join_predictors(data, p_data, p_rows, "p")
  phi_frame <- .cmr_join_predictors(data, phi_data, phi_rows, "phi")
  p_active <- p_rows$t > data$first[p_rows$i] & p_rows$t <= data$end[p_rows$i] &
    data$observed[cbind(p_rows$i, p_rows$t)]
  phi_active <- vapply(seq_along(phi_rows$i), function(row) {
    i <- phi_rows$i[[row]]
    t <- phi_rows$t[[row]]
    t >= data$first[[i]] && t < data$end[[i]] &&
      any(data$observed[i, seq.int(t + 1L, data$end[[i]])])
  }, logical(1))
  p_selection_active <- rep(FALSE, nrow(p_rows))
  phi_selection_active <- rep(FALSE, nrow(phi_rows))
  eligibility <- NULL
  if (!is.null(selection)) {
    if (!is.list(selection) || length(selection) != 2L || !setequal(names(selection), c("eligibility", "assumption")) ||
        !identical(selection$assumption, "alive_available"))
      stop("`selection` must be `list(eligibility = occasion_indices, assumption = \"alive_available\")`.", call. = FALSE)
    eligibility_raw <- selection$eligibility
    if (!is.numeric(eligibility_raw) || length(eligibility_raw) != n ||
        anyNA(eligibility_raw) || any(!is.finite(eligibility_raw)) ||
        any(eligibility_raw != floor(eligibility_raw)) ||
        any(eligibility_raw < 1 | eligibility_raw > data$first))
      stop("selection eligibility must give one occasion index at or before each individual's first capture.", call. = FALSE)
    eligibility <- as.integer(eligibility_raw)
    random_groups <- c(phi_formula$group, p_formula$group)
    has_individual_effect <- any(random_groups == "id", na.rm = TRUE)
    has_shared_effect <- any(!is.na(random_groups) & random_groups != "id")
    if (!has_individual_effect || has_shared_effect)
      stop("reference selection supports persistent individual effects only; every random-effect process must use `(1 | id)`, and shared-effect selection is unsupported.", call. = FALSE)
    phi_selection_active <- phi_rows$t >= eligibility[phi_rows$i] &
      phi_rows$t < data$first[phi_rows$i]
    p_selection_active <- p_rows$t >= eligibility[p_rows$i] &
      p_rows$t <= data$first[p_rows$i] & data$observed[cbind(p_rows$i, p_rows$t)]
  }
  if (!any(p_active))
    stop("CJS fitting needs at least one surveyed post-capture occasion to inform detection.", call. = FALSE)
  if (!is.list(contrasts) || is.null(names(contrasts)) ||
      any(!names(contrasts) %in% c("phi", "p")) || anyDuplicated(names(contrasts)))
    stop("`contrasts` must be a named list with optional `phi` and `p` specifications.", call. = FALSE)
  p_design_active <- p_active | p_selection_active
  phi_design_active <- phi_active | phi_selection_active
  p_design <- .cmr_design(p_formula$fixed, p_frame, "p", p_design_active, contrasts$p)
  phi_design <- .cmr_design(phi_formula$fixed, phi_frame, "phi", phi_design_active, contrasts$phi)
  for (design in list(phi_design, p_design)) {
    if (ncol(design$X) && qr(design$X)$rank < ncol(design$X))
      stop("`", design$process, "` design is rank deficient; remove linearly dependent predictors.", call. = FALSE)
  }
  # A direction occurring only at the final declared occasion/interval
  # is confounded with its paired terminal process probability.
  if (!is.null(terminal_constraint) && (!is.list(terminal_constraint) ||
      length(terminal_constraint) != 1L || is.null(names(terminal_constraint)) ||
      !names(terminal_constraint) %in% c("phi", "p")))
    stop("supply exactly one named `terminal_constraint`: `phi` or `p`.", call. = FALSE)
  # Identification constraint refers to the common last declared occasion;
  # each individual's administrative endpoint only truncates their likelihood.
  p_terminal <- p_rows$t == nt
  phi_terminal <- phi_rows$t == nt - 1L
  p_fixed <- .cmr_or_null(terminal_constraint[["p"]])
  phi_fixed <- .cmr_or_null(terminal_constraint[["phi"]])
  random_phi <- .cmr_random_design(phi_formula$group, phi_frame, phi_design_active,
                                   phi_rows$i, phi_rows$t, n, nt, "phi")
  random_p <- .cmr_random_design(p_formula$group, p_frame, p_design_active,
                                 p_rows$i, p_rows$t, n, nt, "p")
  phi_terminal_identified <- .cmr_terminal_rank(phi_design, phi_terminal,
                                                 phi_design_active, random_phi)
  p_terminal_identified <- .cmr_terminal_rank(p_design, p_terminal,
                                               p_design_active, random_p)
  if (phi_terminal_identified && p_terminal_identified && is.null(terminal_constraint))
    stop("terminal phi and p shared directions are confounded; supply one `terminal_constraint = list(phi = value)` or `list(p = value)`.", call. = FALSE)
  p_design <- .cmr_fixed_terminal(p_design, p_terminal, "p", p_fixed)
  phi_design <- .cmr_fixed_terminal(phi_design, phi_terminal, "phi", phi_fixed)
  random_route <- .cmr_cjs_random_route(random_phi, random_p, n)
  if (!is.null(random_phi) && !is.null(phi_fixed) &&
      !any(random_phi$active & !phi_terminal))
    stop("`phi` random effect has no informative rows outside the terminal constraint; remove the random effect or change the constraint.", call. = FALSE)
  if (!is.null(random_p) && !is.null(p_fixed) &&
      !any(random_p$active & !p_terminal))
    stop("`p` random effect has no informative rows outside the terminal constraint; remove the random effect or change the constraint.", call. = FALSE)
  if (identical(engine, "julia") && random_route != "fixed")
    stop("`engine = \"julia\"` currently supports fixed-effects CJS only; random effects, SD formulas, and selection remain on the native TMB route.", call. = FALSE)
  individual_route <- startsWith(random_route, "individual_")
  if (!individual_route && !is.null(phi_fixed)) random_phi <- .cmr_random_terminal(random_phi, phi_terminal)
  if (!individual_route && !is.null(p_fixed)) random_p <- .cmr_random_terminal(random_p, p_terminal)
  shared_sd_route <- !individual_route && (!is.null(sd_phi) || !is.null(sd_p))
  if (shared_sd_route) {
    random_phi <- .cmr_shared_sd_prune(random_phi)
    random_p <- .cmr_shared_sd_prune(random_p)
  }
  n_phi <- ncol(phi_design$X); n_p <- ncol(p_design$X)
  x_phi <- phi_design$X; x_p <- p_design$X
  beta_phi <- rep(0, n_phi); beta_p <- rep(0, n_p)
  map <- list()
  if (n_phi == 0L) {
    x_phi <- matrix(0, nrow(phi_design$X), 1L)
    beta_phi <- 0
    if (n_p > 0L) map$beta_phi <- factor(NA)
  }
  if (n_p == 0L) {
    x_p <- matrix(0, nrow(p_design$X), 1L)
    beta_p <- 0
    map$beta_p <- factor(NA)
  }
  # Keep a single inert slot in the high-level all-fixed route; it is excluded
  # from the public coefficients and never optimized.
  if (n_phi == 0L && n_p == 0L) map <- list(beta_p = factor(NA))
  has_random <- !is.null(random_phi) || !is.null(random_p)
  has_laplace <- has_random && !individual_route
  model_type <- if (individual_route) 1002L else if (shared_sd_route) 1003L else if (has_laplace) 1001L else 1000L
  cmr_data <- list(
    model_type = model_type, cmr_N = n, cmr_T = nt,
    cmr_y = as.integer(t(data$y)), cmr_observed = as.integer(t(data$observed)),
    cmr_first = data$first - 1L, cmr_end = data$end - 1L,
    cmr_delta = as.numeric(t(data$delta)), cmr_frequency = data$frequency,
    cmr_X_phi = x_phi, cmr_X_p = x_p,
    cmr_offset_phi = phi_design$offset, cmr_offset_p = p_design$offset
  )
  parameters <- list(beta_phi = beta_phi, beta_p = beta_p)
  random_parameters <- character()
  if (has_random) {
    if (is.null(random_phi)) {
      cmr_data$cmr_Z_phi <- matrix(0, n * max(nt - 1L, 0L), 0L)
      parameters$u_phi <- numeric()
      parameters$log_sigma_phi <- 0
      map$log_sigma_phi <- factor(NA)
    } else {
      cmr_data$cmr_Z_phi <- random_phi$Z
      parameters$u_phi <- numeric(ncol(random_phi$Z))
      parameters$log_sigma_phi <- log(0.5)
      random_parameters <- c(random_parameters, "u_phi")
    }
    if (is.null(random_p)) {
      cmr_data$cmr_Z_p <- matrix(0, n * nt, 0L)
      parameters$u_p <- numeric()
      parameters$log_sigma_p <- 0
      map$log_sigma_p <- factor(NA)
    } else {
      cmr_data$cmr_Z_p <- random_p$Z
      parameters$u_p <- numeric(ncol(random_p$Z))
      parameters$log_sigma_p <- log(0.5)
      random_parameters <- c(random_parameters, "u_p")
    }
  }
  if (shared_sd_route) {
    sd_design_phi <- .cmr_shared_sd_design(sd_phi,phi_frame,random_phi,"phi",contrasts$phi)
    sd_design_p <- .cmr_shared_sd_design(sd_p,p_frame,random_p,"p",contrasts$p)
    for (process in c("phi","p")) {
      design <- if (process=="phi") sd_design_phi else sd_design_p
      cmr_data[[paste0("cmr_sd_X_",process)]] <- if (is.null(design)) matrix(0,0,0) else design$X
      cmr_data[[paste0("cmr_sd_offset_",process)]] <- if (is.null(design)) numeric() else design$offset
      parameters[[paste0("log_sd_",process)]] <- if (is.null(design)) numeric() else .cmr_shared_sd_start(design)
      parameters[[paste0("log_sigma_",process)]] <- NULL
      map[[paste0("log_sigma_",process)]] <- NULL
    }
  }
  if (identical(engine, "julia")) {
    result <- .cmr_julia_fit_fixed(data, phi_design, p_design, phi_active,
                                   p_active, terminal_constraint, control)
    names(result$beta_phi) <- phi_design$columns
    names(result$beta_p) <- p_design$columns
    fixed_names <- c(paste0("phi:", phi_design$columns), paste0("p:", p_design$columns))
    names(result$beta) <- fixed_names
    dimnames(result$hessian) <- list(fixed_names, fixed_names)
    names(result$gradient) <- fixed_names
    opt <- list(par = result$beta, objective = result$objective,
                convergence = if (result$converged) 0L else 1L,
                message = "DRModels.jl fixed-effects CJS optimizer",
                iterations = result$iterations)
    return(structure(list(data = data, logLik = result$loglik,
      objective = result$loglik, training_phi_data = phi_frame,
      training_p_data = p_frame,
      coefficients = list(phi = result$beta_phi, p = result$beta_p),
      optimizer = opt, gradient = result$gradient,
      gradient_fd = numeric(), gradient_norm = if (length(result$gradient)) max(abs(result$gradient)) else 0,
      hessian = result$hessian, n_informative = sum(data$first < data$end),
      n_post_occasions = sum(p_active), convergence = opt$convergence,
      message = opt$message, obj = NULL, phi = phi_design, p = p_design,
      phi_active = phi_active, p_active = p_active,
      terminal_constraint = terminal_constraint,
      prediction_contract = list(version = 1L,
        selection_enabled = !is.null(selection),
        sd_formula_present = c(phi = !is.null(sd_phi), p = !is.null(sd_p))),
      random_effects = list(route = "fixed", phi = NULL, p = NULL,
        parameters = NULL, laplace = FALSE, integration = NULL,
        sd = c(phi = NA_real_, p = NA_real_), mode_status = "not_applicable",
        laplace_status = "not_applicable", curvature_status =
          "Julia automatic-differentiation Hessian; interval calibration is not established."),
      engine = "julia", inference = "local Wald curvature only; calibration not established"),
      class = "drm_cjs"))
  }
  integration <- NULL
  if (individual_route) {
    integration <- list(algorithm = "death_time_decomposition")
    # Shared-effect setup above may have installed log_sigma_* map entries.
    # The individual kernel has a different parameter contract (log_sd_*).
    map <- list()
    if (n_phi == 0L && n_p > 0L) map$beta_phi <- factor(NA)
    if (n_p == 0L && n_phi > 0L) map$beta_p <- factor(NA)
    if (n_phi == 0L && n_p == 0L) map$beta_p <- factor(NA)
    parameters <- list(beta_phi = beta_phi, beta_p = beta_p)
    random_parameters <- character()
    cmr_data$cmr_has_individual_phi <- as.integer(!is.null(random_phi))
    cmr_data$cmr_has_individual_p <- as.integer(!is.null(random_p))
    sd_design_phi <- if (!is.null(random_phi)) .cmr_sd_design(sd_phi, phi_frame, n, "phi", data$id, phi_design_active) else list(X = matrix(0, n, 0L), columns = character())
    sd_design_p <- if (!is.null(random_p)) .cmr_sd_design(sd_p, p_frame, n, "p", data$id, p_design_active) else list(X = matrix(0, n, 0L), columns = character())
    cmr_data$cmr_sd_X_phi <- sd_design_phi$X
    cmr_data$cmr_sd_X_p <- sd_design_p$X
    cmr_data$cmr_sd_offset_phi <- if (is.null(sd_design_phi$offset)) rep(0, n) else sd_design_phi$offset
    cmr_data$cmr_sd_offset_p <- if (is.null(sd_design_p$offset)) rep(0, n) else sd_design_p$offset
    cmr_data$cmr_selection <- as.integer(!is.null(selection))
    cmr_data$cmr_terminal_phi <- as.integer(!is.null(phi_fixed))
    cmr_data$cmr_terminal_p <- as.integer(!is.null(p_fixed))
    cmr_data$cmr_eligibility <- if (is.null(eligibility)) rep(0L, n) else eligibility - 1L
    parameters$log_sd_phi <- if (!is.null(random_phi)) rep(log(0.5), ncol(sd_design_phi$X)) else numeric()
    parameters$log_sd_p <- if (!is.null(random_p)) rep(log(0.5), ncol(sd_design_p$X)) else numeric()
    orders <- c(25L, 41L, 65L, 97L, 129L, 161L, 193L)
    integration$orders <- orders
    integration$parameter_tolerance <- 1e-5
    integration$history_log_integral_tolerance <- 1e-8
    integration$comparisons <- list()
    integration$optimizer_polish <- list()
    integration$order_timings <- data.frame(
      order = integer(), setup_and_optimize_seconds = numeric(),
      convergence = integer(), iterations = integer(),
      function_evaluations = integer(), gradient_evaluations = integer()
    )
    previous_obj <- NULL
    previous_opt <- NULL
    for (order in orders) {
      order_started <- proc.time()[["elapsed"]]
      gh <- .cmr_gauss_hermite(order)
      order_data <- cmr_data
      order_data$cmr_gh_nodes <- gh$nodes
      order_data$cmr_gh_weights <- gh$weights
      obj <- TMB::MakeADFun(data = order_data, parameters = parameters, map = map,
                            DLL = "drmTMB", silent = TRUE)
      start <- if (is.null(previous_opt)) obj$par else previous_opt$par
      if (length(start)) names(start) <- names(obj$par)
      if (!is.null(selection)) {
        initial_selection_report <- obj$report(start)
        initial_selection_denominator <- as.numeric(initial_selection_report$cmr_selection_log_den)
        if (length(initial_selection_denominator) != n ||
            any(!is.finite(initial_selection_denominator)))
          stop("CJS selection normalization probability is zero or non-finite.", call. = FALSE)
      }
      if (length(obj$par)) {
        opt <- stats::nlminb(start = start, objective = obj$fn,
                             gradient = obj$gr, control = control)
      } else {
        opt <- list(par = obj$par, objective = obj$fn(obj$par), convergence = 0L,
                    message = "No free coefficients; evaluated the integrated CJS objective.",
                    iterations = 0L, evaluations = c("function" = 1L, gradient = 0L))
      }
      opt <- .cmr_polish_integrated_opt(obj, opt)
      integration$optimizer_polish[[as.character(order)]] <- opt$polish
      evaluations <- opt$evaluations
      function_evaluations <- if (!is.null(names(evaluations)) &&
        "function" %in% names(evaluations)) unname(evaluations[["function"]]) else NA_integer_
      gradient_evaluations <- if (!is.null(names(evaluations)) &&
        "gradient" %in% names(evaluations)) unname(evaluations[["gradient"]]) else NA_integer_
      integration$order_timings[nrow(integration$order_timings) + 1L, ] <- list(
        as.integer(order), proc.time()[["elapsed"]] - order_started,
        as.integer(opt$convergence), as.integer(opt$iterations),
        as.integer(function_evaluations), as.integer(gradient_evaluations)
      )
      if (!is.null(previous_opt)) {
        parameter_change <- if (length(opt$par)) max(abs(opt$par - previous_opt$par)) else 0
        current_report <- obj$report(opt$par)
        previous_report <- previous_obj$report(opt$par)
        current_history <- current_report$cmr_individual_loglik
        previous_history <- previous_report$cmr_individual_loglik
        history_change <- max(abs(current_history - previous_history))
        numerator_change <- max(abs(current_report$cmr_selection_log_num - previous_report$cmr_selection_log_num))
        denominator_change <- max(abs(current_report$cmr_selection_log_den - previous_report$cmr_selection_log_den))
        integration$comparisons[[length(integration$comparisons) + 1L]] <- list(
          from = previous_obj$gh_order, to = order,
          max_parameter_change = parameter_change,
          max_history_log_integral_change = history_change,
          max_numerator_log_integral_change = numerator_change,
          max_denominator_log_integral_change = denominator_change
        )
        if (parameter_change <= integration$parameter_tolerance &&
            history_change <= integration$history_log_integral_tolerance &&
            numerator_change <= integration$history_log_integral_tolerance &&
            denominator_change <= integration$history_log_integral_tolerance) {
          integration$status <- "refined"
          integration$selected_order <- order
          break
        }
      }
      obj$gh_order <- order
      previous_obj <- obj
      previous_opt <- opt
      integration$status <- "unrefined_at_order_cap"
      integration$selected_order <- order
    }
  } else {
    obj <- TMB::MakeADFun(data = cmr_data, parameters = parameters, map = map,
                          random = if (length(random_parameters)) random_parameters else NULL,
                          DLL = "drmTMB", silent = TRUE)
    n_free <- length(obj$par)
    if (n_free) {
      opt <- stats::nlminb(start = obj$par, objective = obj$fn,
                           gradient = obj$gr, control = control)
      if (has_laplace)
        opt <- .cmr_finish_shared_opt(obj, opt, control = control)
      else if (!has_random)
        opt <- .cmr_polish_integrated_opt(obj, opt)
    } else {
      opt <- list(par = obj$par, objective = obj$fn(obj$par), convergence = 0L,
                  message = "No free coefficients; evaluated the fixed CJS objective.",
                  iterations = 0L, evaluations = c("function" = 1L, gradient = 0L))
    }
  }

  n_free <- length(obj$par)
  grad <- if (n_free) obj$gr(opt$par) else numeric()
  fd <- if (n_free && !has_laplace) .cmr_fd_gradient(obj$fn, opt$par) else numeric()
  final_nll <- obj$fn(opt$par)
  hessian <- if (n_free && !has_laplace) obj$he(opt$par) else matrix(numeric(), 0L, 0L)
  if (n_free && !has_random) {
    fixed_names <- c(paste0("phi:", phi_design$columns), paste0("p:", p_design$columns))
    if (length(fixed_names) == length(opt$par)) names(opt$par) <- fixed_names
  }
  coefficient_par <- if (has_laplace) {
    .cmr_laplace_par_list(obj, opt)
  } else if (individual_route) {
    obj$env$parList(opt$par)
  } else NULL
  beta_phi_fit <- if (has_random) coefficient_par$beta_phi else opt$par[seq_len(ncol(phi_design$X))]
  beta_p_fit <- if (has_random) coefficient_par$beta_p else opt$par[ncol(phi_design$X) + seq_len(ncol(p_design$X))]
  if (length(beta_phi_fit)) names(beta_phi_fit) <- phi_design$columns
  if (length(beta_p_fit)) names(beta_p_fit) <- p_design$columns
  parameter_names <- if (has_random) names(opt$par) else
    c(paste0("phi:", phi_design$columns), paste0("p:", p_design$columns))
  if (!has_random && length(parameter_names) != length(opt$par))
    parameter_names <- paste0("CJS:internal_", seq_along(opt$par))
  if (length(opt$par)) names(opt$par) <- parameter_names
  random_mode <- if (has_laplace) {
    unlist(coefficient_par[c("u_phi", "u_p")], use.names = FALSE)
  } else numeric()
  inner_diagnostics <- if (has_laplace) {
    .cmr_shared_mode_diagnostics(
      data = cmr_data,
      parameters = coefficient_par,
      random_parameters = random_parameters
    )
  } else {
    .cmr_shared_mode_diagnostics_not_applicable()
  }
  random_sd <- if (individual_route || shared_sd_route) list(
    phi = if (!is.null(random_phi)) .cmr_sd_summary(cmr_data$cmr_sd_X_phi,
      coefficient_par$log_sd_phi, cmr_data$cmr_sd_offset_phi, if (shared_sd_route) random_phi$levels else data$id) else NULL,
    p = if (!is.null(random_p)) .cmr_sd_summary(cmr_data$cmr_sd_X_p,
      coefficient_par$log_sd_p, cmr_data$cmr_sd_offset_p, if (shared_sd_route) random_p$levels else data$id) else NULL
  ) else if (has_random) c(
    phi = if (!is.null(random_phi)) exp(coefficient_par$log_sigma_phi) else NA_real_,
    p = if (!is.null(random_p)) exp(coefficient_par$log_sigma_p) else NA_real_
  ) else c(phi = NA_real_, p = NA_real_)
  random_mode_status <- if (!has_laplace) "not_applicable" else
    if (length(random_mode) && all(is.finite(random_mode))) "finite_mode" else "nonfinite_mode"
  laplace_status <- if (!has_laplace) "not_applicable" else
    if (!isTRUE(opt$convergence == 0L) || !is.finite(final_nll) ||
        !identical(random_mode_status, "finite_mode")) "outer_or_mode_failure" else
      switch(inner_diagnostics$status,
        stationary_positive_curvature = "outer_converged_inner_stationary_pd",
        unavailable_dense_size_guard = "outer_converged_inner_hessian_size_guard",
        unavailable = "outer_converged_inner_diagnostics_unavailable",
        "outer_or_inner_diagnostic_failure")
  n_informative <- sum(data$first < data$end)
  n_post_occasions <- sum(p_active)
  fitted_coefficients <- list(phi=beta_phi_fit,p=beta_p_fit)
  if (shared_sd_route) {
    for (process in c("phi","p")) {
      design <- if (process=="phi") sd_design_phi else sd_design_p
      gamma <- coefficient_par[[paste0("log_sd_",process)]]
      if (!is.null(design)) names(gamma) <- design$columns
      fitted_coefficients[[paste0("sd_",process)]] <- gamma
    }
  }
  structure(list(data = data, logLik = -final_nll, objective = -final_nll,
                 # Keep the keyed source rows as well as the fitted designs.
                 # A design matrix cannot be inverted to recover factors,
                 # transforms, interactions, or offset expressions for
                 # conditional simulation and prediction on the training set.
                 training_phi_data = phi_frame, training_p_data = p_frame,
                 coefficients = fitted_coefficients,
                 optimizer = opt, gradient = grad, gradient_fd = fd,
                 gradient_norm = if (length(grad)) max(abs(grad)) else 0,
                 hessian = hessian,
                 n_informative = n_informative, n_post_occasions = n_post_occasions,
                 convergence = opt$convergence, message = opt$message,
                 obj = obj, phi = phi_design, p = p_design,
                 phi_active = phi_active, p_active = p_active,
                 terminal_constraint = terminal_constraint,
                 selection = if (is.null(eligibility)) NULL else
                   list(eligibility = as.integer(eligibility),
                        assumption = "alive_available"),
                 prediction_contract = list(version = 1L,
                   selection_enabled = !is.null(selection),
                   sd_formula_present = c(phi = !is.null(sd_phi), p = !is.null(sd_p))),
                 random_effects = list(route = random_route, phi = random_phi,
                   p = random_p, parameters = if (has_random) coefficient_par else NULL,
                   laplace = has_laplace,
                   integration = integration,
                   sd_design = if (individual_route || shared_sd_route) list(phi = sd_design_phi, p = sd_design_p) else NULL,
                   sd = random_sd, mode_status = random_mode_status,
                   laplace_status = laplace_status,
                   inner_gradient_norm = inner_diagnostics$gradient_norm,
                   inner_hessian_dimension = inner_diagnostics$hessian_dimension,
                   inner_hessian_min_eigenvalue = inner_diagnostics$hessian_min_eigenvalue,
                   inner_hessian_positive_definite = inner_diagnostics$hessian_positive_definite,
                   inner_diagnostics_status = inner_diagnostics$status,
                   inner_diagnostics_message = inner_diagnostics$message,
                   curvature_status = if (has_laplace) inner_diagnostics$status else "not_applicable",
                   diagnostic = if (individual_route) "Deterministic Gauss-Hermite marginal likelihood; numerical refinement is reported separately and does not establish variance recovery or inference calibration." else if (has_laplace) "TMB Laplace fit; variance interpretation requires route-specific integration and identification validation." else "fixed-effects exact CJS objective"),
                 call = match.call()), class = "drm_cjs")
}

.cmr_laplace_par_list <- function(obj, opt) {
  # Re-evaluate at the selected outer optimum immediately before extracting
  # latent modes. TMB's `last.par.best` can belong to an earlier trial point;
  # `last.par` is the conditional mode from this exact objective evaluation.
  value <- obj$fn(opt$par)
  if (length(value) != 1L || !is.finite(value))
    stop("Could not evaluate the selected CJS Laplace objective.", call. = FALSE)
  full_par <- obj$env$last.par
  if (is.null(full_par) || !length(full_par) || any(!is.finite(full_par)))
    stop("The selected CJS Laplace evaluation did not retain a finite latent mode.", call. = FALSE)
  obj$env$parList(opt$par, par = full_par)
}

.cmr_finish_shared_opt <- function(obj, opt, control = list(),
                                   gradient_tolerance = 1e-4,
                                   strict_optimizer = stats::nlminb,
                                   bfgs_optimizer = stats::optim) {
  record <- function(par, objective, convergence, message,
                     iterations = NA_integer_, evaluations = NULL,
                     gradient_norm = NA_real_) {
    list(par = par, objective = objective, convergence = convergence,
         message = message, iterations = iterations,
         evaluations = evaluations, gradient_norm = gradient_norm)
  }
  gradient_norm <- function(par) {
    g <- tryCatch(as.numeric(obj$gr(par)), error = function(e) NULL)
    if (is.null(g) || length(g) != length(par) || any(!is.finite(g)))
      return(Inf)
    max(abs(g))
  }
  initial <- record(opt$par, as.numeric(opt$objective), opt$convergence,
                    opt$message, opt$iterations, opt$evaluations,
                    gradient_norm(opt$par))
  opt$polish <- list(status = "not_needed", stages = list(initial = initial),
                     function_evaluations = NA_integer_,
                     gradient_evaluations = NA_integer_)
  if (!length(opt$par) || length(opt$par) > 64L) {
    opt$polish$status <- "dimension_guard"
    return(opt)
  }
  if (isTRUE(opt$convergence == 0L) &&
      is.finite(initial$gradient_norm) &&
      initial$gradient_norm <= gradient_tolerance)
    return(opt)

  strict_control <- control
  strict_control$iter.max <- max(as.integer(strict_control$iter.max %||% 0L), 500L)
  strict_control$eval.max <- max(as.integer(strict_control$eval.max %||% 0L), 700L)
  strict_control$rel.tol <- min(as.numeric(strict_control$rel.tol %||% 1e-15), 1e-15)
  strict_control$x.tol <- min(as.numeric(strict_control$x.tol %||% 1e-12), 1e-12)
  strict <- tryCatch(strict_optimizer(
    start = opt$par, objective = obj$fn, gradient = obj$gr,
    control = strict_control
  ), error = identity)
  if (inherits(strict, "error")) {
    opt$polish$status <- "strict_optimizer_error"
    opt$polish$strict_error <- conditionMessage(strict)
    return(opt)
  }
  strict_norm <- gradient_norm(strict$par)
  strict_record <- record(strict$par, as.numeric(strict$objective),
                          strict$convergence, strict$message,
                          strict$iterations, strict$evaluations, strict_norm)
  opt$polish$stages$strict <- strict_record
  objective_tolerance <- 1e-10 * max(1, abs(initial$objective))
  strict_accepted <- isTRUE(strict$convergence == 0L) &&
    is.finite(strict_record$objective) &&
    strict_record$objective <= initial$objective + objective_tolerance &&
    strict_norm <= gradient_tolerance
  if (strict_accepted) {
    opt$par <- strict$par
    opt$objective <- strict_record$objective
    opt$convergence <- strict$convergence
    opt$message <- strict$message
    opt$iterations <- strict$iterations
    opt$evaluations <- strict$evaluations
    opt$polish$status <- "strict_nlminb_accepted"
    return(opt)
  }

  bfgs_start <- if (is.finite(strict_record$objective) &&
                    strict_record$objective <= initial$objective + objective_tolerance)
    strict$par else opt$par
  bfgs <- tryCatch(bfgs_optimizer(
    par = bfgs_start, fn = obj$fn,
    gr = function(x) as.numeric(obj$gr(x)), method = "BFGS",
    control = list(maxit = 500L, reltol = 1e-14)
  ), error = identity)
  if (inherits(bfgs, "error")) {
    opt$polish$status <- "bfgs_optimizer_error"
    opt$polish$bfgs_error <- conditionMessage(bfgs)
    return(opt)
  }
  bfgs_norm <- gradient_norm(bfgs$par)
  bfgs_record <- record(bfgs$par, as.numeric(bfgs$value),
                        bfgs$convergence, bfgs$message,
                        NA_integer_, bfgs$counts, bfgs_norm)
  opt$polish$stages$bfgs <- bfgs_record
  reference_objective <- min(c(initial$objective, strict_record$objective),
                             na.rm = TRUE)
  bfgs_accepted <- isTRUE(bfgs$convergence == 0L) &&
    is.finite(bfgs_record$objective) &&
    bfgs_record$objective <= reference_objective + objective_tolerance &&
    bfgs_norm <= gradient_tolerance
  if (!bfgs_accepted) {
    opt$polish$status <- "no_accepted_candidate"
    return(opt)
  }

  opt$par <- bfgs$par
  opt$objective <- as.numeric(obj$fn(opt$par))
  opt$convergence <- 0L
  opt$message <- paste0("BFGS finish accepted after strict nlminb: ", bfgs$message)
  opt$iterations <- NA_integer_
  opt$evaluations <- bfgs$counts
  opt$polish$status <- "bfgs_accepted"
  opt$polish$function_evaluations <- unname(bfgs$counts[[1L]])
  opt$polish$gradient_evaluations <- unname(bfgs$counts[[2L]])
  opt
}

.cmr_shared_mode_diagnostics_not_applicable <- function() {
  list(
    gradient_norm = NA_real_,
    hessian_dimension = 0L,
    hessian_min_eigenvalue = NA_real_,
    hessian_positive_definite = NA,
    status = "not_applicable",
    message = NA_character_
  )
}

.cmr_polish_integrated_opt <- function(obj, opt, trigger = 1e-4,
                                       tolerance = 1e-6, max_steps = 2L) {
  opt$polish <- list(status = "not_needed", steps = 0L,
                     initial_gradient = NA_real_, final_gradient = NA_real_)
  if (!isTRUE(opt$convergence == 0L)) {
    opt$polish$status <- "optimizer_failed"
    return(opt)
  }
  if (!length(opt$par) || length(opt$par) > 64L) return(opt)
  g <- tryCatch(as.numeric(obj$gr(opt$par)), error = function(e) NULL)
  if (length(g) != length(opt$par) || any(!is.finite(g))) {
    opt$polish$status <- "gradient_unavailable"
    return(opt)
  }
  norm <- max(abs(g))
  opt$polish$initial_gradient <- opt$polish$final_gradient <- norm
  if (norm <= trigger) return(opt)
  for (k in seq_len(max_steps)) {
    H <- tryCatch(obj$he(opt$par), error = function(e) NULL)
    if (is.null(H) || !identical(dim(H), c(length(g), length(g))) ||
        any(!is.finite(H))) {
      opt$polish$status <- "hessian_unavailable"
      break
    }
    H <- (H + t(H)) / 2
    if (inherits(try(chol(H), silent = TRUE), "try-error")) {
      opt$polish$status <- "nonpositive_curvature"
      break
    }
    step <- tryCatch(as.numeric(solve(H, g)), error = function(e) NULL)
    if (is.null(step) || any(!is.finite(step))) {
      opt$polish$status <- "solve_unavailable"
      break
    }
    base <- tryCatch(obj$fn(opt$par), error = function(e) NA_real_)
    if (length(base) != 1L || !is.finite(base)) {
      opt$polish$status <- "objective_unavailable"
      break
    }
    accepted <- FALSE
    for (alpha in 2^-(0:12)) {
      candidate <- opt$par - alpha * step
      value <- tryCatch(obj$fn(candidate), error = function(e) NA_real_)
      candidate_g <- tryCatch(as.numeric(obj$gr(candidate)), error = function(e) NULL)
      if (length(value) == 1L && length(candidate_g) == length(g) && is.finite(value) && value <= base && all(is.finite(candidate_g)) &&
          max(abs(candidate_g)) < norm) {
        opt$par <- candidate
        opt$objective <- value
        g <- candidate_g
        norm <- max(abs(g))
        opt$polish$steps <- as.integer(k)
        opt$polish$final_gradient <- norm
        accepted <- TRUE
        break
      }
    }
    if (!accepted) {
      opt$polish$status <- "no_improving_step"
      break
    }
    opt$polish$status <- "step_limit"
    if (norm <= tolerance) {
      opt$polish$status <- "small_gradient"
      break
    }
  }
  opt
}

.cmr_shared_mode_diagnostics <- function(data, parameters, random_parameters,
                                         gradient_tolerance = 1e-4,
                                         curvature_tolerance = 1e-10,
                                         max_hessian_dimension = 256L) {
  random_parameters <- intersect(random_parameters, names(parameters))
  random_dimension <- sum(vapply(parameters[random_parameters], length, integer(1)))
  result <- list(
    gradient_norm = NA_real_,
    hessian_dimension = as.integer(random_dimension),
    hessian_min_eigenvalue = NA_real_,
    hessian_positive_definite = NA,
    status = "unavailable",
    message = NA_character_
  )
  if (!length(random_parameters) || random_dimension < 1L) {
    result$message <- "No active shared random parameters were available for inner-mode diagnostics."
    return(result)
  }

  # Fix every outer parameter at the selected Laplace evaluation and leave only
  # the standardized random mode free. This uses the public no-random TMB
  # objective so its gradient and Hessian describe the joint conditional CJS
  # objective without depending on MakeADFun's private inner optimizer state.
  fixed_parameters <- setdiff(names(parameters), random_parameters)
  map <- lapply(parameters[fixed_parameters], function(x) {
    if (length(x)) factor(rep(NA_integer_, length(x))) else NULL
  })
  map <- map[lengths(map) > 0L]
  diagnostic <- tryCatch(
    TMB::MakeADFun(
      data = data,
      parameters = parameters,
      map = map,
      random = NULL,
      DLL = "drmTMB",
      silent = TRUE
    ),
    error = identity
  )
  if (inherits(diagnostic, "error")) {
    result$message <- conditionMessage(diagnostic)
    return(result)
  }
  gradient <- tryCatch(diagnostic$gr(diagnostic$par), error = identity)
  if (inherits(gradient, "error") || !length(gradient) || any(!is.finite(gradient))) {
    result$status <- "unavailable"
    result$message <- if (inherits(gradient, "error")) conditionMessage(gradient) else
      "The fixed-outer inner-mode gradient was empty or non-finite."
    return(result)
  }
  result$gradient_norm <- max(abs(gradient))
  if (random_dimension > max_hessian_dimension) {
    result$status <- "unavailable_dense_size_guard"
    result$message <- paste0(
      "Inner-mode gradient was retained, but the dense random-effect Hessian was skipped: ",
      random_dimension, " exceeds the diagnostic limit of ", max_hessian_dimension, "."
    )
    return(result)
  }
  hessian <- tryCatch(diagnostic$he(diagnostic$par), error = identity)
  if (inherits(hessian, "error") || !is.matrix(hessian) ||
      any(!is.finite(hessian))) {
    result$message <- if (inherits(hessian, "error")) conditionMessage(hessian) else
      "The fixed-outer inner-mode Hessian was not a finite matrix."
    return(result)
  }
  if (!identical(dim(hessian), c(random_dimension, random_dimension))) {
    result$message <- "The fixed-outer inner-mode Hessian dimension did not match the active random mode."
    return(result)
  }
  eigenvalues <- tryCatch(
    eigen((hessian + t(hessian)) / 2, symmetric = TRUE, only.values = TRUE)$values,
    error = identity
  )
  if (inherits(eigenvalues, "error") || !length(eigenvalues) ||
      any(!is.finite(eigenvalues))) {
    result$message <- if (inherits(eigenvalues, "error")) conditionMessage(eigenvalues) else
      "The symmetrized inner-mode Hessian eigenvalues were empty or non-finite."
    return(result)
  }
  result$hessian_min_eigenvalue <- min(eigenvalues)
  curvature_scale <- max(abs(eigenvalues))
  result$hessian_positive_definite <- is.finite(curvature_scale) &&
    curvature_scale > 0 && result$hessian_min_eigenvalue >
      curvature_tolerance * curvature_scale
  gradient_ok <- is.finite(result$gradient_norm) &&
    result$gradient_norm <= gradient_tolerance
  if (gradient_ok && isTRUE(result$hessian_positive_definite)) {
    result$status <- "stationary_positive_curvature"
    result$message <- NA_character_
  } else if (!gradient_ok) {
    result$status <- "nonstationary"
    result$message <- paste0(
      "Inner-mode gradient norm ", signif(result$gradient_norm, 5),
      " exceeds tolerance ", signif(gradient_tolerance, 5), "."
    )
  } else {
    result$status <- "nonpositive_curvature"
    result$message <- paste0(
      "Inner-mode minimum Hessian eigenvalue ",
      signif(result$hessian_min_eigenvalue, 5),
      " does not exceed the scale-relative positive-definiteness tolerance."
    )
  }
  result
}

.cmr_sd_summary <- function(X, beta, offset, ids) {
  stats::setNames(as.numeric(exp(X %*% beta + offset)), ids)
}

.cmr_split_random_intercept <- function(formula, process) {
  found <- list()
  has_bar <- function(x) is.call(x) && (identical(x[[1L]], as.name("|")) ||
    identical(x[[1L]], as.name("||")) || any(vapply(as.list(x)[-1L], has_bar, logical(1))))
  strip <- function(x) {
    if (is.call(x) && identical(x[[1L]], as.name("(")) && length(x) == 2L)
      return(strip(x[[2L]]))
    if (is.call(x) && identical(x[[1L]], as.name("+"))) {
      left <- strip(x[[2L]]); right <- strip(x[[3L]])
      if (is.null(left)) return(right)
      if (is.null(right)) return(left)
      return(call("+", left, right))
    }
    if (has_bar(x)) {
      if (!is.call(x) || !identical(x[[1L]], as.name("|")) ||
          length(x) != 3L || !identical(x[[2L]], 1) || !is.name(x[[3L]]))
        stop("`", process, "` supports only one additive `(1 | group)` random intercept.", call. = FALSE)
      found[[length(found) + 1L]] <<- as.character(x[[3L]])
      return(NULL)
    }
    x
  }
  rhs <- strip(formula[[2L]])
  if (length(found) > 1L)
    stop("`", process, "` supports at most one random intercept term.", call. = FALSE)
  fixed <- if (is.null(rhs)) stats::as.formula("~ 1", env = environment(formula)) else
    stats::as.formula(call("~", rhs), env = environment(formula))
  list(fixed = fixed, group = if (length(found)) found[[1L]] else NULL)
}

.cmr_random_design <- function(group, frame, active, history, occasion,
                               n, nt, process) {
  if (is.null(group)) return(NULL)
  if (!group %in% names(frame))
    stop("`", process, "` random-effect grouping variable `", group,
         "` is absent from its keyed predictor table.", call. = FALSE)
  values <- frame[[group]]
  if (anyNA(values[active]))
    stop("`", process, "` random-effect grouping values must be present on every contributing row.", call. = FALSE)
  labels <- as.character(values[active])
  if (any(!nzchar(labels)))
    stop("`", process, "` random-effect grouping values must not be empty.", call. = FALSE)
  levels <- if (is.factor(values)) levels(droplevels(values[active])) else unique(labels)
  levels <- levels[levels %in% labels]
  if (!length(levels)) stop("`", process, "` random effect has no contributing levels.", call. = FALSE)
  idx <- match(as.character(values), levels)
  process_rows <- if (process == "phi") max(nt - 1L, 0L) else nt
  within_history <- if (process == "phi") pmax(occasion - 1L, 0L) else occasion - 1L
  row_index <- (history - 1L) * process_rows + within_history + 1L
  nrow_z <- n * process_rows
  Z <- matrix(0, nrow_z, length(levels), dimnames = list(NULL, levels))
  rows <- which(active & !is.na(idx))
  if (length(rows)) Z[cbind(row_index[rows], idx[rows])] <- 1
  # A site intercept must be shared by every contributing row in each history.
  by_history <- split(as.character(values[active]), history[active])
  site <- all(vapply(by_history, function(x) length(unique(x)) == 1L, logical(1)))
  histories_per_level <- vapply(levels, function(level) {
    length(unique(history[active & as.character(values) == level]))
  }, integer(1))
  individual <- site && length(histories_per_level) > 0L &&
    all(histories_per_level == 1L)
  list(Z = Z, levels = levels, group = group, process = process,
       active = active, row_index = row_index, values = as.character(values), site = site,
       by_history = by_history,
       n_levels = length(levels), histories_per_level = histories_per_level,
       replicated_across_histories = any(histories_per_level > 1L),
       individual = individual)
}

.cmr_random_terminal <- function(random, terminal) {
  if (is.null(random)) return(NULL)
  if (length(terminal) != length(random$row_index))
    stop("internal CJS terminal-constraint rows do not match the random-effect design.", call. = FALSE)
  rows <- random$row_index[terminal]
  if (length(rows)) random$Z[rows, ] <- 0
  random
}

.cmr_julia_fit_fixed <- function(data, phi_design, p_design, phi_active, p_active,
                                 terminal_constraint, control) {
  if (!requireNamespace("JuliaCall", quietly = TRUE))
    stop("`engine = \"julia\"` requires the JuliaCall package.", call. = FALSE)
  drm_julia_setup()
  JuliaCall::julia_command(paste(
    "drmTMB_cjs_bridge(Y, observed, first, ends, intervals, frequency, Xphi, ophi, Xp, op, tname, tvalue, maxiters, gtol) =",
    "drmTMB_backend.cjs_matrix_bridge(Y, observed, first, ends, intervals, frequency, Xphi, ophi, Xp, op, tname, tvalue, maxiters, gtol); nothing"
  ))
  n <- nrow(data$y); nt <- ncol(data$y)
  phi_rows <- unlist(lapply(seq_len(n), function(i) if (data$first[i] < data$end[i])
    (i - 1L) * (nt - 1L) + seq.int(data$first[i], data$end[i] - 1L) else integer()), use.names = FALSE)
  p_rows <- unlist(lapply(seq_len(n), function(i) if (data$first[i] < data$end[i])
    (i - 1L) * nt + seq.int(data$first[i] + 1L, data$end[i]) else integer()), use.names = FALSE)
  term_name <- if (is.null(terminal_constraint)) "" else names(terminal_constraint)
  term_value <- if (is.null(terminal_constraint)) 0 else unname(terminal_constraint[[1L]])
  result <- JuliaCall::julia_call(
    "drmTMB_cjs_bridge", data$y, data$observed, as.integer(data$first),
    as.integer(data$end), as.numeric(data$delta[1L, ]),
    as.integer(data$frequency), phi_design$X[phi_rows, , drop = FALSE],
    phi_design$offset[phi_rows], p_design$X[p_rows, , drop = FALSE],
    p_design$offset[p_rows], term_name, as.numeric(term_value),
    as.integer(if (is.null(control$iter.max)) 1000L else control$iter.max), as.numeric(if (is.null(control$rel.tol)) 1e-8 else control$rel.tol)
  )
  beta <- as.numeric(result$beta)
  n_phi <- ncol(phi_design$X)
  list(beta = beta, beta_phi = beta[seq_len(n_phi)],
       beta_p = beta[n_phi + seq_len(ncol(p_design$X))],
       loglik = as.numeric(result$loglik), objective = as.numeric(result$objective),
       gradient = as.numeric(result$gradient), hessian = as.matrix(result$hessian),
       converged = isTRUE(result$converged), iterations = as.integer(result$iterations))
}

.cmr_cjs_random_route <- function(phi, p, n) {
  if (is.null(phi) && is.null(p)) return("fixed")
  effects <- Filter(Negate(is.null), list(phi, p))
  if (all(vapply(effects, `[[`, logical(1), "individual")))
    return(if (length(effects) == 2L) "individual_pair" else
      if (!is.null(phi)) "individual_phi" else "individual_p")
  if (any(vapply(effects, `[[`, logical(1), "individual")))
    stop("mixing individual and shared CJS random effects across processes is not supported.", call. = FALSE)
  if (all(vapply(effects, `[[`, logical(1), "site"))) {
    if (any(!vapply(effects, `[[`, logical(1), "replicated_across_histories")))
      stop("shared CJS intercept levels must be used by more than one history; individual random effects are not in this route.", call. = FALSE)
    if (length(effects) == 2L) {
      if (!identical(phi$levels, p$levels) ||
          !identical(phi$group, p$group))
        stop("independent site effects on both processes must use the same site grouping variable and levels.", call. = FALSE)
      for (history in intersect(names(phi$by_history), names(p$by_history))) {
        if (!identical(unique(phi$by_history[[history]]),
                       unique(p$by_history[[history]])))
          stop("survival and detection shared site labels disagree for history ",
               history, call. = FALSE)
      }
      return("site_pair")
    }
    return(if (!is.null(phi)) "site_phi" else "site_p")
  }
  if (any(vapply(effects, `[[`, logical(1), "site")))
    stop("mixing site and year grouping structures across processes is not supported.", call. = FALSE)
  if (any(vapply(effects, function(x) x$n_levels < 2L, logical(1))))
    stop("year-vector random effects require at least two contributing levels.", call. = FALSE)
  for (effect in effects) {
    counts <- table(effect$values[effect$active])
    if (!effect$replicated_across_histories || !any(counts >= 2L))
      stop("year-vector random effects require levels repeated across histories and contributing rows.", call. = FALSE)
  }
  # Independent processes may have different active years after masks or a
  # process-specific terminal constraint; their latent vectors remain separate.
  if (length(effects) == 2L && !identical(phi$group, p$group))
    stop("year-vector effects on both processes must use the same grouping variable.", call. = FALSE)
  "year_vector"
}

.cmr_gauss_hermite <- function(order) {
  if (length(order) != 1L || is.na(order) || order < 1L || order != as.integer(order))
    stop("`order` must be a positive integer.", call. = FALSE)
  order <- as.integer(order)
  jacobi <- matrix(0, order, order)
  if (order > 1L) {
    upper <- sqrt(seq_len(order - 1L))
    jacobi[cbind(seq_len(order - 1L), 2:order)] <- upper
    jacobi <- jacobi + t(jacobi)
  }
  decomposition <- eigen(jacobi, symmetric = TRUE)
  permutation <- base::order(decomposition$values)
  list(nodes = decomposition$values[permutation],
       weights = decomposition$vectors[1L, permutation]^2)
}

.cmr_join_predictors <- function(data, predictors, rows, process) {
  keys <- if (process == "p") c("id", "occasion") else c("id", "interval_start", "interval_end")
  keydata <- data.frame(id = data$id[rows$i], occasion = data$occasions[rows$t])
  if (process == "phi") {
    keydata$interval_start <- data$occasions[rows$t]
    keydata$interval_end <- data$occasions[rows$t + 1L]
  }
  if (is.null(predictors)) return(keydata)
  if (!is.data.frame(predictors) || !all(keys %in% names(predictors)))
    stop("`", process, "_data` must be a data frame keyed by ", paste(keys, collapse = ", "), ".", call. = FALSE)
  if (anyNA(predictors[keys]))
    stop("`", process, "_data` keys must be non-missing.", call. = FALSE)
  if (anyDuplicated(predictors[keys])) stop("`", process, "_data` has duplicate keys.", call. = FALSE)
  known <- keydata[keys]
  known$.cmr_known <- TRUE
  checked <- merge(predictors[keys], known, by = keys, all.x = TRUE, sort = FALSE)
  if (anyNA(checked$.cmr_known))
    stop("`", process, "_data` contains unknown keys outside the declared histories and occasions.", call. = FALSE)
  keydata$.cmr_row <- seq_len(nrow(keydata))
  if (".cmr_row" %in% names(predictors))
    stop("predictor tables may not use the reserved name `.cmr_row`.", call. = FALSE)
  joined <- merge(keydata, predictors, by = keys, all.x = TRUE, sort = FALSE)
  joined <- joined[order(joined$.cmr_row), , drop = FALSE]
  if (nrow(joined) != nrow(keydata))
    stop("`", process, "_data` has duplicated or malformed keyed rows.", call. = FALSE)
  joined$.cmr_row <- NULL
  joined
}

.cmr_sd_design <- function(formula, frame, n, process, ids, active) {
  if (is.null(formula)) return(list(X = matrix(1, n, 1L), columns = "(Intercept)", offset = rep(0, n)))
  if (!is.logical(active) || length(active) != nrow(frame) || anyNA(active))
    stop("`sd_", process, "` active-row mask must match its process table.", call. = FALSE)
  variables <- all.vars(formula)
  row_id <- match(frame$id, ids)
  if (anyNA(row_id)) stop("`sd_", process, "` predictor table contains an unknown individual.", call. = FALSE)
  unit <- data.frame(.cmr_i = seq_len(n))
  for (v in variables) {
    if (!v %in% names(frame)) stop("`sd_", process, "` predictor `", v, "` is absent from its process table.", call. = FALSE)
    values <- vector("list", n)
    fallback <- frame[[v]][!is.na(frame[[v]])]
    if (!length(fallback))
      stop("`sd_", process, "` predictor `", v, "` has no observed values.", call. = FALSE)
    for (i in seq_len(n)) {
      rows <- row_id == i
      x <- frame[[v]][rows & active]
      if (!length(x)) {
        # A history with no active process rows contributes an integral of one;
        # its SD predictor is irrelevant, so use a deterministic observed value.
        values[[i]] <- fallback[[1L]]
        next
      }
      if (anyNA(x) || length(unique(x)) != 1L)
        stop("`sd_", process, "` predictor `", v, "` must be complete and constant within each individual.", call. = FALSE)
      values[[i]] <- x[[1L]]
    }
    unit[[v]] <- if (is.factor(frame[[v]])) factor(unlist(values), levels = levels(frame[[v]])) else unlist(values)
  }
  mf <- stats::model.frame(formula, data = unit, na.action = stats::na.fail,
                           drop.unused.levels = TRUE)
  X <- stats::model.matrix(formula, mf)
  off <- stats::model.offset(mf)
  if (is.null(off)) off <- rep(0, n)
  if (any(!is.finite(X)) || any(!is.finite(off)))
    stop("`sd_", process, "` design and offsets must be finite.", call. = FALSE)
  list(X = X, columns = colnames(X), offset = as.numeric(off), terms = stats::terms(formula),
       contrasts = attr(X, "contrasts"), xlevels = stats::.getXlevels(stats::terms(formula), mf))
}

.cmr_design <- function(formula, frame, process, active, contrasts = NULL) {
  tr <- stats::terms(formula)
  mf <- stats::model.frame(tr, data = frame[active, , drop = FALSE],
                           na.action = stats::na.fail, drop.unused.levels = TRUE)
  xa <- stats::model.matrix(tr, mf, contrasts.arg = contrasts)
  off <- stats::model.offset(mf); if (is.null(off)) off <- rep(0, nrow(xa))
  if (any(!is.finite(xa)) || any(!is.finite(off)))
    stop("`", process, "` design and offsets must contain finite values.", call. = FALSE)
  X <- matrix(0, nrow(frame), ncol(xa), dimnames = list(NULL, colnames(xa)))
  X[active, ] <- xa
  full_offset <- rep(0, nrow(frame)); full_offset[active] <- off
  list(X = X, offset = as.numeric(full_offset), columns = colnames(X), terms = tr,
       contrasts = attr(xa, "contrasts"), xlevels = stats::.getXlevels(tr, mf),
       process = process)
}

.cmr_terminal_rank <- function(design, terminal, active, random = NULL) {
  X <- design$X[active, , drop = FALSE]
  if (!is.null(random)) X <- cbind(X, random$Z[active, , drop = FALSE])
  terminal <- terminal[active]
  if (!nrow(X) || !length(terminal) || !any(terminal)) return(FALSE)
  qr(cbind(X, as.numeric(terminal)))$rank == qr(X)$rank
}

.cmr_or_null <- function(x) if (is.null(x) || !length(x)) NULL else x

.cmr_fixed_terminal <- function(design, terminal, process, fixed) {
  if (!nrow(design$X)) return(design)
  if (is.null(fixed)) return(design)
  if (length(fixed) != 1L || !is.numeric(fixed) || !is.finite(fixed) || fixed <= 0 || fixed >= 1)
    stop("terminal `", process, "` constraint must be one finite probability strictly between zero and one.", call. = FALSE)
  if (!is.null(fixed)) {
    design$X[terminal, ] <- 0
    design$offset[terminal] <- stats::qlogis(fixed)
    if (ncol(design$X)) {
      keep <- qr(design$X)$pivot[seq_len(qr(design$X)$rank)]
      design$X <- design$X[, keep, drop = FALSE]
      design$columns <- design$columns[keep]
    }
  }
  design
}

.cmr_fd_gradient <- function(fn, par) {
  vapply(seq_along(par), function(i) {
    h <- .Machine$double.eps^(1/3) * max(1, abs(par[[i]]))
    d1 <- (fn(replace(par, i, par[[i]] + h)) - fn(replace(par, i, par[[i]] - h))) / (2 * h)
    h <- h / 2
    d2 <- (fn(replace(par, i, par[[i]] + h)) - fn(replace(par, i, par[[i]] - h))) / (2 * h)
    if (!is.finite(d1) || !is.finite(d2) || abs(d1 - d2) > 1e-5 * max(1, abs(d2)))
      warning("finite-difference gradient did not stabilize across step halving for parameter ", i, call. = FALSE)
    d2
  }, numeric(1))
}
