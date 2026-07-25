drm_pair_full_refit_bootstrap <- function(
    data, binary_response, nbinom2_response, binary_formula, nbinom2_formula,
    association = ~1, binary_control = list(), nbinom2_control = list(),
    attempts = 399L, minimum_resolved = 380L, seed = NULL) {
  if (!is.data.frame(data) || !all(c(binary_response, nbinom2_response) %in% names(data))) {
    cli::cli_abort("The full-refit bootstrap needs a data frame with named Bernoulli and NB2 responses.")
  }
  if (length(binary_response) != 1L || length(nbinom2_response) != 1L ||
      !is.character(binary_response) || !is.character(nbinom2_response)) {
    cli::cli_abort("Bootstrap response names must be single strings.")
  }
  if (!is.numeric(attempts) || length(attempts) != 1L || attempts < 1L || attempts != as.integer(attempts)) {
    cli::cli_abort("Bootstrap attempts must be one positive integer.")
  }
  if (!is.numeric(minimum_resolved) || length(minimum_resolved) != 1L ||
      minimum_resolved < 1L || minimum_resolved > attempts) {
    cli::cli_abort("The minimum resolved count must be between one and the attempted count.")
  }
  if (!is.null(seed)) set.seed(seed)
  outer_binary <- tryCatch(
    drmTMB(formula = binary_formula, family = binomial(), data = data,
      control = binary_control),
    error = identity
  )
  outer_nbinom2 <- tryCatch(
    drmTMB(formula = nbinom2_formula, family = nbinom2(), data = data,
      control = nbinom2_control),
    error = identity
  )
  if (inherits(outer_binary, "error") || inherits(outer_nbinom2, "error")) {
    return(list(
      outer_status = "margin_error",
      outer_message = paste(
        if (inherits(outer_binary, "error")) conditionMessage(outer_binary) else NULL,
        if (inherits(outer_nbinom2, "error")) conditionMessage(outer_nbinom2) else NULL,
        collapse = " | "
      ),
      attempts = data.frame(), diagnostics = list()
    ))
  }
  outer <- tryCatch(
    associate_pairs(outer_binary, outer_nbinom2,
      kernel = latent_normal(), association = association),
    error = identity
  )
  if (inherits(outer, "error") || identical(outer$status, "boundary_unresolved")) {
    return(list(
      outer_status = if (inherits(outer, "error")) "association_error" else "boundary_unresolved",
      outer_message = if (inherits(outer, "error")) conditionMessage(outer) else "Outer association is unresolved.",
      outer = if (inherits(outer, "error")) NULL else outer,
      attempts = data.frame(), diagnostics = list()
    ))
  }
  components <- outer$components
  attempt_seeds <- sample.int(.Machine$integer.max, as.integer(attempts))
  raw <- lapply(seq_len(attempts), function(index) {
    set.seed(attempt_seeds[[index]])
    draw <- tryCatch(
      drm_pair_simulate_bernoulli_nbinom2(
        binary_p = components$binary_p,
        nbinom2_mu = components$nbinom2_mu,
        nbinom2_sigma = components$nbinom2_sigma,
        eta = outer$eta_internal
      ),
      error = identity
    )
    out <- list(
      bootstrap_index = index,
      seed = attempt_seeds[[index]],
      simulation_status = if (inherits(draw, "error")) "error" else "ok",
      binary_margin_status = NA_character_,
      nbinom2_margin_status = NA_character_,
      association_status = NA_character_,
      resolved = FALSE,
      message = if (inherits(draw, "error")) conditionMessage(draw) else NA_character_,
      coefficients = NULL,
      diagnostics = list(simulation = if (inherits(draw, "error")) {
        list(message = conditionMessage(draw))
      } else {
        list(message = NA_character_)
      })
    )
    if (inherits(draw, "error")) return(out)
    bootstrap_data <- data
    bootstrap_data[[binary_response]] <- draw$bernoulli
    bootstrap_data[[nbinom2_response]] <- draw$nbinom2
    binary_fit <- tryCatch(
      drmTMB(formula = binary_formula, family = binomial(), data = bootstrap_data,
        control = binary_control),
      error = identity
    )
    nbinom2_fit <- tryCatch(
      drmTMB(formula = nbinom2_formula, family = nbinom2(), data = bootstrap_data,
        control = nbinom2_control),
      error = identity
    )
    out$binary_margin_status <- if (inherits(binary_fit, "error")) "error" else "ok"
    out$nbinom2_margin_status <- if (inherits(nbinom2_fit, "error")) "error" else "ok"
    out$diagnostics$binary_margin <- drm_pair_margin_refit_diagnostics(binary_fit)
    out$diagnostics$nbinom2_margin <- drm_pair_margin_refit_diagnostics(nbinom2_fit)
    if (inherits(binary_fit, "error") || inherits(nbinom2_fit, "error")) {
      out$message <- paste(
        if (inherits(binary_fit, "error")) conditionMessage(binary_fit) else NULL,
        if (inherits(nbinom2_fit, "error")) conditionMessage(nbinom2_fit) else NULL,
        collapse = " | "
      )
      return(out)
    }
    association_fit <- tryCatch(
      associate_pairs(binary_fit, nbinom2_fit,
        kernel = latent_normal(), association = association),
      error = identity
    )
    if (inherits(association_fit, "error")) {
      out$association_status <- "error"
      out$message <- conditionMessage(association_fit)
      return(out)
    }
    out$association_status <- association_fit$status
    out$resolved <- association_fit$status %in% c("interior", "near_boundary")
    out$coefficients <- association_fit$association_coefficients
    out$diagnostics$association <- association_fit$diagnostics
    out
  })
  coefficient_names <- names(outer$association_coefficients)
  attempt_table <- do.call(rbind, lapply(raw, function(x) {
    coefficients <- setNames(rep(NA_real_, length(coefficient_names)), coefficient_names)
    if (!is.null(x$coefficients)) coefficients[names(x$coefficients)] <- x$coefficients
    row <- data.frame(
      bootstrap_index = x$bootstrap_index, seed = x$seed,
      simulation_status = x$simulation_status,
      binary_margin_status = x$binary_margin_status,
      nbinom2_margin_status = x$nbinom2_margin_status,
      association_status = x$association_status,
      resolved = x$resolved, message = x$message,
      stringsAsFactors = FALSE
    )
    cbind(row, as.data.frame(as.list(coefficients), check.names = FALSE))
  }))
  names(attempt_table)[(ncol(attempt_table) - length(coefficient_names) + 1L):ncol(attempt_table)] <-
    paste0("alpha_", make.names(coefficient_names))
  list(
    outer_status = outer$status,
    outer_message = NA_character_,
    outer = outer,
    attempts = attempt_table,
    diagnostics = lapply(raw, `[[`, "diagnostics"),
    minimum_resolved = as.integer(minimum_resolved),
    interval_available = sum(attempt_table$resolved) >= minimum_resolved
  )
}

drm_pair_margin_refit_diagnostics <- function(fit) {
  if (inherits(fit, "error")) {
    return(list(
      status = "error",
      convergence = NA_integer_,
      pd_hess = NA,
      objective = NA_real_,
      message = conditionMessage(fit)
    ))
  }
  list(
    status = "ok",
    convergence = fit$opt$convergence,
    pd_hess = isTRUE(fit$sdr$pdHess),
    objective = fit$opt$objective,
    message = fit$opt$message
  )
}

drm_pair_staged_eta_coverage_summary <- function(
    outer_attempts, truth, minimum_resolved = 380L) {
  required <- c("interval_available", "resolved_bootstrap", "bootstrap_attempts")
  if (!is.data.frame(outer_attempts) || !all(required %in% names(outer_attempts))) {
    cli::cli_abort("Outer attempts must record availability and resolved/attempted bootstrap counts.")
  }
  if (!is.numeric(truth) || is.null(names(truth))) {
    cli::cli_abort("Truth must be a named numeric vector of reported targets.")
  }
  n_outer <- nrow(outer_attempts)
  availability <- outer_attempts$interval_available &
    outer_attempts$resolved_bootstrap >= minimum_resolved &
    outer_attempts$bootstrap_attempts >= minimum_resolved
  summaries <- lapply(names(truth), function(target) {
    lower <- paste0(target, "_lower")
    upper <- paste0(target, "_upper")
    estimate <- paste0(target, "_estimate")
    if (!all(c(lower, upper, estimate) %in% names(outer_attempts))) {
      cli::cli_abort("Outer attempts do not contain all interval columns for {.val {target}}.")
    }
    finite_interval <- availability & is.finite(outer_attempts[[lower]]) &
      is.finite(outer_attempts[[upper]])
    covered <- finite_interval & outer_attempts[[lower]] <= truth[[target]] &
      truth[[target]] <= outer_attempts[[upper]]
    conditional_denominator <- sum(finite_interval)
    conditional_numerator <- sum(covered[finite_interval])
    data.frame(
      target = target,
      truth = truth[[target]], n_outer = n_outer,
      n_available = sum(finite_interval),
      availability = if (n_outer) sum(finite_interval) / n_outer else NA_real_,
      coverage_all_attempt = if (n_outer) sum(covered) / n_outer else NA_real_,
      coverage_conditional = if (conditional_denominator) {
        conditional_numerator / conditional_denominator
      } else NA_real_,
      bias = mean(outer_attempts[[estimate]] - truth[[target]], na.rm = TRUE),
      rmse = sqrt(mean((outer_attempts[[estimate]] - truth[[target]])^2, na.rm = TRUE)),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, summaries)
}
