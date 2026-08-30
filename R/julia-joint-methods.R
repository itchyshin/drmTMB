# R result adapter for the first formula-routed joint missing-predictor bridge.
# The transport uses explicit block metadata because predictor variable and
# model-matrix names may contain underscores; never infer a block by splitting a
# generated coefficient string.

drm_julia_joint_result_vector <- function(x, label) {
  out <- as.numeric(unlist(x, use.names = FALSE))
  if (length(out) == 0L || any(!is.finite(out))) {
    cli::cli_abort("Julia joint result {label} must be a non-empty finite numeric vector.")
  }
  out
}

drm_julia_joint_scalar_string <- function(x, label) {
  value <- as.character(unlist(x, use.names = FALSE))
  if (length(value) != 1L || is.na(value) || !nzchar(value)) {
    cli::cli_abort("Julia joint result {label} must be one non-empty string.")
  }
  value
}

drm_julia_joint_integer_ids <- function(x, label) {
  value <- unlist(x, use.names = FALSE)
  if (!is.numeric(value) || any(!is.finite(value)) ||
      any(value != floor(value)) || any(abs(value) > .Machine$integer.max)) {
    cli::cli_abort("Julia joint result {label} must contain finite integer row IDs.")
  }
  as.integer(value)
}

drm_julia_joint_mask <- function(x, label) {
  value <- unlist(x, use.names = FALSE)
  if (is.logical(value)) {
    if (anyNA(value)) {
      cli::cli_abort("Julia joint result {label} must contain only TRUE or FALSE values.")
    }
    return(value)
  }
  if (!is.numeric(value) || any(!is.finite(value)) || any(!value %in% c(0, 1))) {
    cli::cli_abort("Julia joint result {label} must contain only TRUE/FALSE or 0/1 values.")
  }
  as.logical(value)
}

drm_julia_joint_validate_raw_vcov <- function(result, raw_names) {
  p <- length(raw_names)
  raw <- result$vcov
  raw_values <- as.numeric(unlist(raw, use.names = FALSE))
  if (is.matrix(raw) && !identical(dim(raw), c(p, p))) {
    cli::cli_abort("Julia joint result covariance must have exactly p by p dimensions.")
  }
  if (length(raw_values) != p^2 || any(is.infinite(raw_values))) {
    cli::cli_abort("Julia joint result covariance must contain exactly p squared values without infinities.")
  }
  vcov_names <- as.character(unlist(result$vcov_names, use.names = FALSE))
  if (!identical(vcov_names, raw_names)) {
    cli::cli_abort("Julia joint result covariance names must exactly match coefficient names.")
  }
  V <- matrix(raw_values, nrow = p, ncol = p)
  status <- drm_julia_joint_scalar_string(result$covariance_status, "covariance_status")
  if (!status %in% c(
    "observed_information_inverse", "hessian_not_positive_definite",
    "hessian_unavailable"
  )) {
    cli::cli_abort("Julia joint result covariance_status is not recognized.")
  }
  all_missing <- all(is.na(raw_values))
  any_missing <- any(is.na(raw_values))
  if (identical(status, "observed_information_inverse")) {
    if (any_missing) {
      cli::cli_abort("Julia joint observed-information covariance must be finite.")
    }
    if (!isTRUE(all.equal(V, t(V), tolerance = 1e-12, check.attributes = FALSE)) ||
        inherits(try(chol(V), silent = TRUE), "try-error")) {
      cli::cli_abort("Julia joint observed-information covariance must be symmetric and positive definite.")
    }
  } else if (any_missing && !all_missing) {
    cli::cli_abort("Julia joint failed-covariance result must use either an all-missing covariance or a finite diagnostic covariance.")
  } else if (!all_missing && !isTRUE(all.equal(V, t(V), tolerance = 1e-12, check.attributes = FALSE))) {
    cli::cli_abort("Julia joint failed-covariance diagnostic matrix must be symmetric.")
  }
  V
}

drm_julia_joint_validate_result_rows <- function(result, payload) {
  n <- length(payload$original_row)
  original_row <- drm_julia_joint_integer_ids(result$original_row, "original_row")
  observed_y <- drm_julia_joint_mask(result$observed_y, "observed_y")
  observed_x <- drm_julia_joint_mask(result$observed_x, "observed_x")
  if (length(original_row) != n || length(observed_y) != n || length(observed_x) != n ||
      !identical(original_row, as.integer(payload$original_row)) ||
      !identical(observed_y, as.logical(payload$observed_y)) ||
      !identical(observed_x, as.logical(payload$observed_x))) {
    cli::cli_abort("Julia joint result row IDs and observation masks must exactly match the prepared payload.")
  }
  list(original_row = original_row, observed_y = observed_y, observed_x = observed_x)
}

drm_julia_joint_validate_imputation <- function(result, payload, rows) {
  table <- result$imputation
  required <- c(
    "variable", "original_row", "model_row", "observed", "estimate", "std_error",
    "source", "uncertainty_status", "se_available"
  )
  if (!is.list(table) || !setequal(names(table), required)) {
    cli::cli_abort("Julia joint result has an invalid imputation table.")
  }
  n <- length(rows$observed_x)
  if (any(vapply(table[required], length, integer(1)) != n)) {
    cli::cli_abort("Julia joint result imputation columns have inconsistent lengths.")
  }
  variable <- as.character(table$variable)
  original_row <- drm_julia_joint_integer_ids(table$original_row, "imputation original_row")
  model_row <- drm_julia_joint_integer_ids(table$model_row, "imputation model_row")
  observed <- drm_julia_joint_mask(table$observed, "imputation observed")
  estimate <- as.numeric(table$estimate)
  std_error <- as.numeric(table$std_error)
  source <- as.character(table$source)
  uncertainty_status <- as.character(table$uncertainty_status)
  available <- drm_julia_joint_mask(table$se_available, "imputation se_available")
  expected_source <- ifelse(
    rows$observed_x,
    "observed",
    if (identical(payload$predictor, "gaussian")) "conditional_mode" else "conditional_probability"
  )
  if (anyNA(variable) || !all(variable == payload$variable) ||
      !identical(original_row, rows$original_row) ||
      !identical(model_row, seq_len(n)) || !identical(observed, rows$observed_x) ||
      any(!is.finite(estimate)) || !identical(source, expected_source) ||
      anyNA(uncertainty_status) || any(!nzchar(uncertainty_status)) || anyNA(available)) {
    cli::cli_abort("Julia joint result imputation table does not match the prepared rows and masks.")
  }
  allowed_status <- c(
    "ok", "sdreport_non_pd_hessian", "sdreport_failed", "sdreport_unavailable",
    "route_conditional_se_unavailable"
  )
  if (any(!uncertainty_status %in% allowed_status)) {
    cli::cli_abort("Julia joint result imputation uncertainty status is not recognized.")
  }
  covariance_status <- drm_julia_joint_scalar_string(
    result$covariance_status, "covariance_status"
  )
  fit_failure_status <- switch(
    covariance_status,
    hessian_not_positive_definite = "sdreport_non_pd_hessian",
    hessian_unavailable = "sdreport_failed",
    NULL
  )
  if (!is.null(fit_failure_status) &&
      (any(uncertainty_status != fit_failure_status) || any(available) || any(is.finite(std_error)))) {
    cli::cli_abort("Julia joint failed-covariance imputation rows must not report available standard errors.")
  }
  observed_rows <- observed
  missing_rows <- !observed
  if (any(available[observed_rows]) || any(is.finite(std_error[observed_rows]))) {
    cli::cli_abort("Observed joint-predictor rows must not report imputation standard errors.")
  }
  ok_missing <- missing_rows & uncertainty_status == "ok"
  unavailable_missing <- missing_rows & !ok_missing
  if (any(!available[ok_missing]) || any(!is.finite(std_error[ok_missing])) ||
      any(std_error[ok_missing] < 0) || any(available[unavailable_missing]) ||
      any(is.finite(std_error[unavailable_missing]))) {
    cli::cli_abort("Julia joint imputation uncertainty status and standard-error availability are inconsistent.")
  }
  table
}

drm_julia_joint_result_contract <- function(result, prepared) {
  result <- as.list(result)
  payload <- prepared$payload
  if (!is.list(payload) || !identical(payload$schema, "joint_missing_v1")) {
    cli::cli_abort("Julia joint result adapter requires a joint_missing_v1 prepared payload.")
  }
  if (!identical(as.character(result$schema), "joint_missing_result_v1")) {
    cli::cli_abort("Julia joint result adapter received an unknown result schema.")
  }
  variable <- as.character(payload$variable)
  predictor <- as.character(payload$predictor)
  if (!predictor %in% c("gaussian", "bernoulli")) {
    cli::cli_abort("Julia joint result adapter received an unsupported predictor family.")
  }
  expected_blocks <- c(
    rep("mu", length(payload$mu_names)),
    rep("sigma", length(payload$sigma_names)),
    rep(paste0("mi_", variable), length(payload$predictor_names)),
    if (identical(predictor, "gaussian")) paste0("logsd_mi_", variable)
  )
  expected_terms <- c(
    payload$mu_names,
    payload$sigma_names,
    payload$predictor_names,
    if (identical(predictor, "gaussian")) "log_sd"
  )
  blocks <- as.character(unlist(result$coefficient_blocks, use.names = FALSE))
  terms <- as.character(unlist(result$coefficient_terms, use.names = FALSE))
  raw_names <- as.character(unlist(result$coef_names, use.names = FALSE))
  raw_theta <- drm_julia_joint_result_vector(result$coefficients, "coefficients")
  if (!identical(blocks, expected_blocks) || !identical(terms, expected_terms) ||
      length(raw_names) != length(expected_blocks) || length(raw_theta) != length(expected_blocks)) {
    cli::cli_abort("Julia joint result coefficient blocks do not match the prepared payload contract.")
  }
  expected_raw_names <- paste0(blocks, "_", terms)
  if (!identical(raw_names, expected_raw_names) || anyDuplicated(raw_names)) {
    cli::cli_abort("Julia joint result coefficient names do not match its explicit block metadata.")
  }
  raw_vcov_input <- drm_julia_joint_validate_raw_vcov(result, raw_names)
  raw_vcov <- drm_julia_vcov(raw_vcov_input, raw_names)
  if (!identical(dim(raw_vcov), c(length(raw_theta), length(raw_theta)))) {
    cli::cli_abort("Julia joint result covariance has the wrong dimension.")
  }
  rows <- drm_julia_joint_validate_result_rows(result, payload)
  imputation <- drm_julia_joint_validate_imputation(result, payload, rows)
  list(
    result = result,
    payload = payload,
    variable = variable,
    predictor = predictor,
    raw_names = raw_names,
    raw_theta = stats::setNames(raw_theta, raw_names),
    raw_vcov = raw_vcov,
    blocks = blocks,
    terms = terms,
    rows = rows,
    imputation = imputation
  )
}

drm_julia_joint_public_parameters <- function(contract) {
  blocks <- contract$blocks
  terms <- contract$terms
  theta <- contract$raw_theta
  V <- contract$raw_vcov
  is_logsd <- startsWith(blocks, "logsd_mi_")
  public_blocks <- blocks
  public_terms <- terms
  public_theta <- as.numeric(theta)
  jacobian <- rep(1, length(theta))
  if (any(is_logsd)) {
    public_blocks[is_logsd] <- paste0("sigma_mi_", contract$variable)
    public_terms[is_logsd] <- contract$variable
    public_theta[is_logsd] <- exp(theta[is_logsd])
    jacobian[is_logsd] <- public_theta[is_logsd]
  }
  labels <- paste(public_blocks, public_terms, sep = ":")
  if (anyDuplicated(labels)) {
    cli::cli_abort("Julia joint result produced duplicate public coefficient labels.")
  }
  J <- diag(jacobian, nrow = length(jacobian))
  public_vcov <- J %*% V %*% J
  dimnames(public_vcov) <- list(labels, labels)
  public_theta <- stats::setNames(public_theta, labels)
  block_order <- unique(public_blocks)
  coefficient_blocks <- lapply(block_order, function(block) {
    take <- public_blocks == block
    stats::setNames(public_theta[take], public_terms[take])
  })
  names(coefficient_blocks) <- block_order
  list(
    blocks = public_blocks,
    terms = public_terms,
    labels = labels,
    theta = public_theta,
    vcov = public_vcov,
    coefficient_blocks = coefficient_blocks,
    natural_sd = is_logsd
  )
}

drm_julia_joint_binary_data <- function(data, variable, levels) {
  if (!variable %in% names(data)) {
    cli::cli_abort("Joint Julia prediction needs the modelled binary predictor in newdata.")
  }
  if (length(levels) != 2L || anyNA(levels) || any(!nzchar(levels))) {
    cli::cli_abort("Joint Julia prediction lacks a valid retained binary-level map.")
  }
  value <- data[[variable]]
  observed <- !is.na(value)
  encoded <- rep(NA_real_, length(value))
  # The same fitted-level rule serves native prediction and this bridge.
  # Training design preparation retains missing entries until it supplies its
  # internal placeholder; public newdata validation still rejects them.
  encoded[observed] <- drm_prediction_binary_values(value[observed], variable, levels)
  data[[variable]] <- encoded
  data
}

drm_julia_joint_training_design_data <- function(data, variable, predictor, levels) {
  template <- data
  if (identical(predictor, "bernoulli")) {
    template <- drm_julia_joint_binary_data(template, variable, levels)
  }
  x <- template[[variable]]
  if (!is.numeric(x)) {
    cli::cli_abort("Joint Julia prediction template requires a numeric modelled predictor.")
  }
  template[[variable]][is.na(x)] <- 0
  template
}

#' Adapt a primitive joint missing-predictor Julia result to a drmTMB fit
#'
#' Internal bridge constructor for the first `engine = "julia"` joint
#' missing-predictor route. It stores the raw Julia coordinates separately and
#' exposes the Gaussian predictor SD on its natural scale.
#'
#' @keywords internal
drm_julia_joint_result <- function(result, prepared, call, formula, family) {
  contract <- drm_julia_joint_result_contract(result, prepared)
  public <- drm_julia_joint_public_parameters(contract)
  training_data <- prepared$spec$data
  predictor_levels <- if (identical(contract$predictor, "bernoulli")) {
    as.character(prepared$spec$missing_predictor$levels)
  } else {
    character(0)
  }
  training_design_data <- drm_julia_joint_training_design_data(
    training_data, contract$variable, contract$predictor, predictor_levels
  )
  base <- new_drmTMB_julia(
    result = contract$result,
    call = call,
    formula = formula,
    family = family,
    data = training_data,
    family_type = "gaussian",
    bridge_payload = contract$payload,
    requested_REML = FALSE,
    effective_REML = FALSE
  )
  n <- length(contract$payload$observed_y)
  fitted <- as.numeric(unlist(contract$result$fitted, use.names = FALSE))
  residuals <- as.numeric(unlist(contract$result$residuals, use.names = FALSE))
  sigma <- as.numeric(unlist(contract$result$sigma, use.names = FALSE))
  if (length(fitted) != n || length(residuals) != n || length(sigma) != n ||
      any(!is.finite(fitted)) || any(!is.finite(residuals[contract$rows$observed_y])) ||
      any(!is.finite(sigma)) || any(sigma <= 0)) {
    cli::cli_abort("Julia joint result fitted, residual, and sigma vectors must be finite and match the payload rows.")
  }
  residuals[!contract$rows$observed_y] <- NA_real_
  covariance_ok <- identical(as.character(contract$result$covariance_status), "observed_information_inverse") &&
    all(is.finite(public$vcov))
  base$coefficients <- public$coefficient_blocks
  base$coef_vector <- public$theta
  base$vcov <- public$vcov
  base$nobs <- as.integer(sum(contract$rows$observed_y))
  base$model$model_type <- "gaussian"
  base$model$dpars <- names(public$coefficient_blocks)
  base$fitted <- fitted
  base$residuals <- residuals
  base$sigma <- sigma
  base$missing_data <- prepared$spec$missing_data
  base$uncertainty <- list(
    status = if (covariance_ok) "ok" else as.character(contract$result$covariance_status),
    se = covariance_ok,
    finite_dpars = names(public$coefficient_blocks),
    message = if (covariance_ok) {
      "DRM.jl bridge returned the full joint covariance on public parameter scales."
    } else {
      "DRM.jl joint covariance is unavailable for Wald inference on this fit."
    }
  )
  base$joint <- list(
    schema = "joint_missing_result_v1",
    variable = contract$variable,
    predictor = contract$predictor,
    predictor_levels = predictor_levels,
    training_data_original = prepared$spec$data,
    training_design_data = training_design_data,
    blocks = public$blocks,
    terms = public$terms,
    labels = public$labels,
    natural_sd = public$natural_sd,
    raw_theta = contract$raw_theta,
    raw_vcov = contract$raw_vcov,
    imputation = contract$imputation,
    optimizer_status = as.character(contract$result$optimizer_status),
    covariance_status = as.character(contract$result$covariance_status),
    iterations = as.integer(contract$result$iterations)
  )
  class(base) <- c("drmTMB_julia_joint", "drmTMB_julia")
  base
}

#' @export
coef.drmTMB_julia_joint <- function(object, dpar = NULL, ...) {
  if (is.null(dpar)) {
    return(object$coefficients)
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  object$coefficients[[dpar]]
}

#' @export
vcov.drmTMB_julia_joint <- function(object, ...) {
  object$vcov
}

#' @export
nobs.drmTMB_julia_joint <- function(object, ...) {
  sum(as.logical(object$bridge_payload$observed_y))
}

#' @export
predict.drmTMB_julia_joint <- function(
  object,
  newdata = NULL,
  dpar = c("mu", "sigma"),
  type = c("response", "link"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("Additional arguments are not used by joint Julia predictions.")
  }
  type <- match.arg(type)
  if (missing(dpar) || is.null(dpar)) {
    dpar <- "mu"
  }
  if (!is.character(dpar) || length(dpar) != 1L || !dpar %in% c("mu", "sigma")) {
    cli::cli_abort("Joint Julia prediction currently supports mu and sigma distributional parameters only.")
  }
  if (is.null(newdata)) {
    value <- if (identical(dpar, "mu")) object$fitted else object$sigma
    return(if (identical(type, "link") && identical(dpar, "sigma")) log(value) else value)
  }
  if (!is.data.frame(newdata)) {
    cli::cli_abort("Joint Julia prediction requires newdata to be a data frame.")
  }
  if (identical(dpar, "mu") && identical(object$joint$predictor, "bernoulli")) {
    newdata <- drm_julia_joint_binary_data(
      newdata, object$joint$variable, object$joint$predictor_levels
    )
  }
  design_object <- object
  if (identical(dpar, "mu")) {
    design_object$data <- object$joint$training_design_data
  }
  fixed <- drm_julia_predict_fixed_eta(design_object, dpar, newdata, "newdata")
  if (identical(type, "link")) {
    return(fixed$eta)
  }
  if (identical(dpar, "mu")) fixed$eta else exp(fixed$eta)
}

#' @export
imputed.drmTMB_julia_joint <- function(
  object,
  variable = NULL,
  rows = c("missing", "all"),
  se = TRUE,
  include_observed,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("Additional arguments are not used by joint Julia imputation summaries.")
  }
  rows <- match.arg(rows)
  if (!missing(include_observed)) {
    if (!is.logical(include_observed) || length(include_observed) != 1L || is.na(include_observed)) {
      cli::cli_abort("include_observed must be one TRUE or FALSE value.")
    }
    rows <- if (isTRUE(include_observed)) "all" else "missing"
  }
  if (!is.logical(se) || length(se) != 1L || is.na(se)) {
    cli::cli_abort("se must be one TRUE or FALSE value.")
  }
  variable <- if (is.null(variable)) object$joint$variable else as.character(variable)
  if (length(variable) != 1L || is.na(variable) || !identical(variable, object$joint$variable)) {
    cli::cli_abort(c(
      "Unknown modelled missing predictor {.val {variable}}.",
      "i" = "This fit models {.val {object$joint$variable}}."
    ))
  }
  table <- object$joint$imputation
  required <- c(
    "variable", "original_row", "model_row", "observed", "estimate", "std_error",
    "source", "uncertainty_status", "se_available"
  )
  if (!is.list(table) || !setequal(names(table), required)) {
    cli::cli_abort("Julia joint result has an invalid imputation table.")
  }
  n <- length(table$observed)
  if (any(vapply(table[required], length, integer(1)) != n)) {
    cli::cli_abort("Julia joint result imputation columns have inconsistent lengths.")
  }
  observed <- as.logical(table$observed)
  available <- as.logical(table$se_available)
  std_error <- as.numeric(table$std_error)
  std_error[is.nan(std_error) | !available] <- NA_real_
  if (!isTRUE(se)) {
    std_error[] <- NA_real_
  }
  take <- if (identical(rows, "all")) seq_len(n) else which(!observed)
  out <- data.frame(
    variable = as.character(table$variable[take]),
    original_row = as.integer(table$original_row[take]),
    model_row = as.integer(table$model_row[take]),
    observed = observed[take],
    estimate = as.numeric(table$estimate[take]),
    std_error = std_error[take],
    source = as.character(table$source[take]),
    uncertainty_status = as.character(table$uncertainty_status[take]),
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

drm_julia_joint_summary_coefficients <- function(object) {
  V <- object$vcov
  variance <- if (isTRUE(object$uncertainty$se)) diag(V) else rep(NA_real_, nrow(V))
  se <- profile_wald_standard_errors(variance)
  estimate <- as.numeric(object$coef_vector)
  statistic <- estimate / se
  p.value <- 2 * stats::pnorm(-abs(statistic))
  statistic[object$joint$natural_sd] <- NA_real_
  p.value[object$joint$natural_sd] <- NA_real_
  data.frame(
    dpar = object$joint$blocks,
    term = object$joint$terms,
    estimate = estimate,
    std.error = se,
    statistic = statistic,
    p.value = p.value,
    stringsAsFactors = FALSE
  )
}

#' @export
summary.drmTMB_julia_joint <- function(
  object,
  conf.int = FALSE,
  level = 0.95,
  method = c("wald", "profile"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("Additional arguments are not used by joint Julia summaries.")
  }
  method <- match.arg(method)
  if (!identical(method, "wald")) {
    cli::cli_abort("Joint Julia profile inference is not implemented; use method = \"wald\" or native engine = \"tmb\".")
  }
  if (!is.logical(conf.int) || length(conf.int) != 1L || is.na(conf.int)) {
    cli::cli_abort("conf.int must be one TRUE or FALSE value.")
  }
  validate_profile_level(level)
  coefficients <- drm_julia_joint_summary_coefficients(object)
  if (isTRUE(conf.int)) {
    ci <- confint.drmTMB_julia_joint(object, level = level)
    key <- paste(coefficients$dpar, coefficients$term, sep = ":")
    hit <- match(key, ci$tmb_parameter)
    coefficients$conf.low <- ci$lower[hit]
    coefficients$conf.high <- ci$upper[hit]
    coefficients$conf.level <- level
  }
  out <- list(
    call = object$call,
    family = object$family,
    engine = "julia",
    coefficients = coefficients,
    random = data.frame(dpar = character(), term = character(), sd = numeric()),
    sigma = object$sigma,
    logLik = object$logLik,
    aic = object$aic,
    bic = object$bic,
    df = object$df,
    nobs = nobs(object),
    converged = isTRUE(object$opt$convergence == 0L),
    uncertainty = object$uncertainty
  )
  class(out) <- c("summary.drmTMB_julia_joint", "summary.drmTMB_julia")
  out
}

#' @export
confint.drmTMB_julia_joint <- function(
  object,
  parm = NULL,
  level = 0.95,
  method = c("wald", "profile", "bootstrap"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("Additional arguments are not used by joint Julia confidence intervals.")
  }
  method <- match.arg(method)
  if (!identical(method, "wald")) {
    cli::cli_abort("Joint Julia profile and bootstrap inference are not implemented; use method = \"wald\" or native engine = \"tmb\".")
  }
  validate_profile_level(level)
  labels <- object$joint$labels
  parm_labels <- paste0("fixef:", labels)
  take <- if (is.null(parm)) {
    seq_along(labels)
  } else {
    requested <- as.character(parm)
    position <- match(requested, c(labels, parm_labels))
    position <- ifelse(position > length(labels), position - length(labels), position)
    if (anyNA(position)) {
      cli::cli_abort("Unknown joint Julia confidence-interval parameter.")
    }
    as.integer(position)
  }
  estimate <- as.numeric(object$coef_vector[take])
  variance <- if (isTRUE(object$uncertainty$se)) {
    diag(object$vcov)[take]
  } else {
    rep(NA_real_, length(take))
  }
  se <- profile_wald_standard_errors(variance)
  z <- stats::qnorm((1 + level) / 2)
  ready <- is.finite(estimate) & is.finite(se)
  lower <- upper <- rep(NA_real_, length(take))
  lower[ready] <- estimate[ready] - z * se[ready]
  upper[ready] <- estimate[ready] + z * se[ready]
  scale <- ifelse(object$joint$natural_sd[take], "response", "linear_predictor")
  data.frame(
    parm = parm_labels[take],
    level = rep(level, length(take)),
    lower = lower,
    upper = upper,
    scale = scale,
    transformation = ifelse(object$joint$natural_sd[take], "exp_delta", "identity"),
    tmb_parameter = labels[take],
    index = take,
    method = rep("wald", length(take)),
    conf.status = ifelse(ready, "ok", "unavailable"),
    stringsAsFactors = FALSE
  )
}
