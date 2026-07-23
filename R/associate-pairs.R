#' Construct a latent-normal association kernel
#'
#' `latent_normal()` declares the Gaussian-copula kernel used by
#' [associate_pairs()]. It is not a Gaussian residual-correlation model and
#' does not use [rho12()].
#'
#' @return A latent-normal kernel specification.
#' @export
latent_normal <- function() {
  structure(
    list(name = "latent_normal", version = 1L),
    class = "drm_pair_kernel"
  )
}

#' Associate two frozen marginal drmTMB fits
#'
#' `associate_pairs()` estimates a named within-row association after fitting
#' two marginal models. It never refits, updates, profiles, or otherwise alters
#' either margin. Arc 6.1 implements only a fixed-effect Gaussian margin paired
#' with a fixed-effect literal Bernoulli `binomial(link = "logit")` margin on
#' the same complete analysis rows.
#'
#' The fitted parameter `eta` is a Gaussian-copula latent-normal association.
#' It is neither [rho12()], an observed-scale correlation, nor [corpairs()].
#' The [corpair()] formula marker is a distinct interface.
#' The stage-2 Hessian treats the margins as fixed, so no standard error,
#' confidence interval, profile, or coverage claim is available.
#'
#' @param fit_1,fit_2 Two fitted `drmTMB` marginal models. They must use the
#'   identical complete analysis data, in the same order.
#' @param kernel A named association kernel. Arc 6.1 accepts only
#'   `latent_normal()`.
#' @param association Association formula. Arc 6.1 accepts only `~ 1`.
#'
#' @return An object of class `drm_pair_association`.
#' @export
#'
#' @examples
#' set.seed(20260723)
#' dat <- data.frame(x = rnorm(80))
#' z_g <- rnorm(80)
#' z_b <- 0.35 * z_g + sqrt(1 - 0.35^2) * rnorm(80)
#' dat$trait_continuous <- 0.2 + 0.5 * dat$x + z_g
#' dat$trait_binary <- as.integer(z_b > qnorm(0.6))
#'
#' gaussian_fit <- drmTMB(
#'   bf(mu = trait_continuous ~ x, sigma = ~ 1),
#'   family = gaussian(), data = dat
#' )
#' binary_fit <- drmTMB(
#'   bf(mu = trait_binary ~ x), family = binomial(), data = dat
#' )
#' assoc <- associate_pairs(
#'   gaussian_fit, binary_fit,
#'   kernel = latent_normal(), association = ~ 1
#' )
#' association(assoc)
associate_pairs <- function(
  fit_1,
  fit_2,
  kernel,
  association
) {
  if (missing(kernel)) {
    cli::cli_abort(
      "Supply an explicit {.code kernel = latent_normal()} declaration."
    )
  }
  if (missing(association)) {
    cli::cli_abort(
      "Supply {.code association = ~ 1}; Arc 6.1 has no implicit association model."
    )
  }
  drm_pair_validate_kernel(kernel)
  drm_pair_validate_intercept_only(association)
  drm_pair_validate_fit(fit_1, "fit_1")
  drm_pair_validate_fit(fit_2, "fit_2")
  drm_pair_validate_shared_data(fit_1, fit_2)

  model_types <- c(fit_1$model$model_type, fit_2$model$model_type)
  if (!setequal(model_types, c("gaussian", "binomial"))) {
    cli::cli_abort(c(
      "Arc 6.1 requires one {.code gaussian()} and one {.code binomial()} fit.",
      i = "Gaussian x NB2 and other pair classes require their own Arc 6 review."
    ))
  }

  gaussian_pos <- which(model_types == "gaussian")
  binary_pos <- which(model_types == "binomial")
  fits <- list(fit_1, fit_2)
  gaussian_fit <- fits[[gaussian_pos]]
  binary_fit <- fits[[binary_pos]]
  drm_pair_validate_gaussian(gaussian_fit)
  drm_pair_validate_bernoulli(binary_fit)

  gaussian_response <- drm_pair_response_name(gaussian_fit)
  binary_response <- drm_pair_response_name(binary_fit)
  gaussian_mu <- stats::predict(gaussian_fit, dpar = "mu", type = "response")
  gaussian_sigma <- stats::predict(
    gaussian_fit,
    dpar = "sigma",
    type = "response"
  )
  binary_p <- stats::predict(binary_fit, dpar = "mu", type = "response")
  gaussian_y <- gaussian_fit$model$y
  binary_y <- binary_fit$model$y

  if (
    any(!is.finite(gaussian_mu)) ||
      any(!is.finite(gaussian_sigma)) ||
      any(gaussian_sigma <= 0) ||
      any(!is.finite(binary_p)) ||
      any(binary_p <= 0 | binary_p >= 1)
  ) {
    cli::cli_abort(
      "Frozen marginal predictions must be finite and strictly interior."
    )
  }

  components <- list(
    gaussian_y = gaussian_y,
    binary_y = binary_y,
    gaussian_mu = gaussian_mu,
    gaussian_sigma = gaussian_sigma,
    binary_p = binary_p
  )
  fit_result <- drm_pair_fit_eta(components)
  snapshot_1 <- drm_pair_margin_snapshot(fit_1)
  snapshot_2 <- drm_pair_margin_snapshot(fit_2)

  response_names <- c(
    fit_1 = drm_pair_response_name(fit_1),
    fit_2 = drm_pair_response_name(fit_2)
  )
  margin_order <- c(
    fit_1 = if (gaussian_pos == 1L) "gaussian" else "bernoulli",
    fit_2 = if (gaussian_pos == 2L) "gaussian" else "bernoulli"
  )

  structure(
    list(
      call = match.call(),
      kernel = kernel,
      association = association,
      status = fit_result$status,
      eta = fit_result$eta,
      eta_internal = fit_result$eta_internal,
      alpha = fit_result$alpha,
      logLik = fit_result$logLik,
      diagnostics = fit_result$diagnostics,
      components = components,
      response_names = response_names,
      margin_order = margin_order,
      margins = list(fit_1 = snapshot_1, fit_2 = snapshot_2),
      provenance = list(
        row_id = seq_len(nrow(fit_1$data)),
        original_row = fit_1$missing_data$original_row,
        data_hash = drm_pair_fingerprint(fit_1$data),
        fit_hashes = c(
          fit_1 = drm_pair_fingerprint(snapshot_1),
          fit_2 = drm_pair_fingerprint(snapshot_2)
        ),
        package_version = as.character(utils::packageVersion("drmTMB"))
      )
    ),
    class = "drm_pair_association"
  )
}

#' Extract a pair association estimate
#'
#' @param object A `drm_pair_association` object.
#' @param ... Reserved for future extractor options.
#'
#' @return A one-row data frame with the latent-normal association and its
#'   diagnostic status. No standard error or interval is supplied.
#' @export
association <- function(object, ...) {
  UseMethod("association")
}

#' @rdname association
#' @export
association.drm_pair_association <- function(object, ...) {
  if (identical(object$status, "boundary_unresolved")) {
    cli::cli_abort(c(
      "The association maximum is boundary-unresolved.",
      i = "Inspect {.code object$diagnostics}; Arc 6.1 does not return a public point estimate for this case."
    ))
  }
  data.frame(
    kernel = object$kernel$name,
    estimand = "latent-normal association",
    eta = object$eta,
    status = object$status,
    boundary = object$diagnostics$near_boundary,
    stringsAsFactors = FALSE
  )
}

#' @export
print.drm_pair_association <- function(x, ...) {
  cli::cli_text("<drmTMB frozen-margin pair association>")
  cli::cli_text("  kernel: {x$kernel$name}")
  cli::cli_text("  status: {x$status}")
  if (!identical(x$status, "boundary_unresolved")) {
    cli::cli_text("  eta: {format(x$eta, digits = 4)}")
  }
  cli::cli_text(
    "  standard errors: unavailable; frozen-margin point estimate only"
  )
  invisible(x)
}

#' @export
summary.drm_pair_association <- function(object, ...) {
  structure(
    list(
      association = if (identical(object$status, "boundary_unresolved")) {
        NULL
      } else {
        association(object)
      },
      diagnostics = object$diagnostics,
      provenance = object$provenance
    ),
    class = "summary.drm_pair_association"
  )
}

#' @export
print.summary.drm_pair_association <- function(x, ...) {
  cli::cli_text("<summary.drm_pair_association>")
  if (is.null(x$association)) {
    cli::cli_text("  association: boundary-unresolved")
  } else {
    cli::cli_text("  eta: {format(x$association$eta, digits = 4)}")
    cli::cli_text("  status: {x$association$status}")
  }
  cli::cli_text("  standard errors and intervals: unavailable")
  invisible(x)
}

#' @export
fitted.drm_pair_association <- function(object, ...) {
  by_role <- list(
    gaussian = object$components$gaussian_mu,
    bernoulli = object$components$binary_p
  )
  out <- data.frame(
    by_role[[object$margin_order[["fit_1"]]]],
    by_role[[object$margin_order[["fit_2"]]]],
    check.names = FALSE
  )
  names(out) <- unname(object$response_names)
  out
}

#' @export
#' @importFrom stats fitted
predict.drm_pair_association <- function(object, newdata = NULL, ...) {
  if (!is.null(newdata)) {
    cli::cli_abort(c(
      "Arc 6.1 association predictions are defined only for frozen analysis rows.",
      i = "New-data association prediction needs a separate validated Arc."
    ))
  }
  fitted(object)
}

#' @export
simulate.drm_pair_association <- function(object, nsim = 1, seed = NULL, ...) {
  if (
    !identical(object$status, "interior") &&
      !identical(object$status, "near_boundary")
  ) {
    cli::cli_abort("Cannot simulate a boundary-unresolved association fit.")
  }
  if (!is.null(seed)) {
    set.seed(seed)
  }
  if (
    !is.numeric(nsim) ||
      length(nsim) != 1L ||
      is.na(nsim) ||
      nsim < 1L ||
      nsim != as.integer(nsim)
  ) {
    cli::cli_abort("{.arg nsim} must be one positive integer.")
  }

  n <- length(object$components$gaussian_mu)
  eta <- object$eta_internal
  draws <- lapply(seq_len(as.integer(nsim)), function(i) {
    z_g <- stats::rnorm(n)
    z_b <- eta * z_g + sqrt(1 - eta^2) * stats::rnorm(n)
    y_g <- object$components$gaussian_mu +
      object$components$gaussian_sigma * z_g
    threshold <- stats::qnorm(1 - object$components$binary_p)
    y_b <- as.integer(z_b > threshold)
    by_role <- list(gaussian = y_g, bernoulli = y_b)
    data.frame(
      by_role[[object$margin_order[["fit_1"]]]],
      by_role[[object$margin_order[["fit_2"]]]],
      check.names = FALSE
    )
  })
  for (i in seq_along(draws)) {
    names(draws[[i]]) <- unname(object$response_names)
  }
  if (length(draws) == 1L) {
    return(draws[[1L]])
  }
  draws
}

#' @export
rho12.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn rho12} is defined for {.fn biv_gaussian} fits, not mixed pair associations.",
    i = "Use {.fn association} for the Arc 6.1 latent-normal estimand."
  ))
}

#' @export
corpairs.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn corpairs} requires a compatible Gaussian random-effect block.",
    i = "Arc 6.1 has fixed margins and no random-effect correlation."
  ))
}

#' @export
sigma.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "{.fn sigma} has no single meaning for a mixed frozen-margin association."
  )
}

#' @export
residuals.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "Residual diagnostics for frozen-margin pair associations are not implemented."
  )
}

#' @export
vcov.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "{.fn vcov} is unavailable for Arc 6.1 frozen-margin association estimates.",
    i = "A later Arc must validate two-stage sandwich or bootstrap uncertainty."
  ))
}

#' @export
profile.drm_pair_association <- function(fitted, ...) {
  cli::cli_abort(
    "Profile inference is unavailable for Arc 6.1 frozen-margin association estimates."
  )
}

#' @export
confint.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "Confidence intervals are unavailable for Arc 6.1 frozen-margin association estimates.",
    i = "A later Arc must validate two-stage uncertainty before {.fn confint} is available."
  ))
}

#' @export
#' @importFrom stats quantile
quantile.drm_pair_association <- function(x, ...) {
  cli::cli_abort(
    "Quantiles are unavailable for Arc 6.1 frozen-margin association estimates."
  )
}

#' @export
update.drm_pair_association <- function(object, ...) {
  cli::cli_abort(c(
    "Frozen-margin association objects cannot be updated.",
    i = "Refit declared margins separately, then construct a new {.fn associate_pairs} object."
  ))
}

#' @exportS3Method emmeans::recover_data
recover_data.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "{.pkg emmeans} is unavailable for Arc 6.1 frozen-margin association estimates."
  )
}

#' @exportS3Method emmeans::emm_basis
emm_basis.drm_pair_association <- function(object, ...) {
  cli::cli_abort(
    "{.pkg emmeans} is unavailable for Arc 6.1 frozen-margin association estimates."
  )
}

drm_pair_validate_kernel <- function(kernel) {
  if (
    !inherits(kernel, "drm_pair_kernel") ||
      !identical(kernel$name, "latent_normal")
  ) {
    cli::cli_abort(
      "Arc 6.1 requires {.code kernel = latent_normal()}."
    )
  }
}

drm_pair_validate_intercept_only <- function(association) {
  if (!inherits(association, "formula")) {
    cli::cli_abort("{.arg association} must be a formula.")
  }
  association_terms <- stats::terms(association)
  if (
    attr(association_terms, "intercept") != 1L ||
      length(attr(association_terms, "term.labels")) != 0L
  ) {
    cli::cli_abort(c(
      "Arc 6.1 supports only {.code association = ~ 1}.",
      i = "Association slopes require a later Arc and separate identification review."
    ))
  }
}

drm_pair_validate_fit <- function(fit, name) {
  if (!inherits(fit, "drmTMB")) {
    cli::cli_abort("{.arg {name}} must be a fitted {.cls drmTMB} model.")
  }
  if (isTRUE(fit$REML) || !identical(fit$estimator, "ML")) {
    cli::cli_abort("{.arg {name}} must be a fixed-effect ML marginal fit.")
  }
  if (
    !identical(fit$missing_data$response_policy, "drop") ||
      !all(fit$model$keep) ||
      nrow(fit$data) != fit$nobs
  ) {
    cli::cli_abort(c(
      "{.arg {name}} must retain one complete analysis data set without dropped rows.",
      i = "Construct the complete-pair data before fitting either margin."
    ))
  }
  random_terms <- vapply(
    fit$model$random,
    function(x) if (is.null(x$n_terms)) 0L else x$n_terms,
    integer(1L)
  )
  if (
    !is.null(fit$model$random_names) ||
      length(fit$random_effects) ||
      length(fit$sdpars) ||
      any(random_terms > 0L) ||
      isTRUE(fit$model$structured$phylo_mu$has)
  ) {
    cli::cli_abort(
      "{.arg {name}} must not contain random or structured effects."
    )
  }
  if (any(fit$model$weights != 1) || isTRUE(fit$model$has_known_v)) {
    cli::cli_abort(
      "{.arg {name}} must use unit weights and no known covariance."
    )
  }
  offsets <- fit$model$offset
  if (!is.null(offsets) && any(unlist(offsets, use.names = FALSE) != 0)) {
    cli::cli_abort("{.arg {name}} must not contain an offset.")
  }
}

drm_pair_validate_shared_data <- function(fit_1, fit_2) {
  if (
    !identical(fit_1$data, fit_2$data) ||
      !identical(
        fit_1$missing_data$original_row,
        fit_2$missing_data$original_row
      )
  ) {
    cli::cli_abort(c(
      "The two margins must be fitted on identical complete analysis data in identical row order.",
      i = "Refit both margins after constructing one complete-pair analysis data set."
    ))
  }
  variables <- unique(c(fit_1$model$variables, fit_2$model$variables))
  if (!all(stats::complete.cases(fit_1$data[, variables, drop = FALSE]))) {
    cli::cli_abort(
      "The shared analysis data contain missing response or predictor values."
    )
  }
}

drm_pair_validate_gaussian <- function(fit) {
  if (
    !identical(fit$family$link, "identity") ||
      !identical(fit$model$dpars, c("mu", "sigma"))
  ) {
    cli::cli_abort("Arc 6.1 requires the standard Gaussian mu/sigma margin.")
  }
}

drm_pair_validate_bernoulli <- function(fit) {
  if (
    !identical(fit$family$link, "logit") ||
      !identical(fit$model$dpars, "mu") ||
      any(fit$model$trials != 1) ||
      any(!fit$model$y %in% c(0, 1))
  ) {
    cli::cli_abort(c(
      "Arc 6.1 requires literal 0/1 Bernoulli data fitted with {.code binomial(link = \"logit\")}.",
      i = "Binomial trials and weights-as-trials require a later pair contract."
    ))
  }
}

drm_pair_response_name <- function(fit) {
  fit$model$response_names$mu
}

drm_pair_margin_snapshot <- function(fit) {
  list(
    call = fit$call,
    formula = fit$formula$calls,
    family = fit$family[c("family", "link")],
    coefficients = fit$coefficients,
    response_name = drm_pair_response_name(fit),
    response = fit$model$y,
    fitted = list(
      mu = stats::predict(fit, dpar = "mu", type = "response"),
      sigma = if ("sigma" %in% fit$model$dpars) {
        stats::predict(fit, dpar = "sigma", type = "response")
      } else {
        NULL
      }
    ),
    original_row = fit$missing_data$original_row,
    data_hash = drm_pair_fingerprint(fit$data),
    package_version = as.character(utils::packageVersion("drmTMB"))
  )
}

drm_pair_fingerprint <- function(x) {
  path <- tempfile("drmtmb-pair-fingerprint-", fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(x, path, version = 3)
  unname(tools::md5sum(path))
}

drm_pair_fit_eta <- function(components) {
  objective <- function(alpha) {
    value <- drm_pair_gaussian_bernoulli_loglik(alpha, components)
    if (!is.finite(value)) {
      return(.Machine$double.xmax)
    }
    -value
  }
  starts <- c(-1, 0, 1)
  fits <- lapply(starts, function(start) {
    stats::nlminb(start = start, objective = objective, lower = -8, upper = 8)
  })
  objectives <- vapply(fits, `[[`, numeric(1L), "objective")
  multistart_alpha <- vapply(
    fits,
    function(fit) unname(fit$par[[1L]]),
    numeric(1L)
  )
  best <- fits[[which.min(objectives)]]
  alpha <- unname(best$par[[1L]])
  eta_internal <- 0.999999 * tanh(alpha)
  logLik <- drm_pair_gaussian_bernoulli_loglik(alpha, components)
  h <- 1e-4
  curvature <- if (alpha > -8 + h && alpha < 8 - h) {
    (drm_pair_gaussian_bernoulli_loglik(alpha + h, components) -
      2 * logLik +
      drm_pair_gaussian_bernoulli_loglik(alpha - h, components)) /
      h^2
  } else {
    NA_real_
  }
  score <- if (alpha > -8 + h && alpha < 8 - h) {
    (drm_pair_gaussian_bernoulli_loglik(alpha + h, components) -
      drm_pair_gaussian_bernoulli_loglik(alpha - h, components)) /
      (2 * h)
  } else {
    NA_real_
  }
  near_boundary <- abs(eta_internal) >= 0.995
  objective_tolerance <- 1e-7 * (1 + abs(min(objectives)))
  multistart_disagreement <- any(
    !is.finite(objectives) |
      (objectives - min(objectives)) > objective_tolerance
  ) || (max(multistart_alpha) - min(multistart_alpha) > 1e-3)
  convergence_failure <- !identical(best$convergence, 0L)
  weak_curvature <- !is.finite(curvature) || curvature >= -1e-6
  score_failure <- !is.finite(score) || abs(score) > 1e-3
  unresolved <- abs(alpha) >= 7.99 ||
    !is.finite(logLik) ||
    convergence_failure ||
    multistart_disagreement ||
    weak_curvature ||
    score_failure
  status <- if (unresolved) {
    "boundary_unresolved"
  } else if (near_boundary) {
    "near_boundary"
  } else {
    "interior"
  }
  list(
    status = status,
    eta = if (identical(status, "boundary_unresolved")) {
      NA_real_
    } else {
      eta_internal
    },
    eta_internal = eta_internal,
    alpha = alpha,
    logLik = logLik,
    diagnostics = list(
      alpha = alpha,
      eta_internal = eta_internal,
      near_boundary = near_boundary,
      boundary_unresolved = unresolved,
      optimizer_convergence = best$convergence,
      optimizer_message = best$message,
      multistart_objectives = objectives,
      multistart_alpha = multistart_alpha,
      multistart_disagreement = multistart_disagreement,
      convergence_failure = convergence_failure,
      weak_curvature = weak_curvature,
      score_failure = score_failure,
      score = score,
      curvature = curvature,
      response_patterns = table(components$binary_y)
    )
  )
}

drm_pair_gaussian_bernoulli_loglik <- function(alpha, components) {
  eta <- 0.999999 * tanh(alpha)
  z <- (components$gaussian_y - components$gaussian_mu) /
    components$gaussian_sigma
  threshold <- stats::qnorm(1 - components$binary_p)
  conditional_z <- (threshold - eta * z) / sqrt(1 - eta^2)
  log_binary <- ifelse(
    components$binary_y == 1,
    stats::pnorm(conditional_z, lower.tail = FALSE, log.p = TRUE),
    stats::pnorm(conditional_z, log.p = TRUE)
  )
  sum(
    stats::dnorm(
      components$gaussian_y,
      mean = components$gaussian_mu,
      sd = components$gaussian_sigma,
      log = TRUE
    ) +
      log_binary
  )
}

drm_pair_gaussian_bernoulli_conditional_prob <- function(
  z,
  p,
  eta,
  binary_y
) {
  threshold <- stats::qnorm(1 - p)
  conditional_z <- (threshold - eta * z) / sqrt(1 - eta^2)
  if (length(binary_y) == 1L) {
    if (binary_y == 1) {
      return(stats::pnorm(conditional_z, lower.tail = FALSE))
    }
    return(stats::pnorm(conditional_z))
  }
  ifelse(
    binary_y == 1,
    stats::pnorm(conditional_z, lower.tail = FALSE),
    stats::pnorm(conditional_z)
  )
}
