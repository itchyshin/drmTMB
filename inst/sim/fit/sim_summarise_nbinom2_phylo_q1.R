phase18_summarise_nbinom2_phylo_q1_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character(),
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50)
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (!is.list(truth) || !identical(truth$surface, "nbinom2_phylo_q1")) {
    stop(
      "`truth` must be an NB2 phylogenetic q1 truth object.",
      call. = FALSE
    )
  }

  target_fit <- phase18_nbinom2_phylo_q1_target_fit(fit)
  comparator_fit <- phase18_nbinom2_phylo_q1_comparator_fit(fit)
  mu_truth <- truth$beta_mu
  sigma_truth <- truth$beta_sigma
  sd_truth <- truth$sd
  comparator_sd_truth <- truth$comparator_sd

  mu_est <- stats::coef(target_fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- stats::coef(target_fit, dpar = "sigma")[names(sigma_truth)]
  sd_est <- target_fit$sdpars$mu[names(sd_truth)]
  comparator_sd_est <- if (is.null(comparator_fit)) {
    stats::setNames(
      rep(NA_real_, length(comparator_sd_truth)),
      names(comparator_sd_truth)
    )
  } else {
    comparator_fit$sdpars$mu[names(comparator_sd_truth)]
  }

  estimate <- c(mu_est, sigma_est, sd_est, comparator_sd_est)
  truth_value <- c(mu_truth, sigma_truth, sd_truth, comparator_sd_truth)
  parameter <- c(
    paste0("mu:", names(mu_est)),
    paste0("sigma:", names(sigma_est)),
    paste0("sd:mu:", names(sd_est)),
    paste0("comparator:sd:mu:", names(comparator_sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  parameter_class <- c(
    rep("fixed_mu", length(mu_est)),
    rep("fixed_sigma", length(sigma_est)),
    rep("phylo_sd", length(sd_est)),
    rep("grouped_comparator_sd", length(comparator_sd_est))
  )
  target_row <- parameter_class != "grouped_comparator_sd"
  converged <- rep(isTRUE(target_fit$opt$convergence == 0), length(parameter))
  pdHess <- rep(isTRUE(target_fit$sdr$pdHess), length(parameter))
  if (!is.null(comparator_fit)) {
    comparator_row <- parameter_class == "grouped_comparator_sd"
    converged[comparator_row] <- isTRUE(comparator_fit$opt$convergence == 0)
    pdHess[comparator_row] <- isTRUE(comparator_fit$sdr$pdHess)
  }

  out <- data.frame(
    surface = "nbinom2_phylo_q1",
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = parameter_class,
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(
      phase18_nbinom2_phylo_q1_std_error(target_fit, parameter, target_row)
    ),
    error = unname(estimate - truth_value),
    converged = converged,
    pdHess = pdHess,
    nobs = stats::nobs(target_fit),
    n_species = truth$n_species,
    n_per_species = truth$n_per_species,
    mean_count = truth$mean_count,
    sigma_baseline = truth$sigma_baseline,
    tree_shape = truth$tree_shape,
    comparator = ifelse(target_row, "phylo_q1", "ordinary_grouped"),
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
  profile_map <- phase18_nbinom2_phylo_q1_profile_parameter_map(
    parameters = profile_parameters
  )
  out <- phase18_profile_interval_columns(
    out,
    fit = target_fit,
    parameters = profile_map,
    conf.level = profile_level,
    interval_scale = "public_sd",
    profile_args = profile_args
  )
  phase18_nbinom2_phylo_q1_attach_status(out, target_fit)
}

phase18_nbinom2_phylo_q1_target_fit <- function(fit) {
  if (inherits(fit, "drmTMB")) {
    return(fit)
  }
  if (is.list(fit) && inherits(fit$target, "drmTMB")) {
    return(fit$target)
  }
  stop(
    "`fit` must be a drmTMB fit or an NB2 phylogenetic q1 fit bundle.",
    call. = FALSE
  )
}

phase18_nbinom2_phylo_q1_comparator_fit <- function(fit) {
  if (is.list(fit) && inherits(fit$grouped_comparator, "drmTMB")) {
    return(fit$grouped_comparator)
  }
  NULL
}

phase18_nbinom2_phylo_q1_profile_parameter_map <- function(
  parameters = character()
) {
  if (!is.character(parameters) || any(!nzchar(parameters))) {
    stop("`parameters` must be a character vector.", call. = FALSE)
  }
  if (length(parameters) == 0L) {
    return(character())
  }

  public_target <- "sd:mu:phylo(1 | species)"
  aliases <- stats::setNames(
    c(public_target, public_target),
    c(public_target, "log_sd_phylo")
  )
  requested <- aliases[intersect(parameters, names(aliases))]
  targets <- unique(unname(requested))
  stats::setNames(targets, targets)
}

phase18_nbinom2_phylo_q1_attach_status <- function(summary, fit) {
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

phase18_nbinom2_phylo_q1_std_error <- function(fit, parameter, target_row) {
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
  matched <- match(parameter[target_row], row.names(coefficients))
  ok <- !is.na(matched)
  target_index <- which(target_row)
  out[target_index[ok]] <- coefficients$std_error[matched[ok]]
  out
}
