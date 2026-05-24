phase18_summarise_poisson_phylo_q1_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character()
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (!is.list(truth) || !identical(truth$surface, "poisson_phylo_q1")) {
    stop(
      "`truth` must be a Poisson phylogenetic q1 truth object.",
      call. = FALSE
    )
  }

  mu_truth <- truth$beta_mu
  sd_truth <- truth$sd

  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sd_est <- fit$sdpars$mu[names(sd_truth)]

  estimate <- c(mu_est, sd_est)
  truth_value <- c(mu_truth, sd_truth)
  parameter <- c(
    paste0("mu:", names(mu_est)),
    paste0("sd:mu:", names(sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  out <- data.frame(
    surface = "poisson_phylo_q1",
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = c(
      rep("fixed_mu", length(mu_est)),
      rep("phylo_sd", length(sd_est))
    ),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(phase18_poisson_phylo_q1_std_error(fit, parameter)),
    error = unname(estimate - truth_value),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    n_species = truth$n_species,
    n_per_species = truth$n_per_species,
    tree_shape = truth$tree_shape,
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
  phase18_poisson_phylo_q1_attach_status(out, fit)
}

phase18_poisson_phylo_q1_attach_status <- function(summary, fit) {
  targets <- tryCatch(
    profile_targets(fit),
    error = function(e) NULL
  )
  diagnostics <- tryCatch(
    check_drm(fit),
    error = function(e) NULL
  )

  summary$profile_target_status <- "unavailable"
  summary$profile_target_parameter <- NA_character_
  summary$diagnostic_status <- NA_character_
  summary$diagnostic_message <- NA_character_

  if (
    is.data.frame(targets) &&
      all(c("parm", "profile_ready") %in% names(targets))
  ) {
    matched <- match(summary$parameter, targets$parm)
    ok <- !is.na(matched)
    summary$profile_target_status[ok] <- ifelse(
      targets$profile_ready[matched[ok]],
      "ready",
      "not_ready"
    )
    summary$profile_target_parameter[ok] <- targets$tmb_parameter[matched[ok]]
  }

  if (
    is.data.frame(diagnostics) &&
      all(c("check", "status", "message") %in% names(diagnostics))
  ) {
    phylo_rows <- diagnostics$check %in%
      c(
        "phylo_mu_replication",
        "phylo_mu_diagnostics"
      )
    status <- paste(diagnostics$status[phylo_rows], collapse = " | ")
    message <- paste(diagnostics$message[phylo_rows], collapse = " | ")
    summary$diagnostic_status[summary$parameter_class == "phylo_sd"] <- status
    summary$diagnostic_message[summary$parameter_class == "phylo_sd"] <- message
  }

  summary
}

phase18_poisson_phylo_q1_std_error <- function(fit, parameter) {
  out <- rep(NA_real_, length(parameter))
  names(out) <- parameter
  coefficients <- tryCatch(
    summary(fit)$coefficients,
    error = function(e) NULL
  )
  if (
    is.null(coefficients) ||
      !"std_error" %in% names(coefficients) ||
      is.null(row.names(coefficients))
  ) {
    return(out)
  }
  matched <- match(parameter, row.names(coefficients))
  ok <- !is.na(matched)
  out[ok] <- coefficients$std_error[matched[ok]]
  out
}
